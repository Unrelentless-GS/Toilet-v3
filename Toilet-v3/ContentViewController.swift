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

//    internal var totalTimeString: String = "" {
//        didSet {
//            totalTime.stringValue = totalTimeString
//        }
//    }

    internal var desc1: [String] = ["Loading...", "00"] {
        didSet {
            updateDescription()
        }
    }

//    internal var data: PieChartModel? {
//        didSet {
//            pieGraph.data = data
//        }
//    }

    internal var desc2: [String] = ["Loading...", "00"] {
        didSet {
            updateDescription()
        }
    }

    internal var desc3: [String] = ["Loading...", "00"] {
        didSet {
            updateDescription()
        }
    }

    internal var desc4: [String] = ["Loading...", "00"] {
        didSet {
            updateDescription()
        }
    }

//    internal var data2: PieChartModel? {
//        didSet {
//            pieGraph2.data = data2
//        }
//    }

    internal var barData: BarGraphModel? {
        didSet {
            guard BarSegement(rawValue: segmentedControl.selectedSegment) == .hourly else { return }
            barGraph.data = barData!
        }
    }

    internal var wasFree: Bool = false
    internal var isFree: Bool = false {
        didSet {
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

    private var state = false
    weak var dataManager: DataManager?

    override func viewDidLoad() {
        super.viewDidLoad()

//        motionCallback = { [unowned self] percentage in
//            guard let percent = percentage?.roundTo(places: 1) else {
//                self.percentLabel.stringValue = ""
//                return
//            }
//            self.percentLabel.stringValue = "\(percent)%"
//        }

//        pieGraph.number = 1
//        pieGraph2.number = 2
//        pieGraph.motionCallback = motionCallback
//        pieGraph2.motionCallback = motionCallback

        barGraph.segment = .hourly

        notifyCheckBox.state = NSControl.StateValue(rawValue: 0)

        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.versionLabel.stringValue = "v\(version)"
        }

        prettify()
//        gestures()
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        barData = dataManager?.barData(for: BarSegement(rawValue: segmentedControl.selectedSegment)!)

        updateDescription()
        updateCharts()

//        totalTime.stringValue = totalTimeString
    }

    private func prettify() {
//        spacerView.wantsLayer = true
        spacerView2.wantsLayer = true
//        spacerView.layer?.backgroundColor = spacerColour.cgColor
        spacerView2.layer?.backgroundColor = spacerColour.cgColor

        descriptionLabel1.wantsLayer = true
        descriptionLabel1.backgroundColor = offlineColour
        descriptionLabel1.layer?.cornerRadius = 3
        descriptionLabel1.textColor = .black

        descriptionLabel2.wantsLayer = true
        descriptionLabel2.backgroundColor = offlineColour
        descriptionLabel2.layer?.cornerRadius = 3
        descriptionLabel2.textColor = .black

        descriptionLabel3.wantsLayer = true
        descriptionLabel3.backgroundColor = offlineColour
        descriptionLabel3.layer?.cornerRadius = 3
        descriptionLabel3.textColor = .black

        descriptionLabel4.wantsLayer = true
        descriptionLabel4.backgroundColor = offlineColour
        descriptionLabel4.layer?.cornerRadius = 3
        descriptionLabel4.textColor = .black
    }

//    private func gestures() {
//        let gesture1 = NSClickGestureRecognizer(target: self, action: #selector(expandPies))
//        let gesture2 = NSClickGestureRecognizer(target: self, action: #selector(expandBar))
//
//        gesture1.numberOfClicksRequired = 1
//        gesture2.numberOfClicksRequired = 1
//
//        pieExpandView.addGestureRecognizer(gesture1)
//        barExpandView.addGestureRecognizer(gesture2)
//    }
//
//    @objc private func expandPies() {
//        let state = pieHeightConstraint.constant == 0
//        NSAnimationContext.beginGrouping()
//        NSAnimationContext.current().duration = 0.4
//        NSAnimationContext.current().timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseInEaseOut)
//        pieHeightConstraint.animator().constant = !state ? 0 : 250
//        pieImageView.animator().rotate(byDegrees: state ? -90.0 : 90.0)
//        NSAnimationContext.endGrouping()
//    }
//
//    @objc private func expandBar() {
//        let state = barHeightConstraint.constant == 0
//        NSAnimationContext.beginGrouping()
//        NSAnimationContext.current().duration = 0.4
//        NSAnimationContext.current().timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseInEaseOut)
//        barHeightConstraint.animator().constant = state ? 260 : 0
//        barImageView.animator().rotate(byDegrees: state ? -90.0 : 90.0)
//        segmentedControl.animator().isHidden = !state
//        NSAnimationContext.endGrouping()
//    }

    internal func updateDescription() {
        descriptionLabel1.stringValue = desc1[0]
        descriptionLabel2.stringValue = desc2[0]
        descriptionLabel3.stringValue = desc3[0]

        timeAmount1.stringValue = desc1[1]
        timeAmount2.stringValue = desc2[1]
        timeAmount3.stringValue = desc3[1]

        descriptionLabel1.backgroundColor = colour(forState: desc1[0]).withAlphaComponent(0.8)
        descriptionLabel2.backgroundColor = colour(forState: desc2[0]).withAlphaComponent(0.8)
        descriptionLabel3.backgroundColor = colour(forState: desc3[0]).withAlphaComponent(0.8)
    }

    internal func updateCharts() {
//        pieGraph.data = data
//        pieGraph2.data = data2
        barGraph.data = barData
    }

    @IBAction func terminateHandler(_ sender: NSButton) {
        NSApp.terminate(sender)
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
    @IBAction func toiletDidChange(_ sender: NSSegmentedControl) {
        print(sender.indexOfSelectedItem)
    }


    @IBAction func didChange(_ sender: NSSegmentedControl) {
        let segment = BarSegement(rawValue: sender.selectedSegment)
        barGraph.segment = segment!
        barGraph.data = dataManager?.barData(for: segment!)
    }
}

extension Double {
    func roundTo(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
