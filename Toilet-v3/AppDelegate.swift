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

    private lazy var menu: NSMenu = {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Terminate", action: #selector(terminate), keyEquivalent: ""))
        return menu
    }()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem.menu = menu
        updateImage(isFree: true)
        doWebSocketStuff()
    }

    private func doWebSocketStuff() {
        socket.on("close") { data, ack in
            print("socket closed")
        }

        socket.on("data") { data, ack in
            for something in data {
                guard let object = something as? [String: AnyObject] else { return }
                guard let lightState = object["lightState"] as? String else { return }

                let isFree = lightState == "1"
                self.updateImage(isFree: isFree)

                if isFree == true { break }
            }


            ack.with("HAHA!", "THX")
        }

        socket.connect()
    }


    private func updateImage(isFree: Bool) {
        var icon: NSImage?

        if isFree {
            icon = NSImage(named: "toilet-yes")
        } else {
            icon = NSImage(named: "toilet-no")
        }

        self.statusItem.button?.image = icon
        self.statusItem.button?.image?.isTemplate = true
    }
    
    @objc private func terminate() {
        NSApp.terminate(nil)
    }
}

