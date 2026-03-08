import SwiftUI

struct VoiceNoteReminderDraft: Identifiable {
    let id = UUID()
    let noteID: UUID
    let existingReminder: VoiceNoteReminder?
    let noteText: String
    let opensAutomatically: Bool
    var title: String
    var scheduledAt: Date
}

struct VoiceNoteReminderComposerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var scheduledDate: Date

    let draft: VoiceNoteReminderDraft
    let onSave: (String, Date) -> Void

    init(draft: VoiceNoteReminderDraft, onSave: @escaping (String, Date) -> Void) {
        self.draft = draft
        self.onSave = onSave
        _title = State(initialValue: draft.title)
        _scheduledDate = State(initialValue: draft.scheduledAt)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(draft.existingReminder == nil ? "Create Reminder" : "Edit Reminder")
                                .font(.title2)
                                .bold()
                                .foregroundStyle(.black)

                            Text(draft.opensAutomatically ? "We found a possible reminder in your voice note." : "Choose when this voice note should remind you.")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Reminder")
                                .font(.headline)
                                .foregroundStyle(.black)

                            TextField("Voice Note Reminder", text: $title)
                                .textInputAutocapitalization(.sentences)
                                .foregroundStyle(.black)
                                .padding()
                                .background(Color.white)
                                .clipShape(.rect(cornerRadius: 16))
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Date & Time")
                                .font(.headline)
                                .foregroundStyle(.black)

                            DatePicker(
                                "Schedule",
                                selection: $scheduledDate,
                                in: Date()...,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.graphical)
                            .padding()
                            .background(Color.white)
                            .clipShape(.rect(cornerRadius: 16))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Voice Note")
                                .font(.headline)
                                .foregroundStyle(.black)

                            Text(draft.noteText)
                                .font(.subheadline)
                                .foregroundStyle(.black.opacity(0.75))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.92))
                                .clipShape(.rect(cornerRadius: 16))
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 120)
                }

                VStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Button {
                            onSave(sanitizedTitle, scheduledDate)
                            dismiss()
                        } label: {
                            Text("Save Alarm")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.black)
                                .clipShape(.rect(cornerRadius: 28))
                        }
                        .buttonStyle(.plain)
                        .disabled(sanitizedTitle.isEmpty)

                        Button {
                            dismiss()
                        } label: {
                            Text("Save Note Only")
                                .font(.subheadline)
                                .bold()
                                .foregroundStyle(.black.opacity(0.65))
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .background(Color("Background").ignoresSafeArea(edges: .bottom))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(.black)
                }
            }
        }
    }

    private var sanitizedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview {
    VoiceNoteReminderComposerView(
        draft: VoiceNoteReminderDraft(
            noteID: UUID(),
            existingReminder: nil,
            noteText: "Remind me tomorrow at 9 to review the design.",
            opensAutomatically: true,
            title: "Review the design",
            scheduledAt: Calendar.current.date(byAdding: .hour, value: 2, to: .now) ?? .now
        )
    ) { _, _ in }
}
