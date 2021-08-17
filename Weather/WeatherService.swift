//
//  WeatherService.swift
//  Weather
//
//  Created by Pierluigi Galdi on 20/06/21.
//  Copyright © 2021 Pierluigi Galdi. All rights reserved.
//

import Foundation
import CoreLocation
import AppKit

struct Weather: Codable {
    let name: String
    let temp: Double
    let icon: String
    let description: String
    var temperature: String {
        guard temp > -999 else {
            return "Unknown information"
        }
        let units: String = Preferences[.units]
        switch units {
        case "celsius":
            let converted = (temp - 32) * (5/9)
            return "\(Int(converted))°"
        default:
            return "\(Int(temp))°"
        }
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
    
    // https://weather.navalia.app/weather?lat=52.37&lon=4.88&units=celsius
    // https://weather.navalia.app/condition?lat=52.37&lon=4.88&units=celsius&name=Dam
    
    func currentConditions(for coordinate: CLLocationCoordinate2D, cityName: String, result: @escaping (WeatherData?) -> Void) {
        let urlString = "https://weather.navalia.app/condition?lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&units=fahrenheit&name=\(cityName)"
        guard let escaped = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: escaped) else {
            print("[WeatherService]: Invalid URL: \(urlString)")
            result(nil)
            return
        }
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        let session = URLSession.shared.dataTask(with: request) { [result] data, response, error in
            print("[WeatherService]: \((response as? HTTPURLResponse)?.statusCode ?? -999)")
            guard error == nil, let data = data else {
                let name: String = Preferences[.city_name]
                let data = WeatherData(
                    metadata: .init(error: nil, code: -999),
                    weather: Weather(
                        name: name,
                        temp: -999,
                        icon: NSImage.touchBarSearchTemplateName,
                        description: "Unknown information"
                    )
                )
                result(data)
                return
            }
            do {
                let weather = try JSONDecoder().decode(WeatherData.self, from: data)
                result(weather)
            } catch {
                let name: String = Preferences[.city_name]
                let data = WeatherData(
                    metadata: .init(error: nil, code: -999),
                    weather: Weather(
                        name: name,
                        temp: -999,
                        icon: NSImage.touchBarSearchTemplateName,
                        description: "Unknown information"
                    )
                )
                result(data)
            }
        }
        session.resume()
    }
    
}
