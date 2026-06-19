//
//  OnboardingViewController.swift
//  StrayPals (MaoWo)
//
//  首次啟動導覽：詢問想認養的種類與關注縣市，作為「為你推薦」的個人化種子。
//  可略過；完成後寫入 UserPreferences 並標記已完成。
//

import UIKit

// MARK: - OnboardingViewController

final class OnboardingViewController: UIViewController {

    // MARK: Callback

    private let onFinish: () -> Void

    // MARK: State

    private var selectedKind: AnimalKindFilter = .all
    private var selectedCities = Set<String>()
    private var kindChips: [ChipButton] = []

    /// 導覽提供的縣市選項（正體字、無重複）。
    private let cities = ["臺北市", "新北市", "基隆市", "桃園市", "新竹市", "新竹縣",
                          "苗栗縣", "臺中市", "彰化縣", "南投縣", "雲林縣", "嘉義市",
                          "嘉義縣", "臺南市", "高雄市", "屏東縣", "宜蘭縣", "花蓮縣",
                          "臺東縣", "澎湖縣", "金門縣", "連江縣"]

    // MARK: Init

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: Setup

    private func setupUI() {
        applyWarmBackdrop()

        // 略過。
        let skip = UIButton(type: .system)
        skip.setTitle(L10n.onboardingSkip, for: .normal)
        skip.addAction(UIAction { [weak self] _ in self?.finish() }, for: .touchUpInside)

        // 標題區。
        let icon = UIImageView(image: UIImage(systemName: "pawprint.fill"))
        icon.tintColor = .appPrimary
        icon.contentMode = .scaleAspectFit
        icon.heightAnchor.constraint(equalToConstant: 56).isActive = true

        let title = UILabel(text: L10n.onboardingWelcomeTitle, font: .systemFont(ofSize: 26, weight: .heavy), lines: 0)
        title.textAlignment = .center
        let subtitle = UILabel(text: L10n.onboardingWelcomeSubtitle,
                               font: .systemFont(ofSize: 15), color: .secondaryLabel, lines: 0)
        subtitle.textAlignment = .center

        // 種類（單選）。
        let kindTitle = UILabel(text: L10n.onboardingKindQuestion, font: .systemFont(ofSize: 17, weight: .bold))
        let kindStack = UIStackView()
        kindStack.axis = .horizontal
        kindStack.spacing = 10
        kindStack.distribution = .fillEqually
        for kind in AnimalKindFilter.allCases {
            let chip = ChipButton(title: kind.title, value: "\(kind.rawValue)")
            chip.isSelected = (kind == selectedKind)
            chip.addAction(UIAction { [weak self] _ in self?.selectKind(kind) }, for: .touchUpInside)
            kindChips.append(chip)
            kindStack.addArrangedSubview(chip)
        }

        // 縣市（多選，可水平捲動）。
        let cityTitle = UILabel(text: L10n.onboardingCityQuestion, font: .systemFont(ofSize: 17, weight: .bold), lines: 0)
        let cityScroll = makeCityChips()

        // 開始按鈕。
        let startButton = GradientButton(title: L10n.onboardingStart, systemImage: "arrow.right.circle.fill")
        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [icon, title, subtitle, kindTitle, kindStack, cityTitle, cityScroll])
        stack.axis = .vertical
        stack.spacing = 16
        stack.setCustomSpacing(28, after: subtitle)
        stack.setCustomSpacing(24, after: kindStack)

        view.addSubviews(skip, stack, startButton)
        NSLayoutConstraint.activate([
            skip.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            skip.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),

            startButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            startButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
    }

    private func makeCityChips() -> UIScrollView {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 10
        for city in cities {
            let chip = ChipButton(title: city, value: city)
            chip.addAction(UIAction { [weak self, weak chip] _ in
                guard let self, let chip else { return }
                chip.isSelected.toggle()
                if chip.isSelected { self.selectedCities.insert(city) } else { self.selectedCities.remove(city) }
                HapticsManager.shared.select()
            }, for: .touchUpInside)
            row.addArrangedSubview(chip)
        }
        scroll.addSubviews(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            row.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            row.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor)
        ])
        return scroll
    }

    // MARK: Selection

    private func selectKind(_ kind: AnimalKindFilter) {
        selectedKind = kind
        HapticsManager.shared.select()
        for (index, chip) in kindChips.enumerated() {
            chip.isSelected = (AnimalKindFilter.allCases[index] == kind)
        }
    }

    // MARK: Finish

    @objc private func startTapped() {
        HapticsManager.shared.tap()
        UserPreferences.shared.preferredKind = selectedKind
        UserPreferences.shared.preferredCities = selectedCities
        finish()
    }

    private func finish() {
        UserPreferences.shared.hasCompletedOnboarding = true
        dismiss(animated: true, completion: onFinish)
    }
}
