//
//  TodayViewController.swift
//  iQ2P-Today
//
//  Created by Pavel Boryseiko on 2/5/17.
//  Copyright © 2017 GRIDSTONE. All rights reserved.
//

import Cocoa
import NotificationCenter

let vacantColour = NSColor(red: 102/255.0, green: 255/255.0, blue: 178/255.0, alpha: 1.0)
let occupiedColour = NSColor(red: 146/255.0, green: 109/255.0, blue: 69/255.0, alpha: 1.0)
let offlineColour = NSColor(red: 255/255.0, green: 102/255.0, blue: 102/255.0, alpha: 1.0)
let spacerColour = NSColor(red: 144/255.0, green: 144/255.0, blue: 144/255.0, alpha: 1.0)

class TodayViewController: NSViewController, NCWidgetProviding {

    @IBOutlet weak var toiletLabel: NSTextField!
    @IBOutlet weak var toilet2Label: NSTextField!

    @IBOutlet weak var toiletStatusLabel: NSTextField!
    @IBOutlet weak var toilet2StatusLabel: NSTextField!

    override var nibName: NSNib.Name? {
        return NSNib.Name(rawValue: "TodayViewController")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        toiletLabel.textColor = .black
        toilet2Label.textColor = .black

        toiletStatusLabel.wantsLayer = true
        toiletStatusLabel.backgroundColor = offlineColour
        toiletStatusLabel.layer?.cornerRadius = 3

        toilet2StatusLabel.wantsLayer = true
        toilet2StatusLabel.backgroundColor = offlineColour
        toilet2StatusLabel.layer?.cornerRadius = 3
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        let _ = updateStatus()
    }

    private func colour(forState status: String) -> NSColor {
        switch status {
        case "Vacant":
            return vacantColour
        case "Occupied":
            return occupiedColour
        case "Offline":
            return offlineColour
        default:
            return NSColor.black
        }
    }

    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        if updateStatus() {
            completionHandler(.newData)
        } else {
            completionHandler(.noData)
        }
    }

    private func updateStatus() -> Bool {

        let defaults = UserDefaults(suiteName: "au.com.gridstone.q2p")

        // Check for null value before setting
        if let toilet1Value = defaults!.string(forKey: "Toilet1") {
            toiletStatusLabel.backgroundColor = colour(forState: toilet1Value)
            toiletStatusLabel.stringValue = toilet1Value

            if let toilet2Value = defaults!.string(forKey: "Toilet2") {
                toilet2StatusLabel.backgroundColor = colour(forState: toilet2Value)
                toilet2StatusLabel.stringValue = toilet2Value
            }
            return true
        } else {
            return false
        }
    }
}
