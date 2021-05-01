//
//  WeatherRepository.swift
//  Weather
//
//  Created by Pierluigi Galdi on 20/05/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import CoreLocation

struct WeatherData {
    public private(set) var locality:  String?
    public private(set) var condition: String?
	public private(set) var temperature: String?
    public private(set) var iconUrl:   URL?
}

class WeatherRepository: NSObject {
    
    typealias WeatherCompletion = (WeatherData?) -> Void
    
    /// Core
	private weak var timer: Timer?
	private var completionBlock: WeatherCompletion?
    
    override init() {
        super.init()
        print("[WeatherRepository]: init")
		timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true, block: { [weak self] _ in
			// TODO: Retrieve location from user input (settings)
			/// Amsterdam
			let location = CLLocation(latitude: 52.37403, longitude: 4.88969)
			self?.fetchCurrentCondition(for: location, locality: "Amsterdam")
		})
		timer?.fire()
    }
    
    deinit {
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
    
    private func fetchCurrentCondition(for location: CLLocation?, locality: String?) {
        guard let coordinate = location?.coordinate else {
            return
        }
        WMWeatherStore.shared()?.currentConditions(for: coordinate, result: { [weak self, locality] data in
            guard let data = data else {
				DispatchQueue.main.async { [weak self] in
					self?.completionBlock?(nil)
				}
                return
            }
            let condition = data.conditionLocalizedString
			let temperature = data.temperatureStringBasedOnLocale
            let iconUrl   = data.imageSmallURL
			DispatchQueue.main.async { [weak self, locality, condition, iconUrl] in
				self?.completionBlock?(WeatherData(locality: locality, condition: condition, temperature: temperature, iconUrl: iconUrl))
			}
        })
    }

}
