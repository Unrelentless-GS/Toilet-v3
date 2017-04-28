//
//  TestViewController.swift
//  Toilet-v3
//
//  Created by Pavel Boryseiko on 28/4/17.
//  Copyright © 2017 GRIDSTONE. All rights reserved.
//

import Cocoa

class TestViewController: NSViewController {

    @IBOutlet weak var barGraph: BarGraph!

    internal var data: [[ToiletStatus: TimeInterval]] = [[ToiletStatus: TimeInterval]]() {
        didSet {
            barGraph.data = data
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }
}
