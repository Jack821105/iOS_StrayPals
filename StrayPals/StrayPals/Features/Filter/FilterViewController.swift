//
//  FilterViewController.swift
//  StrayPals
//
//  進階篩選面板（以 bottom sheet 呈現）。提供性別、年齡、體型、縣市
//  與多個開關條件的多選 chip。按「套用」回傳條件、「重置」清空。
//

import UIKit

// MARK: - FilterViewController

final class FilterViewController: UIViewController {

    // MARK: Dependencies

    private let viewModel: FilterViewModel
    /// 套用時回傳最終條件。
    private let onApply: (FilterCriteria) -> Void

    // MARK: UI

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    // MARK: Init

    init(viewModel: FilterViewModel, onApply: @escaping (FilterCriteria) -> Void) {
        self.viewModel = viewModel
        self.onApply = onApply
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNav()
        setupLayout()
        buildSections()
    }

    // MARK: Setup

    private func setupNav() {
        title = L10n.filterTitle
        applyWarmBackdrop()
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: L10n.filterReset, style: .plain, target: self, action: #selector(resetTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: L10n.filterApply, style: .done, target: self, action: #selector(applyTapped)
        )
    }

    private func setupLayout() {
        view.addSubviews(scrollView)
        scrollView.addSubviews(contentStack)
        scrollView.backgroundColor = .clear
        contentStack.axis = .vertical
        contentStack.spacing = 24
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 40, right: 20)

        let content = scrollView.contentLayoutGuide
        let frame = scrollView.frameLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: content.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: frame.widthAnchor)
        ])
    }

    // MARK: Build Sections

    private func buildSections() {
        // 性別 / 年齡 / 體型。
        contentStack.addArrangedSubview(makeSection(
            title: L10n.filterSex,
            chips: viewModel.sexOptions.map { opt in
                makeChip(title: opt.title, value: opt.value,
                         selected: viewModel.isSexSelected(opt.value)) { [weak self] in
                    self?.viewModel.toggleSex(opt.value)
                }
            }
        ))
        contentStack.addArrangedSubview(makeSection(
            title: L10n.filterAge,
            chips: viewModel.ageOptions.map { opt in
                makeChip(title: opt.title, value: opt.value,
                         selected: viewModel.isAgeSelected(opt.value)) { [weak self] in
                    self?.viewModel.toggleAge(opt.value)
                }
            }
        ))
        contentStack.addArrangedSubview(makeSection(
            title: L10n.filterBodyType,
            chips: viewModel.bodyTypeOptions.map { opt in
                makeChip(title: opt.title, value: opt.value,
                         selected: viewModel.isBodyTypeSelected(opt.value)) { [weak self] in
                    self?.viewModel.toggleBodyType(opt.value)
                }
            }
        ))

        // 條件開關（也以 chip 呈現）。
        let sterilized = makeToggleChip(title: L10n.filterSterilized, on: viewModel.criteria.sterilizedOnly) { [weak self] on in
            self?.viewModel.setSterilizedOnly(on)
        }
        let vaccinated = makeToggleChip(title: L10n.filterVaccinated, on: viewModel.criteria.vaccinatedOnly) { [weak self] on in
            self?.viewModel.setVaccinatedOnly(on)
        }
        let open = makeToggleChip(title: L10n.filterOpen, on: viewModel.criteria.openOnly) { [weak self] on in
            self?.viewModel.setOpenOnly(on)
        }
        contentStack.addArrangedSubview(makeSection(title: L10n.filterCondition, chips: [sterilized, vaccinated, open]))

        // 縣市。
        if !viewModel.cityOptions.isEmpty {
            contentStack.addArrangedSubview(makeSection(
                title: L10n.filterCity,
                chips: viewModel.cityOptions.map { city in
                    makeChip(title: city, value: city,
                             selected: viewModel.isCitySelected(city)) { [weak self] in
                        self?.viewModel.toggleCity(city)
                    }
                }
            ))
        }
    }

    // MARK: Builders

    /// 區段：標題 + 可水平捲動的 chip 列。
    private func makeSection(title: String, chips: [ChipButton]) -> UIView {
        let titleLabel = UILabel(text: title, font: .systemFont(ofSize: 16, weight: .bold))

        let chipStack = UIStackView(arrangedSubviews: chips)
        chipStack.axis = .horizontal
        chipStack.spacing = 10
        chipStack.alignment = .center

        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.addSubviews(chipStack)
        NSLayoutConstraint.activate([
            chipStack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            chipStack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            chipStack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            chipStack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            chipStack.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor)
        ])

        let section = UIStackView(arrangedSubviews: [titleLabel, scroll])
        section.axis = .vertical
        section.spacing = 12
        scroll.heightAnchor.constraint(equalToConstant: 40).isActive = true
        return section
    }

    /// 多選 chip。
    private func makeChip(title: String, value: String, selected: Bool, onToggle: @escaping () -> Void) -> ChipButton {
        let chip = ChipButton(title: title, value: value)
        chip.isSelected = selected
        chip.addAction(UIAction { [weak chip] _ in
            guard let chip else { return }
            HapticsManager.shared.select()
            chip.isSelected.toggle()
            onToggle()
        }, for: .touchUpInside)
        return chip
    }

    /// 布林開關 chip。
    private func makeToggleChip(title: String, on: Bool, onChange: @escaping (Bool) -> Void) -> ChipButton {
        let chip = ChipButton(title: title, value: title)
        chip.isSelected = on
        chip.addAction(UIAction { [weak chip] _ in
            guard let chip else { return }
            HapticsManager.shared.select()
            chip.isSelected.toggle()
            onChange(chip.isSelected)
        }, for: .touchUpInside)
        return chip
    }

    // MARK: Actions

    @objc private func resetTapped() {
        viewModel.reset()
        // 重建畫面以還原所有 chip 狀態。
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        buildSections()
    }

    @objc private func applyTapped() {
        HapticsManager.shared.tap()
        onApply(viewModel.criteria)
        dismiss(animated: true)
    }
}
