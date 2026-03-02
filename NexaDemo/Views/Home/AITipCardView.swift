import SwiftUI

struct AITipCardView: View {
    @State private var viewModel: AITipViewModel

    @MainActor
    init() {
        _viewModel = State(initialValue: AITipViewModel(service: TipsService()))
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color("BrandAccent"))

                Text("Powered by AI")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Text(displayedTip)
                .font(.body)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.leading)
                .redacted(reason: viewModel.isLoading ? .placeholder : [])
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("CardBackground"))
        .clipShape(.rect(cornerRadius: 16))
        .task {
            await viewModel.load()
        }
    }

    private var displayedTip: String {
        viewModel.tip ?? "Try scanning in steady light for sharper results."
    }
}
