//
//  AddEntryViewController.swift
//  StrayPals (MaoWo)
//
//  新增一則日記條目：日期、文字、體重（選填）、照片（選填）。
//

import UIKit
import PhotosUI

// MARK: - AddEntryViewController

final class AddEntryViewController: UIViewController {

    // MARK: State

    private let recordId: UUID
    private var pickedImage: UIImage?

    // MARK: UI

    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let datePicker = UIDatePicker()
    private let textView = JournalForm.textView()
    private let weightField = JournalForm.textField(placeholder: L10n.journalFieldWeightHint)
    private let photoButton = UIButton(type: .system)

    // MARK: Init

    init(recordId: UUID) {
        self.recordId = recordId
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = L10n.journalAddEntry
        view.backgroundColor = .appBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))

        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.maximumDate = Date()

        weightField.keyboardType = .decimalPad

        photoButton.setTitle("  " + L10n.reportPhotoAdd, for: .normal)
        photoButton.setImage(UIImage(systemName: "photo.badge.plus"), for: .normal)
        photoButton.tintColor = .appPrimary
        photoButton.contentHorizontalAlignment = .leading
        photoButton.addTarget(self, action: #selector(pickPhoto), for: .touchUpInside)

        stack.axis = .vertical
        stack.spacing = 16
        stack.addArrangedSubview(JournalForm.row(L10n.journalFieldDate, datePicker))
        stack.addArrangedSubview(JournalForm.label(L10n.journalFieldDiary))
        stack.addArrangedSubview(textView)
        stack.addArrangedSubview(JournalForm.label(L10n.journalFieldWeight))
        stack.addArrangedSubview(weightField)
        stack.addArrangedSubview(photoButton)

        scrollView.addSubviews(stack)
        view.addSubviews(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    // MARK: Actions

    @objc private func cancelTapped() { dismiss(animated: true) }

    @objc private func saveTapped() {
        let text = (textView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let weight = Double((weightField.text ?? "").replacingOccurrences(of: ",", with: "."))
        guard !text.isEmpty || weight != nil || pickedImage != nil else {
            JournalForm.shake(textView)
            return
        }

        var filename: String?
        if let image = pickedImage { filename = AdoptionJournalManager.shared.savePhoto(image) }

        let entry = JournalEntry(recordId: recordId, date: datePicker.date, text: text,
                                 photoFilename: filename, weightKg: weight)
        AdoptionJournalManager.shared.addEntry(entry)
        HapticsManager.shared.notify(.success)
        dismiss(animated: true)
    }

    @objc private func pickPhoto() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate

extension AddEntryViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                self?.pickedImage = image
                self?.photoButton.setTitle("  " + L10n.journalPhotoAdded, for: .normal)
                self?.photoButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
            }
        }
    }
}
