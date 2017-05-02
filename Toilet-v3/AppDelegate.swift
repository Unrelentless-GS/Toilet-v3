//
//  AppDelegate.swift
//  Toilet-v3
//
//  Created by Pavel Boryseiko on 19/4/17.
//  Copyright © 2017 GRIDSTONE. All rights reserved.
//

import Cocoa
import SocketIO

enum ToiletStatus: Int {
    case offline = -1
    case occupied = 0
    case vacant = 1
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    private var poopCode = ""
    private var revealTime = false

    private var toilet1 = Toilet(number: 1)
    private var toilet2 = Toilet(number: 2)

    private var startDate = Date()

    let popover = NSPopover()

    var eventMonitor: EventMonitor?
    var viewController: ContentViewController {
        return popover.contentViewController as! ContentViewController
    }

    private let statusItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)
    private let socket = SocketIOClient(
        socketURL: URL(string: "http://internals.gridstone.com.au")!,
        config: [.forceWebsockets(true)])

    private lazy var dateComponentsFormatter: DateComponentsFormatter = {
        let dateComponentsFormatter = DateComponentsFormatter()
        dateComponentsFormatter.allowedUnits = [.day, .hour, .minute, .second]
        dateComponentsFormatter.maximumUnitCount = 2
        dateComponentsFormatter.unitsStyle = .abbreviated

        return dateComponentsFormatter
    }()

    private var timer: Timer?
    private var deviceIDs = [String]()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem.button?.action = #selector(togglePopover)
        popover.contentViewController = ContentViewController(nibName: String(describing: ContentViewController.self), bundle: nil)
        let _ = viewController.view

        updateImage(isFree: true)
        doWebSocketStuff()

        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(refreshBothStats), userInfo: nil, repeats: true)

        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [unowned self] event in
            if self.popover.isShown {
                self.closePopover(sender: event)
            }
        }
        eventMonitor?.start()

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            self.keyDown(with: $0)
            return $0
        }

        viewController.notifyCallback = { [unowned self] in
            let state = self.toilet1.status == .occupied ? self.toilet2.status == .occupied ? "1" : "2" : "1"
            let notification = NSUserNotification()
            notification.title = "Toilet Available"
            notification.subtitle = "Toilet number \(state) is now available"
            notification.soundName = NSUserNotificationDefaultSoundName
            NSUserNotificationCenter.default.deliver(notification)
        }
    }

    private func doWebSocketStuff() {
        socket.on("error") { data, ack in
            self.toilet1.sinceDate = Date()
            self.toilet2.sinceDate = Date()
            self.statusItem.button?.appearsDisabled = true
            self.toilet1.status = .offline
            self.toilet2.status = .offline
            self.refreshStats(toilet: self.toilet1)
            self.refreshStats(toilet: self.toilet2)
        }

        socket.on("devices") { data, ack in
            self.deviceIDs = data
                .map{$0 as! [[String: AnyObject]]}
                .flatMap{$0}
                .flatMap{$0["deviceId"]} as! [String]
        }

        socket.on("data") { data, ack in
            self.statusItem.button?.appearsDisabled = false

            for something in data {
                guard let object = something as? [String: AnyObject] else { return }
                guard let lightState = object["lightState"] as? String else { return }
                guard let deviceId = object["deviceId"] as? String else { return }
                guard let index = self.deviceIDs.index(of: deviceId) else { return }

                let isFree = lightState == "0"

                if index == 0 {
                    self.toilet1.sinceDate = Date()
                    self.toilet1.status = isFree ? .vacant : .occupied
                    self.refreshStats(toilet: self.toilet1)
                } else {
                    self.toilet2.sinceDate = Date()
                    self.toilet2.status = isFree ? .vacant : .occupied
                    self.refreshStats(toilet: self.toilet2)
                }
            }

            self.updateImage(isFree: (self.toilet1.status == .vacant || self.toilet2.status == .vacant) ? true : false)
            self.viewController.isFree = (self.toilet1.status == .vacant || self.toilet2.status == .vacant) ? true : false

            ack.with("HAHA!", "THX")
        }

        socket.connect()
    }

    @objc private func refreshBothStats() {
        self.refreshStats(toilet: toilet1)
        self.refreshStats(toilet: toilet2)
    }

    private func refreshStats(toilet: Toilet) {
        let status = toilet.status
        var timeString: String?
        var statusString: String?

        let hour = Calendar.current.component(.hour, from: Date())
        let sinceDate = toilet.sinceDate

        switch status {
        case .occupied: //occupied
            timeString = revealTime ? dateComponentsFormatter.string(from: sinceDate, to: Date()) : "[Classified]"
            statusString = "Occupied"
            toilet.occupiedHours[hour] += Date().timeIntervalSince(sinceDate)
        case .vacant: //vacant
            timeString = dateComponentsFormatter.string(from: sinceDate, to: Date())
            statusString = "Vacant"
            toilet.vacantHours[hour] += Date().timeIntervalSince(sinceDate)
        case .offline: //offline
            timeString = dateComponentsFormatter.string(from: sinceDate, to: Date())
            statusString = "Offline"
            toilet.offlineHours[hour] += Date().timeIntervalSince(sinceDate)
        }

        let pieModel = PieChartModel(toilet: toilet)

        switch toilet.number {
        case 1:
            viewController.desc = ["\(statusString!)", "\(timeString!)"]
            viewController.data = pieModel
        case 2:
            viewController.desc2 = ["\(statusString!)", "\(timeString!)"]
            viewController.data2 = pieModel
        default: break
        }

        let timeInterval = NSDate().timeIntervalSince(self.startDate)
        guard let string = dateComponentsFormatter.string(from: timeInterval) else { return }
        viewController.totalTimeString = "Total time: \(string)"

        let model = BarGraphModel(toilets: [toilet1, toilet2])

        viewController.barData = model
    }

    private func updateImage(isFree: Bool) {
        var icon: NSImage?

        if isFree {
            icon = NSImage(named: "toilet-yes")
        } else {
            icon = NSImage(named: "toilet-no")
        }

        statusItem.button?.image = icon
        statusItem.button?.image?.isTemplate = true
        statusItem.button?.toolTip = "Empty = Vacant \nFilled = Occupied"
    }

    @objc private func terminate() {
        NSApp.terminate(nil)
    }

    @objc private func togglePopover(sender: AnyObject?) {
        if popover.isShown {
            closePopover(sender: sender)
        } else {
            showPopover(sender: sender)
        }
    }

    private func showPopover(sender: AnyObject?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func closePopover(sender: AnyObject?) {
        popover.performClose(sender)
        poopCode = ""
        revealTime = false
    }

    func keyDown(with event: NSEvent) {
        guard let characters = event.characters else { return }

        poopCode += characters

        if poopCode == "qps" {
            revealTime = true
        } else {
            revealTime = false
        }
    }
}

public class EventMonitor {
    private var monitor: AnyObject?
    private let mask: NSEventMask
    private let handler: (NSEvent?) -> ()

    public init(mask: NSEventMask, handler: @escaping (NSEvent?) -> ()) {
        self.mask = mask
        self.handler = handler
    }

    deinit {
        stop()
    }

    public func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler) as AnyObject
    }

    public func stop() {
        if monitor != nil {
            NSEvent.removeMonitor(monitor!)
            monitor = nil
        }
    }
}
 
