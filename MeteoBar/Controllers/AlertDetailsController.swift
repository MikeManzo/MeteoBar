//
//  AlertDetails.swift
//  MeteoBar
//
//  Created by Mike Manzo on 3/15/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Cocoa

class AlertDetailsController: NSViewController {

    @IBOutlet weak var alertImage: NSImageView!
    @IBOutlet weak var alertHeadline: NSTextField!
    @IBOutlet weak var alertDetails: NSTextView!
    @IBOutlet weak var agencyImage: NSImageView!
    
    private var alert: MeteoWeatherAlert?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
    }

    override func viewWillAppear() {
        if alert != nil {
            DispatchQueue.main.async { [unowned self] in
                
                self.alertHeadline.stringValue  = self.alert!.headline
                self.alertDetails.string        = self.alert!.detail
                
                switch self.alert!.severity {
                case .extreme, .severe:
                    self.alertImage.image = NSImage(named: "warning-red.png")
                case .minor, .moderate:
                    self.alertImage.image = NSImage(named: "warning-yellow.png")
                case .unknown:
                    log.warning("Unkown alert passed")
                }
                
                guard let model = theDelegate?.theBridge?.weatherModel else {
                    log.warning("Weather model is nil")
                    return
                }
                switch model {
                case is MeteoUSWeather:
                    self.agencyImage.image = NSImage(named: "NWSLogo.png")
                default:
                    self.agencyImage.image = NSImage(named: "NSadvanced")
                }
            }
        }
    }
    
    func update(alert: MeteoWeatherAlert) {
        self.alert = alert
    }
}

///
/// Extension to return a new controller for each sensor popup window
///
///
/// - Throws:  Nothing
/// - Returns: A new SolisSensorPopupController
///
extension AlertDetailsController {
    static func newController() -> AlertDetailsController {
        return AlertDetailsController(nibName: NSNib.Name("AlertDetails"), bundle: nil)
    }
}
