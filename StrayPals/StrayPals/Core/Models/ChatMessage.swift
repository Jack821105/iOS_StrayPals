//
//  ChatMessage.swift
//  StrayPals (MaoWo)
//
//  領養顧問的對話訊息模型。一則助理訊息可附帶「快速回覆選項」與「推薦動物」，
//  讓聊天泡泡能直接顯示可點選的建議與動物卡。
//

import Foundation

// MARK: - ChatMessage

struct ChatMessage {

    enum Sender {
        case user
        case assistant
    }

    let sender: Sender
    let text: String
    /// 快速回覆選項（顯示為可點選的 chip）。
    var quickReplies: [String]
    /// 推薦的動物（顯示為水平卡片）。
    var recommendations: [Animal]

    init(sender: Sender, text: String, quickReplies: [String] = [], recommendations: [Animal] = []) {
        self.sender = sender
        self.text = text
        self.quickReplies = quickReplies
        self.recommendations = recommendations
    }
}
