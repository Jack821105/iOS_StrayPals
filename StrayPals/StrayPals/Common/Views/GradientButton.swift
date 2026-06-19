//
//  GradientButton.swift
//  StrayPals
//
//  帶品牌漸層底色的主要行動按鈕（CTA）。比純色按鈕更有個性，
//  按下時有縮放回饋。用於詳情頁的撥打/地圖、通報送出等重要操作。
//
//  ⚠️ 漸層以 CAGradientLayer 放在按鈕「自身 layer」最底層（而非以 subview 疊加）。
//     UIButton.Configuration 的標題/圖示是 subview，必定繪製在 layer 的 sublayer 之上，
//     如此可保證文字一定顯示在漸層上方（修正先前漸層蓋住文字、按鈕變空白的問題）。
//

import UIKit

// MARK: - GradientButton

final class GradientButton: UIButton {

    // MARK: Layer

    private let gradientLayer = CAGradientLayer()

    // MARK: Init

    init(title: String, systemImage: String? = nil) {
        super.init(frame: .zero)

        // 品牌漸層（珊瑚 → 蜜桃），置於自身 layer 最底層。
        gradientLayer.colors = UIColor.brandGradientColors
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = 16
        gradientLayer.cornerCurve = .continuous
        layer.insertSublayer(gradientLayer, at: 0)

        var config = UIButton.Configuration.plain()
        config.title = title
        if let systemImage { config.image = UIImage(systemName: systemImage) }
        config.imagePadding = 8
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 18)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attr in
            var attr = attr
            attr.font = .systemFont(ofSize: 16, weight: .semibold)
            // 明確固定白字，避免落回 tintColor（橘色）造成「橘字疊橘底」而看不見。
            attr.foregroundColor = UIColor.white
            return attr
        }
        configuration = config
        // 圖示也固定白色，與標題一致。
        tintColor = .white
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        // 漸層填滿整個按鈕；因為是 sublayer，標題（subview）一定在其上方。
        gradientLayer.frame = bounds
    }

    // MARK: Touch Feedback

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.15) {
                self.transform = self.isHighlighted
                    ? CGAffineTransform(scaleX: 0.96, y: 0.96)
                    : .identity
                self.alpha = self.isHighlighted ? 0.9 : 1.0
            }
        }
    }
}
