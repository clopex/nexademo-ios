import SwiftUI

struct VoiceNoteDeleteConfirmationView: View {
    let note: VoiceNote
    let onCancel: () -> Void
    let onConfirm: () -> Void
    @State private var isPresented = false

    var body: some View {
        ZStack {
            Button(action: onCancel) {
                Color.black.opacity(isPresented ? 0.62 : 0)
                    .ignoresSafeArea()
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.red.opacity(0.28), Color.red.opacity(0.12)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 52, height: 52)
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white, .red)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Delete voice note?")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("This action will permanently remove the note.")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }

                    Spacer(minLength: 0)
                }

                Text(note.text)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.88))
                    .lineLimit(3)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.06))
                    )

                HStack(spacing: 12) {
                    Button("Cancel", action: onCancel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.08))
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 16))

                    Button("Delete", action: onConfirm)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.red, Color.red.opacity(0.78)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 16))
                }
                .bold()
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color("CardBackground"))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            }
            .padding(.horizontal, 24)
            .shadow(color: .black.opacity(0.32), radius: 28, x: 0, y: 18)
            .scaleEffect(isPresented ? 1 : 0.92)
            .opacity(isPresented ? 1 : 0)
            .offset(y: isPresented ? 0 : 18)
        }
        .onAppear {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                isPresented = true
            }
        }
        .onDisappear {
            isPresented = false
        }
    }
}
