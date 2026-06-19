//
//  UIColor+App.swift
//  StrayPals
//
//  App 的色彩語意定義。以「日落珊瑚 → 蜜桃」漸層作為品牌主視覺，
//  搭配清新的「薄荷藍綠」作為對比強調色，營造溫暖、療癒又有活力的個性。
//

import UIKit

// MARK: - Hex Init

extension UIColor {

    /// 以 16 進位整數建立顏色，例如 `UIColor(hex: 0xFF6B5E)`。
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let r = CGFloat((hex & 0xFF0000) >> 16) / 255
        let g = CGFloat((hex & 0x00FF00) >> 8) / 255
        let b = CGFloat(hex & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}

// MARK: - App Palette

extension UIColor {

    /// 主題色（日落珊瑚）。
    static let appPrimary = UIColor(hex: 0xFF6B5E)
    /// 漸層搭配色（蜜桃）。
    static let appSecondary = UIColor(hex: 0xFFB26B)
    /// 對比強調色（薄荷藍綠）。
    static let appAccent = UIColor(hex: 0x17C3B2)
    /// 收藏愛心色。
    static let appHeart = UIColor(hex: 0xFF4D6D)

    /// 品牌漸層用的色階（珊瑚 → 蜜桃）。
    static var brandGradientColors: [CGColor] {
        [UIColor(hex: 0xFF7E5F).cgColor, UIColor(hex: 0xFFB26B).cgColor]
    }

    /// 主要背景（支援深色模式，暖象牙 / 暖炭）。
    static let appBackground = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hex: 0x16120F)
            : UIColor(hex: 0xFFF7F0)
    }

    /// 卡片背景（支援深色模式）。
    static let appCard = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hex: 0x271F1A)
            : UIColor(hex: 0xFFFDFB)
    }

    /// 溫馨背景漸層 — 上緣（柔和蜜桃光暈）。
    static let appBackdropTop = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hex: 0x241A14)
            : UIColor(hex: 0xFFE8D6)
    }

    /// 溫馨背景漸層 — 下緣（暖象牙）。
    static let appBackdropBottom = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hex: 0x141110)
            : UIColor(hex: 0xFFF7F0)
    }
}

// MARK: - GradientView

/// 可重用的品牌漸層視圖（左上 → 右下）。
final class GradientView: UIView {

    // MARK: Layer Class

    override class var layerClass: AnyClass { CAGradientLayer.self }

    private var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }

    // MARK: Init

    /// - Parameter colors: 自訂色階；預設使用品牌漸層。
    init(colors: [CGColor] = UIColor.brandGradientColors) {
        super.init(frame: .zero)
        gradientLayer.colors = colors
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        gradientLayer.colors = UIColor.brandGradientColors
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
    }

    // MARK: API

    /// 更新漸層方向。
    func setPoints(start: CGPoint, end: CGPoint) {
        gradientLayer.startPoint = start
        gradientLayer.endPoint = end
    }
}
