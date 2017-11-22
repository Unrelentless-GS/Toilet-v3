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

    private var dataManager: DataManager?

    private var poopCode = ""
    private var revealTime = false

    private lazy var toilets: [Toilet] = {
        var toilets = [Toilet]()
        deviceIDs.enumerated().forEach { count, id in
            toilets.append(Toilet(number: count+1))
        }
        return toilets
    }()

    private var startDate = Date()

    let popover = NSPopover()

    var eventMonitor: EventMonitor?
    var viewController: ContentViewController {
        return popover.contentViewController as! ContentViewController
    }

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let socketManager = SocketManager(
        socketURL: URL(string: "http://internals.gridstone.com.au")!,
        config: [.forceWebsockets(true)])

    private lazy var socket: SocketIOClient = {
        return self.socketManager.defaultSocket
    }()

    private lazy var dateComponentsFormatter: DateComponentsFormatter = {
        let dateComponentsFormatter = DateComponentsFormatter()
        dateComponentsFormatter.allowedUnits = [.day, .hour, .minute, .second]
        dateComponentsFormatter.maximumUnitCount = 4
        dateComponentsFormatter.unitsStyle = .abbreviated

        return dateComponentsFormatter
    }()

    private var timer: Timer?
    private var deviceIDs = [String]() {
        didSet {
            beginEverything()
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem.button?.action = #selector(togglePopover)
        popover.contentViewController = ContentViewController(nibName: NSNib.Name(rawValue: String(describing: ContentViewController.self)), bundle: nil)
        let _ = self.viewController.view
        getDevices()
    }

    private func beginEverything() {
        updateImage()

        dataManager = DataManager { [weak self] in
            guard let `self` = self else { return }
            self.dataManager?.initToilets(count: self.deviceIDs.count)

            self.timer = Timer.scheduledTimer(timeInterval: 1,
                                              target: self,
                                              selector: #selector(self.refreshAll),
                                              userInfo: nil,
                                              repeats: true)

            self.eventMonitor = EventMonitor(mask: [NSEvent.EventTypeMask.leftMouseDown, NSEvent.EventTypeMask.rightMouseDown]) { [weak self] event in
                if let isShown = self?.popover.isShown, isShown == true {
                    self?.closePopover(sender: event)
                }
            }
            self.eventMonitor?.start()

//            NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.keyDown) { [weak self] in
//                self?.keyDown(with: $0)
//                return $0
//            }

            self.viewController.notifyCallback = { [weak self] in
//                let state = self.toilet1.status == .occupied ? self.toilet2.status == .occupied ? "1" : "2" : "1"
//                let notification = NSUserNotification()
//                notification.title = "Toilet Available"
//                notification.subtitle = "Toilet number \(state) is now available"
//                notification.soundName = NSUserNotificationDefaultSoundName
//                NSUserNotificationCenter.default.deliver(notification)
            }
            self.viewController.dataManager = self.dataManager
            self.doWebSocketStuff()
        }
    }

    private func getDevices() {
        socket.once("devices") { [weak self] data, ack in
            self?.deviceIDs = data
                .map{$0 as! [[String: AnyObject]]}
                .flatMap{$0}
                .flatMap{$0["deviceId"]} as! [String]

            ack.with("HAHA!", "THX")
            self?.socket.disconnect()
        }
        socket.connect()
    }

    private func doWebSocketStuff() {
        socket.on("error") { [weak self] data, ack in
            guard let `self` = self else { return }

            for toilet in self.toilets {
                toilet.sinceDate = Date()
                toilet.status = .offline
                self.refreshStats(toilet: toilet)
            }
            self.statusItem.button?.appearsDisabled = true
            ack.with("HAHA!", "THX")
        }

        socket.on("data") { [weak self] data, ack in
            guard let `self` = self else { return }
            self.statusItem.button?.appearsDisabled = false

            for something in data {
                guard let object = something as? [String: AnyObject] else { return }
                guard let lightState = object["lightState"] as? String else { return }
                guard let deviceId = object["deviceId"] as? String else { return }
                guard let index = self.deviceIDs.index(of: deviceId) else { return }

                let isFree = lightState == "0"

                self.toilets[index].sinceDate = Date()
                self.toilets[index].status = isFree ? .vacant : .occupied
                self.refreshStats(toilet: self.toilets[index])
            }

            self.updateImage()
//            self.viewController.isFree = (self.toilet1.status == .vacant || self.toilet2.status == .vacant) ? true : false

            ack.with("HAHA!", "THX")
        }
        socket.connect()
    }

    @objc private func refreshAll() {
        for toilet in toilets {
            refreshStats(toilet: toilet)
        }
    }

    private func refreshStats(toilet: Toilet) {
        let status = toilet.status
        var timeString: String?
        var statusString: String?

        let hour = Calendar.current.component(.hour, from: Date())
        let sinceDate = toilet.sinceDate

        let value = Date().timeIntervalSince(sinceDate)

        dataManager?.updateToilet(number: toilet.number, date: Date(), hour: hour, value: value, status: status)

        switch status {
        case .occupied: //occupied
            timeString = revealTime ? dateComponentsFormatter.string(from: sinceDate, to: Date()) : "[Classified]"
            statusString = "Occupied"
            toilet.occupiedHours[hour] += value
        case .vacant: //vacant
            timeString = dateComponentsFormatter.string(from: sinceDate, to: Date())
            statusString = "Vacant"
            toilet.vacantHours[hour] += value
        case .offline: //offline
            timeString = dateComponentsFormatter.string(from: sinceDate, to: Date())
            statusString = "Offline"
            toilet.offlineHours[hour] += value
        }

//        let pieModel = PieChartModel(toilet: toilet)

        switch toilet.number {
        case 1:
            viewController.desc1 = ["\(statusString!)", "\(timeString!)"]
//            viewController.data = pieModel
        case 2:
            viewController.desc2 = ["\(statusString!)", "\(timeString!)"]
        //            viewController.data2 = pieModel
        case 3:
            viewController.desc3 = ["\(statusString!)", "\(timeString!)"]
        //            viewController.data2 = pieModel
        case 4:
            viewController.desc4 = ["\(statusString!)", "\(timeString!)"]
        //            viewController.data2 = pieModel
        default: break
        }

//        let timeInterval = NSDate().timeIntervalSince(self.startDate)
//        guard let string = dateComponentsFormatter.string(from: timeInterval) else { return }
//        self.viewController.totalTimeString = "Total time: \(string)"

        viewController.barData = dataManager?.barData(for: .hourly)

        let defaults = UserDefaults(suiteName: "au.com.gridstone.q2p")
        defaults?.set("\(statusString!)", forKey: "Toilet\(toilet.number)")
        defaults?.synchronize()
    }

    private func updateImage() {
        var imageName = "toilet_"

        for (index, toilet) in toilets.enumerated() {
            imageName += toilet.status == .occupied ? "\(index+1)" : ""
            print(imageName)
        }

        let icon = NSImage(named: NSImage.Name(rawValue: imageName))

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
        revealTime = poopCode == "qps"
    }
}

public class EventMonitor {
    private var monitor: AnyObject?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent?) -> ()

    public init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> ()) {
        self.mask = mask
        self.handler = handler
    }
    
    deinit { stop() }
    
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

