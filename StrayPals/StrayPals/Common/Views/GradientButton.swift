//
//  GradientButton.swift
//  StrayPals
//
//  帶品牌漸層底色的主要行動按鈕（CTA）。比純色按鈕更有個性，
//  按下時有縮放回饋。用於詳情頁的撥打/地圖、通報送出等重要操作。
//

import UIKit

// MARK: - GradientButton

final class GradientButton: UIButton {

    // MARK: Subviews

    private let gradient = GradientView()

    // MARK: Init

    init(title: String, systemImage: String? = nil) {
        super.init(frame: .zero)

        // 漸層背景置於最底層。
        gradient.isUserInteractionEnabled = false
        gradient.layer.cornerRadius = 16
        gradient.layer.cornerCurve = .continuous
        gradient.clipsToBounds = true
        insertSubview(gradient, at: 0)

        var config = UIButton.Configuration.plain()
        config.title = title
        if let systemImage { config.image = UIImage(systemName: systemImage) }
        config.imagePadding = 8
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 18)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attr in
            var attr = attr
            attr.font = .systemFont(ofSize: 16, weight: .semibold)
            return attr
        }
        configuration = config
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
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
