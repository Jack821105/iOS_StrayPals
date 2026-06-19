//
//  AnimalCardCell.swift
//  StrayPals
//
//  列表 / 收藏共用的動物卡片 Cell：照片 + 漸層 + 資訊 + 收藏愛心。
//  純程式碼 Auto Layout，照片透過 UIImageView+Cache 載入並快取。
//

import UIKit

// MARK: - AnimalCardCell

final class AnimalCardCell: UICollectionViewCell {

    // MARK: Reuse

    static let reuseID = "AnimalCardCell"

    // MARK: Callbacks

    /// 點擊收藏愛心時呼叫。
    var onToggleFavorite: (() -> Void)?

    // MARK: Subviews

    private let container = UIView()
    private let imageView = UIImageView()
    private let gradientLayer = CAGradientLayer()
    private let kindBadge = UILabel(font: .systemFont(ofSize: 12, weight: .semibold), color: .white)
    private let urgentBadge = UILabel(font: .systemFont(ofSize: 11, weight: .bold), color: .white)
    private let nameLabel = UILabel(font: .systemFont(ofSize: 15, weight: .bold), color: .white)
    private let infoLabel = UILabel(font: .systemFont(ofSize: 12, weight: .medium), color: .white, lines: 2)
    private let favoriteButton = UIButton(type: .system)

    // MARK: Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = imageView.bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = UIImageView.defaultPlaceholder
        urgentBadge.isHidden = true
        onToggleFavorite = nil
    }

    // MARK: Setup

    private func setupUI() {
        container.applyCardStyle()
        container.clipsToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground

        // 底部漸層讓白字清晰。
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.6).cgColor]
        gradientLayer.locations = [0.45, 1.0]
        imageView.layer.addSublayer(gradientLayer)

        kindBadge.backgroundColor = .appPrimary
        kindBadge.textAlignment = .center
        kindBadge.layer.cornerRadius = 9
        kindBadge.clipsToBounds = true

        urgentBadge.backgroundColor = .appHeart
        urgentBadge.textAlignment = .center
        urgentBadge.layer.cornerRadius = 9
        urgentBadge.clipsToBounds = true
        urgentBadge.isHidden = true

        favoriteButton.tintColor = .white
        favoriteButton.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        favoriteButton.layer.cornerRadius = 16
        favoriteButton.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside)

        contentView.addSubviews(container)
        container.addSubviews(imageView, kindBadge, urgentBadge, favoriteButton, nameLabel, infoLabel)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            kindBadge.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            kindBadge.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            kindBadge.heightAnchor.constraint(equalToConstant: 18),
            kindBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 36),

            urgentBadge.leadingAnchor.constraint(equalTo: kindBadge.trailingAnchor, constant: 6),
            urgentBadge.centerYAnchor.constraint(equalTo: kindBadge.centerYAnchor),
            urgentBadge.heightAnchor.constraint(equalToConstant: 18),

            favoriteButton.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            favoriteButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            favoriteButton.widthAnchor.constraint(equalToConstant: 32),
            favoriteButton.heightAnchor.constraint(equalToConstant: 32),

            infoLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            infoLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            infoLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),

            nameLabel.leadingAnchor.constraint(equalTo: infoLabel.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: infoLabel.trailingAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: infoLabel.topAnchor, constant: -2)
        ])

        // 內距留白讓卡片陰影不被裁切。
        contentView.layoutMargins = .zero
    }

    // MARK: Configure

    /// 以動物資料與收藏狀態設定畫面。
    /// - Parameters:
    ///   - distanceText: 距離排序啟用時顯示「📍 X 公里」，否則為 nil。
    ///   - showUrgentBadge: 緊急救援區是否顯示倒數徽章。
    ///   - urgentText: 倒數文字（如「剩 3 天」）。
    func configure(with animal: Animal,
                   isFavorite: Bool,
                   distanceText: String? = nil,
                   showUrgentBadge: Bool = false,
                   urgentText: String? = nil) {
        kindBadge.text = "  \(animal.kind.localizedName)  "
        if showUrgentBadge, let urgentText {
            urgentBadge.text = "  \(urgentText)  "
            urgentBadge.isHidden = false
        } else {
            urgentBadge.isHidden = true
        }
        nameLabel.text = animal.shelterName
        var info = "\(animal.sexText) · \(animal.ageText) · \(animal.bodyTypeText)"
        if let distanceText {
            info += "\n📍 \(distanceText)"
        }
        infoLabel.text = info
        imageView.setImage(from: animal.imageURL)
        updateFavorite(isFavorite)
    }

    /// 進場動畫：淡入 + 由下微微上移。
    func animateAppearance(delay: TimeInterval = 0) {
        alpha = 0
        transform = CGAffineTransform(translationX: 0, y: 24)
        UIView.animate(
            withDuration: 0.45,
            delay: delay,
            options: [.curveEaseOut, .allowUserInteraction],
            animations: {
                self.alpha = 1
                self.transform = .identity
            }
        )
    }

    /// 單獨更新收藏圖示（toggle 時用，免重新載圖）。
    func updateFavorite(_ isFavorite: Bool) {
        let name = isFavorite ? "heart.fill" : "heart"
        favoriteButton.setImage(UIImage(systemName: name), for: .normal)
        favoriteButton.tintColor = isFavorite ? .appHeart : .white
    }

    // MARK: Actions

    @objc private func favoriteTapped() {
        HapticsManager.shared.toggle()   // 觸覺回饋
        favoriteButton.bounce()          // 彈跳動畫
        onToggleFavorite?()
    }
}
