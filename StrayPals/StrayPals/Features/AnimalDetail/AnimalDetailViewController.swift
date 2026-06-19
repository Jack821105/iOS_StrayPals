//
//  AnimalDetailViewController.swift
//  StrayPals
//
//  動物詳情頁。以 ScrollView + StackView 排版：大圖、基本資料卡、
//  收容所卡（含撥打電話 / 開啟地圖）、備註。導覽列提供收藏與分享。
//

import UIKit

// MARK: - AnimalDetailViewController

final class AnimalDetailViewController: UIViewController {

    // MARK: Dependencies

    private let viewModel: AnimalDetailViewModel

    // MARK: UI

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let heroImageView = UIImageView()
    private let favoriteBarButton = UIBarButtonItem()
    private let compareBarButton = UIBarButtonItem()
    private weak var liveActivityButton: GradientButton?

    // MARK: Init

    init(viewModel: AnimalDetailViewModel) {
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
        populate()
    }

    // MARK: Setup

    private func setupUI() {
        title = viewModel.navigationTitle
        applyWarmBackdrop()
        navigationItem.largeTitleDisplayMode = .never

        let shareButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain, target: self, action: #selector(shareTapped)
        )
        favoriteBarButton.style = .plain
        favoriteBarButton.target = self
        favoriteBarButton.action = #selector(favoriteTapped)

        compareBarButton.style = .plain
        compareBarButton.target = self
        compareBarButton.action = #selector(compareTapped)
        updateCompareButton()

        navigationItem.rightBarButtonItems = [shareButton, favoriteBarButton, compareBarButton]

        // 比較清單在他處變動時同步圖示。
        NotificationCenter.default.addObserver(
            self, selector: #selector(updateCompareButton),
            name: CompareManager.didChangeNotification, object: nil
        )

        // ScrollView。
        scrollView.backgroundColor = .clear
        view.addSubviews(scrollView)
        scrollView.addSubviews(contentStack)

        contentStack.axis = .vertical
        contentStack.spacing = 16

        // 大圖。
        heroImageView.contentMode = .scaleAspectFill
        heroImageView.clipsToBounds = true
        heroImageView.backgroundColor = .secondarySystemBackground

        let frameGuide = scrollView.frameLayoutGuide
        let contentGuide = scrollView.contentLayoutGuide

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            heroImageView.heightAnchor.constraint(equalToConstant: 320),

            contentStack.topAnchor.constraint(equalTo: contentGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: frameGuide.widthAnchor)
        ])
    }

    // MARK: Binding

    private func bindViewModel() {
        viewModel.isFavorite.bind { [weak self] isFav in
            self?.favoriteBarButton.image = UIImage(systemName: isFav ? "heart.fill" : "heart")
            self?.favoriteBarButton.tintColor = isFav ? .appHeart : .appPrimary
        }
    }

    // MARK: Populate

    private func populate() {
        // 大圖（延伸到瀏海上方），點擊可全螢幕檢視。
        contentStack.addArrangedSubview(heroImageView)
        heroImageView.setImage(from: viewModel.imageURL)
        heroImageView.isUserInteractionEnabled = true
        heroImageView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(openPhotoViewer))
        )

        // 狀態徽章。
        let statusLabel = PaddingLabel()
        statusLabel.text = viewModel.statusText
        statusLabel.font = .systemFont(ofSize: 13, weight: .bold)
        statusLabel.textColor = .white
        statusLabel.backgroundColor = .appAccent   // 薄荷藍綠，與珊瑚 CTA 形成對比
        statusLabel.layer.cornerRadius = 12
        statusLabel.clipsToBounds = true
        let statusWrap = wrap(statusLabel, insets: .init(top: 0, left: 16, bottom: 0, right: 16), align: .leading)
        contentStack.addArrangedSubview(statusWrap)

        // 基本資料卡。
        contentStack.addArrangedSubview(makeCard(title: L10n.detailSectionBasic, rows: viewModel.basicRows))

        // 收容所卡（含動作按鈕）。
        let shelterCard = makeCard(title: L10n.detailSectionShelter, rows: viewModel.shelterRows)
        let actionStack = UIStackView()
        actionStack.axis = .horizontal
        actionStack.distribution = .fillEqually
        actionStack.spacing = 12
        actionStack.addArrangedSubview(makeActionButton(title: L10n.detailActionCall, symbol: "phone.fill", action: #selector(callTapped)))
        actionStack.addArrangedSubview(makeActionButton(title: L10n.detailActionRoute, symbol: "arrow.triangle.turn.up.right.diamond.fill", action: #selector(routeTapped)))
        if let cardStack = shelterCard.subviews.first as? UIStackView {
            cardStack.addArrangedSubview(actionStack)
        }
        contentStack.addArrangedSubview(shelterCard)

        // 備註卡。
        let remarkRow = InfoRow(symbol: "text.bubble", title: L10n.detailRowNote, value: viewModel.remark)
        contentStack.addArrangedSubview(makeCard(title: L10n.detailSectionNote, rows: [remarkRow]))

        // 認養流程（編號）與飼養須知（核取）卡。
        contentStack.addArrangedSubview(makeBulletCard(title: L10n.adoptFlowTitle, items: viewModel.adoptionSteps, numbered: true))
        contentStack.addArrangedSubview(makeBulletCard(title: L10n.careTitle, items: viewModel.careTips, numbered: false))

        // 認養倒數（鎖定畫面 / 動態島）— 緊急且支援時提供。
        if viewModel.canUseLiveActivity {
            let liveButton = GradientButton(title: viewModel.liveActivityButtonTitle, systemImage: "hourglass")
            liveButton.addTarget(self, action: #selector(liveActivityTapped), for: .touchUpInside)
            liveActivityButton = liveButton
            contentStack.addArrangedSubview(wrap(liveButton, insets: .init(top: 0, left: 16, bottom: 0, right: 16), align: .fill))
        }

        // 我已認養 → 建立認養日記。
        let adoptedButton = GradientButton(title: L10n.detailMarkAdopted, systemImage: "house.fill")
        adoptedButton.addTarget(self, action: #selector(markAdoptedTapped), for: .touchUpInside)
        contentStack.addArrangedSubview(wrap(adoptedButton, insets: .init(top: 0, left: 16, bottom: 0, right: 16), align: .fill))
    }

    // MARK: Actions

    @objc private func favoriteTapped() {
        HapticsManager.shared.toggle()   // 觸覺回饋
        viewModel.toggleFavorite()
    }

    @objc private func shareTapped() {
        HapticsManager.shared.tap()
        // 開啟分享圖卡編輯器（可選版型、加留言、即時預覽）。
        let composer = ShareCardComposerViewController(animal: viewModel.animal, image: heroImageView.image)
        if let sheet = composer.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        present(composer, animated: true)
    }

    @objc private func callTapped() {
        guard let url = viewModel.phoneURL(), UIApplication.shared.canOpenURL(url) else {
            showInfoAlert(message: L10n.detailNoPhone)
            return
        }
        UIApplication.shared.open(url)
    }

    @objc private func updateCompareButton() {
        let inCompare = viewModel.isInCompare
        compareBarButton.image = UIImage(systemName: inCompare ? "square.stack.3d.up.fill" : "square.stack.3d.up")
        compareBarButton.tintColor = inCompare ? .appAccent : .appPrimary
    }

    @objc private func compareTapped() {
        switch viewModel.toggleCompare() {
        case .full:
            HapticsManager.shared.notify(.warning)
            showInfoAlert(message: L10n.compareFull)
        case .added, .removed:
            HapticsManager.shared.toggle()
            updateCompareButton()
        }
    }

    @objc private func openPhotoViewer() {
        guard let image = heroImageView.image else { return }
        HapticsManager.shared.tap()
        present(PhotoViewerViewController(image: image), animated: true)
    }

    @objc private func routeTapped() {
        guard let url = viewModel.directionsURL() else {
            showInfoAlert(message: L10n.detailNoAddress)
            return
        }
        UIApplication.shared.open(url)
    }

    @objc private func liveActivityTapped() {
        let nowRunning = viewModel.toggleLiveActivity()
        HapticsManager.shared.toggle()
        liveActivityButton?.configuration?.title = viewModel.liveActivityButtonTitle
        if !nowRunning, !viewModel.isLiveActivityRunning {
            showInfoAlert(message: L10n.detailLiveUnavailable)
        }
    }

    @objc private func markAdoptedTapped() {
        HapticsManager.shared.tap()
        let addVC = AddRecordViewController(prefillFrom: viewModel.animal)
        present(UINavigationController(rootViewController: addVC), animated: true)
    }

    private func showInfoAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.actionOK, style: .default))
        present(alert, animated: true)
    }
}

// MARK: - View Builders

private extension AnimalDetailViewController {

    /// 建立一張卡片（標題 + 多列資訊）。
    func makeCard(title: String, rows: [InfoRow]) -> UIView {
        let card = UIView()
        card.applyCardStyle()

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12

        let titleLabel = UILabel(text: title, font: .systemFont(ofSize: 18, weight: .bold))
        stack.addArrangedSubview(titleLabel)

        for row in rows {
            stack.addArrangedSubview(makeRowView(row))
        }

        card.addSubviews(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        return wrap(card, insets: .init(top: 0, left: 16, bottom: 0, right: 16), align: .fill)
    }

    /// 建立條列卡片（認養流程＝編號、飼養須知＝核取）。
    func makeBulletCard(title: String, items: [String], numbered: Bool) -> UIView {
        let card = UIView()
        card.applyCardStyle()

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12

        stack.addArrangedSubview(UILabel(text: title, font: .systemFont(ofSize: 18, weight: .bold)))

        for (index, item) in items.enumerated() {
            // 編號用數字標籤；核取用 SF Symbol。
            let leading: UIView
            if numbered {
                let marker = UILabel(text: "\(index + 1)",
                                     font: .systemFont(ofSize: 15, weight: .bold),
                                     color: .appPrimary)
                marker.textAlignment = .center
                leading = marker
            } else {
                let icon = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                icon.tintColor = .appAccent
                icon.contentMode = .scaleAspectFit
                leading = icon
            }
            leading.setContentHuggingPriority(.required, for: .horizontal)
            leading.widthAnchor.constraint(equalToConstant: 24).isActive = true

            let text = UILabel(text: item, font: .systemFont(ofSize: 15), lines: 0)

            let row = UIStackView(arrangedSubviews: [leading, text])
            row.axis = .horizontal
            row.alignment = .top
            row.spacing = 10
            stack.addArrangedSubview(row)
        }

        card.addSubviews(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        return wrap(card, insets: .init(top: 0, left: 16, bottom: 0, right: 16), align: .fill)
    }

    /// 建立單列資訊視圖（圖示 + 標題 + 值）。
    func makeRowView(_ row: InfoRow) -> UIView {
        let icon = UIImageView(image: UIImage(systemName: row.symbol))
        icon.tintColor = .appPrimary
        icon.contentMode = .scaleAspectFit
        icon.setContentHuggingPriority(.required, for: .horizontal)
        icon.widthAnchor.constraint(equalToConstant: 22).isActive = true

        let titleLabel = UILabel(text: row.title, font: .systemFont(ofSize: 15), color: .secondaryLabel)
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.widthAnchor.constraint(equalToConstant: 90).isActive = true

        let valueLabel = UILabel(text: row.value, font: .systemFont(ofSize: 15, weight: .medium), lines: 0)

        let stack = UIStackView(arrangedSubviews: [icon, titleLabel, valueLabel])
        stack.axis = .horizontal
        stack.alignment = .top
        stack.spacing = 10
        return stack
    }

    /// 動作按鈕（電話 / 地圖）— 採品牌漸層的 CTA。
    func makeActionButton(title: String, symbol: String, action: Selector) -> UIButton {
        let button = GradientButton(title: title, systemImage: symbol)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    /// 將視圖包進帶內距的容器。
    func wrap(_ inner: UIView, insets: UIEdgeInsets, align: UIStackView.Alignment) -> UIView {
        let container = UIView()
        container.addSubviews(inner)
        NSLayoutConstraint.activate([
            inner.topAnchor.constraint(equalTo: container.topAnchor, constant: insets.top),
            inner.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -insets.bottom),
            inner.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: insets.left)
        ])
        if align == .fill {
            inner.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -insets.right).isActive = true
        } else {
            inner.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -insets.right).isActive = true
        }
        return container
    }
}

// MARK: - PaddingLabel

/// 帶內距的標籤（給狀態徽章用）。
private final class PaddingLabel: UILabel {
    private let inset = UIEdgeInsets(top: 5, left: 12, bottom: 5, right: 12)
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: inset))
    }
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + inset.left + inset.right,
                      height: size.height + inset.top + inset.bottom)
    }
}
