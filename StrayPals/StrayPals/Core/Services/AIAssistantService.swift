//
//  AIAssistantService.swift
//  StrayPals (MaoWo)
//
//  領養顧問的抽象介面。目前由本地規則式 `PetAdvisorService` 實作（零金鑰、可離線）；
//  未來要改用 Claude API 時，只需新增一個符合此協定的實作（例如透過你的後端代理
//  呼叫 Claude Messages API），ViewModel / UI 完全不需更動。
//
//  ⚠️ 安全提醒：若改接 Claude，請務必經由「自己的後端代理」呼叫，
//     切勿把 Anthropic API Key 直接寫進 App（會被反編譯取出盜用）。
//

import Foundation

// MARK: - AIAssistantService

protocol AIAssistantService: AnyObject {
    /// 對話起始招呼（含第一個問題與快速選項）。
    func greeting() -> ChatMessage
    /// 處理使用者輸入並回傳助理回覆。宣告為 async 以便未來替換為網路型 Claude 實作。
    func respond(to text: String) async -> ChatMessage
}
