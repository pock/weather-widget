//
//  Preferences.swift
//  Weather
//
//  Created by Pierluigi Galdi on 20/06/21.
//  Copyright © 2021 Pierluigi Galdi. All rights reserved.
//

import Foundation

internal extension NSNotification.Name {
    static let didChangeWidgetPreferences = NSNotification.Name("didChangeWidgetPreferences")
    static let didChangeWidgetLayout = NSNotification.Name("didChangeWidgetLayout")
}

internal enum TemperatureUnits: String, CaseIterable {
    case celsius, fahrenheit
}

internal enum Title_Options: String, CaseIterable {
    case Neighborhood, City, Address
}

internal enum UpdateFrequencyOptions: String, CaseIterable {
    case Fifteen, Thirty, Sixty
}

internal enum IconStyleOptions: String, CaseIterable {
    case Default, Outlined, Filled, Illustrated
}

internal struct Preferences {
    internal enum Keys: String {
        case country_name
        case city_name
        case units
        case show_description
        case Title
        case OpenWeather
        case IconStyle
        case FutureForecast
        case UpdateFrequency
        case ShowIconOnly
    }
    static subscript<T>(_ key: Keys) -> T {
        get {
            guard let value = UserDefaults.standard.value(forKey: key.rawValue) as? T else {
                switch key {
                case .OpenWeather:
                    return true as! T
                case .FutureForecast:
                    return true as! T
                case .country_name:
                    return "Canada" as! T
                case .city_name:
                    return "Montreal" as! T
                case .units:
                    return "celsius" as! T
                case .show_description:
                    return true as! T
                case .ShowIconOnly:
                    return false as! T
                case .UpdateFrequency:
                    return "Fifteen" as! T
                case .IconStyle:
                    return "Outlined" as! T
                case .Title:
                    return "Neighborhood" as! T
                }
                
            }
            return value
        }
        set {
            #if DEBUG
            print("[Weather] Will update preference: { '\(key.rawValue)': '\(newValue)' }")
            #endif
            UserDefaults.standard.setValue(newValue, forKey: key.rawValue)
        }
    }
    static func reset() {
        Preferences[.OpenWeather] = true
        Preferences[.FutureForecast] = true
        Preferences[.country_name] = "Canada"
        Preferences[.city_name] = "Montreal"
        Preferences[.units] = "celsius"
        Preferences[.show_description] = true
        Preferences[.ShowIconOnly] = false
        Preferences[.UpdateFrequency] = "Fifteen"
        Preferences[.Title] = "Neighborhood"
        Preferences[.IconStyle] = "Outlined"

    }
}
