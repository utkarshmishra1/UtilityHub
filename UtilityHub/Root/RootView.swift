//
//  RootView.swift
//  UtilityHub
//
//  Created by utkarsh mishra on 21/02/26.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: AppTab = .home
    @State private var isUnlocked = false
    @State private var didBootstrap = false
    @State private var showStudentRoleSheet = false
    @AppStorage("app_lock_enabled") private var appLockEnabled = false
    @AppStorage(AppPreferenceKeys.hasStudentRoleSelection) private var hasStudentRoleSelection = false
    @AppStorage(AppPreferenceKeys.isStudentModeEnabled) private var isStudentModeEnabled = true

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeView(selectedTab: $selectedTab)
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .tag(AppTab.home)

                ProductivityView()
                    .tabItem {
                        Label("Productivity", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(AppTab.productivity)

                if isStudentModeEnabled {
                    StudentView()
                        .tabItem {
                            Label("Student", systemImage: "graduationcap")
                        }
                        .tag(AppTab.student)
                }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .tag(AppTab.settings)
            }
            .disabled(appLockEnabled && !isUnlocked)
            .blur(radius: appLockEnabled && !isUnlocked ? 5 : 0)

            if appLockEnabled && !isUnlocked {
                lockView
            }
        }
        .task {
            guard !didBootstrap else { return }
            didBootstrap = true
            DataBootstrapManager().seedIfNeeded(context: modelContext)
            await NotificationService.shared.requestPermissionIfNeeded()
            await refreshLockState()
            showStudentRoleSheet = !hasStudentRoleSelection
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task {
                await refreshLockState()
            }
        }
        .onChange(of: isStudentModeEnabled) { _, enabled in
            if !enabled && selectedTab == .student {
                selectedTab = .home
            }
        }
        .sheet(isPresented: $showStudentRoleSheet) {
            StudentRoleSelectionSheet { isStudent in
                hasStudentRoleSelection = true
                isStudentModeEnabled = isStudent
                if !isStudent && selectedTab == .student {
                    selectedTab = .home
                }
                showStudentRoleSheet = false
            }
            .interactiveDismissDisabled()
            .presentationDetents([.fraction(0.42)])
            .presentationDragIndicator(.hidden)
        }
    }

    private var lockView: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 44))
                .foregroundStyle(HubTheme.accentGradient)
            Text("UtilityHub Locked")
                .font(.title3.bold())
            Button("Unlock with Face ID") {
                Task {
                    await authenticate()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppAccent.current.tintColor)
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: HubTheme.cardRadius, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .padding(.horizontal, 40)
    }

    private func refreshLockState() async {
        if !appLockEnabled {
            isUnlocked = true
            return
        }
        await authenticate()
    }

    private func authenticate() async {
        let unlocked = await BiometricAuthService.shared.authenticate(reason: "Unlock UtilityHub")
        await MainActor.run {
            isUnlocked = unlocked
        }
    }
}

private struct StudentRoleSelectionSheet: View {
    let onSelect: (Bool) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: "graduationcap.circle.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(HubTheme.accentGradient)

                Text("Are you a student?")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundColor(.primary)

                Text("Choose this once to customize your modules.")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    Button {
                        onSelect(false)
                    } label: {
                        Text("No")
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.gray.opacity(0.14))
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        onSelect(true)
                    } label: {
                        Text("Yes")
                            .font(.headline.weight(.bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(AppAccent.current.tintColor)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 6)

                Spacer(minLength: 0)
            }
            .padding(20)
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
