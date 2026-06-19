//
//  ReportViewController.swift
//  StrayPals
//
//  「通報」頁：民眾發現疑似流浪動物時，可拍照 / 選圖、從選單挑選聯絡單位，
//  填寫描述後，透過系統分享（LINE / Mail / 訊息…）將照片與內容送給該單位，
//  並可一鍵撥打單位電話。
//
//  ⚠️ 開放資料未提供單位 Email，故採系統分享方式傳送，誠實不偽造上傳。
//

import UIKit

// MARK: - ReportViewController

final class ReportViewController: UIViewController {

    // MARK: Dependencies

    private let viewModel: ReportViewModel

    // MARK: State

    /// 使用者選擇 / 拍攝的照片。
    private var photo: UIImage?

    // MARK: UI

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let photoImageView = UIImageView()
    private let photoHintLabel = UILabel(text: L10n.reportPhotoHint,
                                         font: .systemFont(ofSize: 15, weight: .medium),
                                         color: .secondaryLabel)
    private let unitButton = UIButton(type: .system)
    private let noteTextView = UITextView()
    private let notePlaceholder = UILabel(text: L10n.reportNotePlaceholder,
                                          font: .systemFont(ofSize: 15),
                                          color: .tertiaryLabel)

    // MARK: Init

    init(viewModel: ReportViewModel) {
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
        viewModel.loadUnits()
    }

    // MARK: Setup

    private func setupUI() {
        title = viewModel.title
        applyWarmBackdrop()
        navigationController?.navigationBar.prefersLargeTitles = true

        view.addSubviews(scrollView)
        scrollView.addSubviews(contentStack)
        scrollView.backgroundColor = .clear
        scrollView.keyboardDismissMode = .interactive
        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 40, right: 20)

        let content = scrollView.contentLayoutGuide
        let frame = scrollView.frameLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: content.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: frame.widthAnchor)
        ])

        contentStack.addArrangedSubview(makePhotoSection())
        contentStack.addArrangedSubview(makeSectionTitle(L10n.reportSectionUnit))
        contentStack.addArrangedSubview(makeUnitButton())
        contentStack.addArrangedSubview(makeSectionTitle(L10n.reportSectionNote))
        contentStack.addArrangedSubview(makeNoteSection())
        contentStack.addArrangedSubview(makeSubmitButton())
    }

    // MARK: Binding

    private func bindViewModel() {
        viewModel.units.bind { [weak self] units in
            self?.updateUnitMenu(units)
        }
    }

    // MARK: Section Builders

    private func makeSectionTitle(_ text: String) -> UILabel {
        UILabel(text: text, font: .systemFont(ofSize: 16, weight: .bold))
    }

    private func makePhotoSection() -> UIView {
        let container = UIView()
        container.applyCardStyle()
        container.clipsToBounds = true

        photoImageView.contentMode = .scaleAspectFill
        photoImageView.clipsToBounds = true
        photoImageView.backgroundColor = .secondarySystemBackground
        photoImageView.isUserInteractionEnabled = true
        photoImageView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(choosePhotoTapped))
        )

        let icon = UIImageView(image: UIImage(systemName: "camera.fill"))
        icon.tintColor = .appPrimary
        icon.contentMode = .scaleAspectFit

        let hintStack = UIStackView(arrangedSubviews: [icon, photoHintLabel])
        hintStack.axis = .vertical
        hintStack.alignment = .center
        hintStack.spacing = 8
        hintStack.isUserInteractionEnabled = false

        container.addSubviews(photoImageView, hintStack)
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 220),
            photoImageView.topAnchor.constraint(equalTo: container.topAnchor),
            photoImageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            photoImageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            photoImageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            hintStack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            hintStack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            icon.heightAnchor.constraint(equalToConstant: 40)
        ])
        return container
    }

    private func makeUnitButton() -> UIButton {
        var config = UIButton.Configuration.bordered()
        config.title = L10n.reportUnitPlaceholder
        config.image = UIImage(systemName: "chevron.up.chevron.down")
        config.imagePlacement = .trailing
        config.imagePadding = 8
        config.baseForegroundColor = .label
        config.cornerStyle = .large
        unitButton.configuration = config
        unitButton.contentHorizontalAlignment = .leading
        unitButton.showsMenuAsPrimaryAction = true
        unitButton.changesSelectionAsPrimaryAction = false
        return unitButton
    }

    private func makeNoteSection() -> UIView {
        let container = UIView()
        container.applyCardStyle()

        noteTextView.font = .systemFont(ofSize: 15)
        noteTextView.backgroundColor = .clear
        noteTextView.isScrollEnabled = false
        noteTextView.delegate = self

        container.addSubviews(noteTextView, notePlaceholder)
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
            noteTextView.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            noteTextView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            noteTextView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            noteTextView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
            notePlaceholder.topAnchor.constraint(equalTo: noteTextView.topAnchor, constant: 8),
            notePlaceholder.leadingAnchor.constraint(equalTo: noteTextView.leadingAnchor, constant: 5)
        ])
        return container
    }

    private func makeSubmitButton() -> UIButton {
        let button = GradientButton(title: "送出通報", systemImage: "paperplane.fill")
        button.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        return button
    }

    // MARK: Unit Menu

    private func updateUnitMenu(_ units: [ContactUnit]) {
        let actions = units.map { unit in
            UIAction(title: unit.name) { [weak self] _ in
                self?.viewModel.selectUnit(unit)
                self?.unitButton.configuration?.title = unit.name
                HapticsManager.shared.select()
            }
        }
        unitButton.menu = UIMenu(title: L10n.reportMenuTitle, children: actions)
    }

    // MARK: Actions

    /// 選擇照片來源。
    @objc private func choosePhotoTapped() {
        let sheet = UIAlertController(title: L10n.reportPhotoAdd, message: nil, preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            sheet.addAction(UIAlertAction(title: L10n.reportPhotoCamera, style: .default) { [weak self] _ in
                self?.presentPicker(source: .camera)
            })
        }
        sheet.addAction(UIAlertAction(title: L10n.reportPhotoLibrary, style: .default) { [weak self] _ in
            self?.presentPicker(source: .photoLibrary)
        })
        sheet.addAction(UIAlertAction(title: L10n.actionCancel, style: .cancel))
        sheet.popoverPresentationController?.sourceView = photoImageView
        present(sheet, animated: true)
    }

    private func presentPicker(source: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = source
        picker.delegate = self
        present(picker, animated: true)
    }

    /// 送出通報（透過系統分享）。
    @objc private func submitTapped() {
        guard viewModel.canSubmit else {
            HapticsManager.shared.notify(.warning)
            presentAlert(title: L10n.reportNeedUnitTitle, message: L10n.reportNeedUnitMessage)
            return
        }

        var items: [Any] = [viewModel.reportText()]
        if let photo { items.append(photo) }

        let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activity.popoverPresentationController?.sourceView = view
        activity.completionWithItemsHandler = { [weak self] _, completed, _, _ in
            if completed {
                self?.viewModel.trackSubmit()
                HapticsManager.shared.notify(.success)
            }
        }
        present(activity, animated: true)
    }

    // MARK: Helpers

    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.actionOK, style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension ReportViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else { return }
        photo = image
        photoImageView.image = image
        photoHintLabel.superview?.isHidden = true   // 隱藏提示
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - UITextViewDelegate

extension ReportViewController: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        notePlaceholder.isHidden = !textView.text.isEmpty
        viewModel.note = textView.text
    }
}
