//
//  PetAdvisorService.swift
//  StrayPals (MaoWo)
//
//  本地「領養顧問」實作（規則式、零金鑰、可離線）。以一問一答的方式蒐集偏好
//  （種類 → 空間 → 經驗 → 地區），再依評分從目前資料推薦最合適的浪浪；
//  過程中也能回答認養流程／飼養須知／費用等常見問題。
//
//  之後若要升級為真正的 LLM，只需另寫一個符合 `AIAssistantService` 的實作。
//

import Foundation

// MARK: - PetAdvisorService

final class PetAdvisorService: AIAssistantService {

    // MARK: Conversation State

    private enum Step { case kind, space, experience, city, done }

    private struct Profile {
        var kind: AnimalKindFilter = .all
        var sizes: Set<String> = []      // SMALL / MEDIUM / BIG
        var beginner: Bool?
        var cities: Set<String> = []
    }

    private let animals: [Animal]
    private var profile = Profile()
    private var pending: Step = .kind

    // MARK: Init

    init(animals: [Animal]) {
        self.animals = animals
    }

    // MARK: AIAssistantService

    func greeting() -> ChatMessage {
        reset()
        return ChatMessage(sender: .assistant, text: L10n.advisorGreeting,
                           quickReplies: [L10n.advOptDog, L10n.advOptCat, L10n.advOptEither])
    }

    func respond(to text: String) async -> ChatMessage {
        // 重新開始。
        if matches(text, ["重新", "重來", "restart", "reset", "重新开始"]) {
            return greeting()
        }
        // 常見問題優先攔截（不影響目前問答進度）。
        if let faq = faqAnswer(for: text) {
            return ChatMessage(sender: .assistant, text: faq, quickReplies: currentQuickReplies())
        }

        record(text, for: pending)
        advance()
        return nextMessage()
    }

    // MARK: Flow

    private func reset() {
        profile = Profile()
        pending = .kind
    }

    private func advance() {
        switch pending {
        case .kind:       pending = .space
        case .space:      pending = .experience
        case .experience: pending = .city
        case .city:       pending = .done
        case .done:       pending = .done
        }
    }

    private func record(_ text: String, for step: Step) {
        switch step {
        case .kind:
            if matches(text, [L10n.advOptDog, "狗", "dog", "犬"]) { profile.kind = .dog }
            else if matches(text, [L10n.advOptCat, "貓", "猫", "cat"]) { profile.kind = .cat }
            else { profile.kind = .all }
        case .space:
            if matches(text, [L10n.advOptStudio, "套房", "studio"]) { profile.sizes = ["SMALL"] }
            else if matches(text, [L10n.advOptApartment, "公寓", "apartment", "apt"]) { profile.sizes = ["SMALL", "MEDIUM"] }
            else if matches(text, [L10n.advOptHouse, "透天", "院子", "獨棟", "独栋", "house", "yard"]) { profile.sizes = ["MEDIUM", "BIG"] }
        case .experience:
            if matches(text, [L10n.advOptBeginner, "新手", "beginner", "no", "沒有", "没有"]) { profile.beginner = true }
            else if matches(text, [L10n.advOptExperienced, "有經驗", "有经验", "experienced", "yes", "有"]) { profile.beginner = false }
        case .city:
            if matches(text, [L10n.advOptAnyCity, "不限", "any", "都可"]) {
                profile.cities = []
            } else {
                let hits = Animal.taiwanCities.filter { text.contains($0) }
                profile.cities = Set(hits)
            }
        case .done:
            break
        }
    }

    private func nextMessage() -> ChatMessage {
        switch pending {
        case .space:
            return ChatMessage(sender: .assistant, text: L10n.advisorAskSpace,
                               quickReplies: [L10n.advOptStudio, L10n.advOptApartment, L10n.advOptHouse])
        case .experience:
            return ChatMessage(sender: .assistant, text: L10n.advisorAskExperience,
                               quickReplies: [L10n.advOptBeginner, L10n.advOptExperienced])
        case .city:
            return ChatMessage(sender: .assistant, text: L10n.advisorAskCity,
                               quickReplies: [L10n.advOptAnyCity, "臺北市", "新北市", "臺中市", "高雄市"])
        case .done:
            return recommendation()
        case .kind:
            return greeting()
        }
    }

    private func currentQuickReplies() -> [String] {
        switch pending {
        case .kind:       return [L10n.advOptDog, L10n.advOptCat, L10n.advOptEither]
        case .space:      return [L10n.advOptStudio, L10n.advOptApartment, L10n.advOptHouse]
        case .experience: return [L10n.advOptBeginner, L10n.advOptExperienced]
        case .city:       return [L10n.advOptAnyCity, "臺北市", "新北市", "臺中市", "高雄市"]
        case .done:       return []
        }
    }

    // MARK: Recommendation

    private func recommendation() -> ChatMessage {
        guard !animals.isEmpty else {
            return ChatMessage(sender: .assistant, text: L10n.advisorResultEmpty)
        }

        var scored: [(animal: Animal, score: Int)] = []
        for animal in animals {
            scored.append((animal, score(animal)))
        }
        scored.sort { $0.score == $1.score ? $0.animal.openDate > $1.animal.openDate : $0.score > $1.score }

        let top = Array(scored.prefix(5))
        let strongMatch = (top.first?.score ?? 0) >= 5
        let intro = strongMatch ? L10n.advisorResultIntro : L10n.advisorResultFallback
        let text = "\(intro)\n\n\(L10n.advisorRestart)"
        return ChatMessage(sender: .assistant, text: text, recommendations: top.map { $0.animal })
    }

    /// 依偏好計算單一動物的契合分數。
    private func score(_ animal: Animal) -> Int {
        var s = 0
        if profile.kind != .all {
            s += profile.kind.matches(animal) ? 4 : -3
        }
        if !profile.sizes.isEmpty, profile.sizes.contains(animal.bodyTypeRaw.uppercased()) {
            s += 2
        }
        if profile.beginner == true {   // 新手：偏好已絕育/已打疫苗/成年（較好照顧）
            if animal.isSterilized { s += 1 }
            if animal.isVaccinated { s += 1 }
            if animal.ageRaw.uppercased() == "ADULT" { s += 1 }
        }
        if !profile.cities.isEmpty, profile.cities.contains(animal.city) {
            s += 4
        }
        if animal.isOpen { s += 1 }
        return s
    }

    // MARK: FAQ

    private func faqAnswer(for text: String) -> String? {
        if matches(text, ["流程", "步驟", "步骤", "process", "step", "怎麼認養", "怎么领养"]) {
            return numbered(L10n.adoptFlowTitle, L10n.adoptionSteps)
        }
        if matches(text, ["須知", "须知", "照顧", "照顾", "飼養", "饲养", "care", "feed"]) {
            return bulleted(L10n.careTitle, L10n.careTips)
        }
        if matches(text, ["費用", "费用", "規費", "规费", "多少錢", "多少钱", "fee", "cost", "price"]) {
            return L10n.advFaqFee
        }
        // 完全不在問答流程中、又無法辨識時，給通用引導。
        if pending == .kind, !looksLikeKindAnswer(text) {
            return L10n.advFaqFallback
        }
        return nil
    }

    private func looksLikeKindAnswer(_ text: String) -> Bool {
        matches(text, [L10n.advOptDog, L10n.advOptCat, L10n.advOptEither, "狗", "貓", "猫", "dog", "cat", "都可", "either"])
    }

    private func numbered(_ title: String, _ items: [String]) -> String {
        let lines = items.enumerated().map { "\($0.offset + 1). \($0.element)" }
        return "\(title)\n" + lines.joined(separator: "\n")
    }

    private func bulleted(_ title: String, _ items: [String]) -> String {
        "\(title)\n" + items.map { "・\($0)" }.joined(separator: "\n")
    }

    // MARK: Helpers

    /// 大小寫不敏感的關鍵字比對。
    private func matches(_ text: String, _ needles: [String]) -> Bool {
        let lower = text.lowercased()
        return needles.contains { !$0.isEmpty && lower.contains($0.lowercased()) }
    }
}
