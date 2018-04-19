//
//  InterfaceController.swift
//  MotionCollectorWatch Extension
//
//  Created by Aleksei Degtiarev on 01/04/2018.
//  Copyright © 2018 Aleksei Degtiarev. All rights reserved.
//

import WatchKit
import Foundation
import CoreMotion
import HealthKit


class MainIC: WKInterfaceController {
    
    // Statuses
    enum Status {
        case waiting
        case recording
    }
    
    var status: Status = Status.waiting {
        willSet(newStatus) {
            
            switch(newStatus) {
            case .waiting:
                waiting()
                break
                
            case .recording:
                recording()
                break
            }
        }
        didSet {
            
        }
    }
    
    // Outlets
    @IBOutlet var timer: WKInterfaceTimer!
    @IBOutlet var recIDLabel: WKInterfaceLabel!
    @IBOutlet var recNumberPicker: WKInterfacePicker!
    @IBOutlet var recordDataFromPhoneSwitch: WKInterfaceSwitch!
    
    // Constants
    let IDsAmount = 20
    let currentFrequency: Int = 60
    
    // For session saving
    var nextSessionid: Int = 0
    var recordTime: String = ""
    var sensorOutputs = [SensorOutput]()
    
    // Variables
    var recordID: Int = 0
    var currentSessionDate: NSDate = NSDate()
    
    // For motion getting
    let motion = CMMotionManager()
    let queue = OperationQueue()
    
    // For background work
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    
    
    // MARK - WKInterfaceController events
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // prepare recNumberPicker
        var items = [WKPickerItem]()
        for i in 0..<IDsAmount {
            let item = WKPickerItem()
            item.title = String (i)
            items.append(item)
        }
        recNumberPicker.setItems(items)
        
        
        // needs to be implemented
        // findLastSessionId()
        
        // Serial queue for sample handling and calculations.
        queue.maxConcurrentOperationCount = 1
        queue.name = "MotionManagerQueue"
        
        status = .waiting
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    
    
    // MARK - Control work of getting motion Data
    
    func startGettingData() {
        
        // If we have already started the workout, then do nothing.
        if (session != nil) {
            return
        }
        
        // Configure the workout session.
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .walking
        workoutConfiguration.locationType = .outdoor
        
        do {
            session = try HKWorkoutSession(configuration: workoutConfiguration)
        } catch {
            fatalError("Unable to create the workout session!")
        }
        
        // Start the workout session and device motion updates.
        healthStore.start(session!)
        
        // Check motion availability
        if !motion.isDeviceMotionAvailable {
            print("Device Motion is not available.")
            return
        }
        
        motion.deviceMotionUpdateInterval = 1.0 / Double(currentFrequency)
        motion.startDeviceMotionUpdates(to: queue) { (deviceMotion: CMDeviceMotion?, error: Error?) in
            if error != nil {
                print("Encountered error: \(error!)")
            }
            
            if deviceMotion != nil {
                
                let currenTime = self.returnCurrentTime()
                let GyroX = deviceMotion!.rotationRate.x
                let GyroY = deviceMotion!.rotationRate.y
                let GyroZ = deviceMotion!.rotationRate.z
                
                let AccX = deviceMotion!.gravity.x + deviceMotion!.userAcceleration.x;
                let AccY = deviceMotion!.gravity.y + deviceMotion!.userAcceleration.y;
                let AccZ = deviceMotion!.gravity.z + deviceMotion!.userAcceleration.z;
                
                print ( "Gyro: \(currenTime) \(GyroX), \(GyroY), \(GyroZ)")
                print ( "Acc : \(currenTime) \(AccX), \(AccY), \(AccZ)")
                
                
                let sensorOutput = SensorOutput()
                
                sensorOutput.timeStamp = Date() as NSDate
                sensorOutput.gyroX = GyroX
                sensorOutput.gyroY = GyroY
                sensorOutput.gyroZ = GyroZ
                sensorOutput.accX = AccX
                sensorOutput.accY = AccY
                sensorOutput.accZ = AccZ
                
                self.sensorOutputs.append(sensorOutput)
                
            }
        }
    }
    
    func stopGettingData() {
        // If we have already stopped the workout, then do nothing.
        if (session == nil) {
            return
        }
        
        // Stop the device motion updates and workout session.
        motion.stopDeviceMotionUpdates()
        healthStore.end(session!)
        
        // Clear the workout session.
        session = nil
    }
    
    
    func returnCurrentTime() -> String {
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        let nanoseconds = calendar.component(.nanosecond, from: date)
        
        let currentTime = "\(hour):\(minutes):\(seconds):\(nanoseconds)"
        
        return currentTime
    }
    
    
    
    // MARK - Action controlls
    
    @IBAction func startButtonPressed() {
        
        status = .recording
        
        // Start session recording
        currentSessionDate = NSDate()
    }
    
    @IBAction func stopButtonPressed() {
        
        //        // Finish session recording
        //        timer.invalidate()
        //
        //
        //        currentSession?.id = Int32(nextSessionid)
        //        currentSession?.date = NSDate()
        //        currentSession?.frequency = Int32(currentFrequency)
        //        currentSession?.isWalking = Int32(recordID)
        //
        //
        //        currentSession?.duration = recordTime
        //
        //        for sensorOutput in sensorOutputs {
        //
        //            let characteristicGyro = Characteristic (context:context)
        //            characteristicGyro.x = sensorOutput.gyroX!
        //            characteristicGyro.y = sensorOutput.gyroY!
        //            characteristicGyro.z = sensorOutput.gyroZ!
        //            characteristicGyro.toCharacteristicName = self.characteristicsNames[1]
        //
        //            let characteristicAcc = Characteristic (context:context)
        //            characteristicAcc.x = sensorOutput.accX!
        //            characteristicAcc.y = sensorOutput.accY!
        //            characteristicAcc.z = sensorOutput.accZ!
        //            characteristicAcc.toCharacteristicName = self.characteristicsNames[0]
        //
        //            let characteristicMag = Characteristic (context:context)
        //            characteristicMag.x = sensorOutput.magX!
        //            characteristicMag.y = sensorOutput.magY!
        //            characteristicMag.z = sensorOutput.magZ!
        //            characteristicMag.toCharacteristicName = self.characteristicsNames[2]
        //
        //
        //            let sensorData = SensorData(context: context)
        //            sensorData.timeStamp = sensorOutput.timeStamp
        //            sensorData.addToToCharacteristic(characteristicGyro)
        //            sensorData.addToToCharacteristic(characteristicAcc)
        //            sensorData.addToToCharacteristic(characteristicMag)
        //            self.currentSession?.addToToSensorData(sensorData)
        //
        //        }
        //
        //        sensorOutputs.removeAll()
        //
        //        currentSession = nil
        //        nextSessionid += 1
        
        status = .waiting
        
    }
    
    @IBAction func recordDataFromPhoneSwitchChanged(_ value: Bool) {
        
    }
    
    
    
    // MARK - Update changing state
    
    func waiting() {
        recNumberPicker.setEnabled(true)
        timer.stop()
        timer.setDate(Date(timeIntervalSinceNow: 0.0))
        recordDataFromPhoneSwitch.setEnabled(true)
        stopGettingData()
    }
    
    func recording() {
        recNumberPicker.setEnabled(false)
        timer.start()
        recordDataFromPhoneSwitch.setEnabled(false)
        startGettingData()
    }
}
