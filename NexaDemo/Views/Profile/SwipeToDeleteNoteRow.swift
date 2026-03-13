import SwiftUI

struct SwipeToDeleteNoteRow<Content: View>: View {
    let onDelete: () -> Void
    @ViewBuilder let content: Content

    @State private var offset: CGFloat = 0
    @GestureState private var dragTranslation: CGFloat = 0

    private let revealWidth: CGFloat = 92
    private let triggerThreshold: CGFloat = 120

    var body: some View {
        ZStack(alignment: .trailing) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.red.opacity(0.9))

            Button("Delete", systemImage: "trash", action: handleDelete)
                .foregroundStyle(.white)
                .padding(.trailing, 18)
                .opacity(actionOpacity)
                .disabled(isActionVisible == false)

            content
                .offset(x: contentOffset)
                .simultaneousGesture(dragGesture)
        }
        .clipShape(.rect(cornerRadius: 16))
        .animation(.spring(response: 0.24, dampingFraction: 0.86), value: offset)
    }

    private var contentOffset: CGFloat {
        let proposedOffset = offset + dragTranslation
        return min(0, max(-triggerThreshold, proposedOffset))
    }

    private var isActionVisible: Bool {
        contentOffset <= -20
    }

    private var actionOpacity: CGFloat {
        min(1, max(0, -contentOffset / revealWidth))
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .updating($dragTranslation) { value, state, _ in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                let translation = value.translation.width
                if translation < 0 || offset < 0 {
                    state = translation
                }
            }
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                let finalOffset = min(0, max(-triggerThreshold, offset + value.translation.width))
                if finalOffset <= -triggerThreshold {
                    handleDelete()
                } else if finalOffset <= -revealWidth / 2 {
                    offset = -revealWidth
                } else {
                    offset = 0
                }
            }
    }

    private func handleDelete() {
        offset = 0
        onDelete()
    }
}
