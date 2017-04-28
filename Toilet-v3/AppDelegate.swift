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

    private var vacantTimes: [[TimeInterval]] = [[0, 0],[0, 0],[0, 0],[0, 0],[0, 0],[0, 0],[0, 0],[0, 0],[0, 0],[0, 0],[0, 0],[0, 0]]
    private var occupiedTimes: [[TimeInterval]] = [[0, 0],[0, 0],[0, 0],[0, 0],[0, 0],[0, 0],[0, 0],[0, 0],[0, 0],[0, 0],[0, 0],[0, 0]]
    private var offlineTimes: [[TimeInterval]] = [[0, 0],[0, 0],[0, 0],[0, 0],[0, 0],[0, 0],[0, 0],[0, 0],[0, 0],[0, 0],[0, 0],[0, 0]]

    private var startDate = Date()

    let popover = NSPopover()
    let testPopover = NSPopover()

    var eventMonitor: EventMonitor?

    var viewController: ContentViewController {
        return popover.contentViewController as! ContentViewController
    }

    var testVC: TestViewController {
        return testPopover.contentViewController as! TestViewController
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

    private var status: ToiletStatus = .vacant
    private var status2: ToiletStatus = .vacant

    private var sinceDate = Date()
    private var sinceDate2 = Date()
    private var deviceIDs = [String]()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        //        statusItem.menu = menu
        statusItem.button?.action = #selector(togglePopover)
        popover.contentViewController = ContentViewController(nibName: String(describing: ContentViewController.self), bundle: nil)
        testPopover.contentViewController = TestViewController(nibName: String(describing: TestViewController.self), bundle: nil)

        updateImage(isFree: true)
        doWebSocketStuff()

        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(refreshBothStats), userInfo: nil, repeats: true)

        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [unowned self] event in
            if self.testPopover.isShown {
                self.closePopover(sender: event)
            }
        }
        eventMonitor?.start()

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            self.keyDown(with: $0)
            return $0
        }

        viewController.notifyCallback = { [unowned self] in
            let state = self.status == .occupied ? self.status2 == .occupied ? "1" : "2" : "1"
            let notification = NSUserNotification()
            notification.title = "Toilet Available"
            notification.subtitle = "Toilet number \(state) is now available"
            notification.soundName = NSUserNotificationDefaultSoundName
            NSUserNotificationCenter.default.deliver(notification)
        }
    }

    private func doWebSocketStuff() {
        socket.on("error") { data, ack in
            self.sinceDate = Date()
            self.sinceDate2 = Date()
            self.statusItem.button?.appearsDisabled = true
            self.status = .offline
            self.status2 = .offline
            self.refreshStats(toiletNumber: 0, status: .offline)
            self.refreshStats(toiletNumber: 1, status: .offline)
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
                    self.sinceDate = Date()
                    self.status = isFree ? .vacant : .occupied
                } else {
                    self.sinceDate2 = Date()
                    self.status2 = isFree ? .vacant : .occupied
                }

                self.refreshStats(toiletNumber: index, status: isFree ? .vacant : .occupied)
            }

            self.updateImage(isFree: (self.status == .vacant || self.status2 == .vacant) ? true : false)
            self.viewController.isFree = (self.status == .vacant || self.status2 == .vacant) ? true : false

            ack.with("HAHA!", "THX")
        }

        socket.connect()
    }

    @objc private func refreshBothStats() {
        self.refreshStats(toiletNumber: 0, status: status)
        self.refreshStats(toiletNumber: 1, status: status2)
    }

    private func refreshStats(toiletNumber: Int, status: ToiletStatus) {
        var timeString: String?
        var statusString: String?

        let hour = Calendar.current.component(.hour, from: Date()) - 7

        switch status {
        case .occupied: //occupied
            let sinceDate = toiletNumber == 0 ? self.sinceDate : self.sinceDate2
            timeString = revealTime ? dateComponentsFormatter.string(from: sinceDate, to: Date()) : "[Classified]"
            statusString = "Occupied"
            occupiedTimes[hour][toiletNumber] += Date().timeIntervalSince(sinceDate)
        case .vacant: //vacant
            let sinceDate = toiletNumber == 0 ? self.sinceDate : self.sinceDate2
            timeString = dateComponentsFormatter.string(from: sinceDate, to: Date())
            statusString = "Vacant"
            vacantTimes[hour][toiletNumber] += Date().timeIntervalSince(sinceDate)
        case .offline:
            let sinceDate = toiletNumber == 0 ? self.sinceDate : self.sinceDate2
            timeString = dateComponentsFormatter.string(from: sinceDate, to: Date())
            statusString = "Offline"
            offlineTimes[hour][toiletNumber] += Date().timeIntervalSince(sinceDate)
        }

        //        self.menuItem.title = "\(statusString!) for: \(timeString!)"

        if toiletNumber == 0 {
            viewController.desc = "\(statusString!) for: \(timeString!)"
            viewController.data = [
                .vacant: vacantTimes.flatMap{$0}[0],
                .occupied: occupiedTimes.flatMap{$0}[0],
                .offline: offlineTimes.flatMap{$0}[0]
            ]
        } else {
            viewController.desc2 = "\(statusString!) for: \(timeString!)"
            viewController.data2 = [
                .vacant: vacantTimes.flatMap{$0}[1],
                .occupied: occupiedTimes.flatMap{$0}[1],
                .offline: offlineTimes.flatMap{$0}[1]
            ]
        }

        let timeInterval = NSDate().timeIntervalSince(self.startDate)
        guard let string = dateComponentsFormatter.string(from: timeInterval) else { return }
        viewController.totalTimeString = "Total time: \(string)"

        var data: [[ToiletStatus: TimeInterval]] = [[ToiletStatus: TimeInterval](), [ToiletStatus: TimeInterval](), [ToiletStatus: TimeInterval](), [ToiletStatus: TimeInterval](), [ToiletStatus: TimeInterval](), [ToiletStatus: TimeInterval](), [ToiletStatus: TimeInterval](), [ToiletStatus: TimeInterval](), [ToiletStatus: TimeInterval](), [ToiletStatus: TimeInterval](), [ToiletStatus: TimeInterval](), [ToiletStatus: TimeInterval]()]

        vacantTimes.enumerated().forEach { (index, _) in
            let vacantTotal = vacantTimes[index].reduce(vacantTimes[index][0]){$0 + $1}
            let occupiedTotal = occupiedTimes[index].reduce(occupiedTimes[index][0]){$0 + $1}
            let offlineTotal = offlineTimes[index].reduce(offlineTimes[index][0]){$0 + $1}

            data[index][.vacant] = vacantTotal
            data[index][.occupied] = occupiedTotal + offlineTotal
        }

        testVC.data = data
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
        if testPopover.isShown {
            closePopover(sender: sender)
        } else {
            showPopover(sender: sender)
        }
    }

    private func showPopover(sender: AnyObject?) {
        if let button = statusItem.button {
            testPopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func closePopover(sender: AnyObject?) {
        testPopover.performClose(sender)
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

//public extension Date {
//
//    func isDate(date: Date, between startDate: Date, andDate endDate: Date) -> Bool {
//        return date.compare(startDate) == .orderedAscending || date.compare(endDate) == .orderedDescending
//    }
//
//    func dataAt(hours: Int) -> Date {
//        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
//        var dateComponents = calendar.components(
//            [NSCalendar.Unit.year,
//             NSCalendar.Unit.month,
//             NSCalendar.Unit.day],
//            from: self)
//
//        dateComponents.hour = hours
//        dateComponents.minute = 0
//        dateComponents.second = 0
//
//        let newDate = calendar.date(from: dateComponents)!
//        return newDate
//    }
//
//    func isDate(date: Date, between startHour: Int, and endHour: Int) -> Bool {
//        let now = Date()
//        let start = now.dateAt(hours: startHour)
//        let end = now.dateAt(hours: endHour)
//        
//        if now >= start && now <= end {
//            return true
//        } else {
//            return false
//        }
//    }
//}

