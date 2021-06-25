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
    case imperial, metric
}

internal struct Preferences {
    internal enum Keys: String {
        case latitude
        case longitude
        case units
        case show_description
    }
    static subscript<T>(_ key: Keys) -> T {
        get {
            guard let value = UserDefaults.standard.value(forKey: key.rawValue) as? T else {
                switch key {
                case .latitude:
                    return CLLocationDegrees(52.37403) as! T
                case .longitude:
                    return CLLocationDegrees(4.88969) as! T
                case .units:
                    return "metric" as! T
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
}
