//
//  WeatherRepository.swift
//  Weather
//
//  Created by Pierluigi Galdi on 20/05/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import CoreLocation
import AppKit
import SystemConfiguration

struct City: Codable, Equatable {
    let name: String
    let country: String
    let lat: String
    let lng: String
    var coords: CLLocation? {
        guard let lat = CLLocationDegrees(lat), let lng = CLLocationDegrees(lng) else {
            return nil
        }
        return CLLocation(latitude: lat, longitude: lng)
    }
}

class WeatherRepository: NSObject {
    
    typealias WeatherCompletion = (WeatherData?) -> Void
    
    /// Core
	private weak var timer: Timer?
	private var completionBlock: WeatherCompletion?
    private var retryWorkItem: DispatchWorkItem?
    private weak var currentTask: URLSessionDataTask?
    /// Default-route reachability (no DNS lookups, callbacks only when the network configuration changes).
    /// Note: `Network.framework`'s `NWPathMonitor` can't be used here, `import Network` resolves to the private
    /// framework because of this target's `SYSTEM_FRAMEWORK_SEARCH_PATHS`.
    private var reachability: SCNetworkReachability?
    
    /// State
    private var isNetworkAvailable: Bool = true
    /// `true` if the last refresh failed (or was skipped while offline) and should be performed as soon as possible.
    private var needsRefresh: Bool = false
    private var retryCount: Int = 0
    private var lastSuccessfulUpdate: Date?

    /// Location
    private let locationProvider = LocationProvider()
    private let geocoder = CLGeocoder()
    private var lastPlace: (location: CLLocation, name: String)?
    private var isResolvingLocation: Bool = false

    /// Interval between two regular refreshes.
    private let refreshInterval: TimeInterval = 3600
    /// Delay before retrying a failed request (e.g. no network right after wake). Doubled on every consecutive failure.
    private let retryInterval: TimeInterval = 60
    /// Max consecutive retries (60 s, 2, 4, 8, 16 min). After that, the regular timer, wake and network changes take over.
    private let maxRetryCount: Int = 5
    /// Non-forced refreshes (timer, wake) are skipped if data was successfully fetched less than this ago.
    private let minimumRefreshInterval: TimeInterval = 600
    
    override init() {
        super.init()
        print("[WeatherRepository]: init")
        Preferences.fixSwappedDefaultCoordinates()
        NotificationCenter.default.addObserver(self, selector: #selector(preferencesDidChange), name: .didChangeWidgetPreferences, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(systemDidWake), name: NSWorkspace.didWakeNotification, object: nil)
        locationProvider.onAuthorizationGranted = { [weak self] in
            self?.preferencesDidChange()
        }
        startMonitoringNetwork()
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true, block: { [weak self] _ in
            self?.refresh(force: false)
        })
        /// Let the system coalesce this (hourly) wake-up with other timers.
        timer?.tolerance = 60
        refresh(force: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
		timer?.invalidate()
        retryWorkItem?.cancel()
        currentTask?.cancel()
        stopMonitoringNetwork()
        completionBlock = nil
        print("[WeatherRepository]: deinit")
    }
    
    public func set(completionBlock: @escaping WeatherCompletion) {
        self.completionBlock = completionBlock
    }
    
    public func printDescription() {
        print("\t- [WeatherRepository]: Location services enabled: \(CLLocationManager.locationServicesEnabled())")
    }
    
    @objc private func preferencesDidChange() {
        retryCount = 0
        refresh(force: true)
    }
    
    @objc private func systemDidWake() {
        retryCount = 0
        refresh(force: false)
    }
    
    private func startMonitoringNetwork() {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let reachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }
        guard let reachability = reachability else {
            return
        }
        var flags = SCNetworkReachabilityFlags()
        if SCNetworkReachabilityGetFlags(reachability, &flags) {
            isNetworkAvailable = WeatherRepository.isReachable(flags)
        }
        /// The callback holds the box (retained by SystemConfiguration), the box holds the repository weakly.
        let box = WeakRepositoryBox(self)
        var context = SCNetworkReachabilityContext(
            version: 0,
            info: Unmanaged.passUnretained(box).toOpaque(),
            retain: { UnsafeRawPointer(Unmanaged<WeakRepositoryBox>.fromOpaque($0).retain().toOpaque()) },
            release: { Unmanaged<WeakRepositoryBox>.fromOpaque($0).release() },
            copyDescription: nil
        )
        let callback: SCNetworkReachabilityCallBack = { _, flags, info in
            guard let info = info else {
                return
            }
            let box = Unmanaged<WeakRepositoryBox>.fromOpaque(info).takeUnretainedValue()
            box.repository?.networkAvailabilityDidChange(WeatherRepository.isReachable(flags))
        }
        guard SCNetworkReachabilitySetCallback(reachability, callback, &context),
              SCNetworkReachabilitySetDispatchQueue(reachability, .main) else {
            SCNetworkReachabilitySetCallback(reachability, nil, nil)
            return
        }
        self.reachability = reachability
    }
    
    private func stopMonitoringNetwork() {
        guard let reachability = reachability else {
            return
        }
        SCNetworkReachabilitySetDispatchQueue(reachability, nil)
        SCNetworkReachabilitySetCallback(reachability, nil, nil)
        self.reachability = nil
    }
    
    private static func isReachable(_ flags: SCNetworkReachabilityFlags) -> Bool {
        guard flags.contains(.reachable) else {
            return false
        }
        guard flags.contains(.connectionRequired) else {
            return true
        }
        let canConnectAutomatically = flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
        return canConnectAutomatically && !flags.contains(.interventionRequired)
    }
    
    private func networkAvailabilityDidChange(_ isAvailable: Bool) {
        let wasAvailable = isNetworkAvailable
        isNetworkAvailable = isAvailable
        if !isAvailable {
            /// Pointless to retry while offline.
            retryWorkItem?.cancel()
            retryWorkItem = nil
        } else if !wasAvailable, needsRefresh {
            print("[WeatherRepository]: Network is back, refreshing")
            retryCount = 0
            refresh(force: true)
        }
    }
    
    /// - parameter force: if `false`, the request is skipped when one is already in flight or when data is still fresh.
    private func refresh(force: Bool) {
        if !force {
            if currentTask?.state == .running {
                return
            }
            if !needsRefresh, let last = lastSuccessfulUpdate, Date().timeIntervalSince(last) < minimumRefreshInterval {
                print("[WeatherRepository]: Data is still fresh, skipping refresh")
                return
            }
        }
        retryWorkItem?.cancel()
        retryWorkItem = nil
        guard isNetworkAvailable else {
            /// Don't hit the network while offline: `networkAvailabilityDidChange(_:)` will refresh once it's back.
            print("[WeatherRepository]: Network unavailable, will refresh once it's back")
            currentTask?.cancel()
            needsRefresh = true
            return
        }
        /// The lookup in flight reads preferences when it ends, so it already covers this refresh.
        guard !isResolvingLocation else {
            return
        }
        resolveLocation { [weak self] location, cityName in
            self?.fetchCurrentCondition(for: location, cityName: cityName)
        }
    }

    /// Calls `completion` (on main queue) with the place to show the weather for:
    /// 1. the location from macOS Location Services, if Pock is allowed to use it;
    /// 2. otherwise the city picked in preferences (the pane only offers the picker in this case);
    /// 3. if no city was ever picked, an approximate location from the IP address.
    private func resolveLocation(_ completion: @escaping (CLLocation, String) -> Void) {
        isResolvingLocation = true
        locationProvider.requestLocation { [weak self] location in
            guard let self = self else {
                return
            }
            if let location = location {
                self.placeName(for: location) { name in
                    self.didResolveLocation(detectedName: name)
                    completion(location, name)
                }
                return
            }
            let pickedCity = {
                self.didResolveLocation(detectedName: nil)
                completion(CLLocation(latitude: Preferences[.lat], longitude: Preferences[.lng]), Preferences[.city_name])
            }
            guard !Preferences.hasPickedCity else {
                pickedCity()
                return
            }
            WeatherRepository.approximateLocation { result in
                guard let (location, name) = result else {
                    pickedCity()
                    return
                }
                self.didResolveLocation(detectedName: nil)
                completion(location, name)
            }
        }
    }

    private func didResolveLocation(detectedName: String?) {
        isResolvingLocation = false
        guard Preferences.detectedCityName != detectedName else {
            return
        }
        Preferences.detectedCityName = detectedName
        NotificationCenter.default.post(name: .didChangeLocationStatus, object: nil)
    }

    /// Reverse geocodes `location`. The last result is reused while the Mac stays within 5 km.
    private func placeName(for location: CLLocation, _ completion: @escaping (String) -> Void) {
        if let last = lastPlace, last.location.distance(from: location) < 5000 {
            completion(last.name)
            return
        }
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            let placemark = placemarks?.first
            guard let name = placemark?.locality ?? placemark?.subAdministrativeArea ?? placemark?.name else {
                completion("Current location")
                return
            }
            self?.lastPlace = (location, name)
            completion(name)
        }
    }

    /// City-level location from the IP address (https://www.geojs.io, free, no key). Can be hundreds of km off on mobile networks.
    private static func approximateLocation(_ completion: @escaping ((CLLocation, String)?) -> Void) {
        struct Response: Decodable {
            let city: String?
            let latitude: String
            let longitude: String
        }
        let url = URL(string: "https://get.geojs.io/v1/ip/geo.json")!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        URLSession.shared.dataTask(with: request) { data, _, _ in
            var result: (CLLocation, String)?
            if let data = data,
               let response = try? JSONDecoder().decode(Response.self, from: data),
               let lat = CLLocationDegrees(response.latitude), let lng = CLLocationDegrees(response.longitude) {
                result = (CLLocation(latitude: lat, longitude: lng), response.city ?? "Current location")
            }
            DispatchQueue.main.async {
                completion(result)
            }
        }.resume()
    }
    
    private func fetchCurrentCondition(for location: CLLocation, cityName: String) {
        print("[WeahterRepository]: Fetching data for: \(cityName)")
        /// Only one request at a time (e.g. wake + preferences change).
        currentTask?.cancel()
        currentTask = WeatherService().currentConditions(for: location.coordinate, cityName: cityName, result: { [weak self] data in
            DispatchQueue.main.async { [weak self, data] in
                guard let data = data else {
					self?.completionBlock?(nil)
                    return
				}
                if data.weather.temp <= -999 {
                    self?.needsRefresh = true
                    self?.scheduleRetry()
                } else {
                    self?.didFetchSuccessfully()
                }
                self?.completionBlock?(data)
			}
        })
    }
    
    private func didFetchSuccessfully() {
        retryWorkItem?.cancel()
        retryWorkItem = nil
        needsRefresh = false
        retryCount = 0
        lastSuccessfulUpdate = Date()
        /// Next regular refresh one full interval after this one (avoids a second fetch shortly after a wake/preferences refresh).
        timer?.fireDate = Date().addingTimeInterval(refreshInterval)
    }
    
    private func scheduleRetry() {
        retryWorkItem?.cancel()
        retryWorkItem = nil
        guard isNetworkAvailable else {
            /// `networkAvailabilityDidChange(_:)` will refresh once the network is back.
            return
        }
        guard retryCount < maxRetryCount else {
            print("[WeatherRepository]: Too many failures, waiting for next regular refresh")
            return
        }
        let delay = retryInterval * pow(2, Double(retryCount))
        retryCount += 1
        let workItem = DispatchWorkItem { [weak self] in
            self?.refresh(force: true)
        }
        retryWorkItem = workItem
        print("[WeatherRepository]: Will retry in \(Int(delay))s")
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

}

/// One-shot lookup through macOS Location Services, with a timeout.
/// Fails unless Pock is allowed in System Settings › Privacy & Security › Location Services.
private final class LocationProvider: NSObject, CLLocationManagerDelegate {

    /// Called when access is granted after a failed lookup, so that the weather can switch to the real location.
    var onAuthorizationGranted: (() -> Void)?

    private let manager = CLLocationManager()
    private var completion: ((CLLocation?) -> Void)?
    private var timeoutWorkItem: DispatchWorkItem?
    private var lastLookupFailed: Bool = false

    override init() {
        super.init()
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.delegate = self
    }

    /// `completion` is called once, on main queue.
    func requestLocation(timeout: TimeInterval = 15, _ completion: @escaping (CLLocation?) -> Void) {
        let status = CLLocationManager.authorizationStatus()
        guard CLLocationManager.locationServicesEnabled(), status != .denied, status != .restricted else {
            print("[LocationProvider]: Location Services not available (status: \(status.rawValue))")
            lastLookupFailed = true
            completion(nil)
            return
        }
        self.completion = completion
        let workItem = DispatchWorkItem { [weak self] in
            print("[LocationProvider]: Timed out")
            self?.finish(nil)
        }
        timeoutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: workItem)
        /// Asks for permission first, if not determined yet.
        manager.requestLocation()
    }

    private func finish(_ location: CLLocation?) {
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
        lastLookupFailed = location == nil
        let completion = self.completion
        self.completion = nil
        completion?(location)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        finish(locations.last)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        /// Transient: sent right away on a cold start, the fix usually follows a couple of seconds later (the timeout covers the rest).
        if (error as? CLError)?.code == .locationUnknown {
            return
        }
        print("[LocationProvider]: Failed: \(error.localizedDescription)")
        finish(nil)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorizedAlways, lastLookupFailed, completion == nil else {
            return
        }
        lastLookupFailed = false
        onAuthorizationGranted?()
    }

}

/// Weak reference to a `WeatherRepository`, handed to the reachability callback.
private final class WeakRepositoryBox {
    weak var repository: WeatherRepository?
    init(_ repository: WeatherRepository) {
        self.repository = repository
    }
}
