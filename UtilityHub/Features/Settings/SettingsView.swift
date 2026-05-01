//
//  SettingsView.swift
//  UtilityHub
//
//  Created by Codex on 26/02/26.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("display_name") private var displayName = "User"

    @State private var draftName = ""
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: HubTheme.sectionSpacing) {
                    accountSection
                }
                .padding(.horizontal, HubTheme.horizontalPadding)
                .padding(.vertical, 12)
            }
            .background(AmbientHubBackground())
            .navigationTitle("Settings")
            .onAppear {
                draftName = displayName
            }
        }
    }

    private func saveName() {
        let clean = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !clean.isEmpty {
            displayName = clean
            draftName = clean
        }
        isNameFieldFocused = false
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
                        .focused($isNameFieldFocused)
                        .submitLabel(.done)
                        .onSubmit(saveName)
                    Button("Save Name", action: saveName)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}
