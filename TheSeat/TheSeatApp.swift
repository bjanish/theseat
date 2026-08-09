import SwiftUI
import AVFoundation

@main
struct TheSeatApp: App {
    @State private var sessionManager = SessionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(sessionManager)
                .onAppear {
                    configureAudioSession()
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
