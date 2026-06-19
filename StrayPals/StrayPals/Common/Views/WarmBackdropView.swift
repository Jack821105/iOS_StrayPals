//
//  WarmBackdropView.swift
//  StrayPals (MaoWo)
//
//  溫馨暖色背景：自頂部柔和蜜桃光暈漸層至暖象牙底色，營造療癒、溫暖的質感。
//  放在各畫面內容的最底層；會自動跟隨深色模式更新顏色。
//

import UIKit

// MARK: - WarmBackdropView

final class WarmBackdropView: UIView {

    // MARK: Gradient

    override class var layerClass: AnyClass { CAGradientLayer.self }
    private var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }

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
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        // 蜜桃光暈集中在上方約 45%，下方維持暖象牙。
        gradientLayer.locations = [0, 0.45, 1]
        refreshColors()
    }

    // MARK: Dynamic Colors

    /// 深色 / 淺色模式切換時更新漸層顏色（CAGradientLayer 不會自動套用動態色）。
    override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previous) {
            refreshColors()
        }
    }

    private func refreshColors() {
        let top = UIColor.appBackdropTop.resolvedColor(with: traitCollection).cgColor
        let bottom = UIColor.appBackdropBottom.resolvedColor(with: traitCollection).cgColor
        gradientLayer.colors = [top, bottom, bottom]
    }
}

// MARK: - UIViewController + Warm Backdrop

extension UIViewController {

    /// 在畫面最底層鋪上溫馨暖色漸層背景。應於加入其他子視圖前呼叫。
    func applyWarmBackdrop() {
        view.backgroundColor = .appBackground
        let backdrop = WarmBackdropView(frame: view.bounds)
        backdrop.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(backdrop, at: 0)
    }
}
