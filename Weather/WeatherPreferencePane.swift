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
    private var countries: [String: [City]] {
        return catalog?.countries ?? [:]
    }
    private var catalog: CitiesCatalog?
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
            /// Set before populating the city list (it's now filled synchronously and shows `selectedCity`).
            selectedCity = countries[countryNamePopUpButton.title]?.first
            updateCityNamePopUpButtonItems(for: popUpButton.titleOfSelectedItem)
        case cityNamePopUpButton:
            /// Resolve the city from the item itself: titles of cities sharing a name are disambiguated
            /// with their coordinates, so they can't be matched against `City.name`.
            guard let item = popUpButton.selectedItem, let city = item.representedObject as? City else {
                return
            }
            selectedCity = city
            cityNamePopUpButton.title = item.title
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
        /// City names are already sorted by `CitiesCatalog`, no need to go off the main thread.
        let entries = catalog?.cityMenuEntries[countryName] ?? []
        cityNamePopUpButton.removeAllItems()
        /// Pull-down buttons use the first item as their title and never show it in the menu,
        /// so add a placeholder title item to keep the first city (e.g. Adelaide, Brno) selectable.
        cityNamePopUpButton.addItem(withTitle: "")
        /// Items are added through the menu so that duplicate titles are never merged by `NSPopUpButton`;
        /// each item carries its `City` so the selection doesn't depend on the title.
        let menu = cityNamePopUpButton.menu
        for entry in entries {
            let item = NSMenuItem(title: entry.title, action: nil, keyEquivalent: "")
            item.representedObject = entry.city
            menu?.addItem(item)
        }
        if let preferred = selectedCity, let entry = entries.first(where: { $0.city == preferred }) {
            cityNamePopUpButton.title = entry.title
        } else if let first = entries.first {
            cityNamePopUpButton.title = first.title
            selectedCity = first.city
        } else {
            cityNamePopUpButton.title = "Select city…"
        }
        cityNamePopUpButton.isEnabled = true
        confirmNewLocationButton.isEnabled = true
    }
    
    private func startLoadingPopUpButtons() {
        countryNamePopUpButton.isEnabled = false
        countryNamePopUpButton.title = "Loading countries…"
        cityNamePopUpButton.isEnabled = false
        cityNamePopUpButton.title = "Loading cities…"
        confirmNewLocationButton.isEnabled = false
    }
    
    private func stopLoadingCountryPopUpButtons() {
        countryNamePopUpButton.isEnabled = true
        countryNamePopUpButton.title = selectedCity?.country ?? "Select country"
    }
    
    private func prepareCitiesList() {
        /// Invalidate controls
        startLoadingPopUpButtons()
        /// Load cities (parsed off the main thread the first time only, then cached)
        CitiesCatalog.load { [weak self] catalog in
            guard let self = self else {
                return
            }
            defer {
                self.stopLoadingCountryPopUpButtons()
            }
            guard let catalog = catalog else {
                return
            }
            self.catalog = catalog
            let countryName: String = Preferences[.country_name]
            let cityName: String = Preferences[.city_name]
            let lat: CLLocationDegrees = Preferences[.lat]
            let lng: CLLocationDegrees = Preferences[.lng]
            self.selectedCity = catalog.city(named: cityName, in: countryName, nearestTo: lat, lng)
            self.countryNamePopUpButton.removeAllItems()
            /// Placeholder title item for the pull-down button (see `updateCityNamePopUpButtonItems(for:)`).
            self.countryNamePopUpButton.addItem(withTitle: "")
            self.countryNamePopUpButton.addItems(withTitles: catalog.sortedCountries)
            self.updateCityNamePopUpButtonItems(for: self.selectedCity?.country)
            print("[WeatherPreferencePane][cities]: Loaded \(catalog.countries.count) countries")
        }
    }
    
}

/// Contents of `cities.csv`.
///
/// The file is parsed lazily, off the main thread, the first time the preference pane asks for it,
/// then kept in memory so that re-opening the pane doesn't parse it again.
private final class CitiesCatalog {
    
    /// Cities grouped by country, in file order.
    let countries: [String: [City]]
    /// City menu entries grouped by country, sorted by title.
    ///
    /// Names that appear more than once in the same country (e.g. "Albany, United States")
    /// get their coordinates appended, e.g. "Albany (42.65°, -73.76°)", so that every entry has a unique title.
    let cityMenuEntries: [String: [(title: String, city: City)]]
    /// Country names, sorted.
    let sortedCountries: [String]
    
    /// Only accessed on `queue`.
    private static var shared: CitiesCatalog?
    private static let queue = DispatchQueue(label: "WeatherWidget.CitiesCatalog", qos: .userInitiated)
    
    private init(countries: [String: [City]]) {
        self.countries = countries
        self.cityMenuEntries = countries.mapValues(CitiesCatalog.menuEntries(for:))
        self.sortedCountries = countries.keys.sorted(by: { $0 < $1 })
    }
    
    private static func menuEntries(for cities: [City]) -> [(title: String, city: City)] {
        var countByName: [String: Int] = [:]
        for city in cities {
            countByName[city.name, default: 0] += 1
        }
        var usedTitles: Set<String> = []
        var entries: [(title: String, city: City)] = []
        entries.reserveCapacity(cities.count)
        for city in cities {
            var title = city.name
            if countByName[city.name, default: 0] > 1 {
                let lat = Double(city.lat) ?? 0
                let lng = Double(city.lng) ?? 0
                title = String(format: "%@ (%.2f°, %.2f°)", city.name, lat, lng)
            }
            /// Safety net: never produce two identical titles (they would be merged by the pop-up button).
            var uniqueTitle = title
            var suffix = 2
            while usedTitles.contains(uniqueTitle) {
                uniqueTitle = "\(title) #\(suffix)"
                suffix += 1
            }
            usedTitles.insert(uniqueTitle)
            entries.append((title: uniqueTitle, city: city))
        }
        return entries.sorted(by: { $0.title < $1.title })
    }
    
    /// Returns the city with the given name in the given country; when several share that name,
    /// the one closest to the given coordinates.
    func city(named name: String, in country: String, nearestTo lat: CLLocationDegrees, _ lng: CLLocationDegrees) -> City? {
        let candidates = countries[country]?.filter({ $0.name == name }) ?? []
        guard candidates.count > 1 else {
            return candidates.first
        }
        func distance(_ city: City) -> Double {
            let dLat = (Double(city.lat) ?? .infinity) - lat
            var dLng = abs((Double(city.lng) ?? .infinity) - lng)
            if dLng > 180 { dLng = 360 - dLng }
            return dLat * dLat + dLng * dLng
        }
        return candidates.min(by: { distance($0) < distance($1) })
    }
    
    /// Calls `completion` on the main queue.
    static func load(completion: @escaping (CitiesCatalog?) -> Void) {
        queue.async {
            if shared == nil {
                shared = parse()
            }
            let catalog = shared
            DispatchQueue.main.async {
                completion(catalog)
            }
        }
    }
    
    private static func parse() -> CitiesCatalog? {
        guard let fileURL = Bundle(for: WeatherPreferencePane.self).url(forResource:"cities", withExtension: "csv") else {
            print("[WeatherPreferencePane][cities]: No such file URL.")
            return nil
        }
        do {
            let data = try String(contentsOfFile: fileURL.path)
            var countries: [String: [City]] = [:]
            for line in data.components(separatedBy: "\n") {
                // [0] name, [1] lat, [2] lng, [3] country, [4] population (unused)
                let cityData = line.components(separatedBy: ",")
                guard cityData.count >= 4 else {
                    continue
                }
                let city = City(name: cityData[0], country: cityData[3], lat: cityData[1], lng: cityData[2])
                countries[city.country, default: []].append(city)
            }
            return CitiesCatalog(countries: countries)
        } catch {
            print("[WeatherPreferencePane][cities]: Error: \(error.localizedDescription)")
            return nil
        }
    }
    
}
