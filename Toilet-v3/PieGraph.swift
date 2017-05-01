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
let spacerColour = NSColor(red: 144/255.0, green: 144/255.0, blue: 144/255.0, alpha: 1.0)

internal class PieGraph: NSView {

    internal var motionCallback: ((Double?) -> ())?
    internal var bezierPaths = [Int: NSBezierPath]()
    internal var tAreas = [NSTrackingArea(), NSTrackingArea(), NSTrackingArea()]
    internal var number: Int = 0
    internal var data: PieChartModel? {
        didSet {
            setNeedsDisplay(self.bounds)
            track()
        }
    }

    private var count = 0

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawArc(value: valueFor(count: count), colour: colourFor(count: count), nextAngle: 0)
    }

    private func drawArc(value: Double, colour: NSColor, nextAngle: CGFloat) {

        let rect = CGRect(x: 20, y: 20, width: self.bounds.size.width - 40, height: self.bounds.size.height - 40)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = rect.size.width / 2.0

        var endAngle = nextAngle

        if value != 0.0 {

            // 3
            let path = NSBezierPath()
            let usedPercent = value / data!.totalTime
            endAngle = nextAngle + CGFloat(360 * usedPercent)
            path.move(to: center)
            path.appendArc(withCenter: center, radius: radius,
                           startAngle: nextAngle, endAngle: endAngle)

            colour.setFill()
            colour.setStroke()

            path.stroke()
            path.fill()
            path.close()

            bezierPaths[count] = path
        }

        count += 1
        guard count != 3 else {
            count = 0
            return
        }
        drawArc(value: valueFor(count: count), colour: colourFor(count: count), nextAngle: endAngle)
    }

    private func colourFor(count: Int) -> NSColor {
        switch count {
        case 0: return vacantColour
        case 1: return occupiedColour
        case 2: return offlineColour
        default: return NSColor.black
        }
    }

    private func valueFor(count: Int) -> Double {
        switch count {
        case 0:
            return data!.vacantTime
        case 1:
            return data!.occupiedTime
        case 2:
            return data!.offlineTime
        default: return 0
        }
    }

    private func track() {
        if let path = self.bezierPaths[0] {
            self.removeTrackingArea(tAreas[0])
            let area = NSTrackingArea(rect: path.bounds, options: [.activeAlways, .mouseEnteredAndExited], owner: self, userInfo: ["status": ToiletStatus.vacant])
            tAreas[0] = area
            self.addTrackingArea(area)
        }

        if let path = self.bezierPaths[1] {
            self.removeTrackingArea(tAreas[1])
            let area = NSTrackingArea(rect: path.bounds, options: [.activeAlways, .mouseEnteredAndExited], owner: self, userInfo: ["status": ToiletStatus.occupied])
            tAreas[1] = area
            self.addTrackingArea(area)
        }

        if let path = self.bezierPaths[2] {
            self.removeTrackingArea(tAreas[2])
            let area = NSTrackingArea(rect: path.bounds, options: [.activeAlways, .mouseEnteredAndExited], owner: self, userInfo: ["status": ToiletStatus.offline])
            tAreas[2] = area
            self.addTrackingArea(area)
        }
    }

    override func mouseEntered(with event: NSEvent) {
        let type = event.trackingArea?.userInfo?["status"] as! ToiletStatus
        var percent: Double = 0.0
        var inView: Bool? = false

        switch type {
        case .vacant:
            percent = (data!.vacantTime / data!.totalTime) * 100
            inView = bezierPaths[0]?.contains(self.convert(event.locationInWindow, from: nil))
        case .occupied:
            percent = (data!.occupiedTime / data!.totalTime) * 100
            inView = bezierPaths[1]?.contains(self.convert(event.locationInWindow, from: nil))
        case .offline:
            percent = (data!.offlineTime / data!.totalTime) * 100
            inView = bezierPaths[2]?.contains(self.convert(event.locationInWindow, from: nil))
        }

        if inView == true {
            motionCallback?(percent)
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        motionCallback?(nil)
    }
}
