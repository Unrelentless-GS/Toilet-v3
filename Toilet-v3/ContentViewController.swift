//
//  ContentViewController.swift
//  Toilet-v3
//
//  Created by Pavel Boryseiko on 24/4/17.
//  Copyright © 2017 GRIDSTONE. All rights reserved.
//

import Cocoa

let vacantColour = NSColor(red: 102/255.0, green: 255/255.0, blue: 178/255.0, alpha: 1.0)
let occupiedColour = NSColor(red: 146/255.0, green: 109/255.0, blue: 69/255.0, alpha: 1.0)
let offlineColour = NSColor(red: 255/255.0, green: 102/255.0, blue: 102/255.0, alpha: 1.0)

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

internal class PieGraph: NSView {

    private var count = 0

    internal var number: Int = 0

    internal var data: [String: TimeInterval] = [String: TimeInterval]() {
        didSet {
            setNeedsDisplay(self.bounds)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
//        fakeData()
        drawArc(value: valueFor(count: count), colour: colourFor(count: count), nextAngle: 0)
    }

    private func drawArc(value: Double, colour: NSColor, nextAngle: CGFloat) {

        let rect = CGRect(x: 20, y: 20, width: self.bounds.size.width - 40, height: self.bounds.size.height - 40)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = rect.size.width / 2.0

        let total = data.values.reduce(0.0) { result, next in
            result + next
        }

        var endAngle = nextAngle

        if value != 0.0 {

            // 3
            let path = NSBezierPath()
            let usedPercent = value / total
            endAngle = nextAngle + CGFloat(360 * usedPercent)
            path.move(to: center)
            path.appendArc(withCenter: center, radius: radius,
                           startAngle: nextAngle, endAngle: endAngle)

            colour.setFill()
            colour.setStroke()

            path.stroke()
            path.fill()
            path.close()
        }

        count += 1
        guard count != 3 else {
            count = 0
            return
        }
        drawArc(value: valueFor(count: count), colour: colourFor(count: count), nextAngle: endAngle)
    }

    func colourFor(count: Int) -> NSColor {
        switch count {
        case 0: return vacantColour
        case 1: return occupiedColour
        case 2: return offlineColour
        default: return NSColor.black
        }
    }

    func valueFor(count: Int) -> Double {
        switch count {
        case 0:
            return data["vacant"]!
        case 1:
            return data["occupied"]!
        case 2:
            return data["offline"]!
        default: return 0
        }
    }

    func fakeData() {
        data["vacant"] = 50
        data["offline"] = 25
        data["occupied"] = 25
    }
}
