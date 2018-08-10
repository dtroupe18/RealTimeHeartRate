//
//  ViewController.swift
//  RealTimeHeartRate
//
//  Created by Dave Troupe on 8/10/18.
//  Copyright © 2018 Dave Troupe. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UITableViewController {
    
    var heartRateData = [HeartRate]()
    let healthStore = HKHealthStore()
    var queryTimer: Timer?
    var lastHeartRateTime: Date?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        requestPermission()
    }
    
    func requestPermission() {
        print("request permission fired")
        // iPad does not have access to HK so we won't be able to do this on an iPad... so sad
        let heartrate = HKQuantityType.quantityType(forIdentifier:HKQuantityTypeIdentifier.heartRate)
        let typesToRead: Set<HKObjectType> = [HKObjectType.workoutType(), heartrate!]
        HKHealthStore().requestAuthorization(toShare: nil, read: typesToRead, completion: { (success, error) in
            print("success: \(success)")
            print("error: \(String(describing: error))")
        })
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1 + heartRateData.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        if indexPath.row == 0 {
            cell.textLabel?.text = "press me to start listening"
        } else {
            cell.textLabel?.text = "HeartRate: \(heartRateData[indexPath.row - 1].bpm)"
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            startLookingForHeartRate()
        }
    }
    
    private func startLookingForHeartRate() {
        queryTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.getLatestHeartRate), userInfo: nil, repeats: true)
    }
    
    @objc func getLatestHeartRate() {
        print("get latest fired!")
        fetchLatestHeartRateSample(completion: { [weak self] sample in
            guard let sample = sample else { return }
            
            /// The completion is called on a background thread
            DispatchQueue.main.async {
                guard let sself = self else { return }
                let heartRate = HeartRate(sample: sample)
                
                // Check that we are still getting new data
                if sself.lastHeartRateTime == nil {
                    sself.lastHeartRateTime = heartRate.time
                    sself.heartRateData.append(heartRate)
                    sself.tableView.reloadData()
                } else if sself.lastHeartRateTime != nil && sself.lastHeartRateTime! != heartRate.time {
                    print("still getting new data \(heartRate.time)")
                    sself.lastHeartRateTime = heartRate.time
                    sself.heartRateData.append(heartRate)
                    sself.tableView.reloadData()
                } else {
                    // QWE: update this to alert the user to start a workout if the first two sample are the same
                    //
                    print("no longer getting new updates \(heartRate.time)")
                }
            }
        })
    }
    
    public func fetchLatestHeartRateSample(completion: @escaping (_ sample: HKQuantitySample?) -> Void) {
        
        /// Create sample type for the heart rate
        guard let sampleType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            print("nil completion")
            completion(nil)
            return
        }
        
        /// Predicate for specifiying start and end dates for the query
        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)
        
        /// Set sorting by date.
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        /// Create the query
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate,
                                  limit: Int(HKObjectQueryNoLimit),
                                  sortDescriptors: [sortDescriptor]) { (_, results, error) in
                
            guard error == nil else {
                print("Fetch Error: \(error!.localizedDescription)")
                return
            }
                
            completion(results?[0] as? HKQuantitySample)
        }
        self.healthStore.execute(query)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
