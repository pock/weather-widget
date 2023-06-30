//
//  WeatherRepository.swift
//  Weather
//
//  Created by Pierluigi Galdi on 20/05/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import CoreLocation
class WeatherRepository: NSObject {
    
    typealias WeatherCompletion = (WeatherData?) -> Void
    
    /// Core
    private weak var timer: Timer?
    private var completionBlock: WeatherCompletion?
    public var timers: Double?
    override init() {
        super.init()
        print("[WeatherRepository]: init")
        let locationManager = CLLocationManager()
        locationManager.requestAlwaysAuthorization()
        locationManager.startMonitoringSignificantLocationChanges()
        NotificationCenter.default.addObserver(self, selector: #selector(updateCurrentCondition), name: .didChangeWidgetPreferences, object: nil)
        if Preferences[.UpdateFrequency] == "Fifteen"{timers = 900} else if Preferences[.UpdateFrequency] == "Thirty"{timers = 1800} else{timers = 3600}
        timer = Timer.scheduledTimer(withTimeInterval:timers!, repeats: true, block: { [weak self] _ in
            self?.updateCurrentCondition()
        })
        timer?.fire()
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.updateCurrentCondition()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        timer?.invalidate()
        completionBlock = nil
        print("[WeatherRepository]: deinit")
    }
    
    public func set(completionBlock: @escaping WeatherCompletion) {
        self.completionBlock = completionBlock
    }
    
    public func printDescription() {
        print("\t- [WeatherRepository]: Location services enabled")
    }
    
    @objc private func updateCurrentCondition() {
        fetchCurrentCondition()
    }
    
    private func fetchCurrentCondition() {
        print("[WeahterRepository]: Fetching data for current loaction")
        WeatherService().currentConditions(result: { [weak self] data in
            DispatchQueue.main.async { [weak self, data] in
                guard let data = data else {
                    self?.completionBlock?(nil)
                    return
                }
                self?.completionBlock?(data)
            }
        })
    }

}
