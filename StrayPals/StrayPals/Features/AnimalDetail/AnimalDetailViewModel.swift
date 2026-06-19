//
//  AnimalDetailViewModel.swift
//  StrayPals
//
//  動物詳情頁的 ViewModel。整理要顯示的資訊列、管理收藏狀態，
//  並提供「撥打收容所電話」「開啟地圖」等動作所需的資料。
//

import Foundation

// MARK: - InfoRow

/// 詳情頁的一列資訊（圖示 + 標題 + 內容）。
struct InfoRow {
    let symbol: String
    let title: String
    let value: String
}

// MARK: - AnimalDetailViewModel

final class AnimalDetailViewModel {

    // MARK: Output

    /// 收藏狀態（供愛心按鈕綁定）。
    let isFavorite = Observable<Bool>(false)

    // MARK: Data

    let animal: Animal

    // MARK: Dependencies

    private let favorites: FavoritesManager
    private let analytics: AnalyticsManager

    // MARK: Init

    init(
        animal: Animal,
        favorites: FavoritesManager = .shared,
        analytics: AnalyticsManager = .shared
    ) {
        self.animal = animal
        self.favorites = favorites
        self.analytics = analytics
        self.isFavorite.value = favorites.isFavorite(animal)
        analytics.track(.viewDetail(animalId: animal.id))
        RecentlyViewedManager.shared.record(animal)   // 記錄最近瀏覽
    }

    // MARK: Display

    var navigationTitle: String { animal.displayName }

    var imageURL: URL? { animal.imageURL }

    /// 狀態徽章文字。
    var statusText: String { animal.isOpen ? L10n.detailStatusOpen : L10n.detailStatusInfo }

    /// 基本資料列。
    var basicRows: [InfoRow] {
        [
            InfoRow(symbol: animal.kind.symbolName, title: L10n.detailRowKind, value: animal.kind.localizedName),
            InfoRow(symbol: "pawprint", title: L10n.detailRowVariety, value: animal.variety),
            InfoRow(symbol: "figure.stand", title: L10n.detailRowSex, value: animal.sexText),
            InfoRow(symbol: "calendar", title: L10n.detailRowAge, value: animal.ageText),
            InfoRow(symbol: "ruler", title: L10n.detailRowBody, value: animal.bodyTypeText),
            InfoRow(symbol: "paintpalette", title: L10n.detailRowColor, value: animal.colourText),
            InfoRow(symbol: "scissors", title: L10n.detailRowSterilized, value: animal.sterilizationText),
            InfoRow(symbol: "syringe", title: L10n.detailRowVaccine, value: animal.isVaccinated ? L10n.vaccineYes : L10n.vaccineNo),
            InfoRow(symbol: "mappin.and.ellipse", title: L10n.detailRowFoundPlace, value: animal.foundPlace.isEmpty ? L10n.notProvided : animal.foundPlace),
            InfoRow(symbol: "clock", title: L10n.detailRowOpenDate, value: animal.openDate)
        ]
    }

    /// 收容所資料列。
    var shelterRows: [InfoRow] {
        [
            InfoRow(symbol: "house", title: L10n.detailRowShelter, value: animal.shelterName),
            InfoRow(symbol: "location", title: L10n.detailRowAddress, value: animal.shelterAddress.isEmpty ? L10n.notProvided : animal.shelterAddress),
            InfoRow(symbol: "phone", title: L10n.detailRowPhone, value: animal.shelterTel.isEmpty ? L10n.notProvided : animal.shelterTel)
        ]
    }

    /// 備註內容。
    var remark: String { animal.remarkText }

    // MARK: Actions

    /// 切換收藏。
    func toggleFavorite() {
        let nowFav = favorites.toggle(animal)
        isFavorite.value = nowFav
        analytics.track(.toggleFavorite(animalId: animal.id, isFavorite: nowFav))
    }

    /// 可撥打的電話 URL。
    func phoneURL() -> URL? {
        let digits = animal.shelterTel.filter { $0.isNumber || $0 == "+" }
        guard !digits.isEmpty else { return nil }
        analytics.track(.tapCallShelter(animalId: animal.id))
        return URL(string: "tel://\(digits)")
    }

    /// 規劃路線 URL（Apple Maps 導航至收容所）。
    func directionsURL() -> URL? {
        let target = animal.shelterAddress.isEmpty ? animal.shelterName : animal.shelterAddress
        guard !target.isEmpty,
              let encoded = target.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        analytics.track(.tapOpenMap(animalId: animal.id))
        // daddr = 目的地，開啟即進入路線規劃。
        return URL(string: "http://maps.apple.com/?daddr=\(encoded)&dirflg=d")
    }

    /// 認養流程步驟。
    var adoptionSteps: [String] { L10n.adoptionSteps }
    /// 飼養須知。
    var careTips: [String] { L10n.careTips }

    // MARK: Compare

    /// 是否已加入比較。
    var isInCompare: Bool { CompareManager.shared.contains(animal) }

    /// 切換比較狀態。
    func toggleCompare() -> CompareToggleResult {
        CompareManager.shared.toggle(animal)
    }

    /// 分享用的文字。
    func shareText() -> String {
        L10n.shareText(kind: animal.kind.localizedName, shelter: animal.shelterName)
    }

    // MARK: Live Activity（認養倒數）

    /// 是否可開啟認養倒數（裝置支援、開放認養中、且有截止日）。
    var canUseLiveActivity: Bool {
        LiveActivityManager.shared.isSupported && animal.isOpen && animal.closedDateValue != nil
    }

    /// 目前是否有進行中的倒數活動。
    var isLiveActivityRunning: Bool {
        LiveActivityManager.shared.isRunning(animalId: animal.id)
    }

    /// 倒數按鈕標題（依目前狀態）。
    var liveActivityButtonTitle: String {
        isLiveActivityRunning ? L10n.detailLiveStop : L10n.detailLiveStart
    }

    /// 切換倒數活動，回傳切換後是否進行中。
    func toggleLiveActivity() -> Bool {
        if isLiveActivityRunning {
            LiveActivityManager.shared.endCountdown(animalId: animal.id)
            return false
        }
        return LiveActivityManager.shared.startCountdown(for: animal)
    }
}
