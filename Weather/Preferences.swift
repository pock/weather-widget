//
//  Preferences.swift
//  Weather
//
//  Created by Pierluigi Galdi on 20/06/21.
//  Copyright © 2021 Pierluigi Galdi. All rights reserved.
//

import Foundation
import CoreLocation

internal extension NSNotification.Name {
    static let didChangeWidgetPreferences = NSNotification.Name("didChangeWidgetPreferences")
    static let didChangeWidgetLayout = NSNotification.Name("didChangeWidgetLayout")
}

internal enum TemperatureUnits: String, CaseIterable {
    case celsius, fahrenheit
}

internal struct Preferences {
    internal enum Keys: String {
        case country_name
        case city_name
        case lat
        case lng
        case units
        case show_description
    }
    static subscript<T>(_ key: Keys) -> T {
        get {
            guard let value = UserDefaults.standard.value(forKey: key.rawValue) as? T else {
                switch key {
                case .country_name:
                    return "Netherlands" as! T
                case .city_name:
                    return "Amsterdam" as! T
                case .lat:
                    return CLLocationDegrees(4.91) as! T
                case .lng:
                    return CLLocationDegrees(52.35) as! T
                case .units:
                    return "celsius" as! T
                case .show_description:
                    return true as! T
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
        Preferences[.country_name] = "Netherlands"
        Preferences[.city_name] = "Amsterdam"
        Preferences[.lat] = CLLocationDegrees(4.91)
        Preferences[.lng] = CLLocationDegrees(52.35)
        Preferences[.units] = "celsius"
        Preferences[.show_description] = true
    }
}
