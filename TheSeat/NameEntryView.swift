import SwiftUI

struct NameEntryView: View {
    @AppStorage("playerName") private var playerName: String = ""
    @State private var nameInput = ""
    @FocusState private var isFocused: Bool

    private let gold = Color(red: 0.85, green: 0.70, blue: 0.40)

    var body: some View {
        ZStack {
            Color(white: 0.12)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                Text("THE SEAT")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .tracking(6)
                    .foregroundStyle(gold)

                Text("What's your name?")
                    .font(.title2)
                    .foregroundStyle(.white)

                TextField("Your name", text: $nameInput)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .focused($isFocused)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(white: 0.18))
                    )
                    .padding(.horizontal, 50)
                    .onSubmit {
                        saveName()
                    }

                Button {
                    saveName()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(gold.opacity(nameInput.trimmingCharacters(in: .whitespaces).isEmpty ? 0.15 : 0.3))
                                .stroke(gold.opacity(nameInput.trimmingCharacters(in: .whitespaces).isEmpty ? 0.3 : 1.0), lineWidth: 1)
                        )
                }
                .disabled(nameInput.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, 40)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            isFocused = true
        }
    }

    private func saveName() {
        let trimmed = nameInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        playerName = trimmed
    }
}

#Preview {
    NameEntryView()
}
