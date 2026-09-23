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
        let cityName: String = Preferences[.city_name]
        let lat: CLLocationDegrees = Preferences[.lat]
        let lng: CLLocationDegrees = Preferences[.lng]
        fetchCurrentCondition(for: CLLocation(latitude: lat, longitude: lng), cityName: cityName)
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

/// Weak reference to a `WeatherRepository`, handed to the reachability callback.
private final class WeakRepositoryBox {
    weak var repository: WeatherRepository?
    init(_ repository: WeatherRepository) {
        self.repository = repository
    }
}
