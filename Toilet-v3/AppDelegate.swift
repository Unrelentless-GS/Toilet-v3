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
    private var sinceDate = Date()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem.menu = menu
        updateImage(isFree: true)
        doWebSocketStuff()

        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.refreshStats()
        }
    }

    private func doWebSocketStuff() {
        socket.on("error") { data, ack in
            self.sinceDate = Date()
            self.statusItem.button?.appearsDisabled = true
            self.status = -1
            self.refreshStats()
            print(data)
        }

        socket.on("data") { data, ack in
            self.sinceDate = Date()
            self.statusItem.button?.appearsDisabled = false

            for something in data {
                guard let object = something as? [String: AnyObject] else { return }
                guard let lightState = object["lightState"] as? String else { return }

                let isFree = lightState == "1"
                self.status = isFree ? 1 : 0
                self.updateImage(isFree: isFree)

                if isFree == true { break }
            }


            ack.with("HAHA!", "THX")
            print(data)
            self.refreshStats()
        }

        socket.connect()
    }

    private func refreshStats() {
        let timeString = dateComponentsFormatter.string(from: self.sinceDate, to: Date())
        let statusString = self.status == -1 ? "Offline" : self.status == 0 ? "Occupied" : "Vacant"
        self.menuItem.title = "\(statusString) for: \(timeString!)"
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
}

