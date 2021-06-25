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
    
    override init() {
        super.init()
        print("[WeatherRepository]: init")
		timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true, block: { [weak self] _ in
            self?.updateCurrentCondition()
		})
		timer?.fire()
        NotificationCenter.default.addObserver(self, selector: #selector(updateCurrentCondition), name: .didChangeWidgetPreferences, object: nil)
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
        print("\t- [WeatherRepository]: Location services enabled: \(CLLocationManager.locationServicesEnabled())")
    }
    
    @objc private func updateCurrentCondition() {
        // Amsterdam
        // let location = CLLocation(latitude: 52.37403, longitude: 4.88969)
        let lat: CLLocationDegrees = Preferences[.latitude]
        let lng: CLLocationDegrees = Preferences[.longitude]
        let location = CLLocation(latitude: lat, longitude: lng)
        fetchCurrentCondition(for: location)
    }
    
    private func fetchCurrentCondition(for location: CLLocation?) {
        guard let coordinate = location?.coordinate else {
            return
        }
        WeatherService().currentConditions(for: coordinate, result: { [weak self] data in
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
