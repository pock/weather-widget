//
//  WeatherRepository.swift
//  Weather
//
//  Created by Pierluigi Galdi on 20/05/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import CoreLocation

struct City: Codable {
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
    
    override init() {
        super.init()
        print("[WeatherRepository]: init")
        NotificationCenter.default.addObserver(self, selector: #selector(updateCurrentCondition), name: .didChangeWidgetPreferences, object: nil)
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true, block: { [weak self] _ in
            self?.updateCurrentCondition()
        })
        timer?.fire()
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
        let cityName: String = Preferences[.city_name]
        let lat: CLLocationDegrees = Preferences[.lat]
        let lng: CLLocationDegrees = Preferences[.lng]
        fetchCurrentCondition(for: CLLocation(latitude: lat, longitude: lng), cityName: cityName)
    }
    
    private func fetchCurrentCondition(for location: CLLocation, cityName: String) {
        print("[WeahterRepository]: Fetching data for: \(cityName)")
        WeatherService().currentConditions(for: location.coordinate, cityName: cityName, result: { [weak self] data in
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
