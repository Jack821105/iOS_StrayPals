//
//  AdoptionCountdownAttributes.swift
//  StrayPals (MaoWo) — 主 App 與 Widget Extension 共用
//
//  Live Activity（鎖定畫面 + 動態島）的資料契約。此型別必須同時編譯進
//  主 App 與 Widget Extension 兩個 target，ActivityKit 才能正確配對。
//

import ActivityKit
import Foundation

// MARK: - AdoptionCountdownAttributes

@available(iOS 16.1, *)
struct AdoptionCountdownAttributes: ActivityAttributes {

    /// 會即時更新的動態內容。
    public struct ContentState: Codable, Hashable {
        /// 認養開放截止時間（用於倒數）。
        var deadline: Date
        /// 收容所名稱。
        var shelterName: String
    }

    // 活動建立後固定不變的資訊。
    var animalName: String
    var kindEmoji: String
    var animalId: Int
}
