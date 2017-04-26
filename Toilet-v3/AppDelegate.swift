//
//  AppDelegate.swift
//  Toilet-v3
//
//  Created by Pavel Boryseiko on 19/4/17.
//  Copyright © 2017 GRIDSTONE. All rights reserved.
//

import Cocoa
import SocketIO

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    private var vacantTimes: [TimeInterval] = [0, 0]
    private var occupiedTimes: [TimeInterval] = [0, 0]
    private var offlineTimes: [TimeInterval] = [0, 0]

    let popover = NSPopover()
    var eventMonitor: EventMonitor?

    var viewController: ContentViewController {
        return popover.contentViewController as! ContentViewController
    }

    private let statusItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)
    private let socket = SocketIOClient(
        socketURL: URL(string: "http://internals.gridstone.com.au")!,
        config: [.forceWebsockets(true)])

    private lazy var menu: NSMenu = { [unowned self] in
        let menu = NSMenu()
        menu.addItem(self.menuItem)
        menu.addItem(NSMenuItem(title: "Terminate", action: #selector(terminate), keyEquivalent: ""))
        return menu
        }()

    private lazy var dateComponentsFormatter: DateComponentsFormatter = {
        let dateComponentsFormatter = DateComponentsFormatter()
        dateComponentsFormatter.allowedUnits = [.hour,.minute,.second]
        dateComponentsFormatter.maximumUnitCount = 2
        dateComponentsFormatter.unitsStyle = .abbreviated

        return dateComponentsFormatter
    }()

    private let menuItem = NSMenuItem(title: "Vacant for:", action: nil, keyEquivalent: "")
    private var timer: Timer?

    private var status = 1
    private var status2 = 1

    private var sinceDate = Date()
    private var deviceIDs = [String]()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        //        statusItem.menu = menu
        statusItem.button?.action = #selector(togglePopover)
        popover.contentViewController = ContentViewController(nibName: String(describing: ContentViewController.self), bundle: nil)

        updateImage(isFree: true)
        doWebSocketStuff()

        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(refreshBothStats), userInfo: nil, repeats: true)

        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [unowned self] event in
            if self.popover.isShown {
                self.closePopover(sender: event)
            }
        }
        eventMonitor?.start()
    }

    private func doWebSocketStuff() {
        socket.on("error") { data, ack in
            self.sinceDate = Date()
            self.statusItem.button?.appearsDisabled = true
            self.status = -1
            self.status2 = -1
            self.refreshStats(toiletNumber: 0, status: -1)
            self.refreshStats(toiletNumber: 1, status: -1)
            print(data)
        }

        socket.on("devices") { data, ack in
            self.deviceIDs = data
                .map{$0 as! [[String: AnyObject]]}
                .flatMap{$0}
                .flatMap{$0["deviceId"]} as! [String]
        }

        socket.on("data") { data, ack in
            self.sinceDate = Date()
            self.statusItem.button?.appearsDisabled = false

            for (index, something) in data.enumerated() {
                guard let object = something as? [String: AnyObject] else { return }
                guard let lightState = object["lightState"] as? String else { return }

                let isFree = lightState == "0"
                self.updateImage(isFree: isFree)

                if index == 0 {
                    self.status = isFree ? 1 : 0
                } else {
                    self.status2 = isFree ? 1 : 0
                }

                self.refreshStats(toiletNumber: index, status: isFree ? 1 : 0)
            }

            ack.with("HAHA!", "THX")
            print(data)
        }

        socket.connect()
    }


    @objc private func refreshBothStats() {
        self.refreshStats(toiletNumber: 0, status: status)
        self.refreshStats(toiletNumber: 1, status: status2)
    }

    private func refreshStats(toiletNumber: Int, status: Int) {
        var timeString: String?
        var statusString: String?

        switch status {
        case 0: //occupied
            timeString = "[Classified]"
            statusString = "Occupied"
            occupiedTimes[toiletNumber] += Date().timeIntervalSince(sinceDate)
        case 1: //vacant
            timeString = dateComponentsFormatter.string(from: self.sinceDate, to: Date())
            statusString = "Vacant"
            vacantTimes[toiletNumber] += Date().timeIntervalSince(sinceDate)
        case -1:
            timeString = dateComponentsFormatter.string(from: self.sinceDate, to: Date())
            statusString = "Offline"
            offlineTimes[toiletNumber] += Date().timeIntervalSince(sinceDate)
        default: break
        }

        //        self.menuItem.title = "\(statusString!) for: \(timeString!)"

        if toiletNumber == 0 {
            viewController.desc = "\(statusString!) for: \(timeString!)"
            viewController.data = [
                "vacant": vacantTimes[0],
                "occupied": occupiedTimes[0],
                "offline": offlineTimes[0]
            ]
        } else {
            viewController.desc2 = "\(statusString!) for: \(timeString!)"
            viewController.data2 = [
                "vacant": vacantTimes[1],
                "occupied": occupiedTimes[1],
                "offline": offlineTimes[1]
            ]
        }
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
