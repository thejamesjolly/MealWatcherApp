/**
 <MealWatcher is a phone & watch application to record motion data from a watch and smart ring>
 Copyright (C) <2023>  <James Jolly, Faria Armin, Adam Hoover>

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/**
  File: CMUtils.swift
  Project: MealWatcher Watch App

  Created by Cameron Burroughs on 3/22/22.
  Edited and moved to project by Jimmy Nguyen in Summer of 2023.
  Edited and Maintained by James Jolly since Dec 15, 2023
 
    Purpose:
 Defines and manages watch sensor data streams and recordings to files.
 
Utilizes CoreLocation Manager to maintain background processing while user is not looking at the watch
*/

import Foundation
import CoreMotion
import WatchKit

public var samplingRate = 100

struct sensorParam {
    
    // gyro values
    var gyrox: Float32
    var gyroy: Float32
    var gyroz: Float32
    
    // acc values
    var accx: Float32
    var accy: Float32
    var accz: Float32
    
    var magFieldx: Float32
    var magFieldy: Float32
    var magFieldz: Float32
    
    var attitudex: Float32
    var attitudey: Float32
    var attitudez: Float32
    var attitudew: Float32
    
    var linaccx: Float32
    var linaccy: Float32
    var linaccz: Float32
    
    var timeMeasurement: UInt64
    var timeSystem: UInt64
}

// Class CMutils implements functionality using CoreMotion framework
class CMUtils: NSObject {
    
    var WatchLogger = WatchAppLogger.shared
    @Published var maxTimerErrorFlag = false
    //let file_manager = LocalFileManager.instance
    let manager = CMMotionManager()
    let queue = OperationQueue()
    
    var LocationManager = BGLocationManager.shared
    
    let interval = 1.0/Double(samplingRate)
    @Published var timeOffset: UInt64?
    let degreeConv = 180.0/Double.pi
    var outputStream: OutputStream?
    let vm = FileManagerViewModelWatch()
    @Published var currentURL: URL?
    
    // Periodic Timer variables
    var counterPeriods = 0 // Used to print occasionally in sampling
//    let CntEveryXSamples = 3000 // how many samples to print before printing occasionally
    let PeriodTimerPeriod = TimeInterval(60 * 5) //Print every 5 minutes
    @Published private var timerPeriodRecording: Timer?
    @Published private var isPeriodTimerRunning: Bool = false
    
    // Max Timer Variables
    @Published private var timerMaxRecording: Timer?
    @Published private var isMaxTimerRunning: Bool = false
    
    
    override init() {
    }
    
    // Requests healthstore access, establishes bckgnd session to record sensor data
    // Documentation for setting up a background workout session found here
    //https://developer.apple.com/documentation/healthkit/workouts_and_activity_rings/running_workout_sessions
    
    
    // Sets struct to all zeros, diagnostic to see where we are/aren't getting data
    func zeroParams() -> sensorParam {
        let sensorData = sensorParam(gyrox: 0, gyroy: 0, gyroz: 0, accx: 0, accy: 0, accz: 0, magFieldx: 0, magFieldy: 0, magFieldz: 0, attitudex: 0, attitudey: 0, attitudez: 0, attitudew: 1.0, linaccx: 0, linaccy: 0, linaccz: 0, timeMeasurement: 0, timeSystem: 0)
        return sensorData
    }
    
    // Begins data retrieval from sensors and appends to csv file in background
    func startUpdates(filename: String) {
//        startWorkoutSession()
        WatchLogger.info(Subsystem: "wCMU", Msg: "Starting LocManager")
        LocationManager.start()
        
        self.currentURL = vm.getFilePath(filename: filename)
        guard let currentURL = currentURL else {return}
        self.startRecording(fileURL: currentURL)
        

        // Verify device-motion service is available on device
        if !manager.isDeviceMotionAvailable {
            fatalError("Device motion not available.")
        }

        // Set sampling rate
        let interval = 1/Double(samplingRate)
        print("Interval is: ", interval)
        
        manager.deviceMotionUpdateInterval = interval
        
        print("Device motion interval:", manager.deviceMotionUpdateInterval)
        // Continually gets motion data and updates CSV file
        manager.startDeviceMotionUpdates(to: queue){ [self] (data,err) in
            if err != nil {
                print("Error starting Device Updates: \(err!)")
            }
            var sensorData = self.zeroParams()
            
            let gravity = data!.gravity
            if data != nil {
//                self.counter = self.counter + 1 // Increment for the new sample
                
                sensorData.accx = Float(data!.userAcceleration.x + gravity.x)
                sensorData.accy = Float(data!.userAcceleration.y + gravity.y)
                sensorData.accz = Float(data!.userAcceleration.z + gravity.z)
                sensorData.gyrox = Float(data!.rotationRate.x * self.degreeConv)
                sensorData.gyroy = Float(data!.rotationRate.y * self.degreeConv)
                sensorData.gyroz = Float(data!.rotationRate.z * self.degreeConv)
                
                sensorData.linaccx = Float(data!.userAcceleration.x)
                sensorData.linaccy = Float(data!.userAcceleration.y)
                sensorData.linaccz = Float(data!.userAcceleration.z)
                
                sensorData.attitudex = Float(data!.attitude.quaternion.x)
                sensorData.attitudey = Float(data!.attitude.quaternion.y)
                sensorData.attitudez = Float(data!.attitude.quaternion.z)
                sensorData.attitudew = Float(data!.attitude.quaternion.w)
                
                sensorData.magFieldx = Float(data!.magneticField.field.x)
                sensorData.magFieldy = Float(data!.magneticField.field.y)
                sensorData.magFieldz = Float(data!.magneticField.field.z)

                
                let CMTimeStamp = data!.timestamp
                if self.timeOffset == nil {
                    let since1970 = Date().timeIntervalSince1970 // Get the time interval since Jan 1, 1970
                    let timeInMilliseconds = UInt64(since1970 * 1000) // Convert the time interval to milliseconds
                    self.timeOffset = timeInMilliseconds - UInt64(CMTimeStamp*1000)
                    WatchLogger.info(Subsystem: "wCMU", Msg: "TimeOffset currently nil... Setting to \(String(describing: self.timeOffset)))")
                }
                sensorData.timeMeasurement = UInt64(CMTimeStamp*1000)+(self.timeOffset ?? 0)
                
//                if self.counter >= self.CntEveryXSamples {
//                    self.counter = 0
////                    print("timestamp: \(sensorData.time)")
////                    print("Acc: \(sensorData.accx), \(sensorData.accy), \(sensorData.accz) - Gyro: \(sensorData.gyrox), \(sensorData.gyroy), \(sensorData.gyroz)")
//                    let uptime = UInt64(ProcessInfo.processInfo.systemUptime)
//                    print("Core Motion Timestamp: \(sensorData.timeMeasurement), Time since last boot (seconds): \(uptime), Offset: \(sensorData.timeMeasurement-uptime)")

                
                //Grab SysTime for final timestamp
                let currSysTime = Date().timeIntervalSince1970
                // Convert the time interval to milliseconds and swap to big-endian (swift default is little-endian)
                let currSysTimeOutput = UInt64(currSysTime * 1000)
                sensorData.timeSystem = currSysTimeOutput
                
                let binaryData = Data(bytes: &sensorData, count: MemoryLayout<sensorParam>.size)
                self.writeToStream(data: binaryData)
                
            }
        }   
        
    }
    
    // Stops device motion updates
    func stopUpdates(filename: String) {
        print("Stopping device motion updates ...")
        self.timeOffset = nil
        self.stopRecording()
        manager.stopDeviceMotionUpdates()
//        endWorkoutSession()
        WatchLogger.info(Subsystem: "wCMU", Msg: "Stopping LocManager")
        LocationManager.stop()
    }
    
    // Handles sensor data struct, formats to string to write to csv
    // Change how data is written to file here
    func sortData (usingData params: sensorParam) -> String {
        return "\(params.timeMeasurement),\(params.timeSystem), \(params.accx),\(params.accy),\(params.accz), \(params.gyrox),\(params.gyroy),\(params.gyroz), \(params.linaccx),\(params.linaccy),\(params.linaccz), \(params.attitudex),\(params.attitudey),\(params.attitudez),\(params.attitudew), \(params.magFieldx),\(params.magFieldy),\(params.magFieldz)\n"
    }
    
    

    
    // Function to write data to the stream
    func writeToStream(data: Data) {
        guard let stream = self.outputStream else {
            print("Stream is not open")
            return
        }
        
        let buffer = [UInt8](data)
        let bytesWritten = stream.write(buffer, maxLength: buffer.count)
        if bytesWritten < 0 {
            print("Write error")
        }
    }
    
    // Function to start recording
    func startRecording(fileURL: URL) {
        self.timeOffset = nil // Clear offset to allow for 
        self.outputStream = OutputStream(url: fileURL, append: true)
        self.outputStream?.open()
        
        // Mark the Current File as an active recording
        if (self.vm.newRecordingFile(startedFileURL: fileURL) == false) {
            WatchLogger.warning(Subsystem: "CMU", Msg: "Issue Setting CurrentFile in FileManager")
        }
        
        self.startMaxTimer()
        self.startPeriodTimer()
    }
    
    // Function to stop recording
    func stopRecording() {
        WatchLogger.info(Subsystem: "CMU", Msg: "Stopping Watch Recording")
        self.outputStream?.close()
        
        // Mark the Current File as an not an active recording
        if (self.vm.finishedRecordingFile() == false) {
            WatchLogger.warning(Subsystem: "BTMan", Msg: "Issue clearing CurrentFile in FileManager")
        }
        
        self.timerMaxRecording?.invalidate()
        self.timerPeriodRecording?.invalidate()
    }
    
    func startPeriodTimer() {
        // Invalidate the existing timer, if any
        timerPeriodRecording?.invalidate()
        self.counterPeriods = 0
        print("Starting Max Timer")
        isPeriodTimerRunning = true
        // Create a new timer that fires at predefined period
        timerPeriodRecording = Timer.scheduledTimer(withTimeInterval: PeriodTimerPeriod, repeats: true) { _ in
            self.counterPeriods += 1
            self.WatchLogger.info(Subsystem: "CMU", Msg: "Watch Periodic Timer. Count \(self.counterPeriods)")
        }
        
        // Make sure the timer is added to the current run loop
        RunLoop.current.add(timerPeriodRecording!, forMode: .common)
    }
    
    func stopPeriodTimer() {
        // Invalidate the timer when you want to stop it
        self.WatchLogger.info(Subsystem: "CMU", Msg: "Periodic Timer being stopped")
        isPeriodTimerRunning = false
        timerPeriodRecording?.invalidate()
    }
    
    
    func startMaxTimer() {
        // Invalidate the existing timer, if any
        timerMaxRecording?.invalidate()
        print("Starting Max Timer")
        isMaxTimerRunning = true
        maxTimerErrorFlag = false // clear flag for new timer
        // One hour timer, minus 10 seconds to beat workout session expiration
        let TimeToRun = TimeInterval(60 * 60 - 10)
        // Create a new timer that fires every 1 second
        timerMaxRecording = Timer.scheduledTimer(withTimeInterval: TimeToRun, repeats: false) { _ in
            self.WatchLogger.error(Subsystem: "CMU", Msg: "MAX TIMER EXPIRED!")
            self.stopRecording()
            self.stopMaxTimer()
            // Raise flag error to triggerwatch face update
            self.maxTimerErrorFlag = true
        }
        
        
        // Make sure the timer is added to the current run loop
        RunLoop.current.add(timerMaxRecording!, forMode: .common)
    }
    
    func stopMaxTimer() {
        // Invalidate the timer when you want to stop it
        self.WatchLogger.info(Subsystem: "CMU", Msg: "Max Timer being stopped")
        isMaxTimerRunning = false
        timerMaxRecording?.invalidate()
    }
    
    
    
}




