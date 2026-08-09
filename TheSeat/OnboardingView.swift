import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var currentPage = 0

    private let gold = Color(red: 0.85, green: 0.70, blue: 0.40)

    var body: some View {
        ZStack {
            Color(white: 0.12)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    slide1.tag(0)
                    slide2.tag(1)
                    slide3.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button {
                    if currentPage < 2 {
                        withAnimation { currentPage += 1 }
                    } else {
                        hasSeenOnboarding = true
                    }
                } label: {
                    Text(currentPage < 2 ? "Next" : "Get Started")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(gold.opacity(0.3))
                                .stroke(gold, lineWidth: 1)
                        )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Slides

    private var slide1: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "chair.fill")
                .font(.system(size: 80))
                .foregroundStyle(gold)

            Text("Take the seat.")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("Answer anything.")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.7))

            Spacer()
        }
    }

    private var slide2: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundStyle(gold)

            Text("Friends connect anonymously.")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            Text("Questions appear.\nNobody knows who asked what.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            Spacer()
        }
    }

    private var slide3: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "hand.tap.fill")
                .font(.system(size: 60))
                .foregroundStyle(gold)

            Text("You pick what to answer.")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            Text("This app uses your local network\nto connect nearby devices.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
