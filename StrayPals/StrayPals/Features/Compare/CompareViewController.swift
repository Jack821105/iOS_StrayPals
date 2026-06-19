//
//  CompareViewController.swift
//  StrayPals (MaoWo)
//
//  比較頁：將最多三隻動物並排成表格（首欄為屬性名稱，其餘為各動物的值），
//  頂部有照片與名稱欄並可移除。無資料時顯示空狀態。
//

import UIKit

// MARK: - CompareViewController

final class CompareViewController: UIViewController {

    // MARK: Dependencies

    private let viewModel: CompareViewModel

    // MARK: UI

    private let scrollView = UIScrollView()
    private let tableStack = UIStackView()
    private let emptyStateView = EmptyStateView()

    private let attributeColumnWidth: CGFloat = 84

    // MARK: Init

    init(viewModel: CompareViewModel) {
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

    // MARK: Setup

    private func setupUI() {
        title = viewModel.title
        applyWarmBackdrop()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: L10n.compareClear, style: .plain, target: self, action: #selector(clearTapped)
        )

        scrollView.backgroundColor = .clear
        tableStack.axis = .vertical
        tableStack.spacing = 1
        tableStack.isLayoutMarginsRelativeArrangement = true
        tableStack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        view.addSubviews(scrollView, emptyStateView)
        scrollView.addSubviews(tableStack)

        emptyStateView.configure(
            symbol: "square.stack.3d.up",
            title: L10n.compareEmptyTitle,
            message: L10n.compareEmptyMessage,
            showRetry: false
        )

        let content = scrollView.contentLayoutGuide
        let frame = scrollView.frameLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            tableStack.topAnchor.constraint(equalTo: content.topAnchor),
            tableStack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            tableStack.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            tableStack.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            tableStack.widthAnchor.constraint(equalTo: frame.widthAnchor),

            emptyStateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: Binding

    private func bindViewModel() {
        viewModel.animals.bind { [weak self] _ in self?.rebuildTable() }
        viewModel.isEmpty.bind { [weak self] isEmpty in
            self?.emptyStateView.isHidden = !isEmpty
            self?.scrollView.isHidden = isEmpty
            self?.navigationItem.rightBarButtonItem?.isEnabled = !isEmpty
        }
    }

    // MARK: Actions

    @objc private func clearTapped() {
        HapticsManager.shared.tap()
        viewModel.clearAll()
    }

    // MARK: Table

    private func rebuildTable() {
        tableStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let animals = viewModel.animals.value
        guard !animals.isEmpty else { return }

        tableStack.addArrangedSubview(makeHeaderRow(animals))
        for (index, row) in viewModel.rows.enumerated() {
            tableStack.addArrangedSubview(makeAttributeRow(row, shaded: index % 2 == 0))
        }
    }

    /// 頂部：屬性欄留白 + 各動物照片與名稱（可移除）。
    private func makeHeaderRow(_ animals: [Animal]) -> UIView {
        let spacer = UIView()
        spacer.widthAnchor.constraint(equalToConstant: attributeColumnWidth).isActive = true

        let cells = UIStackView()
        cells.axis = .horizontal
        cells.distribution = .fillEqually
        cells.spacing = 8

        for animal in animals {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 10
            imageView.backgroundColor = .secondarySystemBackground
            imageView.heightAnchor.constraint(equalToConstant: 84).isActive = true
            imageView.setImage(from: animal.imageURL)

            let name = UILabel(text: animal.shelterName,
                               font: .systemFont(ofSize: 12, weight: .semibold),
                               color: .label, lines: 2)
            name.textAlignment = .center

            let remove = UIButton(type: .system)
            remove.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            remove.tintColor = .tertiaryLabel
            remove.addAction(UIAction { [weak self] _ in self?.viewModel.remove(animal) }, for: .touchUpInside)

            let cell = UIStackView(arrangedSubviews: [imageView, name, remove])
            cell.axis = .vertical
            cell.alignment = .center
            cell.spacing = 4
            cells.addArrangedSubview(cell)
        }

        let row = UIStackView(arrangedSubviews: [spacer, cells])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 8
        return row
    }

    /// 一列屬性。
    private func makeAttributeRow(_ row: CompareRow, shaded: Bool) -> UIView {
        let attr = UILabel(text: row.attribute,
                           font: .systemFont(ofSize: 13, weight: .semibold),
                           color: .secondaryLabel, lines: 0)
        attr.widthAnchor.constraint(equalToConstant: attributeColumnWidth).isActive = true

        let values = UIStackView()
        values.axis = .horizontal
        values.distribution = .fillEqually
        values.spacing = 8
        for value in row.values {
            let label = UILabel(text: value, font: .systemFont(ofSize: 14, weight: .medium), lines: 0)
            label.textAlignment = .center
            values.addArrangedSubview(label)
        }

        let stack = UIStackView(arrangedSubviews: [attr, values])
        stack.axis = .horizontal
        stack.alignment = .top
        stack.spacing = 8
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)

        let container = UIView()
        container.backgroundColor = shaded ? UIColor.appCard.withAlphaComponent(0.6) : .clear
        container.layer.cornerRadius = 10
        container.addSubviews(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        return container
    }
}
