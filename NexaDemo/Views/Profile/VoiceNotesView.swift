import SwiftUI
import SwiftData

struct VoiceNotesView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VoiceNote.createdAt, order: .reverse) private var notes: [VoiceNote]
    @State private var speechService: SpeechService
    @State private var showingRecorder = false
    @State private var editingNote: VoiceNote?
    @State private var isRecorderPrewarmed = false

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
                        onEdit: { editingNote = $0 },
                        onDelete: deleteNote
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
    }

    private func saveNote(text: String, duration: TimeInterval) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let note = VoiceNote(text: trimmed)
        modelContext.insert(note)
        VoiceNoteDurationStore.setDuration(duration, for: note.id)
        let allNotes = [note] + notes
        syncWidgetUsage(with: allNotes)
    }

    private func deleteNote(_ note: VoiceNote) {
        modelContext.delete(note)
        VoiceNoteDurationStore.removeDuration(for: note.id)
        let remaining = notes.filter { $0.id != note.id }
        syncWidgetUsage(with: remaining)
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
}

#Preview {
    NavigationStack {
        VoiceNotesView()
    }
    .modelContainer(for: VoiceNote.self)
}
