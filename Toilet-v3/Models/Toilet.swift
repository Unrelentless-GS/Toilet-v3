//
//  HourStats.swift
//  Toilet-v3
//
//  Created by Pavel Boryseiko on 1/5/17.
//  Copyright © 2017 GRIDSTONE. All rights reserved.
//

import Cocoa

class Toilet {
    var occupiedHours = [TimeInterval]()
    var vacantHours = [TimeInterval]()
    var offlineHours = [TimeInterval]()

    var status: ToiletStatus = .vacant
    var sinceDate: Date = Date()

    var number: Int

    init(number: Int) {
        self.number = number
        for _ in 0..<24 {
            occupiedHours.append(0)
            vacantHours.append(0)
            offlineHours.append(0)
        }
    }
}
