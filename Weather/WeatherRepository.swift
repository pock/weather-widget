//
//  WeatherRepository.swift
//  Weather
//
//  Created by Pierluigi Galdi on 20/05/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import CoreLocation

class WeatherData: NSObject {
    public private(set) var locality:  String?
    public private(set) var condition: String?
    public private(set) var iconUrl:   URL?
    convenience init(locality: String?, condition: String?, iconUrl: URL?) {
        self.init()
        self.locality  = locality
        self.condition = condition
        self.iconUrl   = iconUrl
    }
}

class WeatherRepository: NSObject {
    
    typealias WeatherCompletion = (WeatherData?) -> Void
    
    /// Core
    private var timer:           Timer?
    private var completionBlock: WeatherCompletion?
    private var locationManager: CLLocationManager?
    
    override init() {
        super.init()
        print("[WeatherRepository]: init")
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true, block: { [weak self] _ in
            self?.startLocationManager()
        })
        timer?.fire()
    }
    
    deinit {
        timer           = nil
        completionBlock = nil
        locationManager = nil
        print("[WeatherRepository]: deinit")
    }
    
    private func startLocationManager() {
        if self.locationManager == nil {
            self.locationManager = CLLocationManager()
        }
        self.locationManager?.delegate = self
        self.locationManager?.desiredAccuracy = .leastNormalMagnitude
        self.locationManager?.distanceFilter  = .leastNormalMagnitude
        self.locationManager?.startUpdatingLocation()
    }
    
    private func stopLocationManager() {
        self.locationManager?.stopUpdatingLocation()
        self.locationManager?.delegate = nil
        self.locationManager = nil
    }
    
    public func set(completionBlock: @escaping WeatherCompletion) {
        self.completionBlock = completionBlock
    }
    
    public func printDescription() {
        print("\t- [WeatherRepository]: Location services enabled: \(CLLocationManager.locationServicesEnabled())")
    }
    
}

extension WeatherRepository: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        defer {
            self.stopLocationManager()
        }
//		/// Amsterdam
//		let _location = CLLocation(latitude: 52.37403, longitude: 4.88969)
//		self.fetchCurrentCondition(for: _location, locality: "Amsterdam")
		guard let location = locations.last else { return }
		CLGeocoder().reverseGeocodeLocation(location, completionHandler: { [weak self] placemarks, error in
			guard let placemark = placemarks?.first else {
				return
			}
			self?.fetchCurrentCondition(for: placemark.location, locality: placemark.locality)
		})
    }
    
    private func fetchCurrentCondition(for location: CLLocation?, locality: String?) {
        guard let coordinate = location?.coordinate else {
            return
        }
        WMWeatherStore.shared()?.currentConditions(for: coordinate, result: { [weak self, locality] data in
            guard let data = data else {
                self?.completionBlock?(nil)
                return
            }
            let condition = data.conditionLocalizedString
            let iconUrl   = data.imageSmallURL
            self?.completionBlock?(WeatherData(locality: locality, condition: condition, iconUrl: iconUrl))
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.stopLocationManager()
        print("[WeatherRepository]: Can't update location: \(error.localizedDescription)")
    }
}
