//
//  SettingsView.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = SettingsViewModel()
    @StateObject private var adMobService = AdMobService.shared

    @AppStorage("display_name") private var displayName = "User"

    @State private var draftName = ""
    @State private var showResetAlert = false
    @State private var adPrivacyMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: HubTheme.sectionSpacing) {
                    accountSection
                    dataSection
                    aboutSection
                }
                .padding(.horizontal, HubTheme.horizontalPadding)
                .padding(.vertical, 12)
            }
            .background(AmbientHubBackground())
            .navigationTitle("Settings")
            .onAppear {
                draftName = displayName
                adMobService.refreshConsentState()
            }
            .alert("Reset all local data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    viewModel.resetAllData(context: modelContext)
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    private var accountSection: some View {
        VStack(spacing: 10) {
            HubSectionHeader(title: "Account")
            HubCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Profile")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                    TextField("Change Name", text: $draftName)
                        .textFieldStyle(.roundedBorder)
                    Button("Save Name") {
                        let clean = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !clean.isEmpty {
                            displayName = clean
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private var dataSection: some View {
        VStack(spacing: 10) {
            HubSectionHeader(title: "Data")
            HubCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("All modules are offline-first and stored locally.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Button("Backup Data") {
                        viewModel.createBackup(context: modelContext)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppAccent.current.tintColor)
                    if let backupURL = viewModel.backupFileURL {
                        ShareLink(item: backupURL) {
                            Label("Share Latest Backup", systemImage: "square.and.arrow.up")
                                .font(.footnote.weight(.semibold))
                        }
                    }
                    if let backupMessage = viewModel.backupMessage {
                        Text(backupMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if adMobService.isPrivacyOptionsRequired {
                        Button("Manage Ad Privacy") {
                            Task {
                                do {
                                    try await adMobService.presentPrivacyOptionsForm()
                                    adPrivacyMessage = "Ad privacy settings updated."
                                } catch {
                                    adPrivacyMessage = "Couldn't open ad privacy settings right now."
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    if let adPrivacyMessage {
                        Text(adPrivacyMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Button("Reset Data") {
                        showResetAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }

    private var aboutSection: some View {
        VStack(spacing: 10) {
            HubSectionHeader(title: "About")
            HubCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Orbyt")
                        .font(.headline.weight(.semibold))
                    Text("Offline-first daily control center built with SwiftUI + SwiftData.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
