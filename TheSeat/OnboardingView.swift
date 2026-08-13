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
                    slidePass.tag(3)
                    slide4.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button {
                    if currentPage < 4 {
                        withAnimation { currentPage += 1 }
                    } else {
                        hasSeenOnboarding = true
                    }
                } label: {
                    Text(currentPage < 4 ? "Next" : "Get Started")
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
            Spacer().frame(height: 200)

            Image(systemName: "chair.lounge.fill")
                .font(.system(size: 60))
                .frame(height: 70)
                .foregroundStyle(gold)
                .shadow(color: gold.opacity(0.4), radius: 12, x: 0, y: 4)

            Text("Take the seat.")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("Answer anything.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))

            Spacer()
        }
    }

    private var slide2: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 200)

            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .frame(height: 70)
                .offset(y: 1)
                .foregroundStyle(gold)

            Text("Friends connect anonymously.")
                .font(.title2)
                .fontWeight(.bold)
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
            Spacer().frame(height: 200)

            Image(systemName: "hand.tap.fill")
                .font(.system(size: 60))
                .frame(height: 70)
                .offset(y: -5)
                .foregroundStyle(gold)

            Text("You pick what to answer.")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("Swipe through questions.\nTap to choose one.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            Spacer()
        }
    }

    private var slidePass: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 200)

            Image(systemName: "person.line.dotted.person.fill")
                .font(.system(size: 60))
                .frame(height: 70)
                .offset(y: -9)
                .foregroundStyle(gold)

            Text("Pass the seat.")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("Choose who's next.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            Spacer()
        }
    }

    private var slide4: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 200)

            Image(systemName: "wifi")
                .font(.system(size: 60))
                .frame(height: 70)
                .foregroundStyle(.green)

            Text("One more thing —")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("Tap \"Allow\" on the next pop-up\nso we can find players nearby.")
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
