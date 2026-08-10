import SwiftUI

struct HostView: View {
    @Environment(SessionManager.self) private var sessionManager
    @State private var showPassSheet = false

    private let gold = Color(red: 0.85, green: 0.70, blue: 0.40)

    var body: some View {
        ZStack {
            Color(white: 0.12)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                topBar

                // Main content
                if let question = sessionManager.currentDisplayedQuestion {
                    fullScreenQuestion(question)
                } else if sessionManager.questionQueue.isEmpty {
                    emptyState
                } else {
                    questionList
                }
            }
        }
        .sheet(isPresented: $showPassSheet) {
            passTheSeatSheet
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Text("\(sessionManager.connectedPeers.count) connected")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))

            Spacer()

            if !sessionManager.questionQueue.isEmpty {
                Text("\(sessionManager.questionQueue.count) question\(sessionManager.questionQueue.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(gold)
            }

            Spacer()

            if !sessionManager.connectedPeers.isEmpty {
                Button("Pass") {
                    showPassSheet = true
                }
                .font(.subheadline)
                .foregroundStyle(gold)
            }

            Button("End") {
                sessionManager.endSession()
            }
            .font(.subheadline)
            .foregroundStyle(.red.opacity(0.8))
            .padding(.leading, 12)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()
            GlowView()
            Spacer().frame(height: 50)
            Text("Waiting for questions...")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.5))
            Spacer()
        }
    }

    // MARK: - Question Stack

    @State private var dragOffset: CGSize = .zero

    private var questionList: some View {
        VStack(spacing: 0) {
            Spacer()

            // Flourish + Cards + Flourish as one centered unit
            VStack(spacing: 20) {
                Image("Flourish")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                    .opacity(0.7)

                ZStack {
                    ForEach(Array(sessionManager.questionQueue.enumerated().reversed()), id: \.offset) { index, question in
                        if index < 3 {
                            questionCard(question)
                                .offset(x: CGFloat(index) * 20)
                                .scaleEffect(1.0 - CGFloat(index) * 0.05)
                                .opacity(index == 0 ? 1.0 : 0.5)
                                .zIndex(Double(sessionManager.questionQueue.count - index))
                                .offset(x: index == 0 ? dragOffset.width : 0)
                                .rotationEffect(index == 0 ? .degrees(Double(dragOffset.width) / 20) : .zero)
                                .gesture(index == 0 ? swipeGesture : nil)
                                .onTapGesture {
                                    if index == 0 {
                                        sessionManager.selectQuestion(at: 0)
                                    }
                                }
                                .animation(.spring(response: 0.3), value: dragOffset)
                        }
                    }
                }

                Image("Flourish")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                    .opacity(0.7)
                    .rotationEffect(.degrees(180))
            }

            Spacer()

            // Instructions pinned to bottom
            Text("swipe to browse · tap to choose")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
                .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func questionCard(_ question: String) -> some View {
        VStack {
            Spacer()
            Text(question)
                .font(.custom("Cinzel-Regular", size: 22))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(30)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.14))
                .stroke(gold.opacity(0.4), lineWidth: 1)
        )
        .padding(.horizontal, 30)
    }

    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                if value.translation.width > 80 {
                    // Swipe right — move to back (cycle forward)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        dragOffset = CGSize(width: 500, height: 0)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        if !self.sessionManager.questionQueue.isEmpty {
                            let question = self.sessionManager.questionQueue.removeFirst()
                            self.sessionManager.questionQueue.append(question)
                        }
                        dragOffset = .zero
                    }
                } else if value.translation.width < -80 {
                    // Swipe left — move to back (cycle backward)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        dragOffset = CGSize(width: -500, height: 0)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        if !self.sessionManager.questionQueue.isEmpty {
                            let question = self.sessionManager.questionQueue.removeLast()
                            self.sessionManager.questionQueue.insert(question, at: 0)
                        }
                        dragOffset = .zero
                    }
                } else {
                    // Snap back
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dragOffset = .zero
                    }
                }
            }
    }

    // MARK: - Full Screen Question

    private func fullScreenQuestion(_ question: String) -> some View {
        ZStack {
            // Tap to dismiss
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.3)) {
                        sessionManager.currentDisplayedQuestion = nil
                    }
                }

            VStack {
                Spacer()

                Text(question)
                    .font(.custom("Cinzel-Regular", size: 28))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)

                Spacer()

                // Watermark
                Text("The Seat")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.2))
                    .padding(.bottom, 20)
            }
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
        .animation(.easeIn(duration: 0.4), value: sessionManager.currentDisplayedQuestion)
    }

    // MARK: - Pass the Seat Sheet

    private var passTheSeatSheet: some View {
        NavigationStack {
            List(sessionManager.connectedPeers, id: \.self) { name in
                Button {
                    sessionManager.passTheSeat(to: name)
                    showPassSheet = false
                } label: {
                    Text(name)
                        .foregroundStyle(.white)
                }
                .listRowBackground(Color(white: 0.16))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(white: 0.12))
            .navigationTitle("Pass the Seat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showPassSheet = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    HostView()
        .environment(SessionManager())
}
