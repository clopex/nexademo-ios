import FamilyControls
import SwiftUI

struct FocusSessionProposalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(FocusSessionStore.self) private var focusSessionStore

    @State private var editableProposal: FocusSessionProposal
    @State private var selection = FamilyActivitySelection()
    @State private var shouldNotifyAtEnd: Bool
    @State private var isPickerPresented = false
    @State private var isStarting = false
    @State private var errorMessage: String?

    init(proposal: FocusSessionProposal) {
        _editableProposal = State(initialValue: proposal)
        _shouldNotifyAtEnd = State(initialValue: proposal.shouldSuggestEndReminder)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Label(editableProposal.preset.title, systemImage: editableProposal.preset.systemImage)
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("Nexa prepared a focus session based on your intent. Choose what to block, adjust the duration if needed, and start.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color("CardBackground"))
                .clipShape(.rect(cornerRadius: 24))

                VStack(alignment: .leading, spacing: 16) {
                    Text("Duration")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Stepper(value: $editableProposal.durationMinutes, in: 5...180, step: 5) {
                        Text("\(editableProposal.durationMinutes) minutes")
                            .font(.title3)
                            .bold()
                            .foregroundStyle(.white)
                    }
                    .tint(Color("BrandAccent"))
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color("CardBackground"))
                .clipShape(.rect(cornerRadius: 24))

                VStack(alignment: .leading, spacing: 16) {
                    Text("Suggested blocks")
                        .font(.headline)
                        .foregroundStyle(.white)

                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(editableProposal.suggestedCategories, id: \.self) { category in
                                Text(category)
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Color("PremiumGradientStart"))
                                    .clipShape(.capsule)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color("CardBackground"))
                .clipShape(.rect(cornerRadius: 24))

                VStack(alignment: .leading, spacing: 16) {
                    Button("Choose Apps & Websites", systemImage: "checklist") {
                        Task {
                            do {
                                try await focusSessionStore.requestAuthorizationIfNeeded()
                                isPickerPresented = true
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color("PremiumGradientStart"))
                    .clipShape(.rect(cornerRadius: 20))
                    .buttonStyle(.plain)

                    Text(selectionSummary)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color("CardBackground"))
                .clipShape(.rect(cornerRadius: 24))

                Toggle(isOn: $shouldNotifyAtEnd) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notify me when session ends")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Nexa can remind you when the focus window is over.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .tint(Color("BrandAccent"))
                .padding(20)
                .background(Color("CardBackground"))
                .clipShape(.rect(cornerRadius: 24))

                Button(isStarting ? "Starting..." : "Start Session", systemImage: "sparkles") {
                    Task {
                        isStarting = true
                        do {
                            try await focusSessionStore.startSession(
                                proposal: editableProposal,
                                selection: selection,
                                shouldNotifyAtEnd: shouldNotifyAtEnd
                            )
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                        isStarting = false
                    }
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color("BrandAccent").opacity(canStart ? 1 : 0.35))
                .clipShape(.rect(cornerRadius: 28))
                .buttonStyle(.plain)
                .disabled(!canStart || isStarting)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(Color("BackgroundDark").ignoresSafeArea())
        .navigationTitle("AI Focus")
        .navigationBarTitleDisplayMode(.inline)
        .familyActivityPicker(isPresented: $isPickerPresented, selection: $selection)
        .alert("Focus Session", isPresented: errorIsPresented) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "Something went wrong.")
        }
    }

    private var canStart: Bool {
        selection.applicationTokens.isEmpty == false
            || selection.categoryTokens.isEmpty == false
            || selection.webDomainTokens.isEmpty == false
    }

    private var selectionSummary: String {
        let selectedApps = selection.applicationTokens.count
        let selectedCategories = selection.categoryTokens.count
        let selectedDomains = selection.webDomainTokens.count
        let total = selectedApps + selectedCategories + selectedDomains

        if total == 0 {
            return "No distractions selected yet. Pick apps, categories, or websites to block."
        }

        return "Blocking \(selectedApps) apps, \(selectedCategories) categories, and \(selectedDomains) websites."
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { newValue in
                if newValue == false {
                    errorMessage = nil
                }
            }
        )
    }
}

#Preview {
    NavigationStack {
        FocusSessionProposalView(
            proposal: FocusAIParserService().defaultProposal()
        )
        .environment(FocusSessionStore())
    }
}
