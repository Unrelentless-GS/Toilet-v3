//
//  ContentViewController.swift
//  Toilet-v3
//
//  Created by Pavel Boryseiko on 24/4/17.
//  Copyright © 2017 GRIDSTONE. All rights reserved.
//

import Cocoa

internal class ContentViewController: NSViewController {

    @IBOutlet weak var descriptionLabel: NSTextField!
    @IBOutlet weak var descriptionLabel2: NSTextField!
    @IBOutlet weak var terminateButton: NSButton!

    @IBOutlet weak var pieGraph: PieGraph!
    @IBOutlet weak var pieGraph2: PieGraph!
    @IBOutlet weak var barGraph: BarGraph!

    @IBOutlet weak var pieImageView: NSImageView!
    @IBOutlet weak var barImageView: NSImageView!

    @IBOutlet weak var pieHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var barHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var pieExpandView: NSView!
    @IBOutlet weak var barExpandView: NSView!
    @IBOutlet weak var legend1Colour: NSTextField!
    @IBOutlet weak var legend2Colour: NSTextField!
    @IBOutlet weak var legend3Colour: NSTextField!

    @IBOutlet weak var spacerView: NSView!
    @IBOutlet weak var spacerView2: NSView!
    @IBOutlet weak var totalTime: NSTextField!
    @IBOutlet weak var percentLabel: NSTextField!
    @IBOutlet weak var notifyCheckBox: NSButton!
    
    @IBOutlet weak var versionLabel: NSTextField!

    private var state = false

    internal var totalTimeString: String = "" {
        didSet {
            totalTime.stringValue = totalTimeString
        }
    }

    internal var desc: String = "Loading..." {
        didSet {
            descriptionLabel.stringValue = desc
        }
    }
    internal var data: PieChartModel? {
        didSet {
            pieGraph.data = data
        }
    }

    internal var desc2: String = "Loading..." {
        didSet {
            descriptionLabel2.stringValue = desc2
        }
    }

    internal var data2: PieChartModel? {
        didSet {
            pieGraph2.data = data2
        }
    }

    internal var barData: BarGraphModel? {
        didSet {
            barGraph.data = barData!
        }
    }

    internal var wasFree: Bool = false
    internal var isFree: Bool = false {
        didSet {
            if isFree == false { notifyCheckBox.isHidden = false }
            defer { wasFree = isFree }
            if isFree == true, wasFree == false, notifyCheckBox.state == 1 {
                notifyCallback?()
                notifyCheckBox.state = 0
                notifyCheckBox.isHidden = true
            }
            if isFree == true { self.notifyCheckBox.isHidden = true }
        }
    }

    internal var motionCallback: ((Double?) -> ())?
    internal var notifyCallback: (() -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()

//        legend1Colour.drawsBackground = true
//        legend1Colour.wantsLayer = true
//        legend1Colour.backgroundColor = vacantColour
//        legend1Colour.layer?.cornerRadius = 2
//
//        legend2Colour.drawsBackground = true
//        legend2Colour.wantsLayer = true
//        legend2Colour.backgroundColor = occupiedColour
//        legend2Colour.layer?.cornerRadius = 2
//
//        legend3Colour.drawsBackground = true
//        legend3Colour.wantsLayer = true
//        legend3Colour.backgroundColor = offlineColour
//        legend3Colour.layer?.cornerRadius = 2

        motionCallback = { [unowned self] percentage in
            guard let percent = percentage?.roundTo(places: 1) else {
                self.percentLabel.stringValue = ""
                return
            }
            self.percentLabel.stringValue = "\(percent)%"
        }

        pieGraph.number = 1
        pieGraph2.number = 2
        pieGraph.motionCallback = motionCallback
        pieGraph2.motionCallback = motionCallback

        spacerView.wantsLayer = true
        spacerView2.wantsLayer = true
        spacerView.layer?.backgroundColor = spacerColour.cgColor
        spacerView2.layer?.backgroundColor = spacerColour.cgColor

        notifyCheckBox.state = 0

        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.versionLabel.stringValue = "v\(version)"
        }

        gestures()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        updateDescription()
        updateCharts()

        totalTime.stringValue = totalTimeString
    }

    private func gestures() {
        let gesture1 = NSClickGestureRecognizer(target: self, action: #selector(expandPies))
        let gesture2 = NSClickGestureRecognizer(target: self, action: #selector(expandBar))

        gesture1.numberOfClicksRequired = 1
        gesture2.numberOfClicksRequired = 1

        pieExpandView.addGestureRecognizer(gesture1)
        barExpandView.addGestureRecognizer(gesture2)
    }

    @objc private func expandPies() {
        let state = pieHeightConstraint.constant == 0
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0.4
        NSAnimationContext.current().timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseInEaseOut)
        pieHeightConstraint.animator().constant = !state ? 0 : 250
        pieImageView.animator().rotate(byDegrees: state ? -90.0 : 90.0)
        NSAnimationContext.endGrouping()
    }

    @objc private func expandBar() {
        let state = barHeightConstraint.constant == 0
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0.4
        NSAnimationContext.current().timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseInEaseOut)
        barHeightConstraint.animator().constant = !state ? 0 : 200
        barImageView.animator().rotate(byDegrees: state ? -90.0 : 90.0)
        NSAnimationContext.endGrouping()
    }

    internal func updateDescription() {
        descriptionLabel.stringValue = desc
        descriptionLabel2.stringValue = desc2
    }

    internal func updateCharts() {
        pieGraph.data = data
        pieGraph2.data = data2
        barGraph.data = barData!
    }

    @IBAction func terminateHandler(_ sender: NSButton) {
        NSApp.terminate(sender)
    }
}

extension Double {
    func roundTo(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
