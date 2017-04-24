//
//  ContentViewController.swift
//  Toilet-v3
//
//  Created by Pavel Boryseiko on 24/4/17.
//  Copyright © 2017 GRIDSTONE. All rights reserved.
//

import Cocoa
import Charts

internal class ContentViewController: NSViewController {

    @IBOutlet weak var descriptionLabel: NSTextField!
    @IBOutlet weak var pieChartView: PieChartView!
    @IBOutlet weak var terminateButton: NSButton!

    internal var desc: String = "Loading..."
    internal var data: [String: TimeInterval]? = [String: TimeInterval]()

    override func viewWillAppear() {
        super.viewWillAppear()
        updateDescription()
        updatePieChart()
        pieChartView.animate(xAxisDuration: 0.0, yAxisDuration: 1.0)
    }

    internal func updateDescription() {
        descriptionLabel.stringValue = desc
    }

    internal func updatePieChart() {
        pieChartView.data = PieChartData(dataSets: newDataSet())
    }

    private func newDataSet() -> [PieChartDataSet] {
        var dataSets = [PieChartDataSet]()

        let ds1: PieChartDataSet?
        let ds2: PieChartDataSet?
        let ds3: PieChartDataSet?

        if self.data?["vacant"] != 0.0 {
            ds1 = PieChartDataSet()
            ds1!.label = "Vacant"
            let _ = ds1!.addEntry(PieChartDataEntry(value: self.data!["vacant"]!))
            dataSets.append(ds1!)
        }

        if self.data?["occupied"] != 0.0 {
            ds2 = PieChartDataSet()
            ds2!.label = "Occupied"
            let _ = ds2!.addEntry(PieChartDataEntry(value: self.data!["occupied"]!))
            dataSets.append(ds2!)
        }

        if self.data?["offline"] != 0.0 {
            ds3 = PieChartDataSet()
            ds3!.label = "Offline"
            let _ = ds3!.addEntry(PieChartDataEntry(value: self.data!["offline"]!))
            dataSets.append(ds3!)
        }

        print("updatng dataset")
        return dataSets
    }

    @IBAction func terminateHandler(_ sender: NSButton) {
        NSApp.terminate(sender)
    }
}
