//
//  AddRecordViewController.swift
//  StrayPals (MaoWo)
//
//  新增（或由收藏帶入）一筆認養紀錄：照片、名字、種類、收容所、認養日期、備註。
//

import UIKit
import PhotosUI

// MARK: - AddRecordViewController

final class AddRecordViewController: UIViewController {

    // MARK: State

    private var pickedImage: UIImage?
    private var sourceAnimalId: Int?

    // MARK: UI

    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let photoButton = UIButton(type: .system)
    private let nameField = JournalForm.textField(placeholder: L10n.journalFieldName)
    private let kindControl = UISegmentedControl(items: [L10n.kindDog, L10n.kindCat, L10n.kindOther])
    private let shelterField = JournalForm.textField(placeholder: L10n.journalFieldShelter)
    private let datePicker = UIDatePicker()
    private let noteView = JournalForm.textView()

    // MARK: Init

    init(prefillFrom animal: Animal? = nil) {
        super.init(nibName: nil, bundle: nil)
        if let animal {
            sourceAnimalId = animal.id
            nameField.text = animal.displayName
            shelterField.text = animal.shelterName
            switch animal.kind {
            case .dog:   kindControl.selectedSegmentIndex = 0
            case .cat:   kindControl.selectedSegmentIndex = 1
            case .other: kindControl.selectedSegmentIndex = 2
            }
        }
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
        title = L10n.journalAddRecord
        view.backgroundColor = .appBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))

        if kindControl.selectedSegmentIndex == UISegmentedControl.noSegment {
            kindControl.selectedSegmentIndex = 0
        }

        // 圓形照片按鈕。
        photoButton.setImage(UIImage(systemName: "camera.circle.fill"), for: .normal)
        photoButton.tintColor = .appPrimary
        photoButton.imageView?.contentMode = .scaleAspectFill
        photoButton.clipsToBounds = true
        photoButton.layer.cornerRadius = 50
        photoButton.backgroundColor = .appCard
        photoButton.addTarget(self, action: #selector(pickPhoto), for: .touchUpInside)
        photoButton.translatesAutoresizingMaskIntoConstraints = false
        photoButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        photoButton.heightAnchor.constraint(equalToConstant: 100).isActive = true
        let photoWrap = UIStackView(arrangedSubviews: [photoButton])
        photoWrap.alignment = .center

        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.maximumDate = Date()

        stack.axis = .vertical
        stack.spacing = 16
        stack.addArrangedSubview(photoWrap)
        stack.addArrangedSubview(JournalForm.label(L10n.journalFieldName))
        stack.addArrangedSubview(nameField)
        stack.addArrangedSubview(JournalForm.label(L10n.journalFieldKind))
        stack.addArrangedSubview(kindControl)
        stack.addArrangedSubview(JournalForm.label(L10n.journalFieldShelter))
        stack.addArrangedSubview(shelterField)
        stack.addArrangedSubview(JournalForm.row(L10n.journalFieldAdoptedDate, datePicker))
        stack.addArrangedSubview(JournalForm.label(L10n.journalFieldNote))
        stack.addArrangedSubview(noteView)

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
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            JournalForm.shake(nameField)
            return
        }
        let kindRaw: String
        switch kindControl.selectedSegmentIndex {
        case 0: kindRaw = AnimalKind.dog.rawValue
        case 1: kindRaw = AnimalKind.cat.rawValue
        default: kindRaw = AnimalKind.other.rawValue
        }

        var filename: String?
        if let image = pickedImage { filename = AdoptionJournalManager.shared.savePhoto(image) }

        let record = AdoptionRecord(
            name: name,
            kindRaw: kindRaw,
            shelterName: (shelterField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            adoptedDate: datePicker.date,
            photoFilename: filename,
            sourceAnimalId: sourceAnimalId,
            note: noteView.text ?? ""
        )
        AdoptionJournalManager.shared.addRecord(record)
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

extension AddRecordViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                self?.pickedImage = image
                self?.photoButton.setImage(image, for: .normal)
                self?.photoButton.imageView?.contentMode = .scaleAspectFill
            }
        }
    }
}
