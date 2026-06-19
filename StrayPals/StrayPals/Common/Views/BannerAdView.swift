//
//  BannerAdView.swift
//  StrayPals (MaoWo)
//
//  橫幅廣告的容器視圖。當「應顯示廣告」時載入 AdMob 橫幅，否則高度收合為 0，
//  完全不占畫面。以 `#if canImport(GoogleMobileAds)` 閘控，未整合 SDK 時保持收合。
//

import UIKit
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

// MARK: - BannerAdView

final class BannerAdView: UIView {

    // MARK: Properties

    private var heightConstraint: NSLayoutConstraint!

    #if canImport(GoogleMobileAds)
    private var bannerView: BannerView?
    #endif

    // MARK: Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .appBackground
        heightConstraint = heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.isActive = true
    }

    // MARK: Load

    /// 載入廣告。需傳入承載的 ViewController（AdMob 規定）。
    func load(from viewController: UIViewController) {
        guard AdsService.shared.shouldShowAds else {
            collapse()
            return
        }

        #if canImport(GoogleMobileAds)
        let banner = bannerView ?? BannerView(adSize: AdSizeBanner)
        banner.adUnitID = AppConfig.shared.adBannerUnitID
        banner.rootViewController = viewController
        banner.translatesAutoresizingMaskIntoConstraints = false

        if banner.superview == nil {
            addSubview(banner)
            NSLayoutConstraint.activate([
                banner.centerXAnchor.constraint(equalTo: centerXAnchor),
                banner.topAnchor.constraint(equalTo: topAnchor)
            ])
        }
        bannerView = banner
        heightConstraint.constant = AdSizeBanner.size.height
        banner.load(Request())
        #else
        collapse()
        #endif
    }

    // MARK: Helpers

    private func collapse() {
        heightConstraint.constant = 0
    }
}
