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
		set(title: 	  "Weather", 	   speed: 0)
		set(subtitle: "Fetching data", speed: 0)
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
    public static var identifier: NSTouchBarItem.Identifier = NSTouchBarItem.Identifier(rawValue: "WeatherWidget")
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
    }
    
    deinit {
		print("[WeatherWidget]: Deinit")
		weatherRepository = nil
        view = nil
		data = nil
    }
    
    private func update() {
        guard let view = view as? WeatherView, let data = data else {
            return
        }
        let locality = data.locality ?? "Unknown location"
        
        let titleWidth    = (locality as NSString).size(withAttributes: view.titleView?.textFontAttributes).width
        let subtitleWidth = (data.condition as NSString?)?.size(withAttributes: view.subtitleView?.textFontAttributes).width ?? 0
        view.maxWidth = max(titleWidth, subtitleWidth)
        
        view.set(title:    data.locality,  speed: 0)
        view.set(subtitle: data.condition, speed: 0)
        if let iconUrl = data.iconUrl {
            view.set(image: NSImage(contentsOf: iconUrl))
        }
        view.updateConstraints()
        view.layoutSubtreeIfNeeded()
    }
    
    @objc private func printDescription() {
        weatherRepository?.printDescription()
    }
        
}
