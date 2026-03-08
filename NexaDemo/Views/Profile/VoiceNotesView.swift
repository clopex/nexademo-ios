import SwiftUI
import SwiftData

struct VoiceNotesView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VoiceNote.createdAt, order: .reverse) private var notes: [VoiceNote]
    @Query(sort: \VoiceNoteReminder.createdAt, order: .reverse) private var reminders: [VoiceNoteReminder]
    @State private var speechService: SpeechService
    @State private var showingRecorder = false
    @State private var editingNote: VoiceNote?
    @State private var reminderDraft: VoiceNoteReminderDraft?
    @State private var reminderErrorMessage: String?
    @State private var isRecorderPrewarmed = false
    private let reminderParser = VoiceNoteReminderParser()

    @MainActor
    init() {
        _speechService = State(initialValue: SpeechService())
    }

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 0) {
                if notes.isEmpty {
                    VoiceNotesEmptyStateView()
                } else {
                    VoiceNotesListView(
                        notes: notes,
                        remindersByNoteID: remindersByNoteID,
                        onEdit: { editingNote = $0 },
                        onDelete: deleteNote,
                        onAddReminder: openReminderComposer(for:),
                        onEditReminder: openReminderComposer(for:),
                        onRemoveReminder: removeReminder
                    )
                }
            }

            VStack {
                Spacer()
                VoiceNotesFloatingButton {
                    Task { await presentRecorder() }
                }
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Voice Notes")
        .navigationBarTitleDisplayMode(.large)
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
    }

    private func saveNote(text: String, duration: TimeInterval) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let note = VoiceNote(text: trimmed)
        modelContext.insert(note)
        VoiceNoteDurationStore.setDuration(duration, for: note.id)
        let allNotes = [note] + notes
        syncWidgetUsage(with: allNotes)

        if let candidate = reminderParser.parseCandidate(from: trimmed) {
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

    @MainActor
    private func presentRecorder() async {
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
        let candidate = reminderParser.parseCandidate(from: note.text)
        reminderDraft = makeDraft(
            for: note,
            existingReminder: nil,
            candidate: candidate,
            opensAutomatically: false
        )
    }

    private func openReminderComposer(for reminder: VoiceNoteReminder) {
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
}

#Preview {
    NavigationStack {
        VoiceNotesView()
    }
    .modelContainer(for: [VoiceNote.self, VoiceNoteReminder.self])
}
