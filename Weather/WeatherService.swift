//
//  WeatherService.swift
//  Weather
//
//  Created by Pierluigi Galdi on 20/06/21.
//  Copyright © 2021 Pierluigi Galdi. All rights reserved.
//

import Foundation
import CoreLocation

struct Weather: Codable {
    struct Info: Codable {
        let id: Int
        let status: String
        let description: String
        let icon: String
        private enum CodingKeys: String, CodingKey {
            case id, status = "main", description, icon
        }
    }
    struct Temperature: Codable {
        let value: Float
        var formatted: String {
            return "\(Int(value))°"
        }
        private enum CodingKeys: String, CodingKey {
            case value = "temp"
        }
    }
    let name: String
    let info: [Info]
    let temperature: Temperature
    var condition: Info? {
        return info.last
    }
    private enum CodingKeys: String, CodingKey {
        case name, info = "weather", temperature = "main"
    }
}

struct WeatherData: Codable {
    struct Metadata: Codable {
        let error: String?
        let code: Int
    }
    let metadata: Metadata
    let weather: Weather
    private enum CodingKeys: String, CodingKey {
        case weather = "data", metadata
    }
}

internal class WeatherService {
    
    // https://weather.navalia.app/weather?lat=52.37&lon=4.88&units=metric
    
    func currentConditions(for coordinate: CLLocationCoordinate2D, result: @escaping (WeatherData?) -> Void) {
        let units: String = Preferences[.units]
        let urlString = "https://weather.navalia.app/weather?lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&units=\(units)"
        guard let url = URL(string: urlString) else {
            result(nil)
            return
        }
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        let session = URLSession.shared.dataTask(with: request) { [result] data, response, error in
            guard error == nil, let data = data else {
                result(nil)
                return
            }
            result(try? JSONDecoder().decode(WeatherData.self, from: data))
        }
        session.resume()
    }
    
}
