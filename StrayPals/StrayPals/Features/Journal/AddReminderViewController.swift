//
//  AddReminderViewController.swift
//  StrayPals (MaoWo)
//
//  新增一筆照護提醒：類型、標題、到期時間。儲存時排程「本地通知」。
//  若使用者尚未授權通知，會引導開啟（提醒仍會儲存，僅不發送通知）。
//

import UIKit

// MARK: - AddReminderViewController

final class AddReminderViewController: UIViewController {

    // MARK: State

    private let recordId: UUID
    private var selectedKind: CareReminderKind = .vaccine

    // MARK: UI

    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let kindControl = UISegmentedControl(items: CareReminderKind.allCases.map(\.localizedTitle))
    private let titleField = JournalForm.textField(placeholder: L10n.journalFieldReminderTitle)
    private let datePicker = UIDatePicker()

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
        title = L10n.journalAddReminder
        view.backgroundColor = .appBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))

        kindControl.selectedSegmentIndex = 0
        kindControl.apportionsSegmentWidthsByContent = true
        kindControl.addTarget(self, action: #selector(kindChanged), for: .valueChanged)
        titleField.text = selectedKind.localizedTitle

        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .compact
        datePicker.minimumDate = Date()
        // 預設明天此刻。
        datePicker.date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

        let kindScroll = UIScrollView()
        kindScroll.showsHorizontalScrollIndicator = false
        kindScroll.addSubviews(kindControl)
        NSLayoutConstraint.activate([
            kindControl.topAnchor.constraint(equalTo: kindScroll.contentLayoutGuide.topAnchor),
            kindControl.bottomAnchor.constraint(equalTo: kindScroll.contentLayoutGuide.bottomAnchor),
            kindControl.leadingAnchor.constraint(equalTo: kindScroll.contentLayoutGuide.leadingAnchor),
            kindControl.trailingAnchor.constraint(equalTo: kindScroll.contentLayoutGuide.trailingAnchor),
            kindControl.heightAnchor.constraint(equalTo: kindScroll.frameLayoutGuide.heightAnchor)
        ])
        kindScroll.heightAnchor.constraint(equalToConstant: 36).isActive = true

        stack.axis = .vertical
        stack.spacing = 16
        stack.addArrangedSubview(JournalForm.label(L10n.journalFieldReminderKind))
        stack.addArrangedSubview(kindScroll)
        stack.addArrangedSubview(JournalForm.label(L10n.journalFieldReminderTitle))
        stack.addArrangedSubview(titleField)
        stack.addArrangedSubview(JournalForm.row(L10n.journalFieldDueDate, datePicker))
        stack.addArrangedSubview(JournalForm.label(L10n.journalReminderHint))

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

    @objc private func kindChanged() {
        let kinds = CareReminderKind.allCases
        guard kindControl.selectedSegmentIndex < kinds.count else { return }
        selectedKind = kinds[kindControl.selectedSegmentIndex]
        // 若使用者未自訂標題，跟著類型更新預設標題。
        titleField.text = selectedKind.localizedTitle
    }

    @objc private func cancelTapped() { dismiss(animated: true) }

    @objc private func saveTapped() {
        let title = (titleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { JournalForm.shake(titleField); return }
        guard datePicker.date > Date() else { JournalForm.shake(datePicker); return }

        let reminder = CareReminder(recordId: recordId, title: title, kind: selectedKind, dueDate: datePicker.date)

        // 先請求通知授權，再儲存（無論是否授權都會儲存，僅授權後才會發送）。
        AdoptionJournalManager.shared.requestNotificationAuthorization { [weak self] granted in
            guard let self else { return }
            AdoptionJournalManager.shared.addReminder(reminder)
            HapticsManager.shared.notify(.success)
            if granted {
                self.dismiss(animated: true)
            } else {
                self.promptEnableNotifications()
            }
        }
    }

    private func promptEnableNotifications() {
        let alert = UIAlertController(title: L10n.journalNotifyDeniedTitle,
                                      message: L10n.journalNotifyDeniedMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.actionGoSettings, style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
        })
        alert.addAction(UIAlertAction(title: L10n.actionOK, style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
}
