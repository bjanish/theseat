import SwiftUI
import AVFoundation

@main
struct TheSeatApp: App {
    @State private var sessionManager = SessionManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(sessionManager)
                .onAppear {
                    configureAudioSession()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .background:
                        sessionManager.enterBackground()
                    case .active:
                        sessionManager.resumeFromBackground()
                    default:
                        break
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    // Stop ready listener on lock so timestamp freezes
                    if sessionManager.role == .solo {
                        sessionManager.stopReadyListenerOnly()
                    }
                }
        }
    }

    private func configureAudioSession() {
        Task.detached {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, options: .mixWithOthers)
                try session.setActive(true)
            } catch {
                #if DEBUG
                print("[AUDIO] Failed to configure audio session: \(error)")
                #endif
            }
        }
    }
}
