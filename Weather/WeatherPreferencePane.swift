//
//  WeatherPreferencePane.swift
//  Weather
//
//  Created by Pierluigi Galdi on 20/06/21.
//  Copyright © 2021 Pierluigi Galdi. All rights reserved.
//

import Cocoa
import CoreLocation
import PockKit
import Combine

class WeatherPreferencePane: NSViewController, PKWidgetPreference {
    static var nibName: NSNib.Name = "WeatherPreferencePane"
    /// UI Elements
    @IBOutlet private weak var temperatureUnitsSegmentedControl: NSSegmentedControl!
    @IBOutlet private weak var City_NeighbourhoodSegmentedControl: NSSegmentedControl!
    @IBOutlet private weak var UpdateFrequencySegmentedControl: NSSegmentedControl!
    @IBOutlet private weak var IconStyleSegmentedControl: NSSegmentedControl!
    @IBOutlet private weak var DisplaySegmentedControl: NSSegmentedControl!
    @IBOutlet private weak var OpenWeatherButton: NSButton!
    @IBOutlet private weak var FutureForecastButton: NSButton!
    @IBOutlet private weak var MoreInfoButton: NSButton!
    deinit {
        print("[WeatherPreferencePane]: Deinit")
    }
    
    func reset() {
        print("[WeatherPreferencePane]: Will reset preferences to default values…")
        Preferences.reset()
        NotificationCenter.default.post(name: .didChangeWidgetPreferences, object: nil)
        NotificationCenter.default.post(name: .didChangeWidgetLayout, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareTemperatureUnitsControl()
        prepareCity_NeighbourhoodSegmentedControl()
        prepareIconStyleSegmentedControl()
        prepareUpdateFrequencySegmentedControl()
        prepareDisplaySegmentedControl()
        updateCheckboxStates()
    }
    
    private func prepareTemperatureUnitsControl() {
        let control = temperatureUnitsSegmentedControl
        var selected = 0
        control?.segmentCount = TemperatureUnits.allCases.count
        for (index,option) in TemperatureUnits.allCases.enumerated() {
            selected = option.rawValue == Preferences[.units] ? index : 0
            control?.setLabel(option.rawValue.capitalized, forSegment: index)
        }
        control?.selectedSegment = selected
    }
    private func prepareCity_NeighbourhoodSegmentedControl() {
        let control = City_NeighbourhoodSegmentedControl
        var selected = 0
        control?.segmentCount = Title_Options.allCases.count
        for (index,option) in Title_Options.allCases.enumerated() {
            selected = option.rawValue == Preferences[.Title] ? index : 0
            control?.setLabel(option.rawValue.capitalized, forSegment: index)
        }
        control?.selectedSegment = selected
    }
    
    private func prepareUpdateFrequencySegmentedControl() {
        let control = UpdateFrequencySegmentedControl
        var selected = 0
        control?.segmentCount = UpdateFrequencyOptions.allCases.count
        for (index,option) in UpdateFrequencyOptions.allCases.enumerated() {
            selected = option.rawValue == Preferences[.UpdateFrequency] ? index : 0
            control?.setLabel(option.rawValue.capitalized, forSegment: index)
        }
        control?.selectedSegment = selected
    }
    
    private func prepareIconStyleSegmentedControl() {
        let control = IconStyleSegmentedControl
        var selected = 1
        control?.segmentCount = IconStyleOptions.allCases.count
        for (index,option) in IconStyleOptions.allCases.enumerated() {
            selected = option.rawValue == Preferences[.IconStyle] ? index : 1
            control?.setLabel(option.rawValue.capitalized, forSegment: index)
        }
        control?.selectedSegment = selected
    }
    private func prepareDisplaySegmentedControl() {
        let control = DisplaySegmentedControl
        var selected = 0
        control?.segmentCount = DisplayOptions.allCases.count
        for (index,option) in DisplayOptions.allCases.enumerated() {
            selected = option.rawValue == Preferences[.Display] ? index : 0
            control?.setLabel(option.rawValue.capitalized, forSegment: index)
        }
        control?.selectedSegment = selected
    }
    private func updateTemperatureUnitsControlState() {
        let currentUnits: String = Preferences[.units]
        if let units = TemperatureUnits(rawValue: currentUnits), let index = TemperatureUnits.allCases.firstIndex(of: units) {
            temperatureUnitsSegmentedControl.selectedSegment = index
        }
    }
    private func updateTitle() {
        let currentUnits: String = Preferences[.Title]
        if let Title = TemperatureUnits(rawValue: currentUnits), let index = TemperatureUnits.allCases.firstIndex(of: Title) {
            temperatureUnitsSegmentedControl.selectedSegment = index
        }
    }
    
    private func updateCheckboxStates() {
            FutureForecastButton.state = Preferences[.FutureForecast] ? .on : .off
            MoreInfoButton.state = Preferences[.MoreInfo] ? .on : .off
            OpenWeatherButton.state = Preferences[.OpenWeather] ? .on : .off
        }
    @IBAction private func didChangePreferences(_ sender: Any?) {
        guard let control = sender as? NSControl else {
            return
        }
        let notificationName: NSNotification.Name?
        switch control {
        case City_NeighbourhoodSegmentedControl:
            Preferences[.Title] = Title_Options.allCases[City_NeighbourhoodSegmentedControl.selectedSegment].rawValue
            notificationName = .didChangeWidgetPreferences
        case temperatureUnitsSegmentedControl:
            Preferences[.units] = TemperatureUnits.allCases[temperatureUnitsSegmentedControl.selectedSegment].rawValue
            notificationName = .didChangeWidgetPreferences
        case UpdateFrequencySegmentedControl:
            Preferences[.UpdateFrequency] = UpdateFrequencyOptions.allCases[UpdateFrequencySegmentedControl.selectedSegment].rawValue
            notificationName = .didChangeWidgetPreferences
        case MoreInfoButton:
            Day = 0
            Info = 0
            Preferences[.MoreInfo] = MoreInfoButton.state == .on
            notificationName = .didChangeWidgetLayout
        case OpenWeatherButton:
            Preferences[.OpenWeather] = OpenWeatherButton.state == .on
            notificationName = .didChangeWidgetLayout
        case FutureForecastButton:
            Preferences[.FutureForecast] = FutureForecastButton.state == .on
            Day = 0
            Info = 0
            notificationName = .didChangeWidgetPreferences
        case IconStyleSegmentedControl:
            Preferences[.IconStyle] = IconStyleOptions.allCases[IconStyleSegmentedControl.selectedSegment].rawValue
            notificationName = .didChangeWidgetPreferences
        case DisplaySegmentedControl:
            Preferences[.Display] = DisplayOptions.allCases[DisplaySegmentedControl.selectedSegment].rawValue
            notificationName = .didChangeWidgetPreferences
        default:
            return
        }
        if let name = notificationName {
            NotificationCenter.default.post(name: name, object: nil)
        }
    }
    
    
}
