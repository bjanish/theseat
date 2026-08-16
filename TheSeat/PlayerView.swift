import SwiftUI

struct PlayerView: View {
    @Environment(SessionManager.self) private var sessionManager
    @State private var questionText = ""
    @State private var hasAsked = false
    @State private var pendingQuestion: String?
    @FocusState private var isInputFocused: Bool

    private let characterLimit = 150
    private let gold = Color(red: 0.85, green: 0.70, blue: 0.40)

    var body: some View {
        ZStack {
            Color(white: 0.12)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                topBar

                Spacer()

                // Current question display (shared screen moment)
                if let currentQuestion = sessionManager.currentDisplayedQuestion {
                    sharedQuestion(currentQuestion)
                }

                Spacer()

                // Input area, confirmation review, or sent state
                if hasAsked {
                    sentConfirmation
                } else if let pending = pendingQuestion {
                    confirmationReview(pending)
                } else {
                    inputArea
                }
            }
        }
        .onAppear {
            hasAsked = false
            pendingQuestion = nil
        }
        .onChange(of: sessionManager.hostRound) { _, _ in
            hasAsked = false
            pendingQuestion = nil
            questionText = ""
        }
        .toast(Binding(
            get: { sessionManager.toast },
            set: { sessionManager.toast = $0 }
        ))
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Spacer()

            Button("Leave") {
                sessionManager.leaveSession()
            }
            .font(.subheadline)
            .foregroundStyle(.red.opacity(0.8))
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    // MARK: - Shared Question

    private func sharedQuestion(_ text: String) -> some View {
        Text(text)
            .font(.custom("Cinzel-Regular", size: 24))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 30)
    }

    // MARK: - Sent Confirmation

    private var sentConfirmation: some View {
        VStack(spacing: 16) {
            Text("Your question is in")
                .font(.title3)
                .foregroundStyle(gold.opacity(0.7))
            Text("Stay connected — you'll get a new question when the seat passes")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.bottom, 40)
    }

    // MARK: - Confirmation Review

    private func confirmationReview(_ question: String) -> some View {
        VStack(spacing: 24) {
            Text("Send this?")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))

            Text(question)
                .font(.custom("Cinzel-Regular", size: 20))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            HStack(spacing: 20) {
                Button {
                    pendingQuestion = nil
                    isInputFocused = true
                } label: {
                    Text("Go back")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }

                Button {
                    confirmSend(question)
                } label: {
                    Text("Send")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(gold.opacity(0.3))
                                .stroke(gold, lineWidth: 1)
                        )
                }
            }
        }
        .padding(.bottom, 40)
    }

    // MARK: - Input Area

    private var inputArea: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                TextField("Ask anything...", text: $questionText, axis: .vertical)
                    .lineLimit(1...3)
                    .keyboardType(.default)
                    .autocorrectionDisabled(true)
                    .focused($isInputFocused)
                    .onChange(of: questionText) { _, newValue in
                        if newValue.count > characterLimit {
                            questionText = String(newValue.prefix(characterLimit))
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color.clear)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundStyle(gold.opacity(0.6))
                        , alignment: .bottom
                    )

                Button {
                    requestConfirmation()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : gold)
                }
                .disabled(questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            // Character counter
            HStack {
                Spacer()
                Text("\(characterLimit - questionText.count)")
                    .font(.caption)
                    .foregroundStyle(questionText.count > characterLimit - 20 ? gold : .white.opacity(0.3))
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - Actions

    private func requestConfirmation() {
        let trimmed = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isInputFocused = false
        pendingQuestion = trimmed
    }

    private func confirmSend(_ question: String) {
        sessionManager.sendQuestion(question)
        questionText = ""
        pendingQuestion = nil
        hasAsked = true

        // Light haptic
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

#Preview {
    PlayerView()
        .environment(SessionManager())
}
