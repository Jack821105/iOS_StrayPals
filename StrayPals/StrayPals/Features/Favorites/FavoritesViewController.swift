//
//  FavoritesViewController.swift
//  StrayPals
//
//  「我的」頁：以分段控制切換「收藏 / 最近瀏覽」，兩者共用同一個
//  AnimalCardCell 與 Diffable Data Source；無資料時顯示對應空狀態。
//

import UIKit

// MARK: - FavoritesViewController

final class FavoritesViewController: UIViewController {

    // MARK: Section

    fileprivate enum Section { case main }

    // MARK: Dependencies

    private let viewModel: FavoritesViewModel

    // MARK: UI

    private let segmentedControl = UISegmentedControl(items: MyListMode.allCases.map(\.title))
    private lazy var collectionView = makeCollectionView()
    private lazy var dataSource = makeDataSource()
    private let emptyStateView = EmptyStateView()
    private var animatedIndexPaths = Set<IndexPath>()

    // MARK: Init

    init(viewModel: FavoritesViewModel) {
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.reload()
    }

    // MARK: Setup

    private func setupUI() {
        title = viewModel.title
        applyWarmBackdrop()
        navigationController?.navigationBar.prefersLargeTitles = true

        // 設定 / 語言切換 + 認養日記。
        let gearButton = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain, target: self, action: #selector(showLanguagePicker)
        )
        let journalButton = UIBarButtonItem(
            image: UIImage(systemName: "book.closed"),
            style: .plain, target: self, action: #selector(openJournal)
        )
        navigationItem.rightBarButtonItems = [gearButton, journalButton]

        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.selectedSegmentTintColor = .appPrimary
        segmentedControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)

        let segmentContainer = UIView()
        segmentContainer.backgroundColor = .clear
        segmentContainer.addSubviews(segmentedControl)

        view.addSubviews(segmentContainer, collectionView, emptyStateView)
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
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateView.topAnchor.constraint(equalTo: collectionView.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: Binding

    private func bindViewModel() {
        viewModel.animals.bind { [weak self] animals in
            self?.applySnapshot(animals)
        }
        viewModel.isEmpty.bind { [weak self] isEmpty in
            guard let self else { return }
            if isEmpty {
                self.emptyStateView.configure(
                    symbol: self.viewModel.emptySymbol,
                    title: self.viewModel.emptyTitle,
                    message: self.viewModel.emptyMessage,
                    showRetry: false
                )
            }
            self.emptyStateView.isHidden = !isEmpty
        }
    }

    // MARK: Actions

    @objc private func modeChanged() {
        guard let mode = MyListMode(rawValue: segmentedControl.selectedSegmentIndex) else { return }
        HapticsManager.shared.select()
        animatedIndexPaths.removeAll()   // 切換模式重新播放進場動畫
        viewModel.setMode(mode)
    }

    /// 開啟認養日記。
    @objc private func openJournal() {
        HapticsManager.shared.tap()
        navigationController?.pushViewController(ViewControllerFactory.makeJournal(), animated: true)
    }

    /// 顯示語言選擇器（App 內即時切換，不需重啟）。
    @objc private func showLanguagePicker() {
        let sheet = UIAlertController(title: L10n.settingsLanguage, message: nil, preferredStyle: .actionSheet)
        for language in AppLanguage.allCases {
            let action = UIAlertAction(title: language.displayName, style: .default) { _ in
                HapticsManager.shared.select()
                LanguageManager.shared.setLanguage(language)
            }
            if language == LanguageManager.shared.language { action.setValue(true, forKey: "checked") }
            sheet.addAction(action)
        }
        sheet.addAction(UIAlertAction(title: L10n.actionCancel, style: .cancel))
        sheet.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(sheet, animated: true)
    }
}

// MARK: - Collection View

private extension FavoritesViewController {

    func makeCollectionView() -> UICollectionView {
        let layout = UICollectionViewCompositionalLayout { _, _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(0.5),
                heightDimension: .fractionalHeight(1.0)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(220)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 10, bottom: 20, trailing: 10)
            return section
        }
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.alwaysBounceVertical = true
        cv.delegate = self
        cv.register(AnimalCardCell.self, forCellWithReuseIdentifier: AnimalCardCell.reuseID)
        return cv
    }

    func makeDataSource() -> UICollectionViewDiffableDataSource<Section, Animal> {
        UICollectionViewDiffableDataSource<Section, Animal>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, animal in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: AnimalCardCell.reuseID,
                for: indexPath
            ) as! AnimalCardCell
            let isFav = self?.viewModel.isFavorite(animal) ?? false
            cell.configure(with: animal, isFavorite: isFav)
            cell.onToggleFavorite = { [weak self, weak cell] in
                self?.viewModel.toggleFavorite(animal)
                cell?.updateFavorite(self?.viewModel.isFavorite(animal) ?? false)
            }
            return cell
        }
    }

    func applySnapshot(_ animals: [Animal]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Animal>()
        snapshot.appendSections([.main])
        snapshot.appendItems(animals, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

// MARK: - UICollectionViewDelegate

extension FavoritesViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let animal = viewModel.animal(at: indexPath.item) else { return }
        let detail = ViewControllerFactory.makeDetail(for: animal)
        navigationController?.pushViewController(detail, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard !animatedIndexPaths.contains(indexPath) else { return }
        animatedIndexPaths.insert(indexPath)
        (cell as? AnimalCardCell)?.animateAppearance(delay: Double(indexPath.item % 2) * 0.06)
    }
}
