//
//  HeartRate.swift
//  RealTimeHeartRate
//
//  Created by Dave Troupe on 8/10/18.
//  Copyright © 2018 Dave Troupe. All rights reserved.
//

import Foundation
import HealthKit

private let heartRateUnit = HKUnit(from: "count/min")

struct HeartRate {
    let time: Date
    let bpm: Double
    
    init(sample: HKQuantitySample) {
        self.time = sample.startDate
        self.bpm = sample.quantity.doubleValue(for: heartRateUnit)
    }
}
