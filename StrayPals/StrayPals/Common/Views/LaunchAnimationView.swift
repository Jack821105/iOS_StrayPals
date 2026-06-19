//
//  LaunchAnimationView.swift
//  StrayPals
//
//  自訂啟動動畫。iOS 的 LaunchScreen 是靜態的，因此在 App 啟動後
//  以此視圖覆蓋畫面，播放品牌動畫（爪印彈入 + 標題浮現），再淡出揭開主畫面。
//

import UIKit

// MARK: - LaunchAnimationView

final class LaunchAnimationView: UIView {

    // MARK: Gradient Background

    override class var layerClass: AnyClass { CAGradientLayer.self }
    private var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }

    // MARK: Subviews

    private let iconView = UIImageView()
    private let titleLabel = UILabel(text: L10n.appName,
                                     font: .systemFont(ofSize: 34, weight: .heavy),
                                     color: .white)
    private let subtitleLabel = UILabel(text: L10n.launchSubtitle,
                                        font: .systemFont(ofSize: 16, weight: .medium),
                                        color: UIColor(white: 1, alpha: 0.9))

    // MARK: Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: Setup

    private func setup() {
        gradientLayer.colors = UIColor.brandGradientColors
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)

        let config = UIImage.SymbolConfiguration(pointSize: 88, weight: .bold)
        iconView.image = UIImage(systemName: "pawprint.fill", withConfiguration: config)
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit

        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 14
        stack.setCustomSpacing(8, after: titleLabel)

        addSubviews(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        // 動畫起始狀態。
        iconView.alpha = 0
        iconView.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
        titleLabel.alpha = 0
        titleLabel.transform = CGAffineTransform(translationX: 0, y: 14)
        subtitleLabel.alpha = 0
    }

    // MARK: Play

    /// 播放啟動動畫，結束後淡出並回呼。
    func play(completion: @escaping () -> Void) {
        // 1) 爪印彈入。
        UIView.animate(withDuration: 0.6, delay: 0.05,
                       usingSpringWithDamping: 0.55, initialSpringVelocity: 6,
                       options: [.curveEaseOut]) {
            self.iconView.alpha = 1
            self.iconView.transform = .identity
        }

        // 2) 標題浮現。
        UIView.animate(withDuration: 0.45, delay: 0.35, options: [.curveEaseOut]) {
            self.titleLabel.alpha = 1
            self.titleLabel.transform = .identity
        }
        UIView.animate(withDuration: 0.45, delay: 0.55, options: [.curveEaseOut]) {
            self.subtitleLabel.alpha = 1
        }

        // 3) 短暫停留後整體淡出。
        UIView.animate(withDuration: 0.45, delay: 1.35, options: [.curveEaseIn]) {
            self.alpha = 0
        } completion: { _ in
            self.removeFromSuperview()
            completion()
        }
    }
}
