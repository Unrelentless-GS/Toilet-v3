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
    @IBOutlet weak var terminateButton: NSButton!
    @IBOutlet weak var pieGraph: PieGraph!

    internal var desc: String = "Loading..."
    internal var data: [String: TimeInterval]? = [String: TimeInterval]()

    override func viewWillAppear() {
        super.viewWillAppear()
        updateDescription()
        updatePieChart()
    }

    internal func updateDescription() {
        descriptionLabel.stringValue = desc
    }

    internal func updatePieChart() {

    }

    @IBAction func terminateHandler(_ sender: NSButton) {
        NSApp.terminate(sender)
    }
}

internal class PieGraph: NSView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawPieChart()
    }

    func drawPieChart() {

        // 1
        let rect = CGRect(x: 20, y: 20, width: self.bounds.size.width - 40, height: self.bounds.size.height - 40)
        let circle = NSBezierPath(ovalIn: rect)
        NSColor.blue.setFill()
        NSColor.green.setStroke()
        circle.stroke()
        circle.fill()

        // 2
        let path = NSBezierPath()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let usedPercent = Double(50 - 100) / Double(100)
        let endAngle = CGFloat(360 * usedPercent)
        let radius = rect.size.width / 2.0
        path.move(to: center)
        path.line(to: CGPoint(x: rect.maxX, y: center.y))
        path.appendArc(withCenter: center, radius: radius,
                       startAngle: 0, endAngle: endAngle)
        path.close()


        // 3
        NSColor.red.setFill()
        NSColor.red.setStroke()
        path.stroke()

        if let gradient = NSGradient(starting: NSColor.red, ending: NSColor.black) {
            gradient.draw(in: path, angle: 45)
        }
    }
}
