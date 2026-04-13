//
//  AdMobConfiguration.swift
//  UtilityHub
//
//  Created by Codex on 28/03/26.
//

import Foundation

enum AdMobConfiguration {
    #if DEBUG
    static let homeBannerAdUnitID = "ca-app-pub-3940256099942544/2435281174"
    static let homeNativeAdUnitID = "ca-app-pub-3940256099942544/3986624511"
    #else
    static let homeBannerAdUnitID = "ca-app-pub-7137418658013523/7591072839"
    // Replace with a production native ad unit ID from AdMob before release.
    static let homeNativeAdUnitID = "ca-app-pub-7137418658013523/7591072839"
    #endif
}
