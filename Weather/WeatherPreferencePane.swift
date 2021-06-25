//
//  WeatherPreferencePane.swift
//  Weather
//
//  Created by Pierluigi Galdi on 20/06/21.
//  Copyright © 2021 Pierluigi Galdi. All rights reserved.
//

import Cocoa
import PockKit

class WeatherPreferencePane: NSViewController, PKWidgetPreference {
        
    static var nibName: NSNib.Name = "WeatherPreferencePane"
    
    /// UI Elements
    @IBOutlet private weak var latitudeTextField: NSTextField!
    @IBOutlet private weak var longitudeTextField: NSTextField!
    @IBOutlet private weak var confirmNewCoordinateButton: NSButton!
    @IBOutlet private weak var retrieveFromCurrentLocationButton: NSButton!
    @IBOutlet private weak var retrieveFromCurrentLocationSpinner: NSProgressIndicator!
    @IBOutlet private weak var temperatureUnitsSegmentedControl: NSSegmentedControl!
    @IBOutlet private weak var showDescriptionButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        retrieveFromCurrentLocationSpinner.stopAnimation(nil)
        prepareTemperatureUnitsControl()
        updateTextFieldLabels()
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
    
    private func updateTextFieldLabels() {
        let latitude: CLLocationDegrees = Preferences[.latitude]
        let longitude: CLLocationDegrees = Preferences[.longitude]
        latitudeTextField.stringValue = ""
        longitudeTextField.stringValue = ""
        latitudeTextField.placeholderString = latitude.description
        longitudeTextField.placeholderString = longitude.description
    }
    
    private func updateTemperatureUnitsControlState() {
        let currentUnits: String = Preferences[.units]
        if let units = TemperatureUnits(rawValue: currentUnits), let index = TemperatureUnits.allCases.firstIndex(of: units) {
            temperatureUnitsSegmentedControl.selectedSegment = index
        }
    }
    
    private func updateCheckboxStates() {
        showDescriptionButton.state = Preferences[.show_description] ? .on : .off
    }
    
    @IBAction private func didChangePreferences(_ sender: Any?) {
        guard let control = sender as? NSControl else {
            return
        }
        let notificationName: NSNotification.Name?
        switch control {
        case confirmNewCoordinateButton:
            if let lat = Double(latitudeTextField.stringValue), let lng = Double(longitudeTextField.stringValue) {
                Preferences[.latitude] = lat
                Preferences[.longitude] = lng
                updateTextFieldLabels()
            }
            notificationName = .didChangeWidgetPreferences
        case retrieveFromCurrentLocationButton:
            retrieveCoordinateFromCurrentLocation()
            return
        case temperatureUnitsSegmentedControl:
            Preferences[.units] = TemperatureUnits.allCases[temperatureUnitsSegmentedControl.selectedSegment].rawValue
            notificationName = .didChangeWidgetPreferences
        case showDescriptionButton:
            Preferences[.show_description] = showDescriptionButton.state == .on
            notificationName = .didChangeWidgetLayout
        default:
            return
        }
        if let name = notificationName {
            NotificationCenter.default.post(name: name, object: nil)
        }
    }
    
}

extension WeatherPreferencePane: CLLocationManagerDelegate {
    
    @objc private func retrieveCoordinateFromCurrentLocation() {
        retrieveFromCurrentLocationButton.isEnabled = false
        retrieveFromCurrentLocationButton.title = "Searching…"
        retrieveFromCurrentLocationSpinner.startAnimation(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [weak self] in
            let manager = CLLocationManager()
            manager.delegate = self
            if #available(macOS 11.0, *) {
                manager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: "Retrieve coordinate from current location")
            } else {
                manager.requestWhenInUseAuthorization()
            }
            manager.requestLocation()
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let last = locations.last {
            Preferences[.latitude] = last.coordinate.latitude
            Preferences[.longitude] = last.coordinate.longitude
            updateTextFieldLabels()
            NotificationCenter.default.post(name: .didChangeWidgetPreferences, object: nil)
        }
        retrieveFromCurrentLocationButton.isEnabled = true
        retrieveFromCurrentLocationButton.title = "Retrieve coordinate from current location"
        retrieveFromCurrentLocationSpinner.stopAnimation(nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        updateTextFieldLabels()
        retrieveFromCurrentLocationButton.isEnabled = true
        retrieveFromCurrentLocationButton.title = "Retrieve coordinate from current location"
        retrieveFromCurrentLocationSpinner.stopAnimation(nil)
    }
    
}
