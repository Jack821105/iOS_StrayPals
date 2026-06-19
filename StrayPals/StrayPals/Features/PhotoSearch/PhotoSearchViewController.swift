//
//  PhotoSearchViewController.swift
//  StrayPals (MaoWo)
//
//  「以圖找毛孩」頁：選擇/拍攝一張照片，於裝置端比對出長相最相似的待認養動物。
//  常見情境：尋找走失的毛孩、或想找「長得像」某張照片的可認養浪浪。
//

import UIKit
import PhotosUI

// MARK: - PhotoSearchViewController

final class PhotoSearchViewController: UIViewController {

    // MARK: Section

    fileprivate enum Section { case main }

    // MARK: Dependencies

    private let viewModel: PhotoSearchViewModel

    // MARK: UI

    private let queryImageView = UIImageView()
    private let statusLabel = UILabel(font: .systemFont(ofSize: 14, weight: .medium), color: .secondaryLabel, lines: 0)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let chooseButton = GradientButton(title: L10n.photoSearchChoose, systemImage: "photo.on.rectangle.angled")
    private let emptyStateView = EmptyStateView()
    private lazy var collectionView = makeCollectionView()
    private lazy var dataSource = makeDataSource()

    // MARK: Init

    init(viewModel: PhotoSearchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.title
        applyWarmBackdrop()
        navigationItem.largeTitleDisplayMode = .never
        setupUI()
        bindViewModel()
        viewModel.preload()
    }

    // MARK: Setup

    private func setupUI() {
        queryImageView.contentMode = .scaleAspectFill
        queryImageView.clipsToBounds = true
        queryImageView.layer.cornerRadius = 16
        queryImageView.layer.cornerCurve = .continuous
        queryImageView.backgroundColor = .secondarySystemBackground
        queryImageView.isHidden = true

        chooseButton.addTarget(self, action: #selector(chooseTapped), for: .touchUpInside)
        activityIndicator.hidesWhenStopped = true

        let statusRow = UIStackView(arrangedSubviews: [activityIndicator, statusLabel])
        statusRow.axis = .horizontal
        statusRow.spacing = 8
        statusRow.alignment = .center

        let header = UIStackView(arrangedSubviews: [queryImageView, statusRow, chooseButton])
        header.axis = .vertical
        header.spacing = 12
        header.alignment = .fill

        view.addSubviews(header, collectionView, emptyStateView)
        emptyStateView.configure(
            symbol: "photo.badge.magnifyingglass",
            title: L10n.photoSearchEmptyTitle,
            message: L10n.photoSearchEmptyMessage,
            showRetry: false
        )

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            queryImageView.heightAnchor.constraint(equalToConstant: 180),

            collectionView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 8),
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
        viewModel.queryImage.bind { [weak self] image in
            self?.queryImageView.image = image
            self?.queryImageView.isHidden = image == nil
        }
        viewModel.statusText.bind { [weak self] text in
            self?.statusLabel.text = text
            self?.statusLabel.isHidden = (text == nil)
        }
        viewModel.isAnalyzing.bind { [weak self] analyzing in
            guard let self else { return }
            if analyzing { self.activityIndicator.startAnimating() } else { self.activityIndicator.stopAnimating() }
            self.chooseButton.isEnabled = !analyzing
            self.chooseButton.alpha = analyzing ? 0.5 : 1
        }
        viewModel.matches.bind { [weak self] matches in
            guard let self else { return }
            self.applySnapshot(matches)
            // 有查詢圖或結果時隱藏初始空狀態。
            self.emptyStateView.isHidden = !matches.isEmpty || self.viewModel.queryImage.value != nil
        }
    }

    // MARK: Actions

    @objc private func chooseTapped() {
        HapticsManager.shared.tap()
        let sheet = UIAlertController(title: L10n.photoSearchChoose, message: nil, preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            sheet.addAction(UIAlertAction(title: L10n.reportPhotoCamera, style: .default) { [weak self] _ in
                self?.presentCamera()
            })
        }
        sheet.addAction(UIAlertAction(title: L10n.reportPhotoLibrary, style: .default) { [weak self] _ in
            self?.presentLibrary()
        })
        sheet.addAction(UIAlertAction(title: L10n.actionCancel, style: .cancel))
        sheet.popoverPresentationController?.sourceView = chooseButton
        present(sheet, animated: true)
    }

    private func presentCamera() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
    }

    private func presentLibrary() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
}

// MARK: - Collection View

private extension PhotoSearchViewController {

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
        UICollectionViewDiffableDataSource<Section, Animal>(collectionView: collectionView) { [weak self] collectionView, indexPath, animal in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AnimalCardCell.reuseID, for: indexPath) as! AnimalCardCell
            let match = self?.viewModel.matches.value.first { $0.animal == animal }
            cell.configure(with: animal,
                           isFavorite: FavoritesManager.shared.isFavorite(animal),
                           distanceText: match.map { self?.viewModel.similarityText(for: $0) ?? "" })
            cell.onToggleFavorite = { [weak cell] in
                let nowFav = FavoritesManager.shared.toggle(animal)
                cell?.updateFavorite(nowFav)
            }
            return cell
        }
    }

    func applySnapshot(_ matches: [ImageSimilarityService.Match]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Animal>()
        snapshot.appendSections([.main])
        snapshot.appendItems(matches.map(\.animal), toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

// MARK: - UICollectionViewDelegate

extension PhotoSearchViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let animals = viewModel.matches.value.map(\.animal)
        guard indexPath.item < animals.count else { return }
        let detail = ViewControllerFactory.makeDetail(for: animals[indexPath.item])
        navigationController?.pushViewController(detail, animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate

extension PhotoSearchViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            DispatchQueue.main.async { self?.viewModel.analyze(image) }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate

extension PhotoSearchViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController,
                              didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            viewModel.analyze(image)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
