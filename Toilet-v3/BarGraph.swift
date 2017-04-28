//
//  BarGraph.swift
//  Toilet-v3
//
//  Created by Pavel Boryseiko on 28/4/17.
//  Copyright © 2017 GRIDSTONE. All rights reserved.
//

import Cocoa

class BarGraph: NSView {

    private let numbers: [NSString] = ["7am", "8am", "9am", "10am", "11am", "12pm", "1pm", "2pm", "3pm", "4pm", "5pm", "6pm", "7pm"]

    private var bottomLeftPoint: CGPoint {
        return CGPoint(x: self.bounds.origin.x + 20.0, y: 20)
    }

    private var topRightPoint: CGPoint {
        return CGPoint(x: self.bounds.size.width - 20.0, y: self.bounds.size.height - 20)
    }

    private var bottomRightPoint: CGPoint {
        return CGPoint(x: self.bounds.size.width - 20.0, y: 20)
    }

    private var topLeftPoint: CGPoint {
        return CGPoint(x: self.bounds.origin.x + 20.0, y: self.bounds.size.height - 20)
    }

    private var totalSize: CGSize {
        let sizeX = bottomRightPoint.x - bottomLeftPoint.x
        let sizeY = topRightPoint.y - bottomRightPoint.y

        return CGSize(width: sizeX, height: sizeY)
    }

    internal var data: [[ToiletStatus: TimeInterval]] = [[ToiletStatus: TimeInterval]]()

    override func awakeFromNib() {
        super.awakeFromNib()

//        fakeData()
    }

    private func fakeData() {
        let dataDict: [ToiletStatus: TimeInterval] = [.occupied: 50.0, .vacant: 50.0]
        let dataDict2: [ToiletStatus: TimeInterval] = [.occupied: 50.0, .vacant: 50.0]
        let dataDict3: [ToiletStatus: TimeInterval] = [.occupied: 25.0, .vacant: 75.0]
        let dataDict4: [ToiletStatus: TimeInterval] = [.occupied: 66.0, .vacant: 33.0]
        let dataDict5: [ToiletStatus: TimeInterval] = [.occupied: 11.0, .vacant: 89.0]
        let dataDict6: [ToiletStatus: TimeInterval] = [.occupied: 78.0, .vacant: 22.0]

        data.append(dataDict)
        data.append(dataDict2)
        data.append(dataDict3)
        data.append(dataDict4)
        data.append(dataDict5)
        data.append(dataDict6)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        drawBackground()
        drawAxes()
        drawXLabels()
        drawYLabels()

        drawGraph()
    }

    private func drawAxes() {
        let pathX = NSBezierPath()
        pathX.move(to: bottomLeftPoint)
        pathX.line(to: bottomRightPoint)

        NSColor.black.setFill()
        NSColor.black.setStroke()

        pathX.stroke()
        pathX.fill()
        pathX.close()

        let pathY = NSBezierPath()
        pathY.move(to: bottomLeftPoint)
        pathY.line(to: topLeftPoint)

        NSColor.black.setFill()
        NSColor.black.setStroke()

        pathY.stroke()
        pathY.fill()
        pathY.close()
    }

    private func drawBackground() {
        let colour = vacantColour.withAlphaComponent(0.5).cgColor

        let context = NSGraphicsContext.current()?.cgContext
        let path = CGMutablePath()

        path.move(to: bottomLeftPoint)
        path.addRect(CGRect(origin: bottomLeftPoint, size: totalSize))
        path.closeSubpath()

        context?.setFillColor(colour)
        context?.addPath(path)
        context?.drawPath(using: .fill)
    }

    private func drawXLabels() {
        let attrs = [NSFontAttributeName: NSFont(name: "HelveticaNeue-Thin", size: 8)!]

        numbers.enumerated().forEach { (index, number) in
            let stringSize = number.size(withAttributes: attrs)
            let space = totalSize.width / CGFloat(numbers.count - 1)
            let bottomX = (bottomLeftPoint.x + (CGFloat(index) * space)) - (stringSize.width / 2)
            let bottomY = bottomLeftPoint.y

            let rect = CGRect(x: bottomX,
                              y: bottomY - stringSize.height,
                              width: stringSize.width,
                              height: stringSize.height)
            number.draw(in: rect, withAttributes: attrs)
        }
    }

    private func drawYLabels() {

        let top: NSString = "100%"
        let bottom: NSString = "0%"

        let attrs = [NSFontAttributeName: NSFont(name: "HelveticaNeue-Thin", size: 8)!]
        let stringSize = top.size(withAttributes: attrs)
        let rect = CGRect(x: topLeftPoint.x - stringSize.width,
                          y:topLeftPoint.y - 10,
                          width: stringSize.width,
                          height: stringSize.height)

        let stringSize2 = bottom.size(withAttributes: attrs)
        let rect2 = CGRect(x: bottomLeftPoint.x - stringSize2.width,
                           y:bottomLeftPoint.y,
                           width: stringSize2.width,
                           height: stringSize2.height)

        top.draw(in: rect, withAttributes: attrs)
        bottom.draw(in: rect2, withAttributes: attrs)
    }

    private func drawGraph() {
        let colour = occupiedColour.withAlphaComponent(0.9).cgColor
        let context = NSGraphicsContext.current()?.cgContext

        data.enumerated().forEach { (index, info) in
            let total = info[.vacant]! + info[.occupied]!
            let space = totalSize.width / CGFloat(numbers.count - 1)
            let sizeY = totalSize.height * CGFloat((info[.occupied]! / total))
            let origin = CGPoint(x: bottomLeftPoint.x + (space * CGFloat(index)), y: bottomLeftPoint.y)
            let size = CGSize(width: space, height: sizeY)

            let path = CGMutablePath()

            path.move(to: bottomLeftPoint)
            path.addRect(CGRect(origin: origin, size: size))
            path.closeSubpath()
            
            context?.setFillColor(colour)
            context?.addPath(path)
            context?.drawPath(using: .fill)
        }
        
    }
}
