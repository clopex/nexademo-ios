import MapKit
import SwiftUI

struct NexaPlacesView: View {
    @Environment(NexaPlacesCoordinator.self) private var coordinator
    @State private var viewModel: NexaPlacesViewModel
    @State private var isHeaderVisible = true

    init(initialQuery: String?) {
        _viewModel = State(initialValue: NexaPlacesViewModel(initialQuery: initialQuery))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack(alignment: .bottomLeading) {
            Map(position: $viewModel.cameraPosition) {
                UserAnnotation()

                ForEach(viewModel.results) { result in
                    Annotation(result.name, coordinate: result.coordinate, anchor: .bottom) {
                        Button {
                            viewModel.select(result)
                        } label: {
                            NexaPlacesAnnotationView(
                                isSelected: viewModel.selectedResult?.id == result.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea(edges: .bottom)

            NexaPlacesMapControlsView(
                onResetTap: viewModel.resetSearch,
                onRecenterTap: viewModel.recenterOnUser
            )
            .padding(.leading, 16)
            .padding(.bottom, viewModel.results.isEmpty ? 24 : 52)
            .animation(.spring(response: 0.32, dampingFraction: 0.84), value: viewModel.selectedResult?.id)
            .animation(.spring(response: 0.32, dampingFraction: 0.84), value: viewModel.results.count)
        }
        .background(Color("BackgroundDark").ignoresSafeArea())
        .navigationTitle("Nexa Places")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .overlay(alignment: .top) {
            ZStack(alignment: .topTrailing) {
                NexaPlacesHeaderView(
                    onClose: {
                        withAnimation(.easeInOut(duration: 0.24)) {
                            isHeaderVisible = false
                        }
                    },
                    statusMessage: viewModel.statusMessage,
                    hasError: viewModel.errorMessage != nil
                )
                .opacity(isHeaderVisible ? 1 : 0)
                .scaleEffect(isHeaderVisible ? 1 : 0.97, anchor: .top)
                .offset(y: isHeaderVisible ? 0 : -18)
                .allowsHitTesting(isHeaderVisible)
                .animation(.easeInOut(duration: 0.24), value: isHeaderVisible)

                NexaPlacesHeaderToggleView {
                    withAnimation(.easeInOut(duration: 0.24)) {
                        isHeaderVisible = true
                    }
                }
                .opacity(isHeaderVisible ? 0 : 1)
                .offset(y: isHeaderVisible ? -10 : 0)
                .allowsHitTesting(isHeaderVisible == false)
                .animation(.easeInOut(duration: 0.24), value: isHeaderVisible)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .safeAreaInset(edge: .bottom) {
            NexaPlacesResultsPanelView(
                results: viewModel.results,
                selectedResult: viewModel.selectedResult,
                onSelect: viewModel.select,
                onRoute: viewModel.openDirections,
                onOpenInMaps: viewModel.openInMaps
            )
        }
        .task {
            await viewModel.prepare()
        }
        .task(id: coordinator.queryVersion) {
            guard coordinator.isVisible else { return }
            guard let query = coordinator.consumePendingQuery() else { return }
            await viewModel.search(for: query)
        }
        .onAppear {
            coordinator.isVisible = true
        }
        .onDisappear {
            coordinator.isVisible = false
            viewModel.stop()
        }
    }
}
