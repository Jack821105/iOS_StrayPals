//
//  AssistantViewController.swift
//  StrayPals (MaoWo)
//
//  領養顧問聊天頁：訊息列表 + 快速回覆 chip + 輸入列。鍵盤以 keyboardLayoutGuide
//  自動避讓。點推薦卡開啟詳情。
//

import UIKit

// MARK: - AssistantViewController

final class AssistantViewController: UIViewController {

    // MARK: Dependencies

    private let viewModel: AssistantViewModel

    // MARK: UI

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let quickRepliesScroll = UIScrollView()
    private let quickRepliesRow = UIStackView()
    private let typingIndicator = UIActivityIndicatorView(style: .medium)
    private let inputField = UITextField()
    private let sendButton = UIButton(type: .system)

    // MARK: Init

    init(viewModel: AssistantViewModel) {
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
        viewModel.start()
    }

    // MARK: Setup

    private func setupUI() {
        title = viewModel.title
        applyWarmBackdrop()
        navigationController?.navigationBar.prefersLargeTitles = true

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .interactive
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(ChatBubbleCell.self, forCellReuseIdentifier: ChatBubbleCell.reuseID)

        quickRepliesScroll.showsHorizontalScrollIndicator = false
        quickRepliesRow.axis = .horizontal
        quickRepliesRow.spacing = 8
        quickRepliesRow.isLayoutMarginsRelativeArrangement = true
        quickRepliesRow.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        // 輸入列。
        let inputBar = UIView()
        inputBar.backgroundColor = .appCard

        inputField.placeholder = L10n.assistantPlaceholder
        inputField.borderStyle = .roundedRect
        inputField.font = .systemFont(ofSize: 16)
        inputField.returnKeyType = .send
        inputField.delegate = self

        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        sendButton.tintColor = .appPrimary
        sendButton.setContentHuggingPriority(.required, for: .horizontal)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        sendButton.widthAnchor.constraint(equalToConstant: 34).isActive = true
        sendButton.heightAnchor.constraint(equalToConstant: 34).isActive = true

        let inputRow = UIStackView(arrangedSubviews: [inputField, sendButton])
        inputRow.axis = .horizontal
        inputRow.spacing = 8
        inputRow.alignment = .center
        inputBar.addSubviews(inputRow)
        quickRepliesScroll.addSubviews(quickRepliesRow)

        view.addSubviews(tableView, quickRepliesScroll, typingIndicator, inputBar)
        typingIndicator.hidesWhenStopped = true

        NSLayoutConstraint.activate([
            inputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBar.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            inputRow.topAnchor.constraint(equalTo: inputBar.topAnchor, constant: 8),
            inputRow.bottomAnchor.constraint(equalTo: inputBar.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            inputRow.leadingAnchor.constraint(equalTo: inputBar.leadingAnchor, constant: 16),
            inputRow.trailingAnchor.constraint(equalTo: inputBar.trailingAnchor, constant: -12),

            quickRepliesScroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            quickRepliesScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            quickRepliesScroll.bottomAnchor.constraint(equalTo: inputBar.topAnchor, constant: -6),
            quickRepliesScroll.heightAnchor.constraint(equalToConstant: 36),

            quickRepliesRow.topAnchor.constraint(equalTo: quickRepliesScroll.contentLayoutGuide.topAnchor),
            quickRepliesRow.leadingAnchor.constraint(equalTo: quickRepliesScroll.contentLayoutGuide.leadingAnchor),
            quickRepliesRow.trailingAnchor.constraint(equalTo: quickRepliesScroll.contentLayoutGuide.trailingAnchor),
            quickRepliesRow.bottomAnchor.constraint(equalTo: quickRepliesScroll.contentLayoutGuide.bottomAnchor),
            quickRepliesRow.heightAnchor.constraint(equalTo: quickRepliesScroll.frameLayoutGuide.heightAnchor),

            typingIndicator.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            typingIndicator.centerYAnchor.constraint(equalTo: quickRepliesScroll.centerYAnchor),

            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: quickRepliesScroll.topAnchor, constant: -6)
        ])
    }

    // MARK: Binding

    private func bindViewModel() {
        viewModel.messages.bind { [weak self] _ in
            guard let self else { return }
            self.tableView.reloadData()
            self.scrollToBottom()
            self.refreshQuickReplies()
        }
        viewModel.isThinking.bind { [weak self] thinking in
            guard let self else { return }
            if thinking {
                self.typingIndicator.startAnimating()
                self.quickRepliesScroll.isHidden = true
            } else {
                self.typingIndicator.stopAnimating()
                self.refreshQuickReplies()
            }
        }
    }

    // MARK: Quick Replies

    private func refreshQuickReplies() {
        quickRepliesRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let replies = viewModel.isThinking.value ? [] : viewModel.latestQuickReplies
        quickRepliesScroll.isHidden = replies.isEmpty
        for reply in replies {
            let chip = ChipButton(title: reply, value: reply)
            chip.addAction(UIAction { [weak self] _ in
                HapticsManager.shared.select()
                self?.viewModel.send(reply)
            }, for: .touchUpInside)
            quickRepliesRow.addArrangedSubview(chip)
        }
    }

    // MARK: Actions

    @objc private func sendTapped() {
        guard let text = inputField.text, !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        inputField.text = nil
        HapticsManager.shared.tap()
        viewModel.send(text)
    }

    private func scrollToBottom() {
        let count = viewModel.messages.value.count
        guard count > 0 else { return }
        let indexPath = IndexPath(row: count - 1, section: 0)
        DispatchQueue.main.async {
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
}

// MARK: - UITableViewDataSource / Delegate

extension AssistantViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.messages.value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatBubbleCell.reuseID, for: indexPath) as! ChatBubbleCell
        cell.configure(with: viewModel.messages.value[indexPath.row])
        cell.onSelectAnimal = { [weak self] animal in
            let detail = ViewControllerFactory.makeDetail(for: animal)
            self?.navigationController?.pushViewController(detail, animated: true)
        }
        return cell
    }
}

// MARK: - UITextFieldDelegate

extension AssistantViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTapped()
        return true
    }
}
