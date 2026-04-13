//
//  HomeTopBannerAdView.swift
//  UtilityHub
//
//  Created by Codex on 28/03/26.
//

import SwiftUI
import GoogleMobileAds
import UIKit

struct HomeTopBannerAdView: View {
    @StateObject private var adMobService = AdMobService.shared

    var body: some View {
        Group {
            if adMobService.canRequestAds {
                HomeTopNativeAdContainer(adUnitID: AdMobConfiguration.homeNativeAdUnitID)
                    .frame(height: 128)
                    .padding(.bottom, 12)
            }
        }
        .task {
            await adMobService.prepareAdsIfNeeded()
        }
    }
}

private struct HomeTopNativeAdContainer: UIViewRepresentable {
    let adUnitID: String

    func makeCoordinator() -> Coordinator {
        Coordinator(adUnitID: adUnitID)
    }

    func makeUIView(context: Context) -> DarkNativeAdCardView {
        let adView = DarkNativeAdCardView()
        context.coordinator.attach(nativeAdView: adView)
        context.coordinator.loadAdIfNeeded()
        return adView
    }

    func updateUIView(_ uiView: DarkNativeAdCardView, context: Context) {
        context.coordinator.attach(nativeAdView: uiView)
        context.coordinator.loadAdIfNeeded()
    }

    static func dismantleUIView(_ uiView: DarkNativeAdCardView, coordinator: Coordinator) {
        coordinator.cleanup()
        uiView.nativeAd = nil
    }

    final class Coordinator: NSObject, NativeAdLoaderDelegate, AdLoaderDelegate, NativeAdDelegate {
        private let adUnitID: String
        private var adLoader: AdLoader?
        private weak var nativeAdView: DarkNativeAdCardView?
        private var nativeAd: NativeAd?
        private var isLoading = false
        private var lastLoadDate: Date?
        private var lastFailureDate: Date?
        private let retryInterval: TimeInterval = 20
        private let reloadInterval: TimeInterval = 55 * 60

        init(adUnitID: String) {
            self.adUnitID = adUnitID
        }

        func attach(nativeAdView: DarkNativeAdCardView) {
            self.nativeAdView = nativeAdView
            applyNativeAdIfNeeded()
        }

        func loadAdIfNeeded() {
            guard !isLoading else { return }
            if let lastFailureDate, Date().timeIntervalSince(lastFailureDate) < retryInterval {
                return
            }

            if let lastLoadDate, Date().timeIntervalSince(lastLoadDate) < reloadInterval, nativeAd != nil {
                return
            }

            let loader = AdLoader(
                adUnitID: adUnitID,
                rootViewController: UIApplication.shared.uhTopViewController,
                adTypes: [.native],
                options: nil
            )
            loader.delegate = self
            adLoader = loader
            isLoading = true
            lastLoadDate = Date()
            loader.load(Request())
        }

        func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
            self.nativeAd = nativeAd
            nativeAd.delegate = self
            lastFailureDate = nil
            applyNativeAdIfNeeded()
        }

        func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
            isLoading = false
            lastFailureDate = Date()
            NSLog("Native ad failed to load: %@", error.localizedDescription)
        }

        func adLoaderDidFinishLoading(_ adLoader: AdLoader) {
            isLoading = false
        }

        private func applyNativeAdIfNeeded() {
            guard let nativeAd, let nativeAdView else { return }
            nativeAdView.render(nativeAd: nativeAd)
        }

        func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {
            NSLog("Native ad impression recorded.")
        }

        func nativeAdDidRecordClick(_ nativeAd: NativeAd) {
            NSLog("Native ad click recorded.")
        }

        func cleanup() {
            nativeAdView?.nativeAd = nil
            nativeAd = nil
            adLoader = nil
            isLoading = false
        }
    }
}

private final class DarkNativeAdCardView: NativeAdView {
    private let containerView = UIView()
    private let adLabel = UILabel()
    private let headlineLabel = UILabel()
    private let bodyLabel = UILabel()
    private let iconViewImage = UIImageView()
    private let callToActionButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func render(nativeAd: NativeAd) {
        headlineLabel.text = nativeAd.headline

        if let body = nativeAd.body, !body.isEmpty {
            bodyLabel.text = body
            bodyLabel.isHidden = false
        } else {
            bodyLabel.isHidden = true
        }

        if let icon = nativeAd.icon?.image {
            iconViewImage.image = icon
            iconViewImage.isHidden = false
        } else {
            iconViewImage.image = nil
            iconViewImage.isHidden = true
        }

        if let cta = nativeAd.callToAction, !cta.isEmpty {
            callToActionButton.setTitle(cta, for: .normal)
            callToActionButton.isHidden = false
        } else {
            callToActionButton.setTitle(nil, for: .normal)
            callToActionButton.isHidden = true
        }

        self.nativeAd = nativeAd
    }

    private func setup() {
        backgroundColor = .clear

        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(white: 0.12, alpha: 0.92)
        containerView.layer.cornerRadius = 14
        containerView.layer.cornerCurve = .continuous
        containerView.layer.borderWidth = 0.8
        containerView.layer.borderColor = UIColor(white: 1.0, alpha: 0.12).cgColor
        addSubview(containerView)

        adLabel.translatesAutoresizingMaskIntoConstraints = false
        adLabel.text = "Ad"
        adLabel.textColor = UIColor(white: 1.0, alpha: 0.94)
        adLabel.font = .systemFont(ofSize: 11, weight: .bold)
        adLabel.textAlignment = .center
        adLabel.backgroundColor = UIColor(white: 0.22, alpha: 1)
        adLabel.layer.cornerRadius = 5
        adLabel.layer.masksToBounds = true

        iconViewImage.translatesAutoresizingMaskIntoConstraints = false
        iconViewImage.contentMode = .scaleAspectFill
        iconViewImage.clipsToBounds = true
        iconViewImage.layer.cornerRadius = 8
        iconViewImage.backgroundColor = UIColor(white: 0.2, alpha: 1)

        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        headlineLabel.font = .systemFont(ofSize: 17, weight: .bold)
        headlineLabel.textColor = UIColor(white: 1.0, alpha: 0.96)
        headlineLabel.numberOfLines = 2

        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.font = .systemFont(ofSize: 13, weight: .medium)
        bodyLabel.textColor = UIColor(white: 1.0, alpha: 0.72)
        bodyLabel.numberOfLines = 2

        callToActionButton.translatesAutoresizingMaskIntoConstraints = false
        var ctaConfiguration = UIButton.Configuration.filled()
        ctaConfiguration.baseForegroundColor = .white
        ctaConfiguration.baseBackgroundColor = UIColor(red: 0.19, green: 0.38, blue: 0.84, alpha: 1)
        ctaConfiguration.cornerStyle = .medium
        ctaConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        ctaConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var updated = incoming
            updated.font = .systemFont(ofSize: 13, weight: .bold)
            return updated
        }
        callToActionButton.configuration = ctaConfiguration
        callToActionButton.isUserInteractionEnabled = false

        containerView.addSubview(adLabel)
        containerView.addSubview(iconViewImage)
        containerView.addSubview(headlineLabel)
        containerView.addSubview(bodyLabel)
        containerView.addSubview(callToActionButton)

        headlineView = headlineLabel
        bodyView = bodyLabel
        iconView = iconViewImage
        callToActionView = callToActionButton

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),

            adLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            adLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            adLabel.widthAnchor.constraint(equalToConstant: 24),
            adLabel.heightAnchor.constraint(equalToConstant: 18),

            iconViewImage.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            iconViewImage.topAnchor.constraint(equalTo: adLabel.bottomAnchor, constant: 10),
            iconViewImage.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -12),
            iconViewImage.widthAnchor.constraint(equalToConstant: 40),
            iconViewImage.heightAnchor.constraint(equalToConstant: 40),

            headlineLabel.leadingAnchor.constraint(equalTo: iconViewImage.trailingAnchor, constant: 10),
            headlineLabel.trailingAnchor.constraint(equalTo: callToActionButton.leadingAnchor, constant: -10),
            headlineLabel.topAnchor.constraint(equalTo: iconViewImage.topAnchor),

            bodyLabel.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: headlineLabel.trailingAnchor),
            bodyLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 4),
            bodyLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -12),

            callToActionButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            callToActionButton.centerYAnchor.constraint(equalTo: iconViewImage.centerYAnchor),
            callToActionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 74),
            callToActionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 34)
        ])
    }
}

private extension UIApplication {
    var uhTopViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController?
            .uhTopMostPresentedViewController
    }
}

private extension UIViewController {
    var uhTopMostPresentedViewController: UIViewController {
        if let presentedViewController {
            return presentedViewController.uhTopMostPresentedViewController
        }

        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.uhTopMostPresentedViewController ?? navigationController
        }

        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.uhTopMostPresentedViewController ?? tabBarController
        }

        return self
    }
}
