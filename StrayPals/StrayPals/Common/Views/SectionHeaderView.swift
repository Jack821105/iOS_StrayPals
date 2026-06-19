//
//  SectionHeaderView.swift
//  StrayPals (MaoWo)
//
//  首頁分區標題（緊急救援 / 為你推薦 / 全部浪浪）。緊急區附上紅點與火焰圖示強調。
//

import UIKit

// MARK: - SectionHeaderView

final class SectionHeaderView: UICollectionReusableView {

    static let reuseID = "SectionHeaderView"

    // MARK: Subviews

    private let iconView = UIImageView()
    private let titleLabel = UILabel(font: .systemFont(ofSize: 19, weight: .bold))

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
        iconView.contentMode = .scaleAspectFit
        iconView.setContentHuggingPriority(.required, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel])
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        addSubviews(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20)
        ])
    }

    // MARK: Configure

    func configure(title: String, isEmergency: Bool) {
        titleLabel.text = title
        iconView.image = UIImage(systemName: isEmergency ? "flame.fill" : "sparkles")
        iconView.tintColor = isEmergency ? .appHeart : .appPrimary
        iconView.isHidden = (title == L10n.homeSectionAll)
        titleLabel.textColor = isEmergency ? .appHeart : .label
    }
}
