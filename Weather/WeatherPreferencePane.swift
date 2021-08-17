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
    @IBOutlet private weak var countryNamePopUpButton: NSPopUpButton!
    @IBOutlet private weak var cityNamePopUpButton: NSPopUpButton!
    @IBOutlet private weak var confirmNewLocationButton: NSButton!
    @IBOutlet private weak var temperatureUnitsSegmentedControl: NSSegmentedControl!
    @IBOutlet private weak var showDescriptionButton: NSButton!
    
    /// Data
    private var countries: [String: [City]] = [:]
    private var selectedCity: City?
    
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
        prepareCitiesList()
        prepareTemperatureUnitsControl()
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
        case confirmNewLocationButton:
            if let city = selectedCity {
                Preferences[.country_name] = city.country
                Preferences[.city_name] = city.name
                Preferences[.lat] = CLLocationDegrees(city.lat)
                Preferences[.lng] = CLLocationDegrees(city.lng)
                print("[WeatherPreferencePane]: Successfully saved new location: `\(city)`")
            } else {
                print("[WeatherPreferencePane]: Invalid city!")
                return
            }
            notificationName = .didChangeWidgetPreferences
        case temperatureUnitsSegmentedControl:
            Preferences[.units] = TemperatureUnits.allCases[temperatureUnitsSegmentedControl.selectedSegment].rawValue
            notificationName = .didChangeWidgetLayout
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
    
    @IBAction private func popUpButtonSelectionDidChange(_ sender: Any?) {
        guard let popUpButton = sender as? NSPopUpButton else {
            return
        }
        switch popUpButton {
        case countryNamePopUpButton:
            countryNamePopUpButton.title = popUpButton.titleOfSelectedItem ?? "Select country…"
            updateCityNamePopUpButtonItems(for: popUpButton.titleOfSelectedItem)
            selectedCity = countries[countryNamePopUpButton.title]?.first
        case cityNamePopUpButton:
            cityNamePopUpButton.title = popUpButton.titleOfSelectedItem ?? "Select city…"
            selectedCity = countries[countryNamePopUpButton.title]?.first(where: { $0.name == popUpButton.titleOfSelectedItem })
        default:
            return
        }
    }
    
    private func updateCityNamePopUpButtonItems(for countryName: String?) {
        guard let countryName = countryName else {
            print("[WeatherPreferencePane]: Invalid country code")
            return
        }
        print("[WeatherPreferencePane]: Loading cities for: \(countryName)")
        cityNamePopUpButton.isEnabled = false
        cityNamePopUpButton.title = "Loading cities…"
        DispatchQueue.global().async { [weak self] in
            if let self = self {
                let cities = self.countries[countryName] ?? []
                let sortedCities = cities.map({ $0.name }).sorted(by: { $0 < $1 })
                DispatchQueue.main.async { [weak self] in
                    if let self = self {
                        self.cityNamePopUpButton.removeAllItems()
                        self.cityNamePopUpButton.addItems(withTitles: sortedCities)
                        if let preferred = self.selectedCity?.name, sortedCities.contains(preferred) {
                            self.cityNamePopUpButton.title = preferred
                        } else {
                            if let first = sortedCities.first {
                                self.cityNamePopUpButton.selectItem(withTitle: first)
                            } else {
                                self.cityNamePopUpButton.selectItem(at: 0)
                            }
                        }
                        self.cityNamePopUpButton.isEnabled = true
                        self.confirmNewLocationButton.isEnabled = true
                    }
                }
            }
        }
    }
    
    private func startLoadingPopUpButtons() {
        countryNamePopUpButton.isEnabled = false
        countryNamePopUpButton.title = "Loading countries…"
        cityNamePopUpButton.isEnabled = false
        cityNamePopUpButton.title = "Loading cities…"
        confirmNewLocationButton.isEnabled = false
    }
    
    private func stopLoadingCountryPopUpButtons() {
        DispatchQueue.main.async { [weak self] in
            self?.countryNamePopUpButton.isEnabled = true
            self?.countryNamePopUpButton.title = self?.selectedCity?.country ?? "Select country"
        }
    }
    
    private func prepareCitiesList() {
        /// Invalidate controls
        startLoadingPopUpButtons()
        /// Load cities
        DispatchQueue.global().async { [weak self] in
            guard let self = self else {
                return
            }
            defer {
                self.stopLoadingCountryPopUpButtons()
            }
            if let fileURL = Bundle(for: Self.self).url(forResource:"cities", withExtension: "csv") {
                do {
                    let data = try String(contentsOfFile: fileURL.path)
                    var sortedCountries: [String] = []
                    var cities: [City] = []
                    for line in data.components(separatedBy: "\n") {
                        // [0] name, [1] lat, [2] lng, [3] country
                        let cityData = line.components(separatedBy: ",")
                        guard cityData.count >= 4 else {
                            continue
                        }
                        let name = cityData[0]
                        let lat = cityData[1]
                        let lng = cityData[2]
                        let country = cityData[3]
                        cities.append(City(name: name, country: country, lat: lat, lng: lng))
                    }
                    let countryName: String = Preferences[.country_name]
                    let cityName: String = Preferences[.city_name]
                    for city in cities {
                        if self.countries[city.country] != nil {
                            self.countries[city.country]?.append(city)
                        } else {
                            sortedCountries.append(city.country)
                            self.countries[city.country] = [city]
                        }
                        if city.country == countryName && city.name == cityName {
                            self.selectedCity = city
                        }
                    }
                    sortedCountries = sortedCountries.sorted(by: { $0 < $1 })
                    DispatchQueue.main.async {
                        self.countryNamePopUpButton.removeAllItems()
                        self.countryNamePopUpButton.addItems(withTitles: sortedCountries)
                        self.updateCityNamePopUpButtonItems(for: self.selectedCity?.country)
                        print("[WeatherPreferencePane][cities]: Loaded \(self.countries.count) countries")
                    }
                } catch {
                    print("[WeatherPreferencePane][cities]: Error: \(error.localizedDescription)")
                }
            } else {
                print("[WeatherPreferencePane][cities]: No such file URL.")
            }
        }
    }
    
}
