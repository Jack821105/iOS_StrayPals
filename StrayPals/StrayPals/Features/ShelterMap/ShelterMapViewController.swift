//
//  ShelterMapViewController.swift
//  StrayPals (MaoWo)
//
//  收容所地圖：以 MapKit 標註各收容所位置（支援聚合 clustering），
//  點選標註可查看該收容所名下的待認養動物。
//

import UIKit
import MapKit

// MARK: - ShelterMapViewController

final class ShelterMapViewController: UIViewController {

    // MARK: Dependencies

    private let viewModel: ShelterMapViewModel

    // MARK: UI

    private let mapView = MKMapView()
    private let loadingLabel = PaddingPill()

    private static let annotationID = "ShelterAnnotation"
    private static let clusterID = "ShelterCluster"

    // MARK: Init

    init(viewModel: ShelterMapViewModel) {
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
        viewModel.load()
    }

    // MARK: Setup

    private func setupUI() {
        title = viewModel.title
        view.backgroundColor = .appBackground
        navigationItem.largeTitleDisplayMode = .never

        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.pointOfInterestFilter = .excludingAll
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: Self.annotationID)
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: Self.clusterID)

        // 預設聚焦台灣本島。
        let taiwan = CLLocationCoordinate2D(latitude: 23.7, longitude: 121.0)
        mapView.setRegion(MKCoordinateRegion(center: taiwan,
                                             span: MKCoordinateSpan(latitudeDelta: 3.6, longitudeDelta: 3.6)),
                          animated: false)

        // 定位追蹤按鈕。
        let trackingButton = MKUserTrackingButton(mapView: mapView)
        trackingButton.layer.cornerRadius = 8
        trackingButton.layer.backgroundColor = UIColor.appCard.withAlphaComponent(0.9).cgColor
        trackingButton.translatesAutoresizingMaskIntoConstraints = false

        loadingLabel.text = L10n.mapLoading
        loadingLabel.isHidden = true

        view.addSubviews(mapView, trackingButton, loadingLabel)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            trackingButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            trackingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            trackingButton.widthAnchor.constraint(equalToConstant: 44),
            trackingButton.heightAnchor.constraint(equalToConstant: 44),

            loadingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12)
        ])
    }

    // MARK: Binding

    private func bindViewModel() {
        viewModel.shelters.bind { [weak self] _ in self?.reloadAnnotations() }
        viewModel.isLoading.bind { [weak self] loading in
            guard let self else { return }
            // 仍無任何收容所標註時才顯示載入提示，避免蓋住已可用的地圖。
            let hasShelters = self.mapView.annotations.contains { $0 is ShelterAnnotation }
            self.loadingLabel.isHidden = !(loading && !hasShelters)
        }
    }

    private func reloadAnnotations() {
        let existing = mapView.annotations.compactMap { $0 as? ShelterAnnotation }
        mapView.removeAnnotations(existing)
        let annotations = viewModel.shelters.value.compactMap(ShelterAnnotation.init(shelter:))
        mapView.addAnnotations(annotations)
        if !annotations.isEmpty { loadingLabel.isHidden = true }
    }

    // MARK: Navigation

    private func openShelter(_ shelter: ShelterGroup) {
        let listVC = ShelterAnimalsViewController(shelter: shelter)
        navigationController?.pushViewController(listVC, animated: true)
    }
}

// MARK: - MKMapViewDelegate

extension ShelterMapViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }

        // 聚合節點。
        if let cluster = annotation as? MKClusterAnnotation {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: Self.clusterID, for: cluster) as! MKMarkerAnnotationView
            view.markerTintColor = .appPrimary
            view.glyphText = "\(cluster.memberAnnotations.count)"
            return view
        }

        guard let shelter = annotation as? ShelterAnnotation else { return nil }
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: Self.annotationID, for: shelter) as! MKMarkerAnnotationView
        view.clusteringIdentifier = Self.clusterID
        view.canShowCallout = true
        view.markerTintColor = shelter.shelter.hasUrgent ? .appHeart : .appPrimary
        view.glyphImage = UIImage(systemName: "pawprint.fill")

        let disclosure = UIButton(type: .detailDisclosure)
        disclosure.tintColor = .appPrimary
        view.rightCalloutAccessoryView = disclosure
        return view
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let shelter = view.annotation as? ShelterAnnotation {
            HapticsManager.shared.tap()
            openShelter(shelter.shelter)
        }
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // 點聚合節點時放大。
        guard let cluster = view.annotation as? MKClusterAnnotation else { return }
        let region = MKCoordinateRegion(
            center: cluster.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.4, longitudeDelta: 0.4)
        )
        mapView.setRegion(region, animated: true)
    }
}

// MARK: - PaddingPill

/// 地圖上方的膠囊狀提示標籤。
final class PaddingPill: UILabel {
    private let inset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)

    override init(frame: CGRect) {
        super.init(frame: frame)
        font = .systemFont(ofSize: 14, weight: .medium)
        textColor = .label
        backgroundColor = .appCard
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        clipsToBounds = true
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.separator.cgColor
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func drawText(in rect: CGRect) { super.drawText(in: rect.inset(by: inset)) }
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + inset.left + inset.right,
                      height: size.height + inset.top + inset.bottom)
    }
}
