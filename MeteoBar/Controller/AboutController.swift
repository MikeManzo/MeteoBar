//
//  AboutController.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/13/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Cocoa

/// Controller for the "About Box"
class AboutController: NSViewController {

    /// Outlets
    @IBOutlet weak var tableAttribution: NSTableView!
    @IBOutlet weak var appName: NSTextField!
    @IBOutlet weak var appCopyright: NSTextField!
    @IBOutlet weak var appVersion: NSTextField!
    @IBOutlet weak var appImageView: NSImageView!
    
    /// Custom variables
    let tableViewData = [
        ["copyImage": "books.png",
         "copyType": "Library",
         "invertable": "yes",
         "copyName": "Alamo Fire: Elegant Networkign in Swift",
         "copyHolder": "Alamofire Software Foundation",
         "copyURL": "https://github.com/Alamofire/Alamofire"
        ],
        ["copyImage": "AppIcon",
         "copyType": "Icon",
         "invertable": "no",
         "copyName": "Application Icon: A meteobridge transmitting to a terminal",
         "copyHolder": "Iconfu",
         "copyURL": "https://iconfu.com"
        ],
        ["copyImage": "books.png",
         "copyType": "Icon",
         "invertable": "yes",
         "copyName": "Library Icon: A group of books representing a library",
         "copyHolder": "Freepick",
         "copyURL": "https://www.flaticon.com/free-icon/living-room-books-group_47536#term=library&page=1&position=23"
        ],
        ["copyImage": "books.png",
         "copyType": "Library",
         "invertable": "yes",
         "copyName": "Preferences: Flexible User Preferences",
         "copyHolder": "Sindre Sorhus",
         "copyURL": "https://github.com/sindresorhus/Preferences"
        ],
        ["copyImage": "books.png",
         "copyType": "Library",
         "invertable": "yes",
         "copyName": "Swifty Beaver: Colorful, flexible, lightweight logging for Swift 2, Swift 3 & Swift 4",
         "copyHolder": "Swifty Beaver",
         "copyURL": "https://swiftybeaver.com"
        ],
        ["copyImage": "books.png",
         "copyType": "Library",
         "invertable": "yes",
         "copyName": "SwiftyJSON",
         "copyHolder": "SwiftyJSON",
         "copyURL": "https://github.com/SwiftyJSON/SwiftyJSON"
        ],
        ["copyImage": "books.png",
         "copyType": "Library",
         "invertable": "yes",
         "copyName": "SwiftyUserDefaults: Modern Swift API for NSUserDefaults",
         "copyHolder": "Radek Pietruszewski",
         "copyURL": "https://github.com/radex/SwiftyUserDefaults"
        ]
    ]
        
    /// Standard override for viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Extract info from the pList and populate the stubs in the About.xib file
        if let appInfo = Bundle.main.infoDictionary {
            appName.stringValue         = appInfo["CFBundleName"] as? String ?? "Error"                                                 // Add App Name from pList
            appCopyright.stringValue    = appInfo["NSHumanReadableCopyright"] as? String ?? "Error"                                     // Add Copyright
            appVersion.stringValue      = "Version: " + Bundle.applicationVersionNumber + "(" + Bundle.applicationBuildNumber + ")"     // Add Version
            appImageView.image          = NSApp.applicationIconImage                                                                    // Add Application Icon
        }
    }
}

// MARK: - Extension
extension AboutController: NSTableViewDataSource, NSTableViewDelegate {
    /// Returns the number of rows that shoudl be displayed by the table
    ///
    /// - Parameter tableView: the TableView in question
    /// - Returns: the number of rows to display
    func numberOfRows(in tableView: NSTableView) -> Int {
        return tableViewData.count
    }
    
    /// TableView override to format the contents of our cutom row (Note the custom AttributionTableCellView class)
    ///
    /// - Parameters:
    ///   - tableView: the TableView in-question
    ///   - tableColumn: the column to format
    ///   - row: the row to format
    /// - Returns: the fully formatted view (AttributionTableCellView in our case)
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let result = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "defaultRow"), owner: self) as? AttributionTableCellView else {
            log.warning("Cannot display attribution table")
            return nil
        }
        
        if !tableViewData.isEmpty {
            guard let icon = NSImage(named: NSImage.Name(tableViewData[row]["copyImage"]!)) else {
                log.warning("Cannot display image: ", tableViewData[row]["copyImage"] ?? "N/A")
                return nil
            }
            
            result.imgView.image                    = (theDelegate.isVibrantMode() && tableViewData[row]["invertable"] == "yes") ? icon.filter(filter: "CIColorInvert") : icon
            result.imageView?.toolTip               = tableViewData[row]["copyType"] ?? "Error"
            result.summaryTextField.stringValue     = tableViewData[row]["copyName"] ?? "Error"
            result.descriptionTextField.stringValue = tableViewData[row]["copyHolder"] ?? "Error"
            result.hyperLink.href                   = tableViewData[row]["copyURL"] ?? "Error"
        }
        
        return result
    }
}

/// Custom view for our row (1 Icon and three text fields)
class AttributionTableCellView: NSTableCellView {
    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var summaryTextField: NSTextField!
    @IBOutlet weak var descriptionTextField: NSTextField!
    @IBOutlet weak var hyperLink: QJHyperTextField!
}
