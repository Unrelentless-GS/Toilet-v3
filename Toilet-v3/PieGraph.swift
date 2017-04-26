//
//  PieGraph.swift
//  Toilet-v3
//
//  Created by Pavel Boryseiko on 26/4/17.
//  Copyright © 2017 GRIDSTONE. All rights reserved.
//

import Cocoa

let vacantColour = NSColor(red: 102/255.0, green: 255/255.0, blue: 178/255.0, alpha: 1.0)
let occupiedColour = NSColor(red: 146/255.0, green: 109/255.0, blue: 69/255.0, alpha: 1.0)
let offlineColour = NSColor(red: 255/255.0, green: 102/255.0, blue: 102/255.0, alpha: 1.0)

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
