//
//  PieChartModel.swift
//  Toilet-v3
//
//  Created by Pavel Boryseiko on 1/5/17.
//  Copyright © 2017 GRIDSTONE. All rights reserved.
//

import Cocoa

struct PieChartModel {

    var toilet: Toilet

    var vacantTime: TimeInterval {
        return toilet.vacantHours.flatMap{$0}.reduce(0) { $0 + $1 }
    }

    var occupiedTime: TimeInterval {
        return toilet.occupiedHours.flatMap{$0}.reduce(0) { $0 + $1 }
    }

    var offlineTime: TimeInterval {
        return toilet.offlineHours.flatMap{$0}.reduce(0) { $0 + $1 }
    }

    var totalTime: TimeInterval {
        return vacantTime + offlineTime + occupiedTime
    }

    init(toilet: Toilet) {
        self.toilet = toilet
    }
}
