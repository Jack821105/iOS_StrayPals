//
//  AnimalListViewController.swift
//  StrayPals
//
//  動物列表頁（MVVM 的 View 層）。
//  使用 UICollectionView + Compositional Layout + Diffable Data Source，
//  並提供：種類分段篩選、搜尋、排序策略切換、下拉重整、空 / 錯誤狀態。
//

import UIKit

// MARK: - AnimalListViewController

final class AnimalListViewController: UIViewController {

    // MARK: Section / Item

    /// 首頁區塊：緊急救援、為你推薦、全部。
    fileprivate enum HomeSection: Hashable {
        case emergency, recommended, all

        var title: String {
            switch self {
            case .emergency:   return L10n.homeSectionEmergency
            case .recommended: return L10n.homeSectionRecommended
            case .all:         return L10n.homeSectionAll
            }
        }
        var isCarousel: Bool { self != .all }
    }

    /// Diffable 項目包裝：同一隻動物可同時出現在不同區塊，需以 section 區分以維持唯一性。
    fileprivate struct ListItem: Hashable {
        let section: HomeSection
        let animal: Animal
    }

    private static let headerKind = "section-header"

    // MARK: Dependencies

    private let viewModel: AnimalListViewModel

    // MARK: UI

    private lazy var collectionView = makeCollectionView()
    private lazy var dataSource = makeDataSource()
    /// 已播放過進場動畫的項目（避免捲動時重複動畫）。
    private var animatedIndexPaths = Set<IndexPath>()
    /// 搜尋輸入的去抖動工作項目。
    private var searchWorkItem: DispatchWorkItem?
    private let segmentedControl = UISegmentedControl(
        items: AnimalKindFilter.allCases.map(\.title)
    )
    private let searchController = UISearchController(searchResultsController: nil)
    private let emptyStateView = EmptyStateView()
    private let skeletonView = SkeletonGridView()
    private let bannerAdView = BannerAdView()

    // MARK: Init

    init(viewModel: AnimalListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        observeFavorites()
        viewModel.load()

        // 取得最新遠端設定後再決定是否載入廣告。
        AppConfig.shared.refresh { [weak self] in
            guard let self else { return }
            self.bannerAdView.load(from: self)
        }
    }

    // MARK: Setup

    private func setupUI() {
        title = viewModel.title
        applyWarmBackdrop()
        navigationController?.navigationBar.prefersLargeTitles = true

        // 排序 + 比較 + 以圖找毛孩按鈕。
        let sortButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.up.arrow.down.circle"),
            style: .plain, target: self, action: #selector(showSortOptions)
        )
        let compareButton = UIBarButtonItem(
            image: UIImage(systemName: "square.stack.3d.up"),
            style: .plain, target: self, action: #selector(openCompare)
        )
        let photoSearchButton = UIBarButtonItem(
            image: UIImage(systemName: "photo.badge.magnifyingglass"),
            style: .plain, target: self, action: #selector(openPhotoSearch)
        )
        navigationItem.rightBarButtonItems = [sortButton, compareButton, photoSearchButton]

        // 進階篩選 + 收容所地圖按鈕。
        let filterButton = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal.decrease.circle"),
            style: .plain, target: self, action: #selector(showFilter)
        )
        let mapButton = UIBarButtonItem(
            image: UIImage(systemName: "map"),
            style: .plain, target: self, action: #selector(openMap)
        )
        navigationItem.leftBarButtonItems = [filterButton, mapButton]

        // 搜尋。
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = L10n.listSearchPlaceholder
        navigationItem.searchController = searchController

        // 種類分段控制。
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(kindFilterChanged), for: .valueChanged)

        let segmentContainer = UIView()
        segmentContainer.backgroundColor = .clear
        segmentContainer.addSubviews(segmentedControl)

        view.addSubviews(segmentContainer, collectionView, skeletonView, emptyStateView, bannerAdView)
        skeletonView.stop()

        emptyStateView.isHidden = true
        emptyStateView.onRetry = { [weak self] in self?.viewModel.load(forceReload: true) }

        // 下拉重整。
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        collectionView.refreshControl = refresh

        NSLayoutConstraint.activate([
            segmentContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            segmentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            segmentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            segmentedControl.topAnchor.constraint(equalTo: segmentContainer.topAnchor, constant: 8),
            segmentedControl.bottomAnchor.constraint(equalTo: segmentContainer.bottomAnchor, constant: -8),
            segmentedControl.leadingAnchor.constraint(equalTo: segmentContainer.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: segmentContainer.trailingAnchor, constant: -16),

            collectionView.topAnchor.constraint(equalTo: segmentContainer.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bannerAdView.topAnchor),

            bannerAdView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bannerAdView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bannerAdView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            skeletonView.topAnchor.constraint(equalTo: segmentContainer.bottomAnchor),
            skeletonView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            skeletonView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            skeletonView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateView.topAnchor.constraint(equalTo: collectionView.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: Binding

    private func bindViewModel() {
        viewModel.animals.bind { [weak self] _ in self?.rebuildSnapshot() }
        viewModel.emergencyAnimals.observe { [weak self] _ in self?.rebuildSnapshot() }
        viewModel.recommendedAnimals.observe { [weak self] _ in self?.rebuildSnapshot() }

        viewModel.isLoading.bind { [weak self] loading in
            guard let self else { return }
            // 初次載入（尚無資料）顯示骨架；下拉重整則用 refreshControl 自身的轉圈。
            let isInitialLoad = loading && self.viewModel.animals.value.isEmpty
            if isInitialLoad { self.skeletonView.start() } else { self.skeletonView.stop() }
            if !loading { self.collectionView.refreshControl?.endRefreshing() }
        }

        viewModel.isEmpty.bind { [weak self] isEmpty in
            guard let self else { return }
            if isEmpty, self.viewModel.errorMessage.value == nil {
                self.emptyStateView.configure(
                    symbol: "magnifyingglass",
                    title: L10n.listEmptyTitle,
                    message: L10n.listEmptyMessage,
                    showRetry: false
                )
            }
            self.emptyStateView.isHidden = !isEmpty
        }

        // 篩選啟用時，按鈕改為填滿圖示並上色。
        viewModel.activeFilterCount.bind { [weak self] count in
            guard let self else { return }
            let active = count > 0
            self.navigationItem.leftBarButtonItem?.image = UIImage(
                systemName: active ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle"
            )
            self.navigationItem.leftBarButtonItem?.tintColor = active ? .appPrimary : nil
        }

        viewModel.errorMessage.bind { [weak self] message in
            guard let self, let message else { return }
            self.emptyStateView.configure(
                symbol: "wifi.exclamationmark",
                title: L10n.listErrorTitle,
                message: message,
                showRetry: true
            )
            self.emptyStateView.isHidden = false
        }
    }

    /// 監聽收藏變動（例如在詳情頁或收藏頁變更後回來要同步愛心）。
    private func observeFavorites() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(favoritesChanged),
            name: FavoritesManager.didChangeNotification,
            object: nil
        )
    }

    // MARK: Actions

    @objc private func kindFilterChanged() {
        guard let filter = AnimalKindFilter(rawValue: segmentedControl.selectedSegmentIndex) else { return }
        HapticsManager.shared.select()
        viewModel.setKindFilter(filter)
    }

    @objc private func pullToRefresh() {
        viewModel.load(forceReload: true)
    }

    /// 請求定位並切換為「離你最近」排序。
    private func requestNearestSort() {
        viewModel.requestNearestSort { [weak self] success in
            guard let self, !success else { return }
            // 定位失敗 / 被拒：引導前往設定開啟權限。
            let alert = UIAlertController(
                title: L10n.locationDeniedTitle,
                message: L10n.locationDeniedMessage,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: L10n.actionGoSettings, style: .default) { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            })
            alert.addAction(UIAlertAction(title: L10n.actionCancel, style: .cancel))
            self.present(alert, animated: true)
        }
    }

    /// 開啟進階篩選面板。
    @objc private func showFilter() {
        HapticsManager.shared.tap()
        let filter = ViewControllerFactory.makeFilter(
            current: viewModel.currentCriteria,
            availableCities: viewModel.availableCities
        ) { [weak self] criteria in
            guard let self else { return }
            self.viewModel.applyCriteria(criteria)
            // 同步頂端分段控制的種類選擇。
            self.segmentedControl.selectedSegmentIndex = criteria.kind.rawValue
        }
        present(filter, animated: true)
    }

    @objc private func favoritesChanged() {
        // 重新套用目前快照，讓可見 cell 的愛心狀態刷新。
        rebuildSnapshot(animating: false)
    }

    /// 彈出排序策略選單（策略模式的使用者入口）。
    @objc private func showSortOptions() {
        let sheet = UIAlertController(title: L10n.sortTitle, message: nil, preferredStyle: .actionSheet)
        for strategy in AnimalSortStrategyProvider.all {
            let isCurrent = !viewModel.isDistanceSortActive && strategy.title == viewModel.currentSortTitle
            let action = UIAlertAction(title: strategy.title, style: .default) { [weak self] _ in
                self?.viewModel.setSortStrategy(strategy)
            }
            if isCurrent { action.setValue(true, forKey: "checked") }
            sheet.addAction(action)
        }

        // 「離你最近」需定位權限，獨立處理。
        let nearest = UIAlertAction(title: L10n.sortDistancePicker, style: .default) { [weak self] _ in
            self?.requestNearestSort()
        }
        if viewModel.isDistanceSortActive { nearest.setValue(true, forKey: "checked") }
        sheet.addAction(nearest)

        sheet.addAction(UIAlertAction(title: L10n.actionCancel, style: .cancel))
        // iPad 需要 popover 錨點。
        sheet.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItems?.first
        present(sheet, animated: true)
    }

    /// 開啟比較頁。
    @objc private func openCompare() {
        HapticsManager.shared.tap()
        navigationController?.pushViewController(ViewControllerFactory.makeCompare(), animated: true)
    }

    /// 開啟收容所地圖。
    @objc private func openMap() {
        HapticsManager.shared.tap()
        navigationController?.pushViewController(ViewControllerFactory.makeShelterMap(), animated: true)
    }

    /// 開啟「以圖找毛孩」。
    @objc private func openPhotoSearch() {
        HapticsManager.shared.tap()
        navigationController?.pushViewController(ViewControllerFactory.makePhotoSearch(), animated: true)
    }
}

// MARK: - Collection View Factory

private extension AnimalListViewController {

    /// 建立分區 Compositional Layout（緊急/推薦＝橫向輪播；全部＝兩欄網格）。
    func makeCollectionView() -> UICollectionView {
        let layout = UICollectionViewCompositionalLayout { [weak self] index, _ in
            let section = self?.dataSource.sectionIdentifier(for: index) ?? .all
            return section.isCarousel ? Self.makeCarouselSection() : Self.makeGridSection()
        }

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.alwaysBounceVertical = true
        cv.keyboardDismissMode = .onDrag
        cv.delegate = self
        cv.register(AnimalCardCell.self, forCellWithReuseIdentifier: AnimalCardCell.reuseID)
        cv.register(SectionHeaderView.self,
                    forSupplementaryViewOfKind: Self.headerKind,
                    withReuseIdentifier: SectionHeaderView.reuseID)
        return cv
    }

    /// 橫向輪播區段（緊急 / 推薦）。
    static func makeCarouselSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                            heightDimension: .fractionalHeight(1)))
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(widthDimension: .absolute(160), heightDimension: .absolute(210)),
            subitems: [item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 12
        section.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 16, bottom: 16, trailing: 16)
        section.boundarySupplementaryItems = [Self.makeHeader()]
        return section
    }

    /// 兩欄網格區段（全部）。
    static func makeGridSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(0.5),
                                                            heightDimension: .fractionalHeight(1)))
        item.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(220)),
            subitems: [item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 10, bottom: 30, trailing: 10)
        section.boundarySupplementaryItems = [Self.makeHeader()]
        return section
    }

    static func makeHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(36)),
            elementKind: headerKind,
            alignment: .top
        )
    }

    /// 建立 Diffable Data Source（含區段標題）。
    func makeDataSource() -> UICollectionViewDiffableDataSource<HomeSection, ListItem> {
        let source = UICollectionViewDiffableDataSource<HomeSection, ListItem>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: AnimalCardCell.reuseID, for: indexPath
            ) as! AnimalCardCell
            let animal = item.animal
            cell.configure(with: animal,
                           isFavorite: self?.viewModel.isFavorite(animal) ?? false,
                           distanceText: self?.viewModel.distanceText(for: animal),
                           showUrgentBadge: item.section == .emergency && animal.isUrgent,
                           urgentText: item.section == .emergency ? self?.urgentText(for: animal) : nil)
            cell.onToggleFavorite = { [weak self, weak cell] in
                let nowFav = self?.viewModel.toggleFavorite(animal) ?? false
                cell?.updateFavorite(nowFav)
            }
            return cell
        }

        source.supplementaryViewProvider = { [weak self] collectionView, _, indexPath in
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: Self.headerKind, withReuseIdentifier: SectionHeaderView.reuseID, for: indexPath
            ) as! SectionHeaderView
            if let section = self?.dataSource.sectionIdentifier(for: indexPath.section) {
                header.configure(title: section.title, isEmergency: section == .emergency)
            }
            return header
        }
        return source
    }

    /// 緊急倒數文字。
    func urgentText(for animal: Animal) -> String? {
        guard let days = animal.daysUntilClosed else { return nil }
        return days <= 0 ? L10n.lastDay : L10n.daysLeft(days)
    }

    /// 依目前資料重建分區快照。
    func rebuildSnapshot(animating: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<HomeSection, ListItem>()

        let emergency = viewModel.emergencyAnimals.value
        if !emergency.isEmpty {
            snapshot.appendSections([.emergency])
            snapshot.appendItems(emergency.map { ListItem(section: .emergency, animal: $0) }, toSection: .emergency)
        }
        let recommended = viewModel.recommendedAnimals.value
        if !recommended.isEmpty {
            snapshot.appendSections([.recommended])
            snapshot.appendItems(recommended.map { ListItem(section: .recommended, animal: $0) }, toSection: .recommended)
        }
        let all = viewModel.animals.value
        if !all.isEmpty {
            snapshot.appendSections([.all])
            snapshot.appendItems(all.map { ListItem(section: .all, animal: $0) }, toSection: .all)
        }
        dataSource.apply(snapshot, animatingDifferences: animating)
    }
}

// MARK: - UICollectionViewDelegate

extension AnimalListViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        let detail = ViewControllerFactory.makeDetail(for: item.animal)
        navigationController?.pushViewController(detail, animated: true)
    }

    /// 首次顯示時播放進場動畫（依欄位錯開些微延遲）。
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard !animatedIndexPaths.contains(indexPath) else { return }
        animatedIndexPaths.insert(indexPath)
        (cell as? AnimalCardCell)?.animateAppearance(delay: Double(indexPath.item % 2) * 0.06)
    }
}

// MARK: - UISearchResultsUpdating

extension AnimalListViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        // 去抖動：停止輸入 0.3 秒後才實際過濾，避免每個字元都重算整份清單。
        searchWorkItem?.cancel()
        let text = searchController.searchBar.text ?? ""
        let work = DispatchWorkItem { [weak self] in
            self?.viewModel.setSearch(text)
        }
        searchWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }
}
