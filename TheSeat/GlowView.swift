import SwiftUI

struct GlowView: View {
    @State private var pulse = false
    @State private var easterEggGlow = false

    private let gold = Color(red: 0.85, green: 0.70, blue: 0.40)

    var body: some View {
        ZStack {
            // Easter egg gold glow
            if easterEggGlow {
                Circle()
                    .stroke(gold.opacity(0.6), lineWidth: 12)
                    .frame(width: 220, height: 220)
                    .blur(radius: 14)
                    .shadow(color: gold.opacity(0.5), radius: 24)
                    .transition(.opacity)
            }

            // Floor shadow under chair
            Ellipse()
                .fill(Color.black.opacity(pulse ? 0.5 : 0.3))
                .frame(width: 140, height: 30)
                .blur(radius: 10)
                .offset(y: 90)

            // Chair icon
            Image("SeatChair")
                .resizable()
                .scaledToFit()
                .frame(width: 170, height: 170)
                .opacity(pulse ? 1.0 : 0.85)
                .onTapGesture {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    withAnimation(.easeIn(duration: 0.3)) {
                        easterEggGlow = true
                    }
                    withAnimation(.easeOut(duration: 1.5).delay(0.3)) {
                        easterEggGlow = false
                    }
                }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.5)
                .repeatForever(autoreverses: true)
            ) {
                pulse = true
            }
        }
    }
}

#Preview {
    ZStack {
        Color(white: 0.12).ignoresSafeArea()
        GlowView()
    }
}
