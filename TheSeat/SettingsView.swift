import SwiftUI

struct SettingsView: View {
    @AppStorage("playerName") private var playerName: String = ""
    @State private var nameInput = ""
    @State private var showHowToPlay = false
    @Environment(\.dismiss) private var dismiss

    private let gold = Color(red: 0.85, green: 0.70, blue: 0.40)
    private let cardBackground = Color(white: 0.18)

    var body: some View {
        ZStack {
            Color(white: 0.08)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Spacer()
                    Text("Settings")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Button("Done") { dismiss() }
                        .foregroundStyle(gold)
                }
                .padding(.horizontal)
                .padding(.vertical, 16)

                ScrollView {
                    VStack(spacing: 24) {
                        // Player Name section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Player Name")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                                .padding(.leading, 16)

                            TextField("Your name", text: $nameInput)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(cardBackground)
                                )
                                .onAppear { nameInput = playerName }
                                .onChange(of: nameInput) { _, newValue in
                                    let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                                    if !trimmed.isEmpty {
                                        playerName = trimmed
                                    }
                                }
                        }

                        // Links section
                        VStack(spacing: 0) {
                            settingsRow("How to Play") {
                                showHowToPlay = true
                            }
                            settingsDivider
                            settingsRow("Rate the App") {
                                if let url = URL(string: "https://apps.apple.com/app/id0000000000") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            settingsDivider
                            settingsRow("Contact / Feedback") {
                                if let url = URL(string: "mailto:support@bjanish.com") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            settingsDivider
                            settingsRow("Privacy Policy") {
                                if let url = URL(string: "https://bjanish.com/privacy") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(cardBackground)
                        )

                        // Restore Purchase section
                        VStack(spacing: 0) {
                            settingsRow("Restore Purchase")
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(cardBackground)
                        )

                        // Version
                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.3))
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
        }
        .sheet(isPresented: $showHowToPlay) {
            HowToPlayView()
        }
    }

    private func settingsRow(_ title: String, action: (() -> Void)? = nil) -> some View {
        Button {
            action?()
        } label: {
            HStack {
                Text(title)
                    .font(.body)
                    .foregroundStyle(gold)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
    }

    private var settingsDivider: some View {
        Divider()
            .background(Color.white.opacity(0.1))
            .padding(.leading, 16)
    }
}

#Preview {
    SettingsView()
}
