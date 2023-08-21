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
class ImageTextFieldCell: NSTextFieldCell {
    var customImage: NSImage?
    
    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        super.drawInterior(withFrame: cellFrame, in: controlView)
        
        if let image = self.customImage {
            let imageFrame = NSRect(x: cellFrame.maxX - image.size.width - 5, y: cellFrame.minY + (cellFrame.height - image.size.height) / 2, width: image.size.width, height: image.size.height)
            image.draw(in: imageFrame)
        }
    }
}
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
            if Preferences[.MoreInfo] == true{
                if Info <= 0{
                    if Day <= 0{
                        Info = 7
                    }else{
                        Info = 6
                    }
                }else{
                    Info = Info - 1
                }
                DoubleTap = 0
                Wait = Wait + 1
                NotificationCenter.default.post(name: .didChangeWidgetPreferences, object: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    if Wait == 1{
                        Wait = 0
                        Info = 0
                        Day = 0
                        NotificationCenter.default.post(name: .didChangeWidgetPreferences, object: nil)
                    }else{ Wait = Wait - 1}
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if DoubleTap == 1 && Day == 0 && Info == 0{
                if Preferences[.OpenWeather] == true{
                    if ProcessInfo.processInfo.operatingSystemVersion.majorVersion > 12{
                        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Weather.app"))
                    }
                }
                DoubleTap = 0
            }else if DoubleTap == 1{
                Day = 0
                Info = 0
                NotificationCenter.default.post(name: .didChangeWidgetPreferences, object: nil)
                DoubleTap = 0
            }else if DoubleTap == 2{
                if Preferences[.FutureForecast] == true{
                    if Info >= 7 && Day <= 0 || Info >= 6 && Day >= 1 {
                        Info = 0
                    }else{
                        Info = Info + 1
                    }
                    print("DoubleTap!")
                    DoubleTap = 0
                    Wait = Wait + 1
                    NotificationCenter.default.post(name: .didChangeWidgetPreferences, object: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        if Wait == 1{
                            Wait = 0
                            Info = 0
                            Day = 0
                            NotificationCenter.default.post(name: .didChangeWidgetPreferences, object: nil)
                        }else{ Wait = Wait - 1}
                    }
                }
            }
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
            if Day >= 1 && Info == 7{
                Info = 6
            }else if Day == 0 && Info == 6{
                Info = 7
            }
            NotificationCenter.default.post(name: .didChangeWidgetPreferences, object: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if Wait == 1{
                    Wait = 0
                    Day = 0
                    Info = 0
                    NotificationCenter.default.post(name: .didChangeWidgetPreferences, object: nil)
                }else{ Wait = Wait - 1}
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
            if Day >= 1 && Info == 7{
                Info = 6
            }else if Day == 0 && Info == 6{
                Info = 7
            }
            NotificationCenter.default.post(name: .didChangeWidgetPreferences, object: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if Wait == 1{
                    Wait = 0
                    Day = 0
                    Info = 0
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
        public var label: NSTextField?
        public var widthConstraints: NSLayoutConstraint?
        public var size: CGFloat?
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
        widthConstraints?.isActive = false
        label?.removeFromSuperview()
        guard let view = view as? WeatherView, let data = data else {
            return
        }
        if Day == 0 && Info == 0{
            view.maxWidth = 120
        }else if Info >= 0{
            view.maxWidth = 300
        }else{
            view.maxWidth = 180
        }
        let locality = data.weather.name
        let displayValue: String = Preferences[.Display]
        switch displayValue {
            case "Icon Only":
            if !(Day == 0) || !(Info == 0){
                view.set(title: locality)
                if !(data.weather.temperature == "°"){
                    if Info >= 1{
                        view.set(subtitle: "\(data.weather.temperature) \(data.weather.description)")
                    }else{
                        view.set(subtitle: "\(data.weather.temperature), \(data.weather.description)")
                    }
                }else{
                    view.set(subtitle: data.weather.description)
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
            case "Icon and Temp":
                if !(Day == 0) || !(Info == 0){
                    view.set(title: locality)
                    if !(data.weather.temperature == "°"){
                        if Info >= 1{
                            view.set(subtitle: "\(data.weather.temperature) \(data.weather.description)")
                        }else{
                            view.set(subtitle: "\(data.weather.temperature), \(data.weather.description)")
                        }
                    }else{
                        view.set(subtitle: data.weather.description)
                    }
                    if let localIcon = Bundle(for: Self.self).image(forResource: data.weather.icon) {
                        view.set(image: localIcon)
                    } else if let systemIcon = NSImage(named: data.weather.icon) {
                        view.set(image: systemIcon)
                    }
                }else{
                    view.set(subtitle: nil)
                    view.set(title: nil)
                    if let localIcon = Bundle(for: Self.self).image(forResource: data.weather.icon) {
                        view.set(image: localIcon)
                    } else if let systemIcon = NSImage(named: data.weather.icon) {
                        view.set(image: systemIcon)
                    }
                    label = NSTextField(labelWithString: data.weather.temperature)
                    label?.textColor = .white
                    label?.backgroundColor = .clear
                    label?.font = NSFont.monospacedDigitSystemFont(ofSize: 25, weight: .ultraLight)
                    view.addSubview(label!)
                    label?.centerInSuperview(offset: CGPoint(x: -20, y:0))
                    label?.edgesToSuperview()
                    widthConstraints = view.widthAnchor.constraint(equalToConstant: view.imageView.frame.width + (label?.frame.width ?? 0) + 8)
                    widthConstraints?.isActive = true
                }
        case "Temp Only":
            if !(Day == 0) || !(Info == 0){
                view.set(title: locality)
                if !(data.weather.temperature == "°"){
                    if Info >= 1{
                        view.set(subtitle: "\(data.weather.temperature) \(data.weather.description)")
                    }else{
                        view.set(subtitle: "\(data.weather.temperature), \(data.weather.description)")
                    }
                }else{
                    view.set(subtitle: data.weather.description)
                }
                if let localIcon = Bundle(for: Self.self).image(forResource: data.weather.icon) {
                    view.set(image: localIcon)
                } else if let systemIcon = NSImage(named: data.weather.icon) {
                    view.set(image: systemIcon)
                }
            }else{
                view.set(subtitle: nil)
                view.set(title: nil)
                view.set(image: nil)
                label = NSTextField(labelWithString: data.weather.temperature)
                label?.textColor = .white
                label?.backgroundColor = .clear
                label?.font = NSFont.monospacedDigitSystemFont(ofSize: 25, weight: .ultraLight)
                view.addSubview(label!)
                label?.centerInSuperview(offset: CGPoint(x: -20, y:0))
                label?.edgesToSuperview()
                widthConstraints = view.widthAnchor.constraint(equalToConstant: (label?.frame.width ?? 0) + 8)
                widthConstraints?.isActive = true
            }
            case "Icon, Temp and Location":
                view.set(title: locality)
                view.set(subtitle: data.weather.temperature)
                if let localIcon = Bundle(for: Self.self).image(forResource: data.weather.icon) {
                    view.set(image: localIcon)
                } else if let systemIcon = NSImage(named: data.weather.icon) {
                    view.set(image: systemIcon)
                }
            default:
                view.set(title: locality)
                if !(data.weather.temperature == "°"){
                    if Info >= 1{
                        view.set(subtitle: "\(data.weather.temperature) \(data.weather.description)")
                    }else{
                        view.set(subtitle: "\(data.weather.temperature), \(data.weather.description)")
                    }
                }else{
                    view.set(subtitle: data.weather.description)
                }
                if let localIcon = Bundle(for: Self.self).image(forResource: data.weather.icon) {
                    view.set(image: localIcon)
                } else if let systemIcon = NSImage(named: data.weather.icon) {
                    view.set(image: systemIcon)
                }
        }
        view.updateConstraints()
        view.layoutSubtreeIfNeeded()
    }
    
    @objc private func printDescription() {
        weatherRepository?.printDescription()
    }
        
}
