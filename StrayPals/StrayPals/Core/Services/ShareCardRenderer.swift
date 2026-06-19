//
//  ShareCardRenderer.swift
//  StrayPals (MaoWo)
//
//  將一隻動物渲染成可分享的「圖卡」。支援多種版型（經典 / 拍立得 / 簡約）
//  與自訂留言，使用 UIGraphicsImageRenderer 把離螢幕版面繪製成 UIImage。
//

import UIKit

// MARK: - ShareCardStyle

enum ShareCardStyle: Int, CaseIterable {
    case classic
    case polaroid
    case minimal

    var localizedName: String {
        switch self {
        case .classic:  return L10n.shareStyleClassic
        case .polaroid: return L10n.shareStylePolaroid
        case .minimal:  return L10n.shareStyleMinimal
        }
    }
}

// MARK: - ShareCardRenderer

enum ShareCardRenderer {

    private static let width: CGFloat = 750

    /// 產生分享圖卡。
    /// - Parameters:
    ///   - message: 使用者自訂留言（可空）。
    static func render(animal: Animal, image: UIImage?, style: ShareCardStyle, message: String = "") -> UIImage {
        switch style {
        case .classic:  return renderClassic(animal, image, message)
        case .polaroid: return renderPolaroid(animal, image, message)
        case .minimal:  return renderMinimal(animal, image, message)
        }
    }

    // MARK: Classic — 照片 + 資訊面板 + 漸層頁尾

    private static func renderClassic(_ animal: Animal, _ image: UIImage?, _ message: String) -> UIImage {
        let imageHeight: CGFloat = 750
        let hasMessage = !message.isEmpty
        let panelHeight: CGFloat = hasMessage ? 230 : 180
        let footerHeight: CGFloat = 120
        let total = imageHeight + panelHeight + footerHeight

        return draw(height: total) { card in
            let photo = makePhoto(image, frame: CGRect(x: 0, y: 0, width: width, height: imageHeight))
            card.addSubview(photo)
            card.addSubview(makeKindBadge(animal, origin: CGPoint(x: 30, y: 30)))

            let name = makeLabel(animal.shelterName, frame: CGRect(x: 40, y: imageHeight + 32, width: width - 80, height: 52),
                                 size: 38, weight: .bold, color: UIColor(hex: 0x222222))
            card.addSubview(name)

            let info = makeLabel("\(animal.sexText) · \(animal.ageText) · \(animal.bodyTypeText) · \(animal.colourText)",
                                 frame: CGRect(x: 40, y: imageHeight + 94, width: width - 80, height: 38),
                                 size: 26, weight: .medium, color: UIColor(hex: 0x8A8A8A))
            card.addSubview(info)

            if hasMessage {
                let msg = makeLabel("「\(message)」", frame: CGRect(x: 40, y: imageHeight + 140, width: width - 80, height: 60),
                                    size: 26, weight: .medium, color: UIColor(hex: 0xFF6B5E), lines: 2)
                card.addSubview(msg)
            }

            card.addSubview(makeFooter(y: total - footerHeight, height: footerHeight))
        }
    }

    // MARK: Polaroid — 白框拍立得

    private static func renderPolaroid(_ animal: Animal, _ image: UIImage?, _ message: String) -> UIImage {
        let margin: CGFloat = 48
        let photoSize = width - margin * 2
        let captionHeight: CGFloat = 200
        let total = margin + photoSize + captionHeight

        return draw(height: total, background: UIColor(hex: 0xFBF7F0)) { card in
            let photo = makePhoto(image, frame: CGRect(x: margin, y: margin, width: photoSize, height: photoSize))
            photo.layer.cornerRadius = 4
            card.addSubview(photo)
            card.addSubview(makeKindBadge(animal, origin: CGPoint(x: margin + 18, y: margin + 18)))

            let captionTop = margin + photoSize + 12
            let title = message.isEmpty ? animal.shelterName : message
            let caption = makeLabel(title, frame: CGRect(x: margin, y: captionTop, width: photoSize, height: 90),
                                    size: 34, weight: .semibold, color: UIColor(hex: 0x33291F), lines: 2)
            caption.textAlignment = .center
            card.addSubview(caption)

            let brand = makeLabel(L10n.shareBrand, frame: CGRect(x: margin, y: total - 70, width: photoSize, height: 40),
                                  size: 22, weight: .medium, color: UIColor(hex: 0xB08968))
            brand.textAlignment = .center
            card.addSubview(brand)
        }
    }

    // MARK: Minimal — 滿版照片 + 底部薄資訊條

    private static func renderMinimal(_ animal: Animal, _ image: UIImage?, _ message: String) -> UIImage {
        let total: CGFloat = 900

        return draw(height: total, background: .black) { card in
            let photo = makePhoto(image, frame: CGRect(x: 0, y: 0, width: width, height: total))
            card.addSubview(photo)

            // 底部漸黑遮罩。
            let overlay = GradientView(colors: [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.75).cgColor])
            overlay.setPoints(start: CGPoint(x: 0.5, y: 0.55), end: CGPoint(x: 0.5, y: 1))
            overlay.frame = CGRect(x: 0, y: 0, width: width, height: total)
            card.addSubview(overlay)

            let text = message.isEmpty
                ? "\(animal.shelterName)\n\(animal.kind.localizedName) · \(animal.sexText) · \(animal.ageText)"
                : message
            let caption = makeLabel(text, frame: CGRect(x: 44, y: total - 200, width: width - 88, height: 120),
                                    size: 32, weight: .bold, color: .white, lines: 3)
            card.addSubview(caption)

            let brand = makeLabel(L10n.shareBrand, frame: CGRect(x: 44, y: total - 70, width: width - 88, height: 36),
                                  size: 22, weight: .medium, color: UIColor(white: 1, alpha: 0.85))
            card.addSubview(brand)
        }
    }

    // MARK: Drawing Helpers

    private static func draw(height: CGFloat, background: UIColor = .white, _ build: (UIView) -> Void) -> UIImage {
        let card = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        card.backgroundColor = background
        build(card)
        let renderer = UIGraphicsImageRenderer(size: card.bounds.size)
        return renderer.image { _ in
            card.drawHierarchy(in: card.bounds, afterScreenUpdates: true)
        }
    }

    private static func makePhoto(_ image: UIImage?, frame: CGRect) -> UIImageView {
        let view = UIImageView(frame: frame)
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.backgroundColor = UIColor(hex: 0xEFEFEF)
        view.image = image ?? UIImageView.defaultPlaceholder
        return view
    }

    private static func makeLabel(_ text: String, frame: CGRect, size: CGFloat,
                                  weight: UIFont.Weight, color: UIColor, lines: Int = 1) -> UILabel {
        let label = UILabel(frame: frame)
        label.text = text
        label.font = .systemFont(ofSize: size, weight: weight)
        label.textColor = color
        label.numberOfLines = lines
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
    }

    private static func makeKindBadge(_ animal: Animal, origin: CGPoint) -> UILabel {
        let badge = UILabel(frame: CGRect(x: origin.x, y: origin.y, width: 120, height: 44))
        badge.text = "  \(animal.kind.localizedName)  "
        badge.font = .systemFont(ofSize: 24, weight: .bold)
        badge.textColor = .white
        badge.backgroundColor = .appPrimary
        badge.textAlignment = .center
        badge.layer.cornerRadius = 22
        badge.clipsToBounds = true
        return badge
    }

    private static func makeFooter(y: CGFloat, height: CGFloat) -> UIView {
        let footer = GradientView()
        footer.frame = CGRect(x: 0, y: y, width: width, height: height)
        let brand = UILabel(frame: CGRect(x: 40, y: 0, width: width - 80, height: height))
        brand.text = L10n.shareBrand
        brand.font = .systemFont(ofSize: 28, weight: .semibold)
        brand.textColor = .white
        brand.adjustsFontSizeToFitWidth = true
        brand.minimumScaleFactor = 0.5
        footer.addSubview(brand)
        return footer
    }
}
