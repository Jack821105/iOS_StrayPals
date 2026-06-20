//
//  ShareCardComposerViewController.swift
//  StrayPals (MaoWo)
//
//  分享圖卡編輯器（以 sheet 呈現）：可選版型（經典 / 拍立得 / 簡約）、加自訂留言，
//  即時預覽，最後分享渲染後的圖卡與文字。
//

import UIKit

// MARK: - ShareCardComposerViewController

final class ShareCardComposerViewController: UIViewController {

    // MARK: Data

    private let animal: Animal
    private let sourceImage: UIImage?
    private var style: ShareCardStyle = .classic
    private var message: String = ""

    // MARK: UI

    private let previewImageView = UIImageView()
    private let styleControl = UISegmentedControl(items: ShareCardStyle.allCases.map(\.localizedName))
    private let messageField = UITextField()

    // MARK: Init

    init(animal: Animal, image: UIImage?) {
        self.animal = animal
        self.sourceImage = image
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updatePreview()
    }

    // MARK: Setup

    private func setupUI() {
        applyWarmBackdrop()

        // 標題列。
        let titleLabel = UILabel(text: L10n.shareComposerTitle, font: .systemFont(ofSize: 20, weight: .bold))
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .tertiaryLabel
        closeButton.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)

        previewImageView.contentMode = .scaleAspectFit
        previewImageView.layer.cornerRadius = 12
        previewImageView.clipsToBounds = true
        // 預覽圖會吸收剩餘空間（而非以原圖像素撐爆版面），其餘控制項才不會被擠出畫面。
        previewImageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        previewImageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        styleControl.selectedSegmentIndex = 0
        styleControl.selectedSegmentTintColor = .appPrimary
        styleControl.addTarget(self, action: #selector(styleChanged), for: .valueChanged)

        messageField.placeholder = L10n.shareComposerMessagePlaceholder
        messageField.borderStyle = .roundedRect
        messageField.font = .systemFont(ofSize: 16)
        messageField.returnKeyType = .done
        messageField.delegate = self
        messageField.addTarget(self, action: #selector(messageChanged), for: .editingChanged)

        let shareButton = GradientButton(title: L10n.shareComposerShare, systemImage: "square.and.arrow.up")
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)

        let header = UIStackView(arrangedSubviews: [titleLabel, UIView(), closeButton])
        header.axis = .horizontal
        header.alignment = .center

        let stack = UIStackView(arrangedSubviews: [header, previewImageView, styleControl, messageField, shareButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.setCustomSpacing(20, after: previewImageView)

        view.addSubviews(stack)

        // 正常時貼齊安全區底部（高優先級，可被鍵盤約束讓位）。
        let stackBottom = stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        stackBottom.priority = .defaultHigh
        // 預覽圖最小高度（高優先級；鍵盤升起空間不足時會讓預覽圖縮小，而非擠出按鈕）。
        let previewMinHeight = previewImageView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200)
        previewMinHeight.priority = .defaultHigh

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackBottom,
            // 鍵盤升起時，將整個 stack 推到鍵盤上方，分享按鈕不被遮住（required）。
            view.keyboardLayoutGuide.topAnchor.constraint(greaterThanOrEqualTo: stack.bottomAnchor, constant: 20),
            previewMinHeight,
            closeButton.widthAnchor.constraint(equalToConstant: 28),
            closeButton.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    // MARK: Actions

    @objc private func styleChanged() {
        style = ShareCardStyle(rawValue: styleControl.selectedSegmentIndex) ?? .classic
        HapticsManager.shared.select()
        updatePreview()
    }

    @objc private func messageChanged() {
        message = messageField.text ?? ""
        updatePreview()
    }

    @objc private func shareTapped() {
        HapticsManager.shared.tap()
        let card = ShareCardRenderer.render(animal: animal, image: sourceImage, style: style, message: message)
        let text = L10n.shareText(kind: animal.kind.localizedName, shelter: animal.shelterName)
        let activity = UIActivityViewController(activityItems: [card, text], applicationActivities: nil)
        activity.popoverPresentationController?.sourceView = view
        present(activity, animated: true)
    }

    // MARK: Preview

    private func updatePreview() {
        previewImageView.image = ShareCardRenderer.render(animal: animal, image: sourceImage, style: style, message: message)
    }
}

// MARK: - UITextFieldDelegate

extension ShareCardComposerViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
