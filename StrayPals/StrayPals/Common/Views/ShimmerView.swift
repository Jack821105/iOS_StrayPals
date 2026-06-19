//
//  ShimmerView.swift
//  StrayPals
//
//  骨架載入用的「微光掃過」效果視圖。以 CAGradientLayer 製作一條
//  斜向亮帶，反覆從左掃到右，營造資料載入中的動態感。
//

import UIKit

// MARK: - ShimmerView

final class ShimmerView: UIView {

    // MARK: Layers

    private let gradient = CAGradientLayer()
    private let animationKey = "shimmer"

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
        backgroundColor = .clear
        layer.cornerRadius = 12
        layer.cornerCurve = .continuous
        clipsToBounds = true

        let base = UIColor.systemGray5.cgColor
        let highlight = UIColor.systemGray4.cgColor
        gradient.colors = [base, highlight, base]
        gradient.locations = [0.0, 0.5, 1.0]
        // 斜向掃光。
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        layer.addSublayer(gradient)
    }

    // MARK: Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        // 讓亮帶起始於畫面左外側，寬度為三倍以利平移。
        gradient.frame = CGRect(x: -bounds.width, y: 0, width: bounds.width * 3, height: bounds.height)
    }

    // MARK: Animation

    /// 開始掃光動畫。
    func startAnimating() {
        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.duration = 1.2
        animation.fromValue = 0
        animation.toValue = bounds.width
        animation.repeatCount = .infinity
        gradient.add(animation, forKey: animationKey)
    }

    /// 停止掃光動畫。
    func stopAnimating() {
        gradient.removeAnimation(forKey: animationKey)
    }
}
