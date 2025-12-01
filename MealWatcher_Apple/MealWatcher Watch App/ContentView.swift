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
 File: ContentView.swift
 Project: MealWatcher Watch App

 Created by Jimmy Nguyen on 6/4/23.
 Edited and Maintained by James Jolly since Dec 15, 2023

    Purpose:
 Main Screen of the MealWatcher Watch App
 
 Handles watch side of "4Tap" protocol, which primarily focuses sensor start and stop locally on watch.
 Additionally handles offers some buttons (more in developer view) to access files currently stored in watch.
 This screen initializes the Watch Logger on start up,
 and handles most of the multi-component reactionary callbacks for the app (such as transfering a file to phone)
 
    Credits:
 Long Press Button features modeled after tutorial by Peter Steinberger at
 https://steipete.com/posts/supporting-both-tap-and-longpress-on-button-in-swiftui/
*/

import SwiftUI
import WatchConnectivity
import HealthKit
import WatchKit



class ExtensionDelegate: NSObject, WKApplicationDelegate, WKExtensionDelegate {

    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    
    override init(){
        super.init()
    }
    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
        print("DidFinishLaunching()")
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("DidBecomeActive()")
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
        print("WillResignActive()")
    }
    
    func applicationDidEnterBackground() {
        // This method is called when an iOS app is running, but no longer in the foreground.
        print("DidEnterBackground()")
    }
    
    func applicationWillTerminate() {
        // app is about to terminate.
        print("applicationWillTerminate()")

    }

    func handle(_ workoutConfiguration: HKWorkoutConfiguration)
    {
        //presentAlert()
        WKInterfaceDevice.current().play(.retry)

    }


}


struct ContentView: View {
    
    @StateObject var WatchLogger = WatchAppLogger.shared
    
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    @StateObject private var vmWatch = FileManagerViewModelWatch()
    
    @State var extendedSession = WKExtendedRuntimeSession()
    @State var extendedDelegate = ExtendedRuntimeManager()

    //State private var appDelegate = ExtensionDelegate()
    //@State var appStartDelegate = ExtensionDelegate()
    
    /* CSV File management */
    let cmutils = CMUtils()
    var filePath: String = ""
    var fileName: String = ""
    @State private var mostRecentFileName: String = "Unknown"
    @State var dataCount = 0
    @State var sensorFlag: Bool = false
    @AppStorage("storedID") var participantID: String = "99999"
    
    /* USED FOR JAMES EDITS IN FORCING TRANSFER TO PHONE APP */
    @State var Txfr_ButtonUpdateFlag: Bool = false
    
    // Main & Repo Folder Variables used for developer view send
    @State var Main_ButtonLabel: String = "REFRESH?"
    @State var Main_ButtonUpdateFlag: Bool = false
    @State var Main_CurrentFiles: [String] = ["No Files"]
    @State var Main_FileLabelCount: Int = 0
    @State var Main_CurrFileLabelIndex: Int = 0
    
    @State var Repo_ButtonLabel: String = "REFRESH?"
    @State var RepoDataCount: Int = 0
    @State var RepoCurrentFiles: [String] = ["No Files"]
    @State var RepoFileLabelCount: Int = 0
    @State var RepoCurrFileLabelIndex: Int = 0
    
    // Debug variables used to generate sizeable files on watch without recording
    private var GenerateFileButtonFlag: Bool = false // displays button to generate files in DevView
    @State var fillerFilesCnt: Int = 0 // used to make unique filenames
    
    // Variables used to handle long press of sensor button
    @State var didLongPress = false
    @GestureState private var isDetectingLongPress = false
    @State private var completedLongPress = false
    
    @State private var deleteRepoAlert: Bool = false

    
    var body: some View {
        
        ScrollView{
            VStack {
                
                Text(participantID)
                    .onAppear {
                        
                        RepoCurrentFiles = vmWatch.getAllFileNames(folderSelect: .dataRepoFolder)
                        RepoDataCount = RepoCurrentFiles.count
                        Main_CurrentFiles = vmWatch.getAllFileNames()
                        Main_FileLabelCount = Main_CurrentFiles.count
                        
                        // FIX BEFORE RELEASE OR DEBUG
                        WatchLogger.info(Subsystem: "wCV", Msg: "Starting Watch App v1.3(5)")
                        
                        // Add Device and OS information
                        WatchLogger.info(Subsystem: "CV", Msg: "OS = \(WKInterfaceDevice.current().systemName) \(WKInterfaceDevice.current().systemVersion)")
                        var size = 0
                        sysctlbyname("hw.machine", nil, &size, nil, 0)
                        var machine = [CChar](repeating: 0,  count: size)
                        sysctlbyname("hw.machine", &machine, &size, nil, 0)
                        WatchLogger.info(Subsystem: "CV", Msg: "Model = \(WKInterfaceDevice.current().model); Machine = \(String(cString:machine))")
                        
                        // Add a statement about intial value of Watch Battery Life
                        WKInterfaceDevice.current().isBatteryMonitoringEnabled = true
                        WatchLogger.info(Subsystem: "wCV", Msg: "Battery at \(Int(roundf(WKInterfaceDevice.current().batteryLevel * 100)))% Charge")
                        
                        // Wrist Orientation
                        if (WKInterfaceDevice.current().wristLocation == .left) {
                            WatchLogger.info(Subsystem: "wCV", Msg: "Watch on LEFT Wrist")
                        }
                        else if (WKInterfaceDevice.current().wristLocation == .right) {
                            WatchLogger.info(Subsystem: "wCV", Msg: "Watch on RIGHT Wrist")
                        }
                        // Crown Orientation
                        if (WKInterfaceDevice.current().crownOrientation == .left) {
                            WatchLogger.info(Subsystem: "wCV", Msg: "Crown is on LEFT")
                        }
                        else if (WKInterfaceDevice.current().wristLocation == .right) {
                            WatchLogger.info(Subsystem: "wCV", Msg: "Crown is on RIGHT")
                        }
                        
                        // Send any files that happen to still be on the watch on launch
                        TransferAllFiles(mainFolderFlag: true)
                    }
                
                // Sensor Toggle Button
                Button {
                    if didLongPress {
                        didLongPress = false
                    } else { // If a short tap
                        
                        WatchLogger.info(Subsystem: "wCV", Msg: "Sensor Button Tapped with sensorFlag=\(connectivityManager.sensorFlag)")
                        
                        // if currently off, turn on sensors
                        if (connectivityManager.sensorFlag == false) {
                            WCSession.default.sendMessage(["sensor-flag-set" : true], replyHandler: { reply in
                                print(reply)
                                if let flag = reply["sensor-flag"] as? Bool {
                                    WatchLogger.info(Subsystem: "wCV", Msg: "Sensor Button Pressed and should be set: Value is \(flag)")
                                    DispatchQueue.main.async {
                                        connectivityManager.sensorFlag = flag
                                    }
                                }
                            },
                                                          errorHandler: { (error) in
                                WatchLogger.error(Subsystem: "wCV", Msg: "Error with button press flag=false -- \(error.localizedDescription)")
                            })
                        }
                        // if currently on, ignore quick tap
                        else { // if (connectivityManager.sensorFlag == true) {
                            WatchLogger.warning(Subsystem: "wCV", Msg: "Ignoring short tap while sensors are on")
                        }
                    }
                } label:  {
                    SensorButton(flag: connectivityManager.sensorFlag)
                }
                // None of this ever fires on Mac Catalyst :(
                .simultaneousGesture(LongPressGesture(minimumDuration: 1.0).onEnded { _ in
                    didLongPress = true
                    
                    WatchLogger.info(Subsystem: "wCV", Msg: "Sensor Button Long Pressed with sensorFlag=\(connectivityManager.sensorFlag)")
                    
                    // if currently off, ignore long press
                    if (connectivityManager.sensorFlag == false) {
                        WatchLogger.warning(Subsystem: "wCV", Msg: "Ignoring long press while sensors are off")
                    }
                    // if currently on, turn sensors off
                    else { //if connectivityManager.sensorFlag == true}
                        WCSession.default.sendMessage(["sensor-flag-clear" : true], replyHandler: { reply in
                            print(reply)
                            if let flag = reply["sensor-flag"] as? Bool {
                                WatchLogger.info(Subsystem: "wCV", Msg: "Sensor Button Pressed and should be cleared: Value is \(flag)")
                                DispatchQueue.main.async {
                                    connectivityManager.sensorFlag = flag
                                }
                            }
                        },
                                                      errorHandler: { (error) in
                            WatchLogger.error(Subsystem: "wCV", Msg: "Error with button pressflag=true -- \(error.localizedDescription)")
                        })
                    }
                })
                .simultaneousGesture(TapGesture().onEnded {
                    didLongPress = false
                })
                
                // Text stating "TAP TO START/STOP"
                Group {
                    if (connectivityManager.sensorFlag == true) {
                        Text("^^ LONG PRESS to Stop") // If button is currently off
                            .foregroundColor(.gray)
                            .bold()
                    }
                    else { // If button is currently off
                        Text("^^ TAP to Start")
                            .foregroundColor(.gray)
                            .bold()
                    }
                }
                .padding()
                
                
                // Button to Force Transfer All Files
                Button(action: {
                    WatchLogger.info(Subsystem: "wCV", Msg: "Pressed File Button")
                    dataCount = vmWatch.listSize()
                    WatchLogger.info(Subsystem: "wCV", Msg: "\(dataCount) Files still on Watch")
                    Txfr_ButtonUpdateFlag = true
                },label: {
                    Text("Force Send Files")
                        .foregroundColor(.purple)
                })
                .padding()
                
                
                // Buttton to Generate Filler Files on Watch
                if GenerateFileButtonFlag == true && connectivityManager.DevViewFlag == true {
                    Button(action: {
                        if (vmWatch.generateFillerFile(filename: "testFile\(fillerFilesCnt).txt", kBytesToWrite: 7500)){
                            print("Successfully created File testFile\(fillerFilesCnt).txt")
                        }
                        
                        else {
                            print("Error Creating test File.")
                        }
                        fillerFilesCnt = fillerFilesCnt + 1
                    },label: {
                        Text("Generate Filler File \(fillerFilesCnt)")
                            .foregroundColor(.purple)
                    })
                    .padding()
                    
                }
                
                // Buttons to Send individual files from Main folder or Repo Folder
                if connectivityManager.DevViewFlag == true { // debug
                    
                    // MAIN FOLDER Button cycles through and sends individual files
                    Button(action: {
                        WatchLogger.info(Subsystem: "wCV", Msg: "MainButton Pressed")
                        if (Main_ButtonLabel == "REFRESH?") {
                            // Refresh File Stats
                            Main_CurrentFiles = vmWatch.getAllFileNames()
                            Main_FileLabelCount = Main_CurrentFiles.count
                            
                            if (Main_FileLabelCount > 0) {
                                Main_CurrFileLabelIndex = 0
                                Main_ButtonLabel = Main_CurrentFiles[Main_CurrFileLabelIndex]
                                WatchLogger.info(Subsystem: "wCV", Msg: "\(Main_FileLabelCount) files in main folder.")
                            }
                            else {
                                Main_ButtonLabel = "NONE"
                                WatchLogger.info(Subsystem: "wCV", Msg: "No files in main folder.")
                            }
                        }
                        else if (Main_ButtonLabel == "NONE") {
                            Main_ButtonLabel = "REFRESH?"
                            WatchLogger.info(Subsystem: "wCV", Msg: "Setting MainButton to Refresh")
                        }
                        else {
                            // attempt to send current file
                            print("Main_CurrFileLabelIndex: \(Main_CurrFileLabelIndex)")
                            let currFileURL = vmWatch.getFilePath(filename: Main_CurrentFiles[Main_CurrFileLabelIndex], folderSelect: .mainFolder)
                            if currFileURL == nil {
                                WatchLogger.error(Subsystem: "wCV", Msg: "Error grabbing Main File URL")
                            }
                            else { // Valid File URL
                                self.sendDataObserver(fileURL: currFileURL!)
                            }
                            
                            //if next file name is still valid
                            if (Main_CurrFileLabelIndex+1 < Main_FileLabelCount) {
                                Main_CurrFileLabelIndex += 1
                                Main_ButtonLabel = Main_CurrentFiles[Main_CurrFileLabelIndex]
                                WatchLogger.info(Subsystem: "wCV", Msg: "Displaying file \(Main_CurrFileLabelIndex) in Main")
                            }
                            else {
                                Main_ButtonLabel = "REFRESH?"
                                WatchLogger.info(Subsystem: "wCV", Msg: "Through all files in Main Folder, setting to refresh")
                            }
                            
                        }
                        
                        // Get the current files in the whole folder
                    },label: {
                        Text("Main: \(Main_ButtonLabel)")
                            .foregroundColor(.purple)
                    })
                    
                    // REPO FOLDER Button cycles through and sends individual files
                    Button(action: {
                        WatchLogger.info(Subsystem: "wCV", Msg: "RepoButton Pressed")
                        //                connectivityManager.recievedFileNameToDelete = ["TestingIfPhoneCanRead.txt"]
                        if (Repo_ButtonLabel == "REFRESH?") {
                            // Refresh File Stats
                            RepoCurrentFiles = vmWatch.getAllFileNames(folderSelect: .dataRepoFolder)
                            RepoFileLabelCount = RepoCurrentFiles.count
                            
                            if (RepoFileLabelCount > 0) {
                                RepoCurrFileLabelIndex = 0
                                Repo_ButtonLabel = RepoCurrentFiles[RepoCurrFileLabelIndex]
                                WatchLogger.info(Subsystem: "wCV", Msg: "\(RepoFileLabelCount) files in repo folder.")
                            }
                            else {
                                Repo_ButtonLabel = "NONE"
                                WatchLogger.info(Subsystem: "wCV", Msg: "No files in repo folder.")
                            }
                        }
                        else if (Repo_ButtonLabel == "NONE") {
                            Repo_ButtonLabel = "REFRESH?"
                            WatchLogger.info(Subsystem: "wCV", Msg: "Setting RepoButton to Refresh")
                        }
                        else {
                            // attempt to send current file
                            print("RepoCurrFileLabelIndex: \(RepoCurrFileLabelIndex)")
                            let currFileURL = vmWatch.getFilePath(filename: RepoCurrentFiles[RepoCurrFileLabelIndex], folderSelect: .dataRepoFolder)
                            if currFileURL == nil {
                                WatchLogger.error(Subsystem: "wCV", Msg: "Error grabbing Repo File URL")
                            }
                            else { // Valid File URL
                                self.sendDataObserver(fileURL: currFileURL!)
                            }
                            
                            // if next file name is still valid
                            if (RepoCurrFileLabelIndex+1 < RepoFileLabelCount) {
                                RepoCurrFileLabelIndex += 1
                                Repo_ButtonLabel = RepoCurrentFiles[RepoCurrFileLabelIndex]
                                WatchLogger.info(Subsystem: "wCV", Msg: "Displaying file \(RepoCurrFileLabelIndex) in Repo")
                            }
                            else {
                                Repo_ButtonLabel = "REFRESH?"
                                WatchLogger.info(Subsystem: "wCV", Msg: "Through all files in Repo Folder, setting to refresh")
                            }
                        }
                        
                        // Get the current files in the whole folder
                    },label: {
                        Text("Repo: \(Repo_ButtonLabel)")
                            .foregroundColor(.purple)
                    })
                    
                    
                    // BUTTON TO DELETE ALL FILES IN REPO FOLDER
                    Button(action: {
                        WatchLogger.info(Subsystem: "wCV", Msg: "Delete Repo Button Pressed")
                        deleteRepoAlert.toggle()
                    },label: {
                        Text("Delete All Repo Files")
                    })
                    .alert(isPresented: $deleteRepoAlert) {
                        Alert(title: Text("Confirmation"),
                              message: Text(" Are you sure you want to discard all data in repository?"),
                              primaryButton: .default(Text("Yes")) {
                            WatchLogger.info(Subsystem: "wCV", Msg: "CONFIRMED DELETE REPO")
                            let fileNames = vmWatch.getAllFileNames(folderSelect: .dataRepoFolder)
                            for i in 0..<fileNames.count {
                                let currFileName = fileNames[i]
                                print("Deleting \(currFileName) from Repo")
                                guard let currFileURL = vmWatch.getFilePath(filename: currFileName, folderSelect: .dataRepoFolder) else {
                                    print("Failed to get URL for filename \(currFileName)")
                                    continue
                                }
                                vmWatch.deleteDataFile(dataURL: currFileURL)
                            }
                        },
                              secondaryButton: .cancel(){
                            WatchLogger.info(Subsystem: "wCV", Msg: "Cancelled Delete Repo Button")
                        }
                        )
                    }
                    .padding()
                    
                } // END OF IF DevViewFlag == True
            } // end of VStack
        } // end of ScrollView
        
        .onChange(of: Txfr_ButtonUpdateFlag) { flag in
            if Txfr_ButtonUpdateFlag == true {
                // Send any files watch hasn't observed 100% progress
                TransferAllFiles(mainFolderFlag: true)
                
                // Don't hog watch CPU unless in developer mode
                if connectivityManager.DevViewFlag == true {
                    TransferAllFiles(mainFolderFlag: false)
                }
                Txfr_ButtonUpdateFlag = false // reset flag to false
            }
            else {
                print("Watch CV: Txfr_ButtonUpdateFlag cleared and now set to false.")
            }
        }
        
        .onChange(of: connectivityManager.sensorFlag) { flag in
            if flag == true {
                WatchLogger.info(Subsystem: "wCV", Msg: "Start logging")
                //startExtendedSession()
                startLogging()
            }
            else {
                WatchLogger.info(Subsystem: "wCV", Msg: "Stop logging")
                //endExtendedSession()
                stopLogging()
                
                //Transfer all files if needed
                if (Main_FileLabelCount > 0) {
                    WatchLogger.info(Subsystem: "wCV", Msg: "\(Main_FileLabelCount) Files Stuck on Watch. Attempting to Transfer")
                    TransferAllFiles(mainFolderFlag: true)
                }
            }
        }
        
        .onChange(of: cmutils.maxTimerErrorFlag) {flag in
            if flag == true {
                // clear watch face interaction
                connectivityManager.sensorFlag = false
                
                // clear flag for future instances
                cmutils.maxTimerErrorFlag = false
            }
            else {
                print("Clearing max timer cmutils flag.")
            }
        }
        
        .onChange(of: connectivityManager.participantID) { changeID in
            if changeID != participantID {
                WatchLogger.info(Subsystem: "wCV", Msg: "Changing Participant ID from \(participantID) to \(changeID)")
                participantID = changeID
            }
        }
        
    }


    func startLogging() {
        WatchLogger.info(Subsystem: "wCV", Msg: "Starting recording")
        WatchLogger.info(Subsystem: "wCV", Msg: "Battery at \(Int(roundf(WKInterfaceDevice.current().batteryLevel * 100)))% Charge")
        startExtendedSession()
        let date = Date()
        let df = DateFormatter()
        //df.dateFormat = "MM-dd-yyyy-hh-mm-a"
        df.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        print(df.string(from: date))
        mostRecentFileName = participantID+"-"+df.string(from: date)
        mostRecentFileName += "-watch"
        mostRecentFileName += ".data"
        // Start sending updates to file
        extendedDelegate.mostRecentFileName = self.mostRecentFileName
        cmutils.startUpdates(filename: mostRecentFileName)
    }
    
    func stopLogging() {
        WatchLogger.info(Subsystem: "wCV", Msg: "Stopping motion recording")
        
        // Stop updating the file
        cmutils.stopUpdates(filename: mostRecentFileName)
        endExtendedSession()
        sendData(filename: mostRecentFileName)
    }


    /// Currently split and duplicated do avoid concurrency issues in the Dispatch Queue looping over a generic "CurrentFiles" in case both folders get sent at the same time.
    /// If this can be fixed with a local context given to the dispatch queue, this function can be consolidated
    func TransferAllFiles(mainFolderFlag: Bool = true) {
        if mainFolderFlag == true {
            WatchLogger.info(Subsystem: "wCV", Msg: "Executing TransferAllFiles() on Main")
            
            // Grab Files based on folder select flag
            Main_CurrentFiles = vmWatch.getAllFileNames(folderSelect: .mainFolder)
            Main_FileLabelCount = Main_CurrentFiles.count
            
            if (Main_CurrentFiles == []) {
                Main_CurrentFiles = ["No Files"]
                WatchLogger.info(Subsystem: "wCV", Msg: "No Files to Transfer in Main Folder from Watch to Phone")
            }
            
            if (Main_FileLabelCount > 0) {
                WatchLogger.info(Subsystem: "wCV", Msg: "Attempt transfering \(Main_FileLabelCount) files from Watch to Phone")
                
                DispatchQueue.main.async {
                    print("Sending Files Asynchronously.")
                    for i in 0..<Main_FileLabelCount{
                        if (Main_CurrentFiles[i] == mostRecentFileName) {
                            WatchLogger.info(Subsystem: "WCV", Msg: "Skipping New Recording in Bulk Transfer to avoid Duplicate")
                            continue
                        }
                        guard let currfileURL = vmWatch.getFilePath(filename: Main_CurrentFiles[i], folderSelect: .mainFolder) else {continue}
                        WatchLogger.info(Subsystem: "wCV", Msg: "Sending file \(Main_CurrentFiles[i])")
                        self.sendDataObserver(fileURL: currfileURL)
                    }
                    self.dataCount = Main_FileLabelCount
                    //                self.dataCount = 1 // reset file count after sending to only include current log file
                }
            }
        }
        else { // if mainFolderFlag == false // Sending repo
            WatchLogger.info(Subsystem: "wCV", Msg: "Executing TransferAllFiles() on Repo")
            
            // Grab Files based on folder select flag
            RepoCurrentFiles = vmWatch.getAllFileNames(folderSelect: .dataRepoFolder)
            RepoFileLabelCount = RepoCurrentFiles.count
            
            if (RepoCurrentFiles == []) {
                RepoCurrentFiles = ["No Files"]
                WatchLogger.info(Subsystem: "wCV", Msg: "No Files in Repo to Transfer from Watch to Phone")
            }
            
            if (RepoFileLabelCount > 0) {
                WatchLogger.info(Subsystem: "wCV", Msg: "Attempt transfering \(RepoFileLabelCount) files from Watch to Phone")
                
                DispatchQueue.main.async {
                    print("Sending Files Asynchronously.")
                    for i in 0..<RepoFileLabelCount{
                        if (RepoCurrentFiles[i] == mostRecentFileName) {
                            WatchLogger.info(Subsystem: "WCV", Msg: "Skipping New Recording in Bulk Transfer to avoid Duplicate")
                            continue
                        }
                        guard let currfileURL = vmWatch.getFilePath(filename: RepoCurrentFiles[i], folderSelect: .dataRepoFolder) else {continue}
                        WatchLogger.info(Subsystem: "wCV", Msg: "Sending file \(RepoCurrentFiles[i])")
                        self.sendDataObserver(fileURL: currfileURL)
                    }
                    self.dataCount = RepoFileLabelCount
                    //                self.dataCount = 1 // reset file count after sending to only include current log file
                }
            }
        }
        
        return
    }
    
    
    
    
    func sendDataObserver(fileURL: URL) {
        let ACTUALLY_SEND_FILES_FLAG = true
        if ACTUALLY_SEND_FILES_FLAG { // ACTUAL CODE FOR RELEASE
            WatchLogger.info(Subsystem: "wCV", Msg: "Attempting to send file with Observer")
            if WCSession.default.isReachable {
                WatchLogger.info(Subsystem: "wCV", Msg: "File transfer initiate: \(fileURL.lastPathComponent)")
                connectivityManager.transferFileWatchToPhone(at: fileURL)
                // OLD //WCSession.default.transferFile(fileURL, metadata: nil)
            } else {
                WatchLogger.warning(Subsystem: "wCV", Msg: "iOS app not reachable")
            }
        }
        else { // Debugging to keep files on watch
            WatchLogger.debug(Subsystem: "wCV", Msg: "NOT SENDING FILE TO AVOID DELETION")
        }
    }
    
    
    func sendData(filename: String) {
        let ACTUALLY_SEND_FILES_FLAG = true
        if ACTUALLY_SEND_FILES_FLAG { // ACTUAL CODE FOR RELEASE
            WatchLogger.info(Subsystem: "wCV", Msg: "Attempting to send file")
            guard let fileURL = vmWatch.getFilePath(filename: filename) else {return}
            if WCSession.default.isReachable {
                WatchLogger.info(Subsystem: "wCV", Msg: "File transfer initiate: \(fileURL)")
                WCSession.default.transferFile(fileURL, metadata: nil)
            } else {
                WatchLogger.warning(Subsystem: "wCV", Msg: "iOS app not reachable")
            }
        }
        else {
            WatchLogger.debug(Subsystem: "wCV", Msg: "NOT SENDING FILE TO AVOID DELETION")
        }
    
    }
    
    
    func startExtendedSession() {
        // Assign the delegate.
        guard extendedSession.state != .running else { return }
        // create or recreate session if needed
        WatchLogger.info(Subsystem: "wCV", Msg: "Starting Extended Session")
        if extendedSession.state == .invalid {
            extendedSession = WKExtendedRuntimeSession()
            extendedSession.delegate = extendedDelegate
        }
        print("Bite session starting")
        
        extendedSession.start()
    }

    func endExtendedSession() {
        if extendedSession.state == .running {
            WatchLogger.info(Subsystem: "wCV", Msg: "Ending Extended Session")
            extendedSession.invalidate()
        }
    }
    

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct SensorButton: View {
    var flag: Bool
    var body: some View {
        
        if (flag == true) {
            Text("ON")
                .bold()
                .font(.title2)
                .frame(width: 185, height: 50)
                .background(Color(.green))
                .foregroundColor(.white)
                .cornerRadius(15)

        }
        else {
            Text("OFF")
                .bold()
                .font(.title2)
                .frame(width: 185, height: 50)
                .background(Color(.red))
                .foregroundColor(.white)
                .cornerRadius(15)
            
        }
        
    }
}


