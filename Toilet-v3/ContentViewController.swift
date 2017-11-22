//
//  ContentViewController.swift
//  Toilet-v3
//
//  Created by Pavel Boryseiko on 24/4/17.
//  Copyright © 2017 GRIDSTONE. All rights reserved.
//

import Cocoa

enum BarSegement: Int {
    case hourly = 0
    case daily = 1
    case monthly = 2
}

internal class ContentViewController: NSViewController {

    @IBOutlet weak var descriptionLabel1: NSTextField!
    @IBOutlet weak var descriptionLabel2: NSTextField!
    @IBOutlet weak var descriptionLabel3: NSTextField!
    @IBOutlet weak var descriptionLabel4: NSTextField!

    @IBOutlet weak var timeAmount1: NSTextField!
    @IBOutlet weak var timeAmount2: NSTextField!
    @IBOutlet weak var timeAmount3: NSTextField!
    @IBOutlet weak var timeAmount4: NSTextField!

    @IBOutlet weak var segmentedControl: NSSegmentedControl!
    @IBOutlet weak var segmentedControlToilets: NSSegmentedControl!
    @IBOutlet weak var terminateButton: NSButton!

    @IBOutlet weak var barGraph: BarGraph!
    @IBOutlet weak var barImageView: NSImageView!
    @IBOutlet weak var barHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var barExpandView: NSView!

    @IBOutlet weak var spacerView2: NSView!
    @IBOutlet weak var notifyCheckBox: NSButton!

    @IBOutlet weak var versionLabel: NSTextField!

    private lazy var descs = {
        return [
            descriptionLabel1,
            descriptionLabel2,
            descriptionLabel3,
            descriptionLabel4
        ]
    }()

    private lazy var timeAmount = {
        return [
            timeAmount1,
            timeAmount2,
            timeAmount3,
            timeAmount4
        ]
    }()

    internal var barData: BarGraphModel? {
        didSet {
            guard BarSegement(rawValue: segmentedControl.selectedSegment) == .hourly else { return }
            barGraph.data = barData!
        }
    }

    internal var wasFree: Bool = false
    internal var isFree: Bool = false {
        didSet {
            guard notifyCheckBox != nil else { return }
            if isFree == false { notifyCheckBox.isHidden = false }
            defer { wasFree = isFree }
            if isFree == true, wasFree == false, notifyCheckBox.state.rawValue == 1 {
                notifyCallback?()
                notifyCheckBox.state = NSControl.StateValue(rawValue: 0)
                notifyCheckBox.isHidden = true
            }
            if isFree == true { self.notifyCheckBox.isHidden = true }
        }
    }

    internal var motionCallback: ((Double?) -> ())?
    internal var notifyCallback: (() -> ())?

    weak internal var dataManager: DataManager?

    override func viewDidLoad() {
        super.viewDidLoad()

        barGraph.segment = .hourly
        barGraph.data = barData

        notifyCheckBox.state = NSControl.StateValue(rawValue: 0)

        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionLabel.stringValue = "v\(version)"
        }

        prettify()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        barData = dataManager?.barData(for: BarSegement(rawValue: segmentedControl.selectedSegment)!)
    }

    @IBAction func terminateHandler(_ sender: NSButton) {
        NSApp.terminate(sender)
    }

    @IBAction func toiletDidChange(_ sender: NSSegmentedControl) {
        print(sender.indexOfSelectedItem)
    }

    @IBAction func didChange(_ sender: NSSegmentedControl) {
        let segment = BarSegement(rawValue: sender.selectedSegment)
        barGraph.segment = segment!
        barGraph.data = dataManager?.barData(for: segment!)
    }

    internal func update(toilet: Toilet, with status: (status: String, time: String)) {
        descs[toilet.number-1]?.stringValue = status.status
        descs[toilet.number-1]?.backgroundColor = colour(forState: status.status).withAlphaComponent(0.8)
        timeAmount[toilet.number-1]?.stringValue = status.time

        barData = dataManager?.barData(for: BarSegement(rawValue: segmentedControl.selectedSegment)!)
    }

    private func prettify() {
        spacerView2.wantsLayer = true
        spacerView2.layer?.backgroundColor = spacerColour.cgColor

        for label in descs {
            label?.wantsLayer = true
            label?.backgroundColor = offlineColour
            label?.layer?.cornerRadius = 3
            label?.textColor = .black
        }
    }

    private func colour(forState state: String) -> NSColor {
        switch state {
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

}

extension Double {
    func roundTo(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
