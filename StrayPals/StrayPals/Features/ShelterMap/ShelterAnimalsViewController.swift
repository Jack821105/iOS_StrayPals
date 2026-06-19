//
//  ShelterAnimalsViewController.swift
//  StrayPals (MaoWo)
//
//  單一收容所的待認養動物列表（由地圖標註進入）。
//  頂部顯示地址與「撥打電話 / 規劃路線」動作，下方為兩欄動物網格。
//

import UIKit

// MARK: - ShelterAnimalsViewController

final class ShelterAnimalsViewController: UIViewController {

    // MARK: Section

    fileprivate enum Section { case main }

    // MARK: Data

    private let shelter: ShelterGroup

    // MARK: UI

    private lazy var collectionView = makeCollectionView()
    private lazy var dataSource = makeDataSource()
    private var animatedIndexPaths = Set<IndexPath>()

    // MARK: Init

    init(shelter: ShelterGroup) {
        self.shelter = shelter
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = shelter.name
        applyWarmBackdrop()
        navigationItem.largeTitleDisplayMode = .never
        setupUI()
        applySnapshot()
    }

    // MARK: Setup

    private func setupUI() {
        let header = makeHeader()
        view.addSubviews(header, collectionView)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            collectionView.topAnchor.constraint(equalTo: header.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func makeHeader() -> UIView {
        let container = UIView()

        let addressLabel = UILabel(
            text: shelter.address.isEmpty ? L10n.notProvided : shelter.address,
            font: .systemFont(ofSize: 14), color: .secondaryLabel, lines: 0
        )
        let countLabel = UILabel(text: shelter.countText,
                                 font: .systemFont(ofSize: 13, weight: .semibold), color: .appPrimary)

        let actionStack = UIStackView()
        actionStack.axis = .horizontal
        actionStack.distribution = .fillEqually
        actionStack.spacing = 12
        let callButton = GradientButton(title: L10n.detailActionCall, systemImage: "phone.fill")
        callButton.addTarget(self, action: #selector(callTapped), for: .touchUpInside)
        let routeButton = GradientButton(title: L10n.detailActionRoute, systemImage: "arrow.triangle.turn.up.right.diamond.fill")
        routeButton.addTarget(self, action: #selector(routeTapped), for: .touchUpInside)
        actionStack.addArrangedSubview(callButton)
        actionStack.addArrangedSubview(routeButton)

        let stack = UIStackView(arrangedSubviews: [countLabel, addressLabel, actionStack])
        stack.axis = .vertical
        stack.spacing = 10

        container.addSubviews(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])
        return container
    }

    // MARK: Actions

    @objc private func callTapped() {
        let digits = shelter.tel.filter { $0.isNumber || $0 == "+" }
        guard !digits.isEmpty, let url = URL(string: "tel://\(digits)"), UIApplication.shared.canOpenURL(url) else {
            showInfoAlert(message: L10n.detailNoPhone)
            return
        }
        UIApplication.shared.open(url)
    }

    @objc private func routeTapped() {
        let target = shelter.address.isEmpty ? shelter.name : shelter.address
        guard !target.isEmpty,
              let encoded = target.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "http://maps.apple.com/?daddr=\(encoded)&dirflg=d") else {
            showInfoAlert(message: L10n.detailNoAddress)
            return
        }
        UIApplication.shared.open(url)
    }

    private func showInfoAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.actionOK, style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Collection View

private extension ShelterAnimalsViewController {

    func makeCollectionView() -> UICollectionView {
        let layout = UICollectionViewCompositionalLayout { _, _ in
            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(0.5),
                                                               heightDimension: .fractionalHeight(1.0)))
            item.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(220)),
                subitems: [item]
            )
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
        UICollectionViewDiffableDataSource<Section, Animal>(collectionView: collectionView) { collectionView, indexPath, animal in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AnimalCardCell.reuseID, for: indexPath) as! AnimalCardCell
            cell.configure(with: animal, isFavorite: FavoritesManager.shared.isFavorite(animal))
            cell.onToggleFavorite = { [weak cell] in
                let nowFav = FavoritesManager.shared.toggle(animal)
                cell?.updateFavorite(nowFav)
            }
            return cell
        }
    }

    func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Animal>()
        snapshot.appendSections([.main])
        snapshot.appendItems(shelter.animals, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - UICollectionViewDelegate

extension ShelterAnimalsViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard indexPath.item < shelter.animals.count else { return }
        let detail = ViewControllerFactory.makeDetail(for: shelter.animals[indexPath.item])
        navigationController?.pushViewController(detail, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard !animatedIndexPaths.contains(indexPath) else { return }
        animatedIndexPaths.insert(indexPath)
        (cell as? AnimalCardCell)?.animateAppearance(delay: Double(indexPath.item % 2) * 0.06)
    }
}
