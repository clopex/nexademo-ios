import SwiftUI
import SwiftData

struct EditNoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var note: VoiceNote
    @State private var editedText = ""

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 24) {
                Color.gray.opacity(0.4)
                    .frame(width: 40, height: 4)
                    .clipShape(.rect(cornerRadius: 3))
                    .padding(.top, 12)

                Text("Edit Note")
                    .font(.title3)
                    .bold()
                    .foregroundStyle(.white)

                TextEditor(text: $editedText)
                    .scrollContentBackground(.hidden)
                    .background(Color("CardBackground"))
                    .foregroundStyle(.white)
                    .clipShape(.rect(cornerRadius: 16))
                    .padding(.horizontal, 24)

                Button("Save Changes") {
                    note.text = editedText
                    note.updatedAt = Date()
                    dismiss()
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .contentShape(.rect)
                .background(Color("BrandAccent"))
                .clipShape(.rect(cornerRadius: 28))
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .task {
            editedText = note.text
        }
    }
}
