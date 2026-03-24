import SwiftUI

struct NexaPlaceVisitPlanDraft: Identifiable {
    let id = UUID()
    let result: NexaPlaceSearchResult
    var title: String
    var scheduledAt: Date
    var note: String

    init(result: NexaPlaceSearchResult) {
        self.result = result
        title = "Visit \(result.name)"
        scheduledAt = Calendar.current.date(byAdding: .hour, value: 2, to: .now) ?? .now
        note = ""
    }
}

struct NexaPlaceVisitPlanSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var scheduledAt: Date
    @State private var note: String

    let draft: NexaPlaceVisitPlanDraft
    let onSave: (String, Date, String) -> Void

    init(draft: NexaPlaceVisitPlanDraft, onSave: @escaping (String, Date, String) -> Void) {
        self.draft = draft
        self.onSave = onSave
        _title = State(initialValue: draft.title)
        _scheduledAt = State(initialValue: draft.scheduledAt)
        _note = State(initialValue: draft.note)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Visit Plan")
                                .font(.title2)
                                .bold()
                                .foregroundStyle(.black)

                            Text("Save a planned visit for \(draft.result.name) to Apple Wallet.")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Title")
                                .font(.headline)
                                .foregroundStyle(.black)

                            TextField("Visit title", text: $title)
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
                                "Planned time",
                                selection: $scheduledAt,
                                in: Date()...,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.graphical)
                            .padding()
                            .background(Color.white)
                            .clipShape(.rect(cornerRadius: 16))
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Note")
                                .font(.headline)
                                .foregroundStyle(.black)

                            TextField("Dinner with friends, meeting point, table note...", text: $note, axis: .vertical)
                                .lineLimit(3...5)
                                .textInputAutocapitalization(.sentences)
                                .foregroundStyle(.black)
                                .padding()
                                .background(Color.white)
                                .clipShape(.rect(cornerRadius: 16))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Place")
                                .font(.headline)
                                .foregroundStyle(.black)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(draft.result.name)
                                    .font(.body)
                                    .bold()
                                if draft.result.address.isEmpty == false {
                                    Text(draft.result.address)
                                        .font(.subheadline)
                                        .foregroundStyle(.black.opacity(0.72))
                                }
                            }
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
                            onSave(sanitizedTitle, scheduledAt, sanitizedNote)
                            dismiss()
                        } label: {
                            Text("Save to Wallet")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.black)
                                .clipShape(.rect(cornerRadius: 28))
                        }
                        .buttonStyle(.plain)
                        .disabled(sanitizedTitle.isEmpty)
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

    private var sanitizedNote: String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
