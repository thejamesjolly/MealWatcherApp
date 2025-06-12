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
  File: LoggerWatch.swift
  Project: MealWatcher Watch App

  Created by James Jolly on 5/31/24.
 
 Purpose:
 Defines a Class which is used by the phone app and all components to record log statements, warnings, and errors.
 
 FOR RELEASE: Set `DEBUG_PrintLogs` to false to avoid unnecessary calls to print; set to true to see all log statements in the terminal
*/


import SwiftUI
import Foundation
import os



class WatchAppLogger: ObservableObject {
    // Use to print log statements to console... Should be false in Release Mode
    // FIX BEFORE RELEASE OR DEBUG
    private let DEBUG_PrintLogs: Bool = false
    
    static let shared: WatchAppLogger = {
        let instance = WatchAppLogger()
        
        let vm = FileManagerViewModelWatch()
        @AppStorage("storedID") var participantID: String = "99999"
        
        // Get current date
        let date = Date()
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        
        instance.logFileName = (participantID+"-"+df.string(from: date)+"-watch.log")
        if let logFilePathCheck = vm.getFilePath(filename: instance.logFileName) {
            instance.logFilePath = logFilePathCheck
        }
        else {
            print("Error creating log file path! Using Default")
            instance.logFilePath = URL(string: "default-watch.log")
        }
        
        //PhoneLogger.logFilePath = logFilePathCheck
        print("Path in CV: \(String(describing: instance.logFilePath))")
        
        print("Attempting to open LogStream...")
        if let logPath = instance.logFilePath {
            instance.logStream = OutputStream(url: logPath, append: true)
            instance.logStream?.open()
            print("OutputStream Opened!")
        }
        else {
            print("Unable to open stream!")
        }
        
        
        return instance
    }()
    
    init() {
        print("Initializing Logger Class Instance!")
    }
    //Binding Variables
    
    // Local Variables
    private var logStream: OutputStream?
    private var logFileName: String = "default.log"
    private var logFilePath: URL?
    
    
    // Potential Swap of Subsystem argument to allow filename instead of string...
    // ...Forces Standard abbreviations but not necessary
    /*
    enum SubsysFile {
        case ExtendedRuntimeManager
        case LoggerWatch
        case WatchFileManager
        case Config
        case CMUtils
        case ContentView
    }
    
    private let SubsystemStrings: [String] = [

            "wERM", // case ExtendedRuntimeManager
            "wLogW",  // case LoggerWatch
            "wFileM", //case WatchFileManager
            "wConf", // case Config
            "wCMU", // case CMUtils
            "wCV", // case ContentView
            
            "Unknown" // Placeholder at end to not need a comma after string
    ]
    */
    // End of SubsystemEnum
    
    // Avoid creating DateFormatter frequently, as Logger counts into the execution budget.
    //
    private lazy var timeStampFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss.SSS"
        return dateFormatter
    }()
    
    // Use this dispatch queue to make the log file access thread-safe.
    // Public methods use performBlockAndWait to access the resource; private methods don't.
    //
    private lazy var ioQueue: DispatchQueue = {
        return DispatchQueue(label: "ioQueue")
    }()
    
    private func performBlockAndWait<T>(_ block: () -> T) -> T {
        return ioQueue.sync {
            return block()
        }
    }
    
    
    
//    func createLogFilePath(PID: String) {
//        let date = Date()
//        let df = DateFormatter()
//        df.dateFormat = "yyyy-MM-dd-HH-mm-ss"
//        self.logFileName = (PID+"-"+df.string(from: date)+"-phone.log")
//        self.logFilePath = self.fileMan.getFilePath(fileName: self.logFileName)
//
//        return
//    }
    func assignLogFilePath(filePath: URL) {
        self.logFilePath = filePath

        return
    }
    
     
    // Function to start recording
    func openLogStream() {
        guard let logFilePathCheck = self.logFilePath else {
            print("ERROR: Unable to Start Log File!!!")
            return
        }
        print("Opening the FileStream in BluetoothManager.")
        self.logStream = OutputStream(url: logFilePathCheck, append: true)
        self.logStream?.open()
        print("OutputStream Opened!")
        return
    }
    
    // Function to stop recording
    func stopLogStream() {
        self.logStream?.close()
        print("OutputStream Closed!")
        return
    }
    
    /// Terminates current log file and immediately begins a new file with current time.
    /// Intended to act as a software power cycle since watch app is rarely fully closed
    /// to trigger terminating the log file for each session.
    func TerminateAndStartNewLogFile() {
        // GENERATE NEW FILENAME
        let vm = FileManagerViewModelWatch()
        @AppStorage("storedID") var participantID: String = "99999"
        // Get current date
        let date = Date()
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        
        self.logFileName = (participantID+"-"+df.string(from: date)+"-watch.log")
        if let logFilePathCheck = vm.getFilePath(filename: self.logFileName) {
            self.logFilePath = logFilePathCheck
        }
        else {
            print("Error creating log file path! Using Default")
            self.logFilePath = URL(string: "default-watch.log")
        }
        
        // Stop current Log
        self.stopLogStream()
        
        // With New Filename assigned, open new stream
        self.openLogStream()
        return
    }

    /// Create an "info" log, used for standard log messages.
    /// Inputs are not allowed to have semicolons  in strings
    /// - Parameters:
    ///   - Subsystem: Short Category description to group log statements
    ///   - Msg: Message of the log entry
    func info(Subsystem: String, Msg: String) {
        guard let stream = self.logStream else {
            print("ERROR: Stream is not open!!!")
            return
        }
        
        let currDate = Date()
        let currTimestamp = timeStampFormatter.string(from: currDate)
        // Format Log String as "timestamp;Level;Subsytem;Msg"
        let logString = currTimestamp + ";I;"+Subsystem+";"+Msg+"\n"
        if DEBUG_PrintLogs == true {
            print("Logging Info Message: \(logString)", terminator: "")
        }
        performBlockAndWait {
            let bytesWritten = stream.write(logString, maxLength: logString.count)
            if bytesWritten < 0 {
                print("Write error")
            }
        }
    }
    
    
    /// Create an "Debug" log, used for active development log messages,
    /// which should be removed before release deployment.
    /// Inputs are not allowed to have semicolons  in strings
    /// - Parameters:
    ///   - Subsystem: Short Category description to group log statements
    ///   - Msg: Message of the log entry
    func debug(Subsystem: String, Msg: String) {
        guard let stream = self.logStream else {
            print("ERROR: Stream is not open!!!")
            return
        }
        
        let currDate = Date()
        let currTimestamp = timeStampFormatter.string(from: currDate)
        // Format Log String as "timestamp;Level;Subsytem;Msg"
        let logString = currTimestamp + ";D;"+Subsystem+";"+Msg+"\n"
        if DEBUG_PrintLogs == true {
            print("Logging Debug Message: \(logString)", terminator: "")
        }
        performBlockAndWait {
            let bytesWritten = stream.write(logString, maxLength: logString.count)
            if bytesWritten < 0 {
                print("Write error")
            }
        }
    }

    /// Create an "Warning" log, used to log not-ideal app behavior which the program
    /// has made a corrective action.
    /// Inputs are not allowed to have semicolons  in strings
    /// - Parameters:
    ///   - Subsystem: Short Category description to group log statements
    ///   - Msg: Message of the log entry
    func warning(Subsystem: String, Msg: String) {
        guard let stream = self.logStream else {
            print("ERROR: Stream is not open!!!")
            return
        }
        
        let currDate = Date()
        let currTimestamp = timeStampFormatter.string(from: currDate)
        // Format Log String as "timestamp;Level;Subsytem;Msg"
        let logString = currTimestamp + ";W;"+Subsystem+";"+Msg+"\n"
        if DEBUG_PrintLogs == true {
            print("Logging Warning Message: \(logString)", terminator: "")
        }
        performBlockAndWait {
            let bytesWritten = stream.write(logString, maxLength: logString.count)
            if bytesWritten < 0 {
                print("Write error")
            }
        }
    }
    
    /// Create an "Error" log, used to attempt to log catastrophic faults before the program aborts.
    /// Inputs are not allowed to have semicolons  in strings
    /// - Parameters:
    ///   - Subsystem: Short Category description to group log statements
    ///   - Msg: Message of the log entry
    func error(Subsystem: String, Msg: String) {
        guard let stream = self.logStream else {
            print("ERROR: Stream is not open!!!")
            return
        }
        
        let currDate = Date()
        let currTimestamp = timeStampFormatter.string(from: currDate)
        // Format Log String as "timestamp;Level;Subsytem;Msg"
        let logString = currTimestamp + ";E;"+Subsystem+";"+Msg+"\n"
        if DEBUG_PrintLogs == true {
            print("Logging Error Message: \(logString)", terminator: "")
        }
        performBlockAndWait {
            let bytesWritten = stream.write(logString, maxLength: logString.count)
            if bytesWritten < 0 {
                print("Write error")
            }
        }
    }

}
