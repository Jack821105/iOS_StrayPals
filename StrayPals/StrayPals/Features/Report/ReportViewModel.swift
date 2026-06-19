//
//  ReportViewModel.swift
//  StrayPals
//
//  「通報」頁的 ViewModel。提供聯絡單位清單（由收容所資料彙整）、
//  保存使用者選擇的單位與描述，並組出要分享給單位的通報文字。
//  照片本身由 View 層持有（UIImage 屬 UIKit），VM 保持與 UI 無關。
//

import Foundation

// MARK: - ReportViewModel

final class ReportViewModel {

    // MARK: Output

    /// 可選的聯絡單位清單。
    let units = Observable<[ContactUnit]>([])

    var title: String { L10n.tabReport }

    // MARK: State

    /// 使用者選擇的聯絡單位。
    private(set) var selectedUnit: ContactUnit?
    /// 通報描述文字。
    var note: String = ""

    // MARK: Dependencies

    private let repository: AnimalRepositoryProtocol
    private let analytics: AnalyticsManager

    // MARK: Init

    init(
        repository: AnimalRepositoryProtocol = AnimalRepository(),
        analytics: AnalyticsManager = .shared
    ) {
        self.repository = repository
        self.analytics = analytics
        analytics.track(.openReport)
    }

    // MARK: Inputs

    /// 載入聯絡單位（取用快取/網路資料後彙整）。
    func loadUnits() {
        // 先用快取秒開，再以網路更新。
        if let cached = repository.cachedAnimals() {
            units.value = cached.uniqueContactUnits()
        }
        Task { @MainActor [weak self] in
            guard let self, let animals = try? await self.repository.fetchAnimals() else { return }
            self.units.value = animals.uniqueContactUnits()
        }
    }

    /// 選擇聯絡單位。
    func selectUnit(_ unit: ContactUnit) {
        selectedUnit = unit
    }

    // MARK: Output Builders

    /// 是否可送出（已選單位）。
    var canSubmit: Bool { selectedUnit != nil }

    /// 組出通報文字（隨照片一起分享給單位）。
    func reportText() -> String {
        var lines = [L10n.reportTextTitle]
        if let unit = selectedUnit {
            lines.append("\(L10n.reportTextUnit)\(unit.name)")
            if !unit.address.isEmpty { lines.append("\(L10n.reportTextAddress)\(unit.address)") }
        }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let desc = trimmedNote.isEmpty ? L10n.reportTextDescDefault : trimmedNote
        lines.append("\(L10n.reportTextDescPrefix)\(desc)")
        lines.append(L10n.reportTextFooter)
        return lines.joined(separator: "\n")
    }

    /// 記錄送出事件。
    func trackSubmit() {
        analytics.track(.submitReport(unit: selectedUnit?.name ?? "unknown"))
    }
}
