import SwiftUI

struct SettingsView: View {
    @AppStorage("appearancePreference") private var appearancePreference = "system"
    @AppStorage("themePreference") private var themeValue = "classic"
    @AppStorage("tintPreference") private var tintValue = "automatic"
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @State private var accountCheck = CloudAccountCheck()

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
                Text(accountCheck.isChecking ? "Checking iCloud account…" : accountCheck.message)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("settings.cloud.result")
                Text("Decks, review progress and practice config sync through your iCloud account. Changes may take a little time to appear on your other device.")
                    .font(.caption).foregroundStyle(.secondary)
                Button {
                    Task { await accountCheck.check() }
                } label: {
                    HStack {
                        if accountCheck.isChecking { ProgressView().controlSize(.small) }
                        Text(accountCheck.isChecking ? "Checking…" : "Check Account Status")
                    }
                }
                .disabled(accountCheck.isChecking)
                .accessibilityIdentifier("settings.cloud.check")
                if let checked = accountCheck.lastChecked {
                    Text("Last checked: \(checked.formatted(date: .omitted, time: .standard))")
                        .font(.caption).foregroundStyle(.secondary)
                        .accessibilityIdentifier("settings.cloud.checked")
                }
                Text("Checks account access only. Sync happens automatically; this does not force a sync or confirm that all changes have synced.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }

        .accessibilityIdentifier("settings.form")
        .pyokoSurface()
        .navigationTitle("Settings")
        .task { await accountCheck.check() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await accountCheck.check() } }
        }
        #if os(macOS)
        .frame(minWidth: 600, idealWidth: 1000, minHeight: 580, idealHeight: 760)
        #endif
    }

}
