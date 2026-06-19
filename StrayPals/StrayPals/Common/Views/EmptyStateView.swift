//
//  EmptyStateView.swift
//  StrayPals
//
//  可重用的空狀態 / 錯誤狀態視圖，顯示圖示、標題、說明與可選的重試按鈕。
//

import UIKit

// MARK: - EmptyStateView

final class EmptyStateView: UIView {

    // MARK: Callbacks

    /// 點擊重試按鈕時的回呼。
    var onRetry: (() -> Void)?

    // MARK: Subviews

    private let imageView = UIImageView()
    private let titleLabel = UILabel(font: .preferredFont(forTextStyle: .headline),
                                     color: .label, lines: 0)
    private let messageLabel = UILabel(font: .preferredFont(forTextStyle: .subheadline),
                                       color: .secondaryLabel, lines: 0)
    private let retryButton = UIButton(type: .system)
    private let stack = UIStackView()

    // MARK: Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: Setup

    private func setupUI() {
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .appSecondary
        imageView.setContentHuggingPriority(.required, for: .vertical)

        titleLabel.textAlignment = .center
        messageLabel.textAlignment = .center

        retryButton.setTitle(L10n.actionRetry, for: .normal)
        retryButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.addArrangedSubview(imageView)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(messageLabel)
        stack.addArrangedSubview(retryButton)
        stack.setCustomSpacing(20, after: messageLabel)

        addSubviews(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 40),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -40),
            imageView.heightAnchor.constraint(equalToConstant: 80)
        ])
    }

    // MARK: Configure

    /// 設定顯示內容。
    /// - Parameter showRetry: 是否顯示重試按鈕（錯誤狀態才需要）。
    func configure(symbol: String, title: String, message: String, showRetry: Bool) {
        let config = UIImage.SymbolConfiguration(pointSize: 64, weight: .light)
        imageView.image = UIImage(systemName: symbol, withConfiguration: config)
        titleLabel.text = title
        messageLabel.text = message
        retryButton.isHidden = !showRetry
    }

    // MARK: Actions

    @objc private func retryTapped() {
        onRetry?()
    }
}
