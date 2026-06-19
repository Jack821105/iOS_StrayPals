//
//  SkeletonGridView.swift
//  StrayPals
//
//  初次載入時覆蓋在列表上的「骨架畫面」：以兩欄方式排列數張
//  ShimmerView 卡片，模擬真實卡片的版位，降低空白等待的焦慮感。
//

import UIKit

// MARK: - SkeletonGridView

final class SkeletonGridView: UIView {

    // MARK: Properties

    private let stack = UIStackView()
    private var shimmers: [ShimmerView] = []

    /// 顯示的骨架卡片列數（每列兩張）。
    private let rowCount = 4

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
        backgroundColor = .appBackground

        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fillEqually
        addSubviews(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])

        // 建立每一列（兩張骨架卡）。
        for _ in 0..<rowCount {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 12
            row.distribution = .fillEqually
            for _ in 0..<2 {
                let card = ShimmerView()
                card.heightAnchor.constraint(equalToConstant: 200).isActive = true
                shimmers.append(card)
                row.addArrangedSubview(card)
            }
            stack.addArrangedSubview(row)
        }
    }

    // MARK: Control

    /// 顯示並開始動畫。
    func start() {
        isHidden = false
        shimmers.forEach { $0.startAnimating() }
    }

    /// 隱藏並停止動畫。
    func stop() {
        isHidden = true
        shimmers.forEach { $0.stopAnimating() }
    }
}
