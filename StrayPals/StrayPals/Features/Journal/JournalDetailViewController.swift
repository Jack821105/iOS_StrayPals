//
//  JournalDetailViewController.swift
//  StrayPals (MaoWo)
//
//  單一毛孩的認養日記與照護提醒。頂部為毛孩卡（照片、陪伴天數、最新體重），
//  下方分「照護提醒」與「日記」兩區。可新增日記/提醒、勾選完成、滑動刪除。
//

import UIKit

// MARK: - JournalDetailViewController

final class JournalDetailViewController: UIViewController {

    // MARK: Section

    private enum Section: Int, CaseIterable { case reminders, entries }

    // MARK: Data

    private var record: AdoptionRecord
    private let manager = AdoptionJournalManager.shared

    private var reminders: [CareReminder] = []
    private var entries: [JournalEntry] = []

    // MARK: UI

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // MARK: Init

    init(record: AdoptionRecord) {
        self.record = record
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        NotificationCenter.default.addObserver(self, selector: #selector(reload),
                                               name: AdoptionJournalManager.didChangeNotification, object: nil)
        reload()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sizeHeaderToFit()
    }

    // MARK: Setup

    private func setupUI() {
        title = record.name
        applyWarmBackdrop()
        navigationItem.largeTitleDisplayMode = .never

        // 「+」選單：新增日記 / 新增提醒。
        let addMenu = UIMenu(children: [
            UIAction(title: L10n.journalAddEntry, image: UIImage(systemName: "square.and.pencil")) { [weak self] _ in
                self?.presentAddEntry()
            },
            UIAction(title: L10n.journalAddReminder, image: UIImage(systemName: "bell.badge")) { [weak self] _ in
                self?.presentAddReminder()
            }
        ])
        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .add, menu: addMenu)

        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 64
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.tableHeaderView = makeHeaderView()

        view.addSubviews(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: Header

    private func makeHeaderView() -> UIView {
        let container = UIView()

        let photoView = UIImageView()
        photoView.contentMode = .scaleAspectFill
        photoView.clipsToBounds = true
        photoView.layer.cornerRadius = 40
        photoView.backgroundColor = .secondarySystemBackground
        if let image = manager.loadPhoto(record.photoFilename) {
            photoView.image = image
        } else {
            photoView.image = UIImage(systemName: record.kind.symbolName)
            photoView.contentMode = .center
            photoView.tintColor = .appPrimary.withAlphaComponent(0.6)
        }

        let daysLabel = UILabel(text: L10n.journalDaysTogether(record.daysTogether),
                                font: .systemFont(ofSize: 22, weight: .bold), color: .appPrimary)
        var sub = "\(record.kind.localizedName)"
        if !record.shelterName.isEmpty { sub += " · \(record.shelterName)" }
        if let latest = manager.weightHistory(for: record.id).last {
            sub += " · \(L10n.journalWeightValue(latest.weight))"
        }
        let subLabel = UILabel(text: sub, font: .systemFont(ofSize: 13), color: .secondaryLabel, lines: 0)

        let textStack = UIStackView(arrangedSubviews: [daysLabel, subLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let row = UIStackView(arrangedSubviews: [photoView, textStack])
        row.axis = .horizontal
        row.spacing = 16
        row.alignment = .center

        container.addSubviews(row)
        NSLayoutConstraint.activate([
            photoView.widthAnchor.constraint(equalToConstant: 80),
            photoView.heightAnchor.constraint(equalToConstant: 80),
            row.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
        return container
    }

    private func sizeHeaderToFit() {
        guard let header = tableView.tableHeaderView else { return }
        let targetWidth = tableView.bounds.width
        let size = header.systemLayoutSizeFitting(
            CGSize(width: targetWidth, height: UIView.layoutFittingCompressedSize.height)
        )
        if header.frame.height != size.height {
            header.frame.size.height = size.height
            tableView.tableHeaderView = header
        }
    }

    // MARK: Data

    @objc private func reload() {
        // 紀錄本身可能被更新（例如改名）。
        if let fresh = manager.record(id: record.id) { record = fresh; title = record.name }
        reminders = manager.reminders(for: record.id)
        entries = manager.entries(for: record.id)
        tableView.reloadData()
    }

    private func presentAddEntry() {
        HapticsManager.shared.tap()
        present(UINavigationController(rootViewController: AddEntryViewController(recordId: record.id)), animated: true)
    }

    private func presentAddReminder() {
        HapticsManager.shared.tap()
        present(UINavigationController(rootViewController: AddReminderViewController(recordId: record.id)), animated: true)
    }
}

// MARK: - UITableViewDataSource / Delegate

extension JournalDetailViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section(rawValue: section) == .reminders ? L10n.journalSectionReminders : L10n.journalSectionEntries
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .reminders: return max(reminders.count, 1)   // 至少一列顯示空狀態
        case .entries:   return max(entries.count, 1)
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = .appCard
        cell.accessoryType = .none
        cell.accessoryView = nil
        var config = cell.defaultContentConfiguration()
        config.textProperties.numberOfLines = 0
        config.secondaryTextProperties.numberOfLines = 0

        switch Section(rawValue: indexPath.section)! {
        case .reminders:
            if reminders.isEmpty {
                config.text = L10n.journalNoReminders
                config.textProperties.color = .secondaryLabel
                config.image = nil
            } else {
                let reminder = reminders[indexPath.row]
                config.text = reminder.title
                config.secondaryText = DateFormatter.journalDateTime.string(from: reminder.dueDate)
                config.image = UIImage(systemName: reminder.isDone ? "checkmark.circle.fill" : reminder.kind.symbol)
                config.imageProperties.tintColor = reminder.isDone ? .appAccent : (reminder.isOverdue ? .appHeart : .appPrimary)
                if reminder.isDone {
                    config.textProperties.color = .secondaryLabel
                }
            }

        case .entries:
            if entries.isEmpty {
                config.text = L10n.journalNoEntries
                config.textProperties.color = .secondaryLabel
                config.image = nil
            } else {
                let entry = entries[indexPath.row]
                config.text = entry.text.isEmpty ? L10n.journalEntryNoText : entry.text
                var secondary = DateFormatter.journalDate.string(from: entry.date)
                if let weight = entry.weightKg { secondary += " · \(L10n.journalWeightValue(weight))" }
                config.secondaryText = secondary
                if let filename = entry.photoFilename, let image = manager.loadPhoto(filename) {
                    config.image = image
                    config.imageProperties.maximumSize = CGSize(width: 48, height: 48)
                    config.imageProperties.cornerRadius = 8
                } else {
                    config.image = UIImage(systemName: "text.bubble")
                    config.imageProperties.tintColor = .appPrimary
                }
            }
        }
        cell.contentConfiguration = config
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard Section(rawValue: indexPath.section) == .reminders, !reminders.isEmpty else { return }
        HapticsManager.shared.toggle()
        manager.toggleReminderDone(reminders[indexPath.row])
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        switch Section(rawValue: indexPath.section)! {
        case .reminders:
            guard !reminders.isEmpty else { return nil }
            let reminder = reminders[indexPath.row]
            let delete = UIContextualAction(style: .destructive, title: L10n.actionDelete) { [weak self] _, _, done in
                self?.manager.deleteReminder(reminder); done(true)
            }
            return UISwipeActionsConfiguration(actions: [delete])
        case .entries:
            guard !entries.isEmpty else { return nil }
            let entry = entries[indexPath.row]
            let delete = UIContextualAction(style: .destructive, title: L10n.actionDelete) { [weak self] _, _, done in
                self?.manager.deleteEntry(entry); done(true)
            }
            return UISwipeActionsConfiguration(actions: [delete])
        }
    }
}

// MARK: - DateFormatter Helpers

extension DateFormatter {

    static let journalDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static let journalDateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
}
