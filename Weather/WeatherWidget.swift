//
//  WeatherWidget.swift
//  Weather
//
//  Created by Pierluigi Galdi on 20/05/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//


import Foundation
import AppKit
        
class WeatherWidget: PockWidget {
    var identifier: NSTouchBarItem.Identifier = NSTouchBarItem.Identifier(rawValue: "WeatherWidget")
    var customizationLabel: String = "Weather"
    var view: NSView!

    required init() {
        self.view = NSButton(title: "Weather", target: self, action: #selector(printMessage))
    }
    
    @objc private func printMessage() {
        print("[WeatherWidget]: Hello, World!")
    }
        
}
