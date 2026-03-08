import SwiftUI

struct VoiceNotesListView: View {
    let notes: [VoiceNote]
    let remindersByNoteID: [UUID: VoiceNoteReminder]
    let onEdit: (VoiceNote) -> Void
    let onDelete: (VoiceNote) -> Void
    let onAddReminder: (VoiceNote) -> Void
    let onEditReminder: (VoiceNoteReminder) -> Void
    let onRemoveReminder: (VoiceNoteReminder) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(notes) { note in
                    NoteCard(
                        note: note,
                        reminder: remindersByNoteID[note.id],
                        onEdit: { onEdit(note) },
                        onDelete: { onDelete(note) },
                        onAddReminder: { onAddReminder(note) },
                        onEditReminder: {
                            guard let reminder = remindersByNoteID[note.id] else { return }
                            onEditReminder(reminder)
                        },
                        onRemoveReminder: {
                            guard let reminder = remindersByNoteID[note.id] else { return }
                            onRemoveReminder(reminder)
                        }
                    )
                }
            }
            .padding(16)
            .padding(.bottom, 100)
        }
    }
}
