import SwiftUI

struct ContentView: View {
    @Environment(SessionManager.self) private var sessionManager
    @AppStorage("playerName") private var playerName: String = ""
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var showSettings = false

    var body: some View {
        Group {
            if playerName.isEmpty {
                NameEntryView()
            } else if !hasSeenOnboarding {
                OnboardingView()
            } else {
                mainContent
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var mainContent: some View {
        switch sessionManager.role {
        case .solo:
            soloView
        case .host:
            HostView()
        case .player:
            PlayerView()
        }
    }

    private var soloView: some View {
        ZStack {
            Color(white: 0.08)
                .ignoresSafeArea()

            // Spotlight cone from above
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.85, blue: 0.4).opacity(0.18),
                    Color(red: 1.0, green: 0.85, blue: 0.4).opacity(0.06),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .init(x: 0.5, y: 0.65)
            )
            .ignoresSafeArea()

            // Radial depth glow behind THE SEAT
            RadialGradient(
                colors: [
                    Color(red: 0.85, green: 0.70, blue: 0.40).opacity(0.12),
                    Color(red: 0.85, green: 0.70, blue: 0.40).opacity(0.04),
                    Color.clear
                ],
                center: .init(x: 0.5, y: 0.72),
                startRadius: 10,
                endRadius: 280
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                GlowView()
                    .offset(y: 24)

                Text("THE SEAT")
                    .font(.custom("Cinzel-Regular", size: 42))
                    .tracking(10)
                    .foregroundStyle(Color(red: 0.85, green: 0.70, blue: 0.40))
                    .shadow(color: Color(red: 0.85, green: 0.70, blue: 0.40).opacity(0.3), radius: 12, x: 0, y: 0)
                    .padding(.top, -10)
                    .offset(y: 22)

                Text("Ask anything. Anonymously.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.top, -2)
                    .padding(.bottom, 2)
                    .offset(y: 24)

                roomPresence
                    .offset(y: 32)

                Spacer()

                Button {
                    sessionManager.joinSession()
                } label: {
                    Text(sessionManager.hostName.isEmpty ? "Join" : "Join \(sessionManager.hostName)")
                        .font(.headline)
                        .foregroundStyle(sessionManager.hostName.isEmpty ? .white.opacity(0.3) : .white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(sessionManager.hostName.isEmpty ? Color.white.opacity(0.04) : Color(red: 0.85, green: 0.70, blue: 0.40).opacity(0.2))
                                .stroke(sessionManager.hostName.isEmpty ? Color.white.opacity(0.15) : Color(red: 0.85, green: 0.70, blue: 0.40), lineWidth: 1)
                        )
                        .shadow(color: sessionManager.hostName.isEmpty ? .clear : Color(red: 0.85, green: 0.70, blue: 0.40).opacity(0.4), radius: 8, y: 4)
                }
                .disabled(sessionManager.hostName.isEmpty)
                .padding(.horizontal, 40)
                .offset(y: 15)

                Button {
                    sessionManager.startHosting()
                } label: {
                    Text(sessionManager.hostName.isEmpty ? "Take the Seat" : "\(sessionManager.hostName) is in The Seat")
                        .font(.headline)
                        .foregroundStyle(sessionManager.hostName.isEmpty ? .white : .white.opacity(0.3))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(sessionManager.hostName.isEmpty ? Color(red: 0.85, green: 0.70, blue: 0.40).opacity(0.3) : Color.white.opacity(0.04))
                                .stroke(sessionManager.hostName.isEmpty ? Color(red: 0.85, green: 0.70, blue: 0.40) : Color.white.opacity(0.15), lineWidth: 1)
                        )
                }
                .disabled(!sessionManager.hostName.isEmpty)
                .padding(.horizontal, 40)
                .padding(.top, -20)
                .offset(y: 15)

                Spacer()
                    .frame(height: 40)
            }

            // Settings cog — top right
            VStack {
                HStack {
                    Spacer()
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.trailing, 24)
                    .padding(.top, 16)
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .toast(Binding(
            get: { sessionManager.toast },
            set: { sessionManager.toast = $0 }
        ))
        .onAppear {
            sessionManager.startBrowser()
        }
    }

    @ViewBuilder
    private var roomPresence: some View {
        let nearbyNames = sessionManager.nearbyReadyPeerNames
        let visible = sessionManager.hostName.isEmpty && !nearbyNames.isEmpty

        VStack(spacing: 7) {
            Text("THE ROOM IS GATHERING")
                .font(.custom("Cinzel-Regular", size: 10))
                .tracking(1.5)
                .foregroundStyle(Color(red: 0.85, green: 0.70, blue: 0.40).opacity(0.8))

            HStack(spacing: 5) {
                ForEach(0..<max(nearbyNames.count + 1, 1), id: \.self) { _ in
                    Circle()
                        .fill(Color(red: 0.85, green: 0.70, blue: 0.40))
                        .frame(width: 6, height: 6)
                }

                Text("\(nearbyNames.count + 1) phones nearby")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.leading, 4)
            }

            Text((nearbyNames + ["You"]).joined(separator: " · "))
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.35))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.22))
                .stroke(Color(red: 0.85, green: 0.70, blue: 0.40).opacity(0.18), lineWidth: 1)
        )
        .opacity(visible ? 1 : 0)
    }
}

#Preview {
    ContentView()
        .environment(SessionManager())
}
