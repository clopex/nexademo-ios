import SwiftUI

struct NoteCard: View {
    let note: VoiceNote
    let reminder: VoiceNoteReminder?
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onAddReminder: () -> Void
    let onEditReminder: () -> Void
    let onRemoveReminder: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.text)
                .font(.body)
                .foregroundStyle(.white)
                .lineLimit(4)
                .multilineTextAlignment(.leading)

            if let reminder {
                VoiceNoteReminderRow(
                    reminder: reminder,
                    onEdit: onEditReminder,
                    onRemove: onRemoveReminder
                )
            } else {
                Button("Add Reminder", systemImage: "alarm") {
                    onAddReminder()
                }
                .font(.caption)
                .bold()
                .foregroundStyle(Color("SuccessAccent"))
                .buttonStyle(.plain)
            }

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

private struct VoiceNoteReminderRow: View {
    let reminder: VoiceNoteReminder
    let onEdit: () -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "alarm")
                    .foregroundStyle(Color("SuccessAccent"))

                VStack(alignment: .leading, spacing: 2) {
                    Text(reminder.title)
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(.white)

                    Text(reminder.scheduledAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.gray)
                }

                Spacer()
            }

            HStack(spacing: 14) {
                Button("Edit Reminder", systemImage: "square.and.pencil", action: onEdit)
                    .font(.caption)
                    .foregroundStyle(Color("BrandAccent"))

                Button("Remove Reminder", systemImage: "trash", role: .destructive, action: onRemove)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .clipShape(.rect(cornerRadius: 14))
    }
}
