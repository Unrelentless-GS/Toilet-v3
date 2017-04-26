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

    internal var desc: String = "Loading..." {
        didSet {
            guard self.view != nil else { return }
            descriptionLabel.stringValue = desc
        }
    }
    internal var data: [String: TimeInterval] = [String: TimeInterval]() {
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
    internal var data2: [String: TimeInterval] = [String: TimeInterval]() {
        didSet {
            guard self.view != nil else { return }
            pieGraph2.data = data2
        }
    }

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

        pieGraph.number = 1
        pieGraph2.number = 2
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        updateDescription()
        updatePieChart()
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
