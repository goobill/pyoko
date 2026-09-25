import SwiftUI
import CloudKit

struct SettingsView: View {
    @AppStorage("appearancePreference") private var appearancePreference = "system"
    @AppStorage("themePreference") private var themeValue = "classic"
    @AppStorage("tintPreference") private var tintValue = "automatic"
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @State private var accountMessage = "Checking iCloud account…"

    var body: some View {
        SettingsLayout {
            SettingsSection("Appearance") {
                Picker("Appearance", selection: $appearancePreference) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }.pickerStyle(.menu).accessibilityIdentifier("settings.theme")
                Text("Appearance applies to this device.").font(.caption).foregroundStyle(.secondary)
            }
            SettingsSection("Theme Palette") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 10) {
                    ForEach(PyokoTheme.allCases) { theme in
                        Button {
                            themeValue = theme.rawValue
                            tintValue = "automatic"
                        } label: {
                            HStack(spacing: 8) {
                                Circle().fill(theme.accent.color(for: scheme)).frame(width: 18, height: 18)
                                Text(theme.title).font(.callout)
                                Spacer(minLength: 0)
                                if themeValue == theme.rawValue {
                                    Image(systemName: "checkmark").font(.caption.bold())
                                }
                            }
                            .foregroundStyle(.primary)
                            .padding(10)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(theme.background(for: scheme), in: RoundedRectangle(cornerRadius: 10))
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(themeValue == theme.rawValue ? theme.accent.color(for: scheme) : Color.primary.opacity(0.12),
                                                  lineWidth: themeValue == theme.rawValue ? 2 : 1)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(theme.title)
                        .accessibilityValue(themeValue == theme.rawValue ? "Selected" : "Not selected")
                        .accessibilityIdentifier("theme.\(theme.rawValue)")
                    }
                }
                Text("A palette sets the background and matching tint. You can choose a different tint below.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            SettingsSection("Tint") {
                Picker("Buttons and Highlights", selection: $tintValue) {
                    Text("Match Theme").tag("automatic")
                    ForEach(PyokoTint.allCases) { tint in
                        HStack {
                            Circle().fill(tint.color(for: scheme)).frame(width: 12, height: 12)
                            Text(tint.title)
                        }.tag(tint.rawValue)
                    }
                }.pickerStyle(.menu).accessibilityIdentifier("settings.tint")
                Text("Changes apply immediately and are saved on this device.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            SettingsSection("iCloud") {
                Label("iCloud sync configured", systemImage: "icloud")
                Text(accountMessage).foregroundStyle(.secondary)
                Text("Decks, review progress and practice config sync through your iCloud account. Changes may take a little time to appear on your other device.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Check iCloud Account") { Task { await checkAccount() } }
                Text("Account availability does not confirm that all changes have synced.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }

        .accessibilityIdentifier("settings.form")
        .pyokoSurface()
        .navigationTitle("Settings")
        .task { await checkAccount() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await checkAccount() } }
        }
        #if os(macOS)
        .frame(minWidth: 600, idealWidth: 1000, minHeight: 580, idealHeight: 760)
        #endif
    }

    private func checkAccount() async {
        do {
            let status = try await CKContainer(identifier: PyokoCloud.containerIdentifier).accountStatus()
            switch status {
            case .available: accountMessage = "iCloud account available."
            case .noAccount: accountMessage = "Sign in to iCloud in your device's Settings to sync."
            case .restricted: accountMessage = "iCloud access is restricted on this device."
            case .couldNotDetermine, .temporarilyUnavailable:
                accountMessage = "iCloud is temporarily unavailable. Try again later."
            @unknown default: accountMessage = "Unable to determine iCloud availability."
            }
        } catch {
            accountMessage = "Could not check iCloud: \(error.localizedDescription)"
        }
    }
}
