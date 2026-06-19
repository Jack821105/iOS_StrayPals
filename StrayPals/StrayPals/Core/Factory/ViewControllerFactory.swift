//
//  ViewControllerFactory.swift
//  StrayPals
//
//  【設計模式：工廠 Factory】
//  集中負責建立各個畫面，並完成「ViewModel ←→ 相依服務」的組裝（依賴注入）。
//  ViewController 之間不直接 new 彼此，而是透過工廠取得，
//  降低耦合、方便日後抽換實作或撰寫測試。
//

import UIKit

// MARK: - ViewControllerFactory

enum ViewControllerFactory {

    // MARK: Root

    /// 建立 App 的根 TabBar（認養列表 + 我的收藏）。
    static func makeRootTabBar() -> UITabBarController {
        let tabBar = UITabBarController()

        let listNav = UINavigationController(rootViewController: makeAnimalList())
        listNav.tabBarItem = UITabBarItem(
            title: L10n.tabAdopt,
            image: UIImage(systemName: "pawprint"),
            selectedImage: UIImage(systemName: "pawprint.fill")
        )

        let assistantNav = UINavigationController(rootViewController: makeAssistant())
        assistantNav.tabBarItem = UITabBarItem(
            title: L10n.tabAssistant,
            image: UIImage(systemName: "sparkles"),
            selectedImage: UIImage(systemName: "sparkles")
        )

        let reportNav = UINavigationController(rootViewController: makeReport())
        reportNav.tabBarItem = UITabBarItem(
            title: L10n.tabReport,
            image: UIImage(systemName: "camera.viewfinder"),
            selectedImage: UIImage(systemName: "camera.fill")
        )

        let favNav = UINavigationController(rootViewController: makeFavorites())
        favNav.tabBarItem = UITabBarItem(
            title: L10n.tabMine,
            image: UIImage(systemName: "heart"),
            selectedImage: UIImage(systemName: "heart.fill")
        )

        tabBar.viewControllers = [listNav, assistantNav, reportNav, favNav]
        tabBar.tabBar.tintColor = .appPrimary
        return tabBar
    }

    // MARK: Screens

    /// 動物列表頁。
    static func makeAnimalList() -> AnimalListViewController {
        let repository = AnimalRepository()
        let viewModel = AnimalListViewModel(repository: repository)
        return AnimalListViewController(viewModel: viewModel)
    }

    /// 動物詳情頁。
    static func makeDetail(for animal: Animal) -> AnimalDetailViewController {
        let viewModel = AnimalDetailViewModel(animal: animal)
        return AnimalDetailViewController(viewModel: viewModel)
    }

    /// 我的收藏頁。
    static func makeFavorites() -> FavoritesViewController {
        let viewModel = FavoritesViewModel()
        return FavoritesViewController(viewModel: viewModel)
    }

    /// 領養顧問頁。
    static func makeAssistant() -> AssistantViewController {
        AssistantViewController(viewModel: AssistantViewModel(repository: AnimalRepository()))
    }

    /// 比較頁。
    static func makeCompare() -> CompareViewController {
        CompareViewController(viewModel: CompareViewModel())
    }

    /// 收容所地圖頁。
    static func makeShelterMap() -> ShelterMapViewController {
        ShelterMapViewController(viewModel: ShelterMapViewModel(repository: AnimalRepository()))
    }

    /// 以圖找毛孩頁。
    static func makePhotoSearch() -> PhotoSearchViewController {
        PhotoSearchViewController(viewModel: PhotoSearchViewModel(repository: AnimalRepository()))
    }

    /// 認養日記頁。
    static func makeJournal() -> JournalListViewController {
        JournalListViewController()
    }

    /// 通報頁。
    static func makeReport() -> ReportViewController {
        let viewModel = ReportViewModel(repository: AnimalRepository())
        return ReportViewController(viewModel: viewModel)
    }

    /// 進階篩選頁（包成 bottom sheet）。
    static func makeFilter(
        current: FilterCriteria,
        availableCities: [String],
        onApply: @escaping (FilterCriteria) -> Void
    ) -> UIViewController {
        let viewModel = FilterViewModel(current: current, availableCities: availableCities)
        let filterVC = FilterViewController(viewModel: viewModel, onApply: onApply)
        let nav = UINavigationController(rootViewController: filterVC)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        return nav
    }
}
