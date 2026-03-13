import SwiftUI

struct VoiceNotesListView: View {
    let notes: [VoiceNote]
    let remindersByNoteID: [UUID: VoiceNoteReminder]
    let onEdit: (VoiceNote) -> Void
    let onDelete: (VoiceNote) -> Void
    let onDeleteOffsets: (IndexSet) -> Void
    let onAddReminder: (VoiceNote) -> Void
    let onEditReminder: (VoiceNoteReminder) -> Void
    let onRemoveReminder: (VoiceNoteReminder) -> Void

    var body: some View {
        List {
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
                .listRowInsets(.init())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
            .onDelete(perform: onDeleteOffsets)
            
            Color.clear
                .frame(height: 92)
                .listRowInsets(.init())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }
}
