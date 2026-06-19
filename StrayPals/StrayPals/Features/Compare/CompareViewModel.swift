//
//  CompareViewModel.swift
//  StrayPals (MaoWo)
//
//  比較頁 ViewModel：把比較清單整理成「屬性列 × 動物欄」的表格資料。
//

import Foundation

// MARK: - CompareRow

/// 比較表的一列（屬性名稱 + 各動物的值）。
struct CompareRow {
    let attribute: String
    let values: [String]
}

// MARK: - CompareViewModel

final class CompareViewModel {

    // MARK: Output

    let animals = Observable<[Animal]>([])
    let isEmpty = Observable<Bool>(true)

    var title: String { L10n.compareTitle }

    // MARK: Dependencies

    private let manager: CompareManager

    // MARK: Init

    init(manager: CompareManager = .shared) {
        self.manager = manager
        NotificationCenter.default.addObserver(
            self, selector: #selector(reload),
            name: CompareManager.didChangeNotification, object: nil
        )
        reload()
    }

    // MARK: Inputs

    @objc func reload() {
        animals.value = manager.items
        isEmpty.value = manager.isEmpty
    }

    func remove(_ animal: Animal) { manager.remove(animal) }
    func clearAll() { manager.clear() }

    // MARK: Table Data

    /// 依目前動物產生比較列。
    var rows: [CompareRow] {
        let list = animals.value
        guard !list.isEmpty else { return [] }
        func row(_ attr: String, _ map: (Animal) -> String) -> CompareRow {
            CompareRow(attribute: attr, values: list.map(map))
        }
        return [
            row(L10n.detailRowKind) { $0.kind.localizedName },
            row(L10n.detailRowSex) { $0.sexText },
            row(L10n.detailRowAge) { $0.ageText },
            row(L10n.detailRowBody) { $0.bodyTypeText },
            row(L10n.detailRowColor) { $0.colourText },
            row(L10n.detailRowSterilized) { $0.sterilizationText },
            row(L10n.detailRowVaccine) { $0.isVaccinated ? L10n.vaccineYes : L10n.vaccineNo },
            row(L10n.filterCity) { $0.city },
            row(L10n.detailRowShelter) { $0.shelterName }
        ]
    }
}
