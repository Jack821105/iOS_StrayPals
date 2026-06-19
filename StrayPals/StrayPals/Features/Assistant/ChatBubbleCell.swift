//
//  ChatBubbleCell.swift
//  StrayPals (MaoWo)
//
//  聊天泡泡 Cell：使用者（右、珊瑚底白字）與助理（左、卡片底）。
//  助理訊息可附帶水平捲動的推薦動物卡，點擊即開啟詳情。
//

import UIKit

// MARK: - ChatBubbleCell

final class ChatBubbleCell: UITableViewCell {

    static let reuseID = "ChatBubbleCell"

    /// 點選推薦動物卡。
    var onSelectAnimal: ((Animal) -> Void)?

    // MARK: Subviews

    private let bubble = UIView()
    private let messageLabel = UILabel(font: .systemFont(ofSize: 16), lines: 0)
    private let recommendationsScroll = UIScrollView()
    private let recommendationsRow = UIStackView()
    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!

    // MARK: Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: Setup

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none

        bubble.layer.cornerRadius = 18
        bubble.layer.cornerCurve = .continuous

        recommendationsScroll.showsHorizontalScrollIndicator = false
        recommendationsRow.axis = .horizontal
        recommendationsRow.spacing = 10

        let stack = UIStackView(arrangedSubviews: [messageLabel, recommendationsScroll])
        stack.axis = .vertical
        stack.spacing = 10

        bubble.addSubviews(stack)
        recommendationsScroll.addSubviews(recommendationsRow)
        contentView.addSubviews(bubble)

        leadingConstraint = bubble.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14)
        trailingConstraint = bubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14)

        NSLayoutConstraint.activate([
            bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            bubble.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.82),

            stack.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -14),
            stack.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -10),

            recommendationsRow.topAnchor.constraint(equalTo: recommendationsScroll.contentLayoutGuide.topAnchor),
            recommendationsRow.leadingAnchor.constraint(equalTo: recommendationsScroll.contentLayoutGuide.leadingAnchor),
            recommendationsRow.trailingAnchor.constraint(equalTo: recommendationsScroll.contentLayoutGuide.trailingAnchor),
            recommendationsRow.bottomAnchor.constraint(equalTo: recommendationsScroll.contentLayoutGuide.bottomAnchor),
            recommendationsScroll.heightAnchor.constraint(equalToConstant: 150),
            recommendationsScroll.widthAnchor.constraint(equalToConstant: 260)
        ])
    }

    // MARK: Configure

    func configure(with message: ChatMessage) {
        messageLabel.text = message.text

        // 對齊與配色。
        if message.sender == .user {
            bubble.backgroundColor = .appPrimary
            messageLabel.textColor = .white
            leadingConstraint.isActive = false
            trailingConstraint.isActive = true
        } else {
            bubble.backgroundColor = .appCard
            messageLabel.textColor = .label
            trailingConstraint.isActive = false
            leadingConstraint.isActive = true
        }

        // 推薦動物卡。
        recommendationsRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let hasRecs = !message.recommendations.isEmpty
        recommendationsScroll.isHidden = !hasRecs
        if hasRecs {
            for animal in message.recommendations {
                recommendationsRow.addArrangedSubview(makeAnimalCard(animal))
            }
        }
    }

    private func makeAnimalCard(_ animal: Animal) -> UIView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = .secondarySystemBackground
        imageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        imageView.setImage(from: animal.imageURL)

        let name = UILabel(text: animal.shelterName, font: .systemFont(ofSize: 12, weight: .semibold),
                           color: .label, lines: 2)
        let info = UILabel(text: "\(animal.kind.localizedName) · \(animal.sexText)",
                           font: .systemFont(ofSize: 11), color: .secondaryLabel)

        let card = UIStackView(arrangedSubviews: [imageView, name, info])
        card.axis = .vertical
        card.spacing = 3
        card.widthAnchor.constraint(equalToConstant: 110).isActive = true

        // 點擊開啟詳情。
        let button = UIButton(type: .custom)
        button.addAction(UIAction { [weak self] _ in self?.onSelectAnimal?(animal) }, for: .touchUpInside)
        card.addSubviews(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: card.topAnchor),
            button.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        return card
    }
}
