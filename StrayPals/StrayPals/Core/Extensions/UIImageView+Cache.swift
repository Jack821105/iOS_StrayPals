//
//  UIImageView+Cache.swift
//  StrayPals
//
//  以 Kingfisher 載入遠端圖片並自動做記憶體 + 磁碟二級快取。
//  對外維持單純的 `setImage(from:placeholder:)` API，因此各 cell / 詳情頁
//  完全不需修改即可享有快取、淡入、cell 重用安全與下載取消等能力。
//

import UIKit
import Kingfisher

// MARK: - UIImageView + Cache

extension UIImageView {

    /// 以 URL 載入圖片（Kingfisher 自動處理快取與 cell 重用）。
    /// - Parameters:
    ///   - url: 圖片網址，為 nil 時顯示佔位圖。
    ///   - placeholder: 佔位 / 失敗時顯示的圖片。
    func setImage(from url: URL?, placeholder: UIImage? = UIImageView.defaultPlaceholder) {
        guard let url else {
            kf.cancelDownloadTask()
            image = placeholder
            return
        }

        kf.setImage(
            with: url,
            placeholder: placeholder,
            options: [
                .transition(.fade(0.25)),   // 淡入顯示
                .cacheOriginalImage,         // 同時快取原圖
                .scaleFactor(UIScreen.main.scale)
            ]
        )
    }

    /// 預設佔位圖（系統爪印符號）。
    static var defaultPlaceholder: UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: 44, weight: .light)
        return UIImage(systemName: "pawprint.fill", withConfiguration: config)?
            .withTintColor(.tertiaryLabel, renderingMode: .alwaysOriginal)
    }
}
