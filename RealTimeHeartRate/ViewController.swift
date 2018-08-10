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
    
    var heartRateData = [Double]()
    let healthStore = HKHealthStore()
    var heartRateQuery: HKObserverQuery?
    var queryTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        requestPermission()
    }
    
    func requestPermission() {
        print("request permission fired")
        let heartrate = HKQuantityType.quantityType(forIdentifier:HKQuantityTypeIdentifier.heartRate)
        let typesToRead: Set<HKObjectType> = [HKObjectType.workoutType(), heartrate!]
        HKHealthStore().requestAuthorization(toShare: nil, read: typesToRead, completion: { (success, error) in
            print("success: \(success)")
            print("error: \(String(describing: error))")
        })
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1 + heartRateData.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = "press me to start listening"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            print("starting to listen")
            setUpBackgroundDeliveryForDataTypes()
        }
    }
    
    private func startLookingForHeartRate() {
        // queryTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: self.fe, userInfo: <#T##Any?#>, repeats: <#T##Bool#>)
    }
    
    private func listenForHeartRateUpdates() {
        guard let sampleType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else { print("shits nil"); return }

        let query = HKObserverQuery(sampleType: sampleType, predicate: nil, updateHandler: { (observeQuery, completion, error) in
            if error != nil {
                // Perform Proper Error Handling Here...
                print("*** An error occured while setting up the stepCount observer. \(error!.localizedDescription) ***")
                abort()
            }

            // Take whatever steps are necessary to update your app's data and UI
            // This may involve executing other queries
            print("query: \(observeQuery)")
            self.healthStore.execute(observeQuery)
            

            // If you have subscribed for background updates you must call the completion handler here.
            // completionHandler()

        })
        healthStore.execute(query)

    }
    
    private func setUpBackgroundDeliveryForDataTypes() {
        guard let sampleType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else { print("shits nil"); return }
        
        let query = HKObserverQuery(sampleType: sampleType, predicate: nil, updateHandler: { [weak self] query, completion, error in
            guard let strongSelf = self else { return }
            
            if error != nil {
                print("Error: \(error!.localizedDescription)")
            }
            strongSelf.queryForUpdates(sampleType)
            completion()
        })
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: sampleType, frequency: .immediate, withCompletion: { success, err in
            if err != nil {
                print("background error: \(err!.localizedDescription)")
            }
        })
    }
    
    private func queryForUpdates(_ type: HKObjectType) {
        print("37")
        if type == HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) {
            fetchLatestHeartRateSample(completion: { sample in
                print("sample: \(sample)")
            })
        }
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
