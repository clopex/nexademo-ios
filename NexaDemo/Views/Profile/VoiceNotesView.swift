import SwiftUI
import SwiftData

struct VoiceNotesView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(AppTabRouter.self) private var tabRouter
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VoiceNote.createdAt, order: .reverse) private var notes: [VoiceNote]
    @Query(sort: \VoiceNoteReminder.createdAt, order: .reverse) private var reminders: [VoiceNoteReminder]
    @State private var speechService: SpeechService
    @State private var showingRecorder = false
    @State private var editingNote: VoiceNote?
    @State private var notePendingDeletion: VoiceNote?
    @State private var reminderDraft: VoiceNoteReminderDraft?
    @State private var reminderErrorMessage: String?
    @State private var isRecorderPrewarmed = false
    @State private var showToast = false
    @State private var toast = Toast.example
    private let reminderParser = VoiceNoteReminderParser()

    @MainActor
    init() {
        _speechService = State(initialValue: SpeechService())
    }

    var body: some View {
        ZStack {
            Color("BackgroundDark").ignoresSafeArea()

            VStack(spacing: 0) {
                if notes.isEmpty {
                    VoiceNotesEmptyStateView()
                } else {
                    VoiceNotesListView(
                        notes: notes,
                        remindersByNoteID: remindersByNoteID,
                        onEdit: { editingNote = $0 },
                        onDelete: requestDeleteConfirmation,
                        onDeleteOffsets: requestDeleteConfirmation,
                        onAddReminder: openReminderComposer(for:),
                        onEditReminder: openReminderComposer(for:),
                        onRemoveReminder: removeReminder
                    )
                }
            }
            .blur(radius: notePendingDeletion == nil ? 0 : 2)
            .scaleEffect(notePendingDeletion == nil ? 1 : 0.985)
            .animation(.spring(response: 0.32, dampingFraction: 0.86), value: notePendingDeletion != nil)

            VStack {
                Spacer()
                VoiceNotesFloatingButton {
                    Task { await presentRecorder() }
                }
                .padding(.bottom, 24)
            }

            if let notePendingDeletion {
                VoiceNoteDeleteConfirmationView(
                    note: notePendingDeletion,
                    onCancel: dismissDeleteConfirmation,
                    onConfirm: confirmPendingDeletion
                )
                .transition(
                    .asymmetric(
                        insertion: .scale(scale: 0.94).combined(with: .opacity),
                        removal: .scale(scale: 0.98).combined(with: .opacity)
                    )
                )
            }
        }
        .navigationTitle("Voice Notes")
        .navigationBarTitleDisplayMode(.inline)
        .dynamicIslandToasts(isPresented: $showToast, value: toast)
        .sheet(isPresented: $showingRecorder) {
            VoiceRecorderSheet(
                speechService: speechService,
                initialHasPermission: isRecorderPrewarmed
            ) { text, duration in
                saveNote(text: text, duration: duration)
            }
        }
        .sheet(item: $editingNote) { note in
            EditNoteSheet(note: note)
        }
        .sheet(item: $reminderDraft) { draft in
            VoiceNoteReminderComposerView(draft: draft) { title, scheduledAt in
                Task {
                    await saveReminder(
                        for: draft.noteID,
                        existingReminder: draft.existingReminder,
                        title: title,
                        scheduledAt: scheduledAt
                    )
                }
            }
        }
        .alert("Reminder Error", isPresented: reminderErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(reminderErrorMessage ?? "Something went wrong while scheduling your alarm.")
        }
        .onAppear {
            syncFreePlanUsage()
        }
        .onChange(of: notes.count) { _, _ in
            syncFreePlanUsage()
        }
        .onChange(of: authVM.currentUser?.id) { _, _ in
            syncFreePlanUsage()
        }
    }

    private func saveNote(text: String, duration: TimeInterval) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let note = VoiceNote(text: trimmed)
        modelContext.insert(note)
        if let userID = authVM.currentUser?.id {
            FreePlanUsageStore.registerVoiceNoteCreated(for: userID)
        }
        VoiceNoteDurationStore.setDuration(duration, for: note.id)
        let allNotes = [note] + notes
        syncWidgetUsage(with: allNotes)

        if let candidate = reminderParser.parseCandidate(from: trimmed) {
            guard isPremium else {
                presentUpgradePaywall()
                return
            }
            reminderDraft = makeDraft(for: note, existingReminder: nil, candidate: candidate, opensAutomatically: true)
        }
    }

    private func deleteNote(_ note: VoiceNote) {
        Task {
            if let reminder = remindersByNoteID[note.id] {
                await deleteReminder(reminder)
            }

            modelContext.delete(note)
            VoiceNoteDurationStore.removeDuration(for: note.id)
            let remaining = notes.filter { $0.id != note.id }
            syncWidgetUsage(with: remaining)
        }
    }

    private func requestDeleteConfirmation(for note: VoiceNote) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            notePendingDeletion = note
        }
    }

    private func requestDeleteConfirmation(at offsets: IndexSet) {
        guard let index = offsets.first, notes.indices.contains(index) else { return }
        requestDeleteConfirmation(for: notes[index])
    }

    private func dismissDeleteConfirmation() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.88)) {
            notePendingDeletion = nil
        }
    }

    private func confirmPendingDeletion() {
        guard let notePendingDeletion else { return }
        dismissDeleteConfirmation()
        deleteNote(notePendingDeletion)
    }

    @MainActor
    private func presentRecorder() async {
        guard canCreateVoiceNote else {
            presentVoiceNoteUpgradeToast()
            return
        }

        let granted = await speechService.requestPermissions()
        if granted {
            await speechService.prepareForRecording()
        }

        isRecorderPrewarmed = granted
        showingRecorder = true
    }

    private func syncWidgetUsage(with sourceNotes: [VoiceNote]) {
        let isPremium = authVM.currentUser?.isPremium ?? false
        let userName = authVM.currentUser?.fullName ?? ""
        let scansToday = AIScanAttemptStore.shared.todayCount()
        let totalVoiceSeconds = Int(VoiceNoteDurationStore.totalDuration(for: sourceNotes).rounded())

        WidgetDataService.shared.syncUsage(
            isPremium: isPremium,
            userName: userName,
            voiceNotesCount: sourceNotes.count,
            voiceSecondsToday: totalVoiceSeconds,
            aiScansToday: scansToday
        )
    }

    private var remindersByNoteID: [UUID: VoiceNoteReminder] {
        Dictionary(uniqueKeysWithValues: reminders.map { ($0.voiceNoteID, $0) })
    }

    private var reminderErrorBinding: Binding<Bool> {
        Binding(
            get: { reminderErrorMessage != nil },
            set: { if !$0 { reminderErrorMessage = nil } }
        )
    }

    private func openReminderComposer(for note: VoiceNote) {
        guard isPremium else {
            presentUpgradePaywall()
            return
        }

        let candidate = reminderParser.parseCandidate(from: note.text)
        reminderDraft = makeDraft(
            for: note,
            existingReminder: nil,
            candidate: candidate,
            opensAutomatically: false
        )
    }

    private func openReminderComposer(for reminder: VoiceNoteReminder) {
        guard isPremium else {
            presentUpgradePaywall()
            return
        }

        guard let note = notes.first(where: { $0.id == reminder.voiceNoteID }) else { return }
        reminderDraft = VoiceNoteReminderDraft(
            noteID: note.id,
            existingReminder: reminder,
            noteText: note.text,
            opensAutomatically: false,
            title: reminder.title,
            scheduledAt: reminder.scheduledAt
        )
    }

    private func makeDraft(
        for note: VoiceNote,
        existingReminder: VoiceNoteReminder?,
        candidate: VoiceNoteReminderCandidate?,
        opensAutomatically: Bool
    ) -> VoiceNoteReminderDraft {
        let defaultDate = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now

        return VoiceNoteReminderDraft(
            noteID: note.id,
            existingReminder: existingReminder,
            noteText: note.text,
            opensAutomatically: opensAutomatically,
            title: candidate?.suggestedTitle ?? reminderParser.defaultTitle(from: note.text),
            scheduledAt: candidate?.suggestedDate ?? existingReminder?.scheduledAt ?? defaultDate
        )
    }

    @MainActor
    private func saveReminder(
        for noteID: UUID,
        existingReminder: VoiceNoteReminder?,
        title: String,
        scheduledAt: Date
    ) async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let reminder = existingReminder ?? VoiceNoteReminder(
            voiceNoteID: noteID,
            title: trimmedTitle,
            scheduledAt: scheduledAt
        )

        if existingReminder == nil {
            modelContext.insert(reminder)
        }

        reminder.title = trimmedTitle
        reminder.scheduledAt = scheduledAt
        reminder.isEnabled = true
        reminder.updatedAt = .now

        do {
            let alarmID = try await AlarmService.shared.schedule(reminder: reminder)
            reminder.systemAlarmID = alarmID

            if reminder.liveActivityID == nil {
                reminder.liveActivityID = await AlarmLiveActivityService.shared.start(for: reminder)
            } else {
                await AlarmLiveActivityService.shared.update(for: reminder)
            }

            clearOtherLiveActivityIDs(except: reminder.id)
        } catch {
            reminderErrorMessage = error.localizedDescription
        }
    }

    private func removeReminder(_ reminder: VoiceNoteReminder) {
        Task {
            await deleteReminder(reminder)
        }
    }

    @MainActor
    private func deleteReminder(_ reminder: VoiceNoteReminder) async {
        AlarmService.shared.cancelAlarm(id: reminder.systemAlarmID)
        await AlarmLiveActivityService.shared.end(for: reminder)
        modelContext.delete(reminder)
    }

    private func clearOtherLiveActivityIDs(except reminderID: UUID) {
        for reminder in reminders where reminder.id != reminderID {
            reminder.liveActivityID = nil
        }
    }

    private var isPremium: Bool {
        authVM.currentUser?.isPremium ?? false
    }

    private var canCreateVoiceNote: Bool {
        guard let userID = authVM.currentUser?.id else { return true }
        return FreePlanUsageStore.canCreateVoiceNote(for: userID, isPremium: isPremium)
    }

    private func syncFreePlanUsage() {
        guard let userID = authVM.currentUser?.id else { return }
        FreePlanUsageStore.syncVoiceNotesCreated(to: notes.count, for: userID)
    }

    private func presentUpgradePaywall() {
        tabRouter.selectedTab = .premium
    }

    @MainActor
    private func presentVoiceNoteUpgradeToast() {
        toast = Toast(
            symbol: "crown.fill",
            symbolFont: .system(size: 28),
            symbolForegrgoundStyle: (.white, Color("SuccessAccent")),
            title: "Upgrade required",
            message: "Free plan supports up to 3 voice notes."
        )
        showToast = true

        Task {
            try? await Task.sleep(for: .seconds(1.4))
            showToast = false
            tabRouter.selectedTab = .premium
        }
    }
}

#Preview {
    NavigationStack {
        VoiceNotesView()
    }
    .modelContainer(for: [VoiceNote.self, VoiceNoteReminder.self])
}
