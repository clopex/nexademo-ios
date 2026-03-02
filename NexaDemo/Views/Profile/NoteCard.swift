import SwiftUI

struct NoteCard: View {
    let note: VoiceNote
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.text)
                .font(.body)
                .foregroundStyle(.white)
                .lineLimit(4)
                .multilineTextAlignment(.leading)

            HStack {
                Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.gray)

                Spacer()

                Button("Edit", systemImage: "pencil", action: onEdit)
                    .labelStyle(.iconOnly)
                    .foregroundStyle(Color("BrandAccent"))
                    .padding(8)

                Button("Delete", systemImage: "trash", action: onDelete)
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.gray)
                    .padding(8)
            }
        }
        .padding(16)
        .background(Color("CardBackground"))
        .clipShape(.rect(cornerRadius: 16))
    }
}
