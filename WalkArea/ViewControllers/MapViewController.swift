//
//  MapViewController.swift
//  WalkArea
//
//  Created by Sergio Rodríguez Rama on 01/05/2020.
//  Copyright © 2020 Sergio Rodríguez Rama. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    // MARK: - Static
    
    private static let notificationIdentifier = "too_far"
    
    static func killAllNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [Self.notificationIdentifier])
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.notificationIdentifier])
    }
    
    // MARK: - Private var let
    
    private var homeLocation: CLLocation?
    private var currentLocation: CLLocation?
    private var circleOverlay: MKOverlay?
    private var radius: CLLocationDistance?
    private var tracking: Bool = false {
        didSet {
            if tracking {
                locationManager.startUpdatingLocation()
            } else {
                locationManager.stopUpdatingLocation()
            }
        }
    }
    private var measuringUnit: MeasuringUnit!
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.requestWhenInUseAuthorization()
        manager.allowsBackgroundLocationUpdates = true
        return manager
    }()

    private let homeAnnotation = MKPointAnnotation()

    // MARK: - IBOutlet
    
    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var metersLabel: UILabel!
    @IBOutlet private weak var findMeButton: UIButton! {
        didSet { findMeButton.alpha = 0 }
    }
    @IBOutlet private weak var startButton: UIButton! {
        didSet { startButton.alpha = 0 }
    }
    @IBOutlet private weak var playPauseButton: UIButton! {
        didSet { playPauseButton.alpha = 0 }
    }
    @IBOutlet private weak var launchScreenImageView: UIImageView! {
        didSet { launchScreenImageView.alpha = 1 }
    }
    
    // MARK: - IBAction
    
    @IBAction private func startButtonTouchUpInside(_ sender: UIButton) {
        presentStartViewController()
    }
    
    @IBAction func playPauseButtonTouchUpInside(_ sender: UIButton) {
        let alertTitle = tracking ? NSLocalizedString("Pause tracking", comment: "") : NSLocalizedString("Resume tracking", comment: "")
        let alertMessage = tracking ? NSLocalizedString("You will pause GPS tracking.", comment: "") : NSLocalizedString("You will resume GPS tracking.", comment: "")
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("No", comment: ""), style: .default, handler: nil))
        let yesAction = UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: { [weak self] _ in
            self?.tracking ?? false ? self?.stopTracking() : self?.startTracking()
        })
        alert.addAction(yesAction)
        alert.preferredAction = yesAction
        present(alert, animated: true)
    }
    
    @IBAction private func findMeButtonTouchUpInside(_ sender: UIButton) {
        mapView.setUserTrackingMode(.followWithHeading, animated: true)
    }
    
    // MARK: - Life cycle
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        removeLaunchScreen()
    }
}

// MARK: - CLLocationManagerDelegate methods

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        if homeLocation == nil {
            setHomeLocation(location)
        } else {
            setCurrentLocation(location)
        }
    }
}

// MARK: - MKMapViewDelegate methods

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let circleColor = UIColor.init(red: 243.0/255.0, green: 0, blue: 101.0/255.0, alpha: 1)
        let circleView = MKCircleRenderer(overlay: overlay)
        circleView.strokeColor = circleColor
        circleView.lineWidth = 3
        return circleView
    }
}

// MARK: - UNUserNotificationCenterDelegate methods

extension MapViewController: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        guard notification.request.identifier == Self.notificationIdentifier else { return }
        center.getDeliveredNotifications { notifications in
            if !notifications.contains(where: { (notification) -> Bool in
                notification.request.identifier == Self.notificationIdentifier
            }) {
                completionHandler([.alert, .sound])
            }
        }
    }
}

// MARK: - StartDelegate methods

extension MapViewController: StartDelegate {
    func start(with distance: CLLocationDistance, in measuringUnit: MeasuringUnit) {
        setupLocationManager()
        setupMapView()
        radius = distance
        self.measuringUnit = measuringUnit
        mapView.setUserTrackingMode(.none, animated: true)
        restart()
    }
    
    func dismiss() {
        if radius == nil {
            presentStartViewController()
        } else {
            showButtons()
        }
    }
}

// MARK: - Private methods

private extension MapViewController {
    
    func removeLaunchScreen() {
        guard launchScreenImageView.alpha == 1 else { return }
        UIView.animate(withDuration: 1, animations: { [weak self] in
            self?.launchScreenImageView.transform = CGAffineTransform(scaleX: 2, y: 2)
            self?.launchScreenImageView.alpha = 0
        }) { [weak self] (_) in
            self?.presentStartViewController()
        }
    }

    func showButtons() {
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.findMeButton.alpha = 1
            self?.startButton.alpha = 1
            self?.playPauseButton.alpha = 1
        }
    }
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.showsBackgroundLocationIndicator = true
    }
    
    func setupMapView() {
        mapView.delegate = self
        mapView.showsScale = true
        mapView.showsCompass = true
        mapView.showsUserLocation = true
    }
    
    func centerMap(in coordinate: CLLocationCoordinate2D) {
        guard let radius = radius else { return }
        // Set a coordinate region big enough to host the walking area
        let regionWidth = radius * 2 + radius * 0.05
        let coordinateRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionWidth, longitudinalMeters: regionWidth)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func restart() {
        mapView.removeAnnotation(homeAnnotation)
        if let overlay = circleOverlay {
            mapView.removeOverlay(overlay)
        }
        homeLocation = nil
        currentLocation = nil
        metersLabel.text = nil
        Self.killAllNotifications()
        startTracking()
    }
    
    func setHomeLocation(_ location: CLLocation) {
        guard let radius = radius else { return }
        // Save home location
        homeLocation = location
        let coordinate = location.coordinate
        centerMap(in: coordinate)
        // Mark the start location in map
        homeAnnotation.coordinate = coordinate
        mapView.addAnnotation(homeAnnotation)
        // Draw a circle over the walking area
        circleOverlay = MKCircle(center: coordinate, radius: radius)
        if let overlay = circleOverlay {
            mapView.addOverlay(overlay)
        }
    }
    
    func setCurrentLocation(_ location: CLLocation) {
        currentLocation = location
        guard let start = homeLocation, let radius = radius else { return }
        let meters = start.distance(from: location)
        metersLabel.text = String(format: "%.2f %@", measuringUnit.fromMeters(meters), measuringUnit.symbol)
        if meters >= radius {
            deliverNotificationIfNeeded()
        } else {
            Self.killAllNotifications()
        }
    }
    
    func deliverNotification() {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("STOP", comment: "")
        content.body = NSLocalizedString("You're leaving your walking area.", comment: "")
        content.sound = UNNotificationSound.init(named: UNNotificationSoundName("News_Flash_Loop.m4a"))
        let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: Self.notificationIdentifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    func deliverNotificationIfNeeded() {
        var pendingAndDelivered: [UNNotificationRequest] = []
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            pendingAndDelivered += requests
            dispatchGroup.leave()
        }
        dispatchGroup.enter()
        UNUserNotificationCenter.current().getDeliveredNotifications(completionHandler: { requests in
            pendingAndDelivered += requests.map({$0.request})
            dispatchGroup.leave()
        })
        dispatchGroup.notify(queue: .main) { [weak self] in
            if !pendingAndDelivered.contains(where: { $0.identifier == Self.notificationIdentifier }) {
                self?.deliverNotification()
            }
        }
    }
    
    func presentStartViewController() {
        present(StartViewController.create(delegate: self), animated: true, completion: nil)
    }
    
    func stopTracking() {
        tracking = false
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
    }
    
    func startTracking() {
        tracking = true
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
    }
}

