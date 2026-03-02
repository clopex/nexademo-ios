import SwiftUI

struct VoiceNotesListView: View {
    let notes: [VoiceNote]
    let onEdit: (VoiceNote) -> Void
    let onDelete: (VoiceNote) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(notes) { note in
                    NoteCard(
                        note: note,
                        onEdit: { onEdit(note) },
                        onDelete: { onDelete(note) }
                    )
                }
            }
            .padding(16)
            .padding(.bottom, 100)
        }
    }
}
