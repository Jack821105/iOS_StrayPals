//
//  JournalListViewController.swift
//  StrayPals (MaoWo)
//
//  「認養日記」首頁：列出所有認養紀錄（你帶回家的毛孩），可新增、進入單一毛孩的
//  日記與照護提醒。資料變動時即時刷新。
//

import UIKit

// MARK: - JournalListViewController

final class JournalListViewController: UIViewController {

    // MARK: Dependencies

    private let manager = AdoptionJournalManager.shared

    // MARK: UI

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyStateView = EmptyStateView()

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        NotificationCenter.default.addObserver(self, selector: #selector(reload),
                                               name: AdoptionJournalManager.didChangeNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    // MARK: Setup

    private func setupUI() {
        title = L10n.journalTitle
        applyWarmBackdrop()
        navigationItem.largeTitleDisplayMode = .never

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add, target: self, action: #selector(addRecordTapped)
        )

        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 88
        tableView.register(JournalRecordCell.self, forCellReuseIdentifier: JournalRecordCell.reuseID)

        view.addSubviews(tableView, emptyStateView)
        emptyStateView.configure(
            symbol: "book.closed",
            title: L10n.journalEmptyTitle,
            message: L10n.journalEmptyMessage,
            showRetry: false
        )

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: Actions

    @objc private func reload() {
        tableView.reloadData()
        emptyStateView.isHidden = !manager.records.isEmpty
    }

    @objc private func addRecordTapped() {
        HapticsManager.shared.tap()
        let addVC = AddRecordViewController()
        present(UINavigationController(rootViewController: addVC), animated: true)
    }
}

// MARK: - UITableViewDataSource / Delegate

extension JournalListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        manager.records.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: JournalRecordCell.reuseID, for: indexPath) as! JournalRecordCell
        cell.configure(with: manager.records[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let record = manager.records[indexPath.row]
        navigationController?.pushViewController(JournalDetailViewController(record: record), animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let record = manager.records[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: L10n.actionDelete) { [weak self] _, _, done in
            self?.confirmDelete(record); done(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }

    private func confirmDelete(_ record: AdoptionRecord) {
        let alert = UIAlertController(title: L10n.journalDeleteTitle, message: record.name, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.actionCancel, style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.actionDelete, style: .destructive) { [weak self] _ in
            self?.manager.deleteRecord(record)
        })
        present(alert, animated: true)
    }
}

// MARK: - JournalRecordCell

private final class JournalRecordCell: UITableViewCell {

    static let reuseID = "JournalRecordCell"

    private let photoView = UIImageView()
    private let nameLabel = UILabel(font: .systemFont(ofSize: 17, weight: .semibold))
    private let subtitleLabel = UILabel(font: .systemFont(ofSize: 13), color: .secondaryLabel)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        backgroundColor = .clear
        accessoryType = .disclosureIndicator

        photoView.contentMode = .scaleAspectFill
        photoView.clipsToBounds = true
        photoView.layer.cornerRadius = 12
        photoView.layer.cornerCurve = .continuous
        photoView.backgroundColor = .secondarySystemBackground

        let textStack = UIStackView(arrangedSubviews: [nameLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        contentView.addSubviews(photoView, textStack)
        NSLayoutConstraint.activate([
            photoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            photoView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            photoView.widthAnchor.constraint(equalToConstant: 64),
            photoView.heightAnchor.constraint(equalToConstant: 64),

            textStack.leadingAnchor.constraint(equalTo: photoView.trailingAnchor, constant: 14),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(with record: AdoptionRecord) {
        nameLabel.text = record.name
        subtitleLabel.text = "\(record.kind.localizedName) · \(L10n.journalDaysTogether(record.daysTogether))"
        if let image = AdoptionJournalManager.shared.loadPhoto(record.photoFilename) {
            photoView.image = image
        } else {
            photoView.image = UIImage(systemName: record.kind.symbolName)
            photoView.tintColor = .appPrimary.withAlphaComponent(0.6)
            photoView.contentMode = .center
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        photoView.image = nil
        photoView.contentMode = .scaleAspectFill
    }
}
