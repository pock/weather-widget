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
            return "\(Int(converted.rounded()))°"
        default:
            return "\(Int(temp.rounded()))°"
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

/// Open-Meteo `/v1/forecast` response (only the fields we request).
/// https://open-meteo.com/en/docs
private struct OpenMeteoResponse: Decodable {
    struct Current: Decodable {
        let temperature_2m: Double
        let weather_code: Int
        let is_day: Int
    }
    let current: Current
}

internal class WeatherService {
    
    // https://api.open-meteo.com/v1/forecast?latitude=52.37&longitude=4.88&current=temperature_2m,weather_code,is_day&temperature_unit=fahrenheit
    
    /// Returns the started task, so that callers can cancel it (a cancelled task never calls `result`).
    @discardableResult
    func currentConditions(for coordinate: CLLocationCoordinate2D, cityName: String, result: @escaping (WeatherData?) -> Void) -> URLSessionDataTask? {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(coordinate.latitude)&longitude=\(coordinate.longitude)&current=temperature_2m,weather_code,is_day&temperature_unit=fahrenheit"
        guard let url = URL(string: urlString) else {
            print("[WeatherService]: Invalid URL: \(urlString)")
            result(nil)
            return nil
        }
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        let session = URLSession.shared.dataTask(with: request) { [result] data, response, error in
            if (error as? URLError)?.code == .cancelled {
                print("[WeatherService]: Request cancelled")
                return
            }
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -999
            print("[WeatherService]: \(statusCode)")
            guard error == nil, statusCode == 200, let data = data else {
                print("[WeatherService]: Request failed: \(error?.localizedDescription ?? "HTTP \(statusCode)")")
                result(Self.unknownWeatherData(cityName: cityName, error: error?.localizedDescription))
                return
            }
            do {
                let current = try JSONDecoder().decode(OpenMeteoResponse.self, from: data).current
                let condition = Self.condition(for: current.weather_code, isDay: current.is_day != 0)
                let weather = WeatherData(
                    metadata: .init(error: nil, code: statusCode),
                    weather: Weather(
                        name: cityName,
                        temp: current.temperature_2m,
                        icon: condition.icon,
                        description: condition.description
                    )
                )
                result(weather)
            } catch {
                print("[WeatherService]: Decoding error: \(error)")
                result(Self.unknownWeatherData(cityName: cityName, error: error.localizedDescription))
            }
        }
        session.resume()
        return session
    }
    
    private static func unknownWeatherData(cityName: String, error: String?) -> WeatherData {
        return WeatherData(
            metadata: .init(error: error, code: -999),
            weather: Weather(
                name: cityName,
                temp: -999,
                icon: NSImage.touchBarSearchTemplateName,
                description: "Unknown information"
            )
        )
    }
    
    /// Maps a WMO weather interpretation code (as returned by Open-Meteo) to one of the
    /// bundled OpenWeatherMap-style icons (`01d`…`50n`) and a short description.
    private static func condition(for code: Int, isDay: Bool) -> (icon: String, description: String) {
        let icon: String
        let description: String
        switch code {
        case 0:             icon = "01"; description = "Clear sky"
        case 1:             icon = "02"; description = "Mainly clear"
        case 2:             icon = "03"; description = "Partly cloudy"
        case 3:             icon = "04"; description = "Overcast"
        case 45, 48:        icon = "50"; description = "Fog"
        case 51, 53, 55:    icon = "09"; description = "Drizzle"
        case 56, 57:        icon = "09"; description = "Freezing drizzle"
        case 61, 63, 65:    icon = "10"; description = "Rain"
        case 66, 67:        icon = "13"; description = "Freezing rain"
        case 71, 73, 75:    icon = "13"; description = "Snow"
        case 77:            icon = "13"; description = "Snow grains"
        case 80, 81, 82:    icon = "09"; description = "Rain showers"
        case 85, 86:        icon = "13"; description = "Snow showers"
        case 95:            icon = "11"; description = "Thunderstorm"
        case 96, 99:        icon = "11"; description = "Thunderstorm with hail"
        default:            icon = "03"; description = "Unknown conditions"
        }
        return (icon + (isDay ? "d" : "n"), description)
    }
    
}
