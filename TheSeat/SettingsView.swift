import SwiftUI

struct SettingsView: View {
    @AppStorage("playerName") private var playerName: String = ""
    @State private var nameInput = ""
    @State private var showNameEdit = false
    @Environment(\.dismiss) private var dismiss

    private let gold = Color(red: 0.85, green: 0.70, blue: 0.40)

    var body: some View {
        NavigationStack {
            List {
                // Name
                Section("Name") {
                    HStack {
                        Text(playerName)
                            .foregroundStyle(.white)
                        Spacer()
                        Button("Change") {
                            nameInput = playerName
                            showNameEdit = true
                        }
                        .foregroundStyle(gold)
                    }
                    .listRowBackground(Color(white: 0.16))
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                            .foregroundStyle(.white)
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .listRowBackground(Color(white: 0.16))

                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                                .foregroundStyle(.white)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                    .listRowBackground(Color(white: 0.16))
                }

                // Rate
                Section {
                    Link(destination: URL(string: "https://apps.apple.com/app/id0000000000")!) {
                        HStack {
                            Text("Rate The Seat")
                                .foregroundStyle(.white)
                            Spacer()
                            Image(systemName: "star.fill")
                                .foregroundStyle(gold)
                        }
                    }
                    .listRowBackground(Color(white: 0.16))
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color(white: 0.12))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Change Name", isPresented: $showNameEdit) {
                TextField("Your name", text: $nameInput)
                Button("Save") {
                    let trimmed = nameInput.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        playerName = trimmed
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

#Preview {
    SettingsView()
}
