//
//  WeatherWidget.swift
//  Weather
//
//  Created by Pierluigi Galdi on 20/05/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation
import AppKit
import PockKit
public var Info = 0
public var Day = 0
public var DoubleTap = 0
public var Wait = 0
class WeatherView: PKDetailView {
    override func didLoad() {
        canScrollTitle = true
        canScrollSubtitle = true
        set(title: "Weather")
        set(subtitle: "Fetching data")
        set(image: NSImage(named: NSImage.touchBarSearchTemplateName))
        super.didLoad()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            NotificationCenter.default.post(name: .didChangeWidgetPreferences, object: nil)
        }
    }
    override func didTapHandler() {
        super.didLoad()
        DoubleTap = DoubleTap + 1
        var StoreDoubleTap = DoubleTap
        if DoubleTap >= 3{
            Info = Info - 1
            DoubleTap = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if DoubleTap == 1 && Day == 0{
                if Preferences[.OpenWeather] == true{
                    if ProcessInfo.processInfo.operatingSystemVersion.majorVersion > 12{
                        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Weather.app"))
                    }
                }
                DoubleTap = 0
            }else if DoubleTap == 1{
                Day = 0
                NotificationCenter.default.post(name: .didChangeWidgetPreferences, object: nil)
                DoubleTap = 0
            }else if DoubleTap == 2{
                Info = Info + 1
                print("DoubleTap!")
                DoubleTap = 0
            }
        print(Info)
        }
        return

    }
    override func didSwipeRightHandler() {
        if Preferences[.FutureForecast] == true{
            if Day == 0{
                Day = 10
            }else{
                Day = Day - 1
            }
            Wait = Wait + 1
            NotificationCenter.default.post(name: .didChangeWidgetPreferences, object: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if Wait == 1{
                    Day = 0
                    NotificationCenter.default.post(name: .didChangeWidgetPreferences, object: nil)
                }
            }
        }
    }
    override func didSwipeLeftHandler() {
        if Preferences[.FutureForecast] == true{
            if Day == 10{
                Day = 0
            }else{
                Day = Day + 1
            }
            Wait = Wait + 1
            NotificationCenter.default.post(name: .didChangeWidgetPreferences, object: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if Wait == 1{
                    Day = 0
                    NotificationCenter.default.post(name: .didChangeWidgetPreferences, object: nil)
                }
                Wait = Wait - 1
            }
        }
    }
}
public class WeatherWidget: PKWidget {
    public static var identifier: String = "WeatherWidget"
        public var customizationLabel: String = "Weather"
        public var view: NSView!
        private var weatherRepository: WeatherRepository? = WeatherRepository()
        private var data: WeatherData?

        required public init() {
            self.view = WeatherView(leftToRight: false)
            self.weatherRepository?.set(completionBlock: { [weak self] data in
                print("[WeatherWidget]: Updated weather data")
                self?.data = data
            self?.update()
        })
        NotificationCenter.default.addObserver(self, selector: #selector(update), name: .didChangeWidgetLayout, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("[WeatherWidget]: Deinit")
        weatherRepository = nil
        view = nil
        data = nil
    }
    
    @objc private func update() {
        guard let view = view as? WeatherView, let data = data else {
            return
        }
        if Day == 0{
            view.maxWidth = 120
        }else{
            view.maxWidth = 180
        }
        let locality = data.weather.name
        if Preferences[.ShowIconOnly] == false || !(Day == 0){
            view.set(title: locality)
            if Preferences[.show_description]{
                if !(data.weather.temperature == "°"){
                    view.set(subtitle: "\(data.weather.temperature), \(data.weather.description)")
                }else{
                    view.set(subtitle: data.weather.description)
                }
            } else {
                view.set(subtitle: data.weather.temperature)
            }
            if let localIcon = Bundle(for: Self.self).image(forResource: data.weather.icon) {
                view.set(image: localIcon)
            } else if let systemIcon = NSImage(named: data.weather.icon) {
                view.set(image: systemIcon)
            }
        }else{
            if let localIcon = Bundle(for: Self.self).image(forResource: data.weather.icon) {
                view.set(image: localIcon)
                view.set(subtitle:"")
                view.set(title:"")
            } else if let systemIcon = NSImage(named: data.weather.icon) {
                view.set(image: systemIcon)
                view.set(subtitle:"")
                view.set(title:"")
            }
        }
        
        view.updateConstraints()
        view.layoutSubtreeIfNeeded()
    }
    
    @objc private func printDescription() {
        weatherRepository?.printDescription()
    }
        
}
