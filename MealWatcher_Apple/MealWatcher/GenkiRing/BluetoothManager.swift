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
  File: BluetoothManager.swift
  Project: MealWatcher Phone App

  Created by Jimmy Nguyen on 7/17/23.
  Edited and Maintained by James Jolly since Dec 15, 2023
 
    Pupose:
 This file manages Bluetooth connection between a the iOS phone and the Bluetooth Ring (specifically, a Genki Ring).
 
 Phone acts as a Bluetooth central device and connects to the ring acting as a Bluetooth peripheral.
 Functions specify connections, disconnections, and bluetooth protocols,
 as well as opening files and streaming data from the ring.
*/
import Foundation
import CoreBluetooth


extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
}

class BluetoothViewModel: NSObject, ObservableObject, CBPeripheralDelegate {
    static let instance = BluetoothViewModel()
    var PhoneLogger = PhoneAppLogger.shared
    private var centralManager: CBCentralManager?
    private var peripherals: [CBPeripheral] = []
    var peripheralNames: [String] = []
    @Published var connectedPeripheral: CBPeripheral?
    @Published var waveRing: CBPeripheral?
    var APICharacteristic: CBCharacteristic?
    //let csv = CSVManager.instance
    let wavePacketLength = 111
    let maxPacketLength = 256
    var wavePacketTotalBytes: Int = 0
    //var wavePacket = [UInt8](repeating: 0, count: 260)
    var wavePacket: [UInt8] = []
    let file_manager = LocalFileManager.instance
    let vm = FileManagerViewModel()
    @Published var filename: String?
    var timeOffset: UInt64?
    @Published var allowNotifications: Bool = false
    @Published var currentURL: URL?
    // Initialize an NSOutputStream instance
    var outputStream: OutputStream?
    let serviceUUID = CBUUID(string: "65E9296C-8DFB-11EA-BC55-0242AC130003")
    
    // Periodic Timer Variables
    var counterPeriods = 0 // Used to print occasionally in sampling
    let PeriodTimerPeriod = TimeInterval(60 * 5) //Print every 5 minutes
    private var timerPeriodRecording: Timer?
    private var isPeriodTimerRunning: Bool = false
    // Max Timer Variables
    private var timerMaxRecording: Timer?
    private var isMaxTimerRunning: Bool = false
    
    @Published var errorFlag: Bool = false
    @Published var isRunning: Bool = false
    
    var PrintedOnlyOnce: Bool = false
    let DEBUG_SYS_TIMING_FLAG: Bool = true
    var PrintCounter: Int = 0 // Used to modulo the frequency of prints
    let DEBUG_PRINT_FLAG: Bool = false

    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .global())
    }
    
    // Connecting to a peripheral
    func connect(peripheral: CBPeripheral) {
        centralManager?.connect(peripheral, options: nil)
     }
    
    func connectWithUUID(ringUUID: UUID) {
        // Retrieve the peripherals with the specified UUID
        let connectedPeripherals = centralManager?.retrievePeripherals(withIdentifiers: [ringUUID])
        // Connect to the retrieved peripheral
        if let device = connectedPeripherals?.first {
            centralManager?.connect(device, options: nil)
        }

    }
        
    func disconnect(peripheral: CBPeripheral) {
        centralManager?.cancelPeripheralConnection(peripheral)
        self.timeOffset = nil
        guard let filename = self.filename else {return}
        self.file_manager.closeFile(filename: filename)

    }
    
    func NoFileDisconnect(peripheral: CBPeripheral) { //JPJ inserted file to use for first time paring ring
        centralManager?.cancelPeripheralConnection(peripheral)
        PhoneLogger.info(Subsystem: "BTMan", Msg: "Ring Disconnected")
    }
    
    func DeleteScanList() { //JPJ inserted file to use for first time paring ring
        self.peripherals = []
    }
    
    func DeleteConnectedDevice() { //JPJ inserted file to use for first time paring ring
        self.connectedPeripheral = nil
    }
    
    // Call after connecting to peripheral
    func discoverServices(peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }
     
    // Call after discovering services
    func discoverCharacteristics(peripheral: CBPeripheral) {
        guard let services = peripheral.services else {
            return
        }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func discoverDescriptors(peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        peripheral.discoverDescriptors(for: characteristic)
    }
    
    // reads characteristic
    func readValue(characteristic: CBCharacteristic) {
        self.connectedPeripheral?.readValue(for: characteristic)
    }
    
    func getUUID(peripheral: CBPeripheral) -> UUID? {
        // Assuming you have a connected peripheral stored in the variable 'connectedPeripheral'
        if let connectedPeripheral = self.connectedPeripheral {
            let deviceUUID = connectedPeripheral.identifier
            print("UUID of the connected Bluetooth device: \(deviceUUID)")
            return deviceUUID
        }
        else {
            //print("getUUID(): value of self.connectedPeripheral \(self.connectedPeripheral != nil ? "Device" : "nil")")
            return nil
        }

    }
}

extension BluetoothViewModel: CBCentralManagerDelegate {
    // gives state of the central manager
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async {
            if central.state == .poweredOn {
                self.centralManager?.scanForPeripherals(withServices: nil)
            }
        }
    }
    
    // provides list of BLE device names
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        DispatchQueue.main.async {
            if !self.peripherals.contains(peripheral) {
                self.peripherals.append(peripheral)
                self.peripheralNames.append(peripheral.name ?? "unnamed device")
                if peripheral.name == "Wave" {
                    self.PhoneLogger.info(Subsystem: "BTMan", Msg: "Found Wave Ring")
                    self.waveRing = peripheral
                    
                }
            }
        }
    }
    
    // Handles connection
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Successfully connected. Store reference to peripheral if not already done.
        DispatchQueue.main.async {
            self.connectedPeripheral = peripheral
            peripheral.delegate = self
            print("Successfully connected to", peripheral.name ?? "unnamed device")
            //guard let ring = self.waveRing else {return}
            guard let ring = self.connectedPeripheral else {return}
            self.discoverServices(peripheral: ring)
            self.isRunning = true
        }
    }
     
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        // Handle error
        self.isRunning = false
    }
    
    // Handles disconnection
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.PhoneLogger.error(Subsystem: "BTMan", Msg: "Disconnect Error: \(error)")
                self.stopRecording() // Stop all timers and close file stream since this is handled by ContentView when normally disconnecting
                self.errorFlag = true //trigger flag to alert those who are watching
                self.isRunning = false
                return
            }
            // Successfully disconnected
            self.isRunning = false
        }
    }
    
    // Discover services and characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if peripheral.services == nil {
            return
        }
        discoverCharacteristics(peripheral: peripheral)
        // print("Services: \(services)")
        print("BTManager: didDiscoverServices message")
    }
     
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            return
        }
        //print("Characteristics: \(characteristics)")
        // Consider storing important characteristics internally for easy access and equivalency checks later.
        // From here, can read/write to characteristics or subscribe to notifications as desired.
        for characteristic in characteristics {
            peripheral.discoverDescriptors(for: characteristic)
            if characteristic.uuid == CBUUID(string: "65e92bb1-8dfb-11ea-bc55-0242ac130003") {
                self.APICharacteristic = characteristic
                print("Atempting to Open current URL now that ring is found.")
                guard let openCurrentURL = self.currentURL else {
                    PhoneLogger.error(Subsystem: "BTMan", Msg: "File path does not exist")
                    return
                }
                self.timeOffset = nil // Reset offset so new file is forced to grab timestamp for new file
                self.startRecording(fileURL: openCurrentURL)
                PhoneLogger.info(Subsystem: "BTMan", Msg: "Ring Recording Started")
                if allowNotifications == true {
                    print("Starting notifications for ring")
                    peripheral.setNotifyValue(true, for: characteristic)
                }
                // Timers must be scheduled on Main (in .common background)
                // in order to have a RunLoop they can attach to
                DispatchQueue.main.async {
                    self.startMaxTimer()
                    self.startPeriodTimer()
                }
                
            }
        }
    }
    
    func setNotifyOff() {
        guard let peripheral = self.connectedPeripheral else {return}
        guard let characteristic = self.APICharacteristic else {return}
        peripheral.setNotifyValue(false, for: characteristic)
        //self.csv.readDataFromCSVFile(filename: "data")
        //self.csv.deleteCSVFile()
    }
    
    // Discover descriptors
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        guard let descriptors = characteristic.descriptors else { return }
        
        //print("\(descriptors)")
     
        // Get user description descriptor
        if let userDescriptionDescriptor = descriptors.first(where: {
            return $0.uuid.uuidString == CBUUIDCharacteristicUserDescriptionString
        }) {
            // Read user description for characteristic
            peripheral.readValue(for: userDescriptionDescriptor)
        }
    }
    
//    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
//        if let error = error {
//            print("Error enabling notifications: \(error.localizedDescription)")
//        } else {
//            print("Notifications enabled for \(characteristic.uuid)")
//        }
//    }
     
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        // Get and print user description for a given characteristic
        if descriptor.uuid.uuidString == CBUUIDCharacteristicUserDescriptionString,
            let userDescription = descriptor.value as? String {
            print("Characterstic \(String(describing: descriptor.characteristic?.uuid.uuidString)) is also known as \(userDescription)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        guard characteristic == self.APICharacteristic, let characteristicValue = characteristic.value else {
            PhoneLogger.warning(Subsystem: "BTMan", Msg: "Can't decode characteristic value")
            return
        }

        let byteArray = [UInt8](characteristicValue)
        for i in 0..<byteArray.count {
            //self.wavePacket[self.wavePacketTotalBytes] = byteArray[i]
            self.wavePacket.append(byteArray[i])
            self.wavePacketTotalBytes += 1
            if self.wavePacketTotalBytes >= self.maxPacketLength {
                PhoneLogger.warning(Subsystem: "BTMan", Msg: "WARNING: Restarting Packet since Max Packet Length exceeded.")
                self.wavePacket = []
                self.wavePacketTotalBytes = 0
                continue
            }
            //read next byte to wavePacket until ready to COBS Decode
            if byteArray[i] != 0 {
                continue
            }
            //Check if this is the 109 values we expect before logging data; 
            //     clear and restart if warning occurs
            if self.wavePacketTotalBytes != self.wavePacketLength { //take off the
                PhoneLogger.warning(Subsystem: "BTMan", Msg: "Skipping Packet of size \(self.wavePacketTotalBytes).")
                self.wavePacket = []
                self.wavePacketTotalBytes = 0
                continue
            }
            var sensorData = zeroParams()
            if let decodedData = decodeCOBS(wavePacket) {
                sensorData.gyrox = littleEndianHexToFloat(Array(decodedData[4..<8]))
                sensorData.gyroy = littleEndianHexToFloat(Array(decodedData[8..<12]))
                sensorData.gyroz = littleEndianHexToFloat(Array(decodedData[12..<16]))
                sensorData.accx = littleEndianHexToFloat(Array(decodedData[16..<20]))
                sensorData.accy = littleEndianHexToFloat(Array(decodedData[20..<24]))
                sensorData.accz = littleEndianHexToFloat(Array(decodedData[24..<28]))
                sensorData.magFieldx = littleEndianHexToFloat(Array(decodedData[28..<32]))
                sensorData.magFieldy = littleEndianHexToFloat(Array(decodedData[32..<36]))
                sensorData.magFieldz = littleEndianHexToFloat(Array(decodedData[36..<40]))
                sensorData.attitudew = littleEndianHexToFloat(Array(decodedData[56..<60]))
                sensorData.attitudex = littleEndianHexToFloat(Array(decodedData[60..<64]))
                sensorData.attitudey = littleEndianHexToFloat(Array(decodedData[64..<68]))
                sensorData.attitudez = littleEndianHexToFloat(Array(decodedData[68..<72]))
                sensorData.linaccx = littleEndianHexToFloat(Array(decodedData[84..<88]))
                sensorData.linaccy = littleEndianHexToFloat(Array(decodedData[88..<92]))
                sensorData.linaccz = littleEndianHexToFloat(Array(decodedData[92..<96]))
                
                let ringTimeStamp = getTimeStamp(Array(decodedData[101..<109]))
                if self.timeOffset == nil {
                    let since1970 = Date().timeIntervalSince1970 // Get the time interval since Jan 1, 1970
                    let timeInMilliseconds = UInt64(since1970 * 1000) // Convert the time interval to milliseconds
                    self.timeOffset = timeInMilliseconds - ringTimeStamp/1000
                    PhoneLogger.info(Subsystem: "BTMan", Msg: "Setting timeOffset to \(String(describing: self.timeOffset))")
                }
                sensorData.timeMeasurement = ringTimeStamp/1000 + (self.timeOffset ?? 0)
//                print("gyrox:",gyrox,"gyroy:",gyroy,"gyroz:",gyroz,"accx:",accx,"accy:",accy,"accz",accz)
//                print("Header is [\(wavePacket[0]), \(wavePacket[1]), \(wavePacket[2]), \(wavePacket[3])]. timestamp: \(sensorData.time)")
                
                //Grab SysTime for final timestamp
                let currSysTime = Date().timeIntervalSince1970
                // Convert the time interval to milliseconds and swap to big-endian (swift default is little-endian)
                let currSysTimeOutput = UInt64(currSysTime * 1000)
                sensorData.timeSystem = currSysTimeOutput
                


                
                let binaryData = Data(bytes: &sensorData, count: MemoryLayout<sensorParam>.size)
                if PrintedOnlyOnce == false {
                    print(MemoryLayout<sensorParam>.size)
                    PrintedOnlyOnce = true // Flip flag once printed
                }
                writeToStream(data: binaryData)
                
            } else {
                PhoneLogger.error(Subsystem: "BTMan", Msg: "Failed to decode COBS-encoded data.")
            }
            self.wavePacketTotalBytes = 0
            self.wavePacket = []
            
            
        }
    
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            // Handle the error if the write operation fails
            PhoneLogger.error(Subsystem: "BTMan", Msg: "Error writing value to characteristic: \(error.localizedDescription)")
        } else {
            // Write operation successful
            print("Value written to characteristic successfully")
        }
    }
    
    // Function to write data to the stream
    func writeToStream(data: Data) {
        guard let stream = self.outputStream else {
            PhoneLogger.warning(Subsystem: "BTMan", Msg: "Stream is not open")
            return
        }
        
        let buffer = [UInt8](data)
        let bytesWritten = stream.write(buffer, maxLength: buffer.count)
        if bytesWritten < 0 {
            PhoneLogger.error(Subsystem: "BTMan", Msg: "Write error")
        }
    }
    
    // Function to start recording
    func startRecording(fileURL: URL) {
        PhoneLogger.info(Subsystem: "BTMan", Msg: "Starting ring recording")
        self.outputStream = OutputStream(url: fileURL, append: true)
        self.outputStream?.open()
        print("Opening the FileStream in BluetoothManager.")
        
        // Mark the Current File as an active recording
        if (self.vm.newRecordingFile(startedFileURL: fileURL) == false) {
            PhoneLogger.warning(Subsystem: "BTMan", Msg: "Issue Setting CurrentFile in FileManager")
        }
        
        print("OutputStream Opened: Clearing WavePacket Data.")
        self.wavePacket = []
        self.wavePacketTotalBytes = 0
        // Clear offset to force grabbing start of fil
        self.timeOffset = nil
    }
    
    // Function to stop recording
    func stopRecording() {
        PhoneLogger.info(Subsystem: "BTMan", Msg: "Stopping ring recording")
        self.outputStream?.close()
        
        // Mark the Current File as an not an active recording
        if (self.vm.finishedRecordingFile() == false) {
            PhoneLogger.warning(Subsystem: "BTMan", Msg: "Issue clearing CurrentFile in FileManager")
        }
        print("OutputStream Closed: Clearing WavePacket Data.")
        self.wavePacket = []
        self.wavePacketTotalBytes = 0
        
        // Set offset to nil in case a new recording starts
        self.timeOffset = nil
        
        PhoneLogger.info(Subsystem: "BTMan", Msg: "Max and Periodic Timers stopping")
        self.timerMaxRecording?.invalidate()
        self.isMaxTimerRunning = false
        self.timerPeriodRecording?.invalidate()
        self.isPeriodTimerRunning = false
    }
    
    
    
    func startPeriodTimer() {
        // Invalidate the existing timer, if any
        timerPeriodRecording?.invalidate()
        self.counterPeriods = 0
        PhoneLogger.info(Subsystem: "BTMan", Msg: "Starting Periodic Timer, period = \(PeriodTimerPeriod) sec")
        
        // Create a new timer that fires at predefined period
        timerPeriodRecording = Timer.scheduledTimer(withTimeInterval: PeriodTimerPeriod, repeats: true) { _ in
            self.counterPeriods += 1
            self.PhoneLogger.info(Subsystem: "BTMan", Msg: "Phone Periodic Timer. Count \(self.counterPeriods)")
        }
        
        // Make sure the timer is added to the current run loop
        isPeriodTimerRunning = true
        RunLoop.current.add(timerPeriodRecording!, forMode: .common)
    }
    
    func stopPeriodTimer() {
        // Invalidate the timer when you want to stop it
        self.PhoneLogger.info(Subsystem: "BTMan", Msg: "Periodic Timer being stopped")
        isPeriodTimerRunning = false
        timerPeriodRecording?.invalidate()
    }
    
    func startMaxTimer() {
        // Invalidate the existing timer, if any
        timerMaxRecording?.invalidate()
        
        let TimeToRun = TimeInterval(60 * 60)
        PhoneLogger.info(Subsystem: "BTMan", Msg: "Starting Max Timer, limit = \(TimeToRun) sec")
        // Create a new timer that fires every 1 second
        timerMaxRecording = Timer.scheduledTimer(withTimeInterval: TimeToRun, repeats: false) { _ in
            self.PhoneLogger.error(Subsystem: "BTMan", Msg: "MAX TIMER EXPIRED!")
            if let connectedRing = self.waveRing {
                self.disconnect(peripheral: connectedRing)
            }
            self.stopRecording()
            self.stopMaxTimer()
            DispatchQueue.main.async {
                self.errorFlag = true // raise error
            }
        }
        
        // Make sure the timer is added to the current run loop
        isMaxTimerRunning = true
        RunLoop.current.add(timerMaxRecording!, forMode: .common)
    }

    
    
    func stopMaxTimer() {
        // Invalidate the timer when you want to stop it
        print("Max Timer being stopped")
        isMaxTimerRunning = false
        timerMaxRecording?.invalidate()
    }
    
    
    /// Function used for debugging bluetooth in main content view
    func DebugFunc() {
        print("Printing Peripheral List...")
        print(peripherals.count)
        for i in 0..<peripherals.count {
            print("#\(i): \(peripherals[i])")
        }
    }
}
