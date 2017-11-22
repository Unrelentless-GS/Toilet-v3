//
//  SocketMan.swift
//  iQ2P
//
//  Created by Pavel Boryseiko on 22/11/17.
//  Copyright © 2017 GRIDSTONE. All rights reserved.
//

import Cocoa
import SocketIO

class SocketMan {

    private let socketManager = SocketManager(
        socketURL: URL(string: "http://internals.gridstone.com.au")!,
        config: [.forceWebsockets(true)])

    private lazy var socket: SocketIOClient = {
        return self.socketManager.defaultSocket
    }()

    func getDeviceIDs(completion: (([String])->())?) {
        socket.once("devices") { [weak self] data, ack in
            let devices = data
                .map{$0 as! [[String: AnyObject]]}
                .flatMap{$0}
                .flatMap{$0["deviceId"]} as! [String]

            ack.with("HAHA!", "THX")
            print(devices)
            self?.socket.disconnect()
            completion?(devices)
        }
        socket.connect()
    }

    func listenToError(completion: (()->())?) {
        socket.on("error") { data, ack in
            ack.with("HAHA!", "THX")
            completion?()
        }
        socket.connect()
    }

    func listenToData(completion: (((deviceID: String, isFree: Bool))->())?) {
        socket.on("data") { data, ack in

            var deviceID: String = ""
            var isFree: Bool = false

            for something in data {
                guard let object = something as? [String: AnyObject] else { return }
                guard let lightState = object["lightState"] as? String else { return }
                guard let deviceId = object["deviceId"] as? String else { return }

                deviceID = deviceId
                isFree = lightState == "0"

                print(deviceId)
                print(lightState == "0")
            }
            completion?((deviceID: deviceID, isFree: isFree))

            ack.with("HAHA!", "THX")
        }
        socket.connect()
    }
}
