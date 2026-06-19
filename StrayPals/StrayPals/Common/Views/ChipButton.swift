//
//  ChipButton.swift
//  StrayPals
//
//  可切換選取狀態的「標籤膠囊」按鈕，用於進階篩選的多選項目。
//  選取時填滿主題色，未選取時為描邊樣式。
//

import UIKit

// MARK: - ChipButton

final class ChipButton: UIButton {

    // MARK: State

    /// 與此 chip 綁定的值（如性別代碼 "M"）。
    let value: String

    /// 是否選取，變更時自動更新外觀。
    override var isSelected: Bool {
        didSet { updateAppearance() }
    }

    // MARK: Init

    init(title: String, value: String) {
        self.value = value
        super.init(frame: .zero)

        // 使用 UIButton.Configuration（iOS 15+）取代已棄用的 contentEdgeInsets。
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attr in
            var attr = attr
            attr.font = .systemFont(ofSize: 14, weight: .medium)
            return attr
        }
        config.title = title
        configuration = config

        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        updateAppearance()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Appearance

    private func updateAppearance() {
        configuration?.background.backgroundColor = isSelected ? .appPrimary : .clear
        configuration?.baseForegroundColor = isSelected ? .white : .label
        layer.borderColor = isSelected ? UIColor.appPrimary.cgColor : UIColor.systemGray3.cgColor
    }
}
