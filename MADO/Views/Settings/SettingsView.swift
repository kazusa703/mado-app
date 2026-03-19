import SwiftUI

struct SettingsView: View {
    @Bindable var theme = ThemeManager.shared
    @State private var showDeleteConfirmation = false
    @State private var storeKit = StoreKitService.shared
    @State private var showRestoreResult = false
    @State private var restoreMessage = ""

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Theme
                Section {
                    Picker(String(localized: "settings_theme"), selection: Bindable(theme).currentTheme) {
                        ForEach(AppTheme.allCases, id: \.self) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                } header: {
                    Text(String(localized: "settings_appearance"))
                }

                // MARK: - Pro
                Section {
                    if storeKit.isPurchased {
                        Label(String(localized: "settings_pro_active"), systemImage: "checkmark.seal.fill")
                            .foregroundStyle(theme.teal)
                    } else {
                        Button {
                            Task {
                                _ = try? await storeKit.purchase()
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(String(localized: "settings_upgrade_pro"))
                                        .font(.headline)
                                    Text(String(localized: "settings_pro_description"))
                                        .font(.caption)
                                        .foregroundStyle(theme.textSub)
                                }
                                Spacer()
                                if let product = storeKit.proProduct {
                                    Text(product.displayPrice)
                                        .font(.headline)
                                        .foregroundStyle(theme.accent)
                                }
                            }
                        }
                        .disabled(storeKit.isLoading)

                        Button(String(localized: "settings_restore_purchase")) {
                            Task {
                                await storeKit.restore()
                                restoreMessage = storeKit.isPurchased
                                    ? String(localized: "settings_restore_success")
                                    : String(localized: "settings_restore_not_found")
                                showRestoreResult = true
                            }
                        }
                    }
                } header: {
                    Text("Pro")
                }

                // MARK: - Legal
                Section {
                    Link(destination: URL(string: "https://kazusa703.github.io/mado-app/privacy.html")!) {
                        Label(String(localized: "settings_privacy_policy"), systemImage: "hand.raised.fill")
                    }
                    Link(destination: URL(string: "https://kazusa703.github.io/mado-app/terms.html")!) {
                        Label(String(localized: "settings_terms"), systemImage: "doc.text.fill")
                    }
                } header: {
                    Text(String(localized: "settings_legal"))
                }

                // MARK: - Disclaimer
                Section {
                    Text(String(localized: "settings_disclaimer"))
                        .font(.caption)
                        .foregroundStyle(theme.textSub)
                }

                // MARK: - Data
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label(String(localized: "settings_delete_data"), systemImage: "trash.fill")
                    }
                } header: {
                    Text(String(localized: "settings_data"))
                }

                // MARK: - App Info
                Section {
                    HStack {
                        Text(String(localized: "settings_version"))
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundStyle(theme.textSub)
                    }
                }
            }
            .navigationTitle(String(localized: "settings_title"))
            .navigationBarTitleDisplayMode(.large)
            .confirmationDialog(
                String(localized: "settings_delete_confirm_title"),
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(String(localized: "settings_delete_confirm"), role: .destructive) {
                    Task {
                        try? await DatabaseService.shared.deleteAllData()
                    }
                }
            } message: {
                Text(String(localized: "settings_delete_confirm_message"))
            }
            .alert(String(localized: "settings_restore_purchase"), isPresented: $showRestoreResult) {
                Button("OK") {}
            } message: {
                Text(restoreMessage)
            }
        }
    }
}
