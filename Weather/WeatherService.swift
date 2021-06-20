//
//  WeatherService.swift
//  Weather
//
//  Created by Pierluigi Galdi on 20/06/21.
//  Copyright © 2021 Pierluigi Galdi. All rights reserved.
//

import Foundation
import CoreLocation

struct WeatherData: Codable {
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

internal class WeatherService {
    
    // https://api.openweathermap.org/data/2.5/weather?lat=52.37&lon=4.88&appid=6fb995ebbeb649828d41be2e962f31e6&units=metric
    
    func currentConditions(for coordinate: CLLocationCoordinate2D, result: @escaping (WeatherData?) -> Void) {
        let apiKey = "6fb995ebbeb649828d41be2e962f31e6"
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&appid=\(apiKey)&units=metric"
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
