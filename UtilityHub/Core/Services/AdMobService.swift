//
//  AdMobService.swift
//  UtilityHub
//
//  Created by Codex on 29/03/26.
//

import Foundation
import Combine
import GoogleMobileAds
import UserMessagingPlatform
import AppTrackingTransparency

@MainActor
final class AdMobService: ObservableObject {
    static let shared = AdMobService()

    @Published private(set) var canRequestAds = false
    @Published private(set) var isPrivacyOptionsRequired = false

    private var isPreparingAds = false
    private var hasStartedGoogleMobileAds = false

    private init() {}

    func prepareAdsIfNeeded() async {
        guard !isPreparingAds else { return }
        isPreparingAds = true
        defer { isPreparingAds = false }

        await updateConsentAndPresentFormIfNeeded()
        guard canRequestAds else { return }

        await requestTrackingAuthorizationIfNeeded()
        startGoogleMobileAdsIfNeeded()
    }

    func refreshConsentState() {
        isPrivacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
        canRequestAds = ConsentInformation.shared.canRequestAds
    }

    func presentPrivacyOptionsForm() async throws {
        try await ConsentForm.presentPrivacyOptionsForm(from: nil)
        refreshConsentState()

        guard canRequestAds else { return }
        await requestTrackingAuthorizationIfNeeded()
        startGoogleMobileAdsIfNeeded()
    }

    private func updateConsentAndPresentFormIfNeeded() async {
        let parameters = RequestParameters()

        await withCheckedContinuation { continuation in
            ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { error in
                if let error {
                    NSLog("AdMob consent info update failed: %@", error.localizedDescription)
                }
                continuation.resume()
            }
        }

        do {
            try await ConsentForm.loadAndPresentIfRequired(from: nil)
        } catch {
            NSLog("AdMob consent form failed: %@", error.localizedDescription)
        }

        refreshConsentState()
    }

    private func requestTrackingAuthorizationIfNeeded() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }

        await withCheckedContinuation { continuation in
            ATTrackingManager.requestTrackingAuthorization { _ in
                continuation.resume()
            }
        }
    }

    private func startGoogleMobileAdsIfNeeded() {
        guard !hasStartedGoogleMobileAds else { return }
        hasStartedGoogleMobileAds = true
        MobileAds.shared.start()
    }
}
