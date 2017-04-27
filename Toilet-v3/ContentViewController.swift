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

    @IBOutlet weak var legend1Colour: NSTextField!
    @IBOutlet weak var legend2Colour: NSTextField!
    @IBOutlet weak var legend3Colour: NSTextField!

    @IBOutlet weak var spacerView: NSView!
    @IBOutlet weak var totalTime: NSTextField!

    @IBOutlet weak var percentLabel: NSTextField!
    
    internal var totalTimeString: String = "" {
        didSet {
            totalTime.stringValue = totalTimeString
        }
    }

    internal var desc: String = "Loading..." {
        didSet {
            guard self.view != nil else { return }
            descriptionLabel.stringValue = desc
        }
    }
    internal var data: [ToiletStatus: TimeInterval] = [ToiletStatus: TimeInterval]() {
        didSet {
            guard self.view != nil else { return }
            pieGraph.data = data
        }
    }

    internal var desc2: String = "Loading..." {
        didSet {
            guard self.view != nil else { return }
            descriptionLabel2.stringValue = desc2
        }
    }
    internal var data2: [ToiletStatus: TimeInterval] = [ToiletStatus: TimeInterval]() {
        didSet {
            guard self.view != nil else { return }
            pieGraph2.data = data2
        }
    }

    internal var motionCallback: ((Double?) -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()

        legend1Colour.drawsBackground = true
        legend1Colour.wantsLayer = true
        legend1Colour.backgroundColor = vacantColour
        legend1Colour.layer?.cornerRadius = 2

        legend2Colour.drawsBackground = true
        legend2Colour.wantsLayer = true
        legend2Colour.backgroundColor = occupiedColour
        legend2Colour.layer?.cornerRadius = 2

        legend3Colour.drawsBackground = true
        legend3Colour.wantsLayer = true
        legend3Colour.backgroundColor = offlineColour
        legend3Colour.layer?.cornerRadius = 2

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
        spacerView.layer?.backgroundColor = NSColor(red: 144/255.0, green: 144/255.0, blue: 144/255.0, alpha: 1.0).cgColor

    }

    override func viewWillAppear() {
        super.viewWillAppear()
        updateDescription()
        updatePieChart()

        totalTime.stringValue = totalTimeString
    }

    override func viewDidAppear() {
        super.viewDidAppear()
    }

    internal func updateDescription() {
        descriptionLabel.stringValue = desc
        descriptionLabel2.stringValue = desc2
    }

    internal func updatePieChart() {
        pieGraph.data = data
        pieGraph2.data = data2
    }

    @IBAction func terminateHandler(_ sender: NSButton) {
        NSApp.terminate(sender)
    }
}

extension Double {
    /// Rounds the double to decimal places value
    func roundTo(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
