//
//  AssistantViewModel.swift
//  StrayPals (MaoWo)
//
//  領養顧問頁的 ViewModel。載入動物資料後建立 `AIAssistantService`（目前為本地
//  規則式實作），驅動對話並以 Observable 廣播訊息與「思考中」狀態。
//  與 UI 只透過 `AIAssistantService` 協定耦合，未來替換為 Claude 不需改動此處以外。
//

import Foundation

// MARK: - AssistantViewModel

final class AssistantViewModel {

    // MARK: Output

    let messages = Observable<[ChatMessage]>([])
    let isThinking = Observable<Bool>(false)

    var title: String { L10n.assistantTitle }

    // MARK: Dependencies

    private let repository: AnimalRepositoryProtocol
    private var service: AIAssistantService?

    // MARK: Init

    init(repository: AnimalRepositoryProtocol = AnimalRepository()) {
        self.repository = repository
    }

    // MARK: Lifecycle

    /// 進入畫面時呼叫：載入資料並送出招呼。
    func start() {
        guard service == nil else { return }

        // 先用快取秒開。
        if let cached = repository.cachedAnimals() {
            setup(with: cached)
        } else {
            messages.value = [ChatMessage(sender: .assistant, text: L10n.advisorLoading)]
        }

        // 再以網路資料補齊（若先前用快取建立則略過）。
        Task { @MainActor [weak self] in
            guard let self, self.service == nil else { return }
            if let animals = try? await self.repository.fetchAnimals() {
                self.setup(with: animals)
            }
        }
    }

    private func setup(with animals: [Animal]) {
        guard service == nil else { return }
        let advisor = PetAdvisorService(animals: animals)
        service = advisor
        messages.value = [advisor.greeting()]
    }

    // MARK: Inputs

    /// 送出使用者訊息。
    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let service else { return }

        messages.value.append(ChatMessage(sender: .user, text: trimmed))
        isThinking.value = true

        Task { @MainActor [weak self] in
            guard let self else { return }
            let reply = await service.respond(to: trimmed)
            self.isThinking.value = false
            self.messages.value.append(reply)
        }
    }

    /// 目前最後一則助理訊息的快速回覆選項。
    var latestQuickReplies: [String] {
        messages.value.last(where: { $0.sender == .assistant })?.quickReplies ?? []
    }
}
