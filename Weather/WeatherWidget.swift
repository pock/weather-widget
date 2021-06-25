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

class WeatherView: PKDetailView {
    override func didLoad() {
		canScrollSubtitle = true
		set(title: 	  "Weather", 	   speed: 0)
		set(subtitle: "Fetching data", speed: 4)
		set(image: NSImage(named: NSImage.touchBarSearchTemplateName))
        super.didLoad()
    }
    override func didTapHandler() {
        #if DEBUG
        print("[WeatherView]: Did tap WeatherView")
        #endif
    }
}

public class WeatherWidget: PKWidget {
    public static var identifier: String = "WeatherWidget"
    public var customizationLabel: String = "Weather"
    public var view: NSView!
    
    private lazy var weatherRepository: WeatherRepository? = WeatherRepository()
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
        guard let view = view as? WeatherView, let data = data, let condition = data.weather.condition else {
            return
        }
        view.maxWidth = 120
        let locality = data.weather.name
        view.set(title: locality, speed: 0)
        if Preferences[.show_description] {
            view.set(subtitle: "\(data.weather.temperature.formatted), \(condition.description)", speed: 4)
        } else {
            view.set(subtitle: data.weather.temperature.formatted)
        }
        view.set(image: Bundle(for: Self.self).image(forResource: condition.icon))
        view.updateConstraints()
        view.layoutSubtreeIfNeeded()
    }
    
    @objc private func printDescription() {
        weatherRepository?.printDescription()
    }
        
}
