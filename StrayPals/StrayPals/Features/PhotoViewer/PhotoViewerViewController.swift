//
//  PhotoViewerViewController.swift
//  StrayPals (MaoWo)
//
//  全螢幕照片檢視器：支援雙指縮放、雙擊放大、下拉關閉、儲存到相簿。
//  從詳情頁點擊大圖開啟。
//

import UIKit

// MARK: - PhotoViewerViewController

final class PhotoViewerViewController: UIViewController {

    // MARK: Data

    private let image: UIImage

    // MARK: UI

    private let scrollView = UIScrollView()
    private let imageView = UIImageView()

    // MARK: Init

    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        imageView.frame = scrollView.bounds
    }

    // MARK: Setup

    private func setupUI() {
        view.backgroundColor = .black

        scrollView.delegate = self
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 4
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)

        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        scrollView.addSubview(imageView)

        // 關閉鈕。
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = UIColor(white: 1, alpha: 0.9)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        // 儲存鈕。
        let saveButton = UIButton(type: .system)
        saveButton.setImage(UIImage(systemName: "square.and.arrow.down"), for: .normal)
        saveButton.tintColor = UIColor(white: 1, alpha: 0.9)
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)

        [closeButton, saveButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 34),
            closeButton.heightAnchor.constraint(equalToConstant: 34),
            saveButton.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            saveButton.widthAnchor.constraint(equalToConstant: 34),
            saveButton.heightAnchor.constraint(equalToConstant: 34)
        ])

        // 雙擊縮放。
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }

    // MARK: Actions

    @objc private func close() { dismiss(animated: true) }

    @objc private func save() {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(didFinishSaving(_:error:contextInfo:)), nil)
    }

    @objc private func didFinishSaving(_ image: UIImage, error: Error?, contextInfo: UnsafeRawPointer) {
        HapticsManager.shared.notify(error == nil ? .success : .error)
        guard error == nil else { return }
        let toast = UIAlertController(title: nil, message: L10n.photoSaved, preferredStyle: .alert)
        present(toast, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { toast.dismiss(animated: true) }
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            scrollView.setZoomScale(scrollView.maximumZoomScale / 2, animated: true)
        }
    }
}

// MARK: - UIScrollViewDelegate

extension PhotoViewerViewController: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
}
