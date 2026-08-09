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
                Text("\(sessionManager.questionQueue.count) waiting")
                    .font(.subheadline)
                    .foregroundStyle(gold)
            }

            Spacer()

            Button("End") {
                sessionManager.endSession()
            }
            .font(.subheadline)
            .foregroundStyle(.red.opacity(0.8))
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

    // MARK: - Question List

    private var questionList: some View {
        List {
            ForEach(Array(sessionManager.questionQueue.enumerated()), id: \.offset) { index, question in
                questionRow(question, at: index)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func questionRow(_ question: String, at index: Int) -> some View {
        Text(question)
            .font(.body)
            .foregroundStyle(.white)
            .padding(.vertical, 8)
            .listRowBackground(Color(white: 0.16))
            .swipeActions(edge: .trailing) {
                Button {
                    sessionManager.selectQuestion(at: index)
                } label: {
                    Label("Show", systemImage: "eye")
                }
                .tint(gold)
            }
            .swipeActions(edge: .leading) {
                Button(role: .destructive) {
                    sessionManager.skipQuestion(at: index)
                } label: {
                    Label("Skip", systemImage: "xmark")
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
                    sessionManager.currentDisplayedQuestion = nil
                }

            VStack {
                Spacer()

                Text(question)
                    .font(.system(size: 32, weight: .medium))
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
        }
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
