import SwiftUI

struct NexaPlacesResultsPanelView: View {
    let results: [NexaPlaceSearchResult]
    let selectedResult: NexaPlaceSearchResult?
    let isAddingToWallet: Bool
    let onSelect: (NexaPlaceSearchResult) -> Void
    let onRoute: () -> Void
    let onOpenInMaps: () -> Void
    let onPlanVisit: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if results.isEmpty == false {
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(results) { result in
                            NexaPlacesResultChipView(
                                result: result,
                                isSelected: selectedResult?.id == result.id,
                                action: { onSelect(result) }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .scrollIndicators(.hidden)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if let selectedResult {
                NexaPlaceDetailCardView(
                    result: selectedResult,
                    isAddingToWallet: isAddingToWallet,
                    onRoute: onRoute,
                    onOpenInMaps: onOpenInMaps,
                    onPlanVisit: onPlanVisit
                )
                .padding(.horizontal, 16)
                .transition(.move(edge: .bottom).combined(with: .scale(scale: 0.96)).combined(with: .opacity))
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 16)
        .animation(.spring(response: 0.3, dampingFraction: 0.82), value: results.count)
        .animation(.spring(response: 0.3, dampingFraction: 0.82), value: selectedResult?.id)
    }
}
