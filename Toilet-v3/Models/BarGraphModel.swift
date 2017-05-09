//
//  BarGraphModel.swift
//  Toilet-v3
//
//  Created by Pavel Boryseiko on 1/5/17.
//  Copyright © 2017 GRIDSTONE. All rights reserved.
//

import Cocoa

struct BarGraphModel {

    var toilets: [Toilet]
    var segment: BarSegement = .hourly

    var totalTimes: [TimeInterval] {
        let occupied = totalOccupiedTimes
        let totalVacant = toilets.map{$0.vacantHours}
        let totalOffline = toilets.map{$0.offlineHours}

        let vacant = (0..<totalVacant.first!.count).map { i in
            return totalVacant.reduce( 0 ) { $0 + $1[i] }
        }
        let offline = (0..<totalOffline.first!.count).map { i in
            return totalOffline.reduce( 0 ) { $0 + $1[i] }
        }

        let total = [vacant, offline, occupied]
        let results = (0..<total.first!.count).map { i in
            return total.reduce( 0 ) { $0 + $1[i] }
        }

        return results
    }

    var totalOccupiedTimes: [TimeInterval] {
        let first = toilets.map{$0.occupiedHours}
        let results = (0..<first.first!.count).map { i in
            return first.reduce( 0 ) { $0 + $1[i] }
        }
        return results
    }

    func occupiedTime(forIndex index: Int) -> TimeInterval {
        return totalOccupiedTimes[segment == .hourly ? index + 7 : index]
    }

    func totalTime(forIndex index: Int) -> TimeInterval {
        return totalTimes[segment == .hourly ? index + 7 : index]
    }

    init(toilets: [Toilet]) {
        self.toilets = toilets
    }
}
