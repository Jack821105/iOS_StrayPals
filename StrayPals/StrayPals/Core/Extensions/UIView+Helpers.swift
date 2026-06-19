//
//  UIView+Helpers.swift
//  StrayPals
//
//  常用的 UI 小工具：圓角陰影卡片樣式、批次加入子視圖。
//

import UIKit

// MARK: - UIView Helpers

extension UIView {

    /// 一次加入多個子視圖並關閉 autoresizing mask（純程式碼 Auto Layout）。
    func addSubviews(_ views: UIView...) {
        views.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
    }

    /// 收藏「彈跳」動畫：先放大再以彈簧回彈，給予點擊的滿足感。
    func bounce() {
        transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        UIView.animate(
            withDuration: 0.45,
            delay: 0,
            usingSpringWithDamping: 0.45,
            initialSpringVelocity: 6,
            options: [.allowUserInteraction],
            animations: { self.transform = .identity }
        )
    }

    /// 套用卡片樣式（圓角 + 柔和陰影）。
    func applyCardStyle(cornerRadius: CGFloat = 16) {
        layer.cornerRadius = cornerRadius
        layer.cornerCurve = .continuous
        backgroundColor = .appCard
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8
    }
}

// MARK: - UILabel Factory

extension UILabel {

    /// 便利建構子，快速產生標準樣式標籤。
    convenience init(text: String? = nil,
                     font: UIFont,
                     color: UIColor = .label,
                     lines: Int = 1) {
        self.init()
        self.text = text
        self.font = font
        self.textColor = color
        self.numberOfLines = lines
    }
}
