import SwiftUI
import SwiftData

struct VoiceNotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VoiceNote.createdAt, order: .reverse) private var notes: [VoiceNote]
    @State private var speechService: SpeechService
    @State private var showingRecorder = false
    @State private var editingNote: VoiceNote?

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
                    showingRecorder = true
                }
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Voice Notes")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingRecorder) {
            VoiceRecorderSheet(speechService: speechService) { text, duration in
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
    }

    private func deleteNote(_ note: VoiceNote) {
        modelContext.delete(note)
        VoiceNoteDurationStore.removeDuration(for: note.id)
    }
}

#Preview {
    NavigationStack {
        VoiceNotesView()
    }
    .modelContainer(for: VoiceNote.self)
}
