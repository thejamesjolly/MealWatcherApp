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
  Project: MealWatcher Phone App

  Created by Jimmy Nguyen on 6/8/23.
  Edited and Maintained by James Jolly since Dec 15, 2023
 
    Purpose
 Main Screen of the MealWatcher Phone App
 
 Displays "4Tap" protocol for before and after meal checklist,
 as well as naviagation links to settings, photo review, and some other miscellaneous buttons.
 This screen initializes the Phone Logger on start up,
 and handles most of the multi-component reactionary callbacks for the app (such as saving a file upon receiving a watch transfer)
*/

import SwiftUI
import HealthKit
import WatchConnectivity
import SwiftyDropbox
import CoreBluetooth
//import BackgroundTasks

class HapticManager {
    
    static let instance = HapticManager() // Singleton
    
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

struct ContentView: View {
    
    @State var viewDidLoadFlag = false // Flag to initialize app, used for logger init
    
    /* Logger Initialization */
    @State var logFileName:String = "default.log"
    @StateObject var PhoneLogger = PhoneAppLogger.shared //Initialize on create
    @State var logFilePath:URL?
    
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("watchSensor") var sensorFlag: Bool = false
    @State var PrePostFlag: Bool = false // false for pre picture, true for post picture
    
    // Set when someone tries to push a button to a feature coming in future update
    @State var futureFeatureErrorFlag: Bool = false
    // Set when watch is unconnected and unable to immediately receive sensor message
    @State var WatchAsleepErrorFlag: Bool = false
    //Raised on change of any variable which should trigger an alert
    @State var GeneralAlertFlag: Bool = false
    // Assigned to value of Alert to trigger.
    // 1: WatchAsleep Error Alert
    // 2: DB Alert (title and message have been updated before toggling flag)
    // 3: Bluetooth (Ring) Disconnect Error Alert
    // 4: Future Feature Alert
    enum GeneralAlertValues {
        case NoCurrentAlert
        case WatchAlseepError
        case DropBoxUpdate
        case BT_error
        case FutureFeatureAlert
    }
    @State var GeneralAlertSpecifier: GeneralAlertValues = .NoCurrentAlert
    
    // Camera variables
    @State var sourceType: UIImagePickerController.SourceType = .camera
    @State private var selectedImage: UIImage?
    @State private var isImagePickerDisplay = false
    @State private var isPreImagePickerDisplay = false
    @State private var isPostImagePickerDisplay = false
    
    // Watch connection variables
    @State var reachable = "Disconnected"
    @State var messageText = ""
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    let applicationContext = ["sensor-flag":true]
    @AppStorage("storedID") var participantID: String = "99999"
    @AppStorage("safeStoredID") var SafeParticipantID: String = "99999"
    
    /* File manager variables */
    @StateObject private var vm = FileManagerViewModel()
    @State var dataCount = 0
    let exampleURL = URL(string: "https://www.example.com")!
    
    /* Data and time varaiable */
    @State private var timeStamp: String = "Unknown"
    
    /* DropBox Variables */
    @State var client = DropboxClient(accessToken: "Fetch Token First")
    @State var accessToken: String = ""
    @State var showDBAlert: Bool = false
    @State var alertDBTitle: String = ""
    @State var alertDBMessage: String = ""
    @State var allowPayloadSubmission: Bool = true
    
    /* History View Data */
    //    @State var historyList: [String] = []
    //    @State var navigateToHistoryView = false
    
    /* Settings View Variables */
    @State var navigateToSettingsView = false
    @AppStorage("LocationFlag") var LocationFlag = 0
    @AppStorage("WristSideFlag") var WristSideFlag = 0
    @AppStorage("CrownSideFlag") var CrownSideFlag = 0
    
    /* Genki Ring Variables */
    @ObservedObject private var bluetoothViewModel = BluetoothViewModel.instance
    @State var ringConnection: Bool = false
    @AppStorage("ringUUID") var ringUUIDString: String = ""
    
    /* Survey Variables */
    @State var navigateToSurveyView: Bool = false
    @State var wasSurveySubmittedFlag: Bool = false
    
    
    /* Photo Review variables */
    @StateObject private var photoFM = FileManagerPhotoViewModel()
    @State var navigateToPhotoView: Bool = false
    @State var photoFilePaths: [URL] = []
    @State var photoNamesList: [String] = []
    @State var totalPhotoCnt: Int = 0
    @State var currPhotoIdx: Int = -1
    // Variables used only within photo review View, but need to be updated for initial display
    @State var currImage: UIImage = UIImage(imageLiteralResourceName: "NoPhotosAvailable")
    @State var currDisplayText_CalDate: String = "No Date"
    @State var currDisplayText_DayTime: String = "No Time"
    
    /* Variables used for 4 tap greenligth */
    @State var hasTakenPrePicFlag: Bool = false // true if user has taken a prepicture since launch or since last post photo
    @State var hasTakenPostPicFlag: Bool = false // true if user has taken a post picture since launch or since last pre photo
    @State var hasTakenSurveyFlag: Bool = false // true if user has taken a post picture since launch or since last pre photo
    @State var PreMealMenuFlag = true // true if displaying pre-meal steps, false if post meal

    @State var DevViewFlag: Bool = false // true if user wants to see additional developer insights

    
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .center) {
                    HStack {
                        /* Checks watch connectivity */
                        CheckWatchConnection(model: connectivityManager, reachable: $reachable)
                            
                        /* Navigates to setting view */
                        Spacer()
                        
                        Button("Settings") {
                            navigateToSettingsView = true
                            PhoneLogger.info(Subsystem: "CV", Msg: "Navigating to Settings")
                        }
                        

                        NavigationLink(destination: SettingsView(
                            safeParticipantID: $SafeParticipantID,
                            participantID: $participantID,
                            selectedOptionLocationFlag: $LocationFlag,
                            selectedOptionWristSideFlag: $WristSideFlag,
                            selectedOptionCrownSideFlag: $CrownSideFlag,
                            ringUUIDString: $ringUUIDString,
                            client: $client,
                            showDBAlert: $showDBAlert,
                            alertDBTitle: $alertDBTitle,
                            alertDBMessage: $alertDBMessage,
                            DevViewFlag: $DevViewFlag), isActive: $navigateToSettingsView) {
                            EmptyView()
                        }
                    }

                    .padding()
                    
                    
                    // Buttons to toggle between pre and post meal checklist
                    HStack{
                        Spacer()
                        
                        Button(action: {
                            PreMealMenuFlag = true
                            PrePostFlag = false // set to false to signify prepictures
                        }, label: {
                            Text("BEFORE MEAL")
                        })
                        .buttonStyle(.borderedProminent)
                        
                        Spacer()
                        
                        Button(action: {
                            PreMealMenuFlag = false
                            PrePostFlag = true // Set to true to signify PostPicture
                        }, label: {
                            Text("AFTER MEAL")
                        })
                        .buttonStyle(.borderedProminent)
                        
                        Spacer()
                    }
                    .padding(.vertical)
                    
                    
                    
                    // HStack of "4Tap" mindset
                    if (PreMealMenuFlag == true) { // Pre Meal Checklist
                        
                        // CHECKLIST HEADER
                        Text("BEFORE MEAL CHECKLIST")
                            .font(.title2)
                            .bold()
                            .underline()
                        
                        //Watch Sensor Check
                        HStack {
                            FourTapCheckTextItem_Plain(
                                // flag: connectivityManager.sensorFlag,
                                labelText: "Start WATCH"
                            )
                            FourTapCheckStatusItem(flag: connectivityManager.sensorFlag)
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 3)

                        // Turn Ring On Check
                        HStack {
                            FourTapCheckTextItem_Plain(
                                // flag: (bluetoothViewModel.waveRing != nil),
                                labelText: "Start RING..."
                            )
                            FourTapCheckStatusItem(flag: (bluetoothViewModel.waveRing != nil))
                        }
                        .padding(.horizontal, 3)
                        .padding(.vertical,5)
                        
                        // Sensors actively recording Check
                        HStack {
                            Button (action: {
                                //print("\(waveRing.state)")
                                PhoneLogger.info(Subsystem: "CV", Msg: "Pressed Start Ring Button")
                                if (bluetoothViewModel.isRunning == false) { // if off, turn sensors on
                                    toggleRing(sensorSetTo: true)
                                }
                                else { // if on, turn sensors off
                                    PhoneLogger.warning(Subsystem: "CV", Msg: "Start Ring Button Pressed while Ring was On")
                                    // Remove Disconnect from Pre Meal
                                    // toggleRing(sensorSetTo: false)
                                }
                            }, label: {
                                Text("...TAP HERE to Pair to Ring")
                                    .font(.title3)
                                    .frame(maxWidth: .infinity, minHeight: 40)
                                    .background(Color(.systemGray))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            })
                            
                            FourTapCheckStatusItem(flag: bluetoothViewModel.isRunning)
                        }
                        .padding(.horizontal, 3)
                        .padding(.vertical,5)
                        // PrePic Check Button
                        HStack {
                            Button (action: {
                                PhoneLogger.info(Subsystem: "CV", Msg: "Pressed \(PrePostFlag ? "Post": "Pre") picture button")
                                isPreImagePickerDisplay.toggle()
                                
                            }, label: {
                                Text("TAP HERE to Take Before-Meal Pic")
                                    .font(.title3)
                                    .frame(maxWidth: .infinity, minHeight: 40)
                                    .background(Color(.systemGray))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            })
                            
                            FourTapCheckStatusItem(flag: hasTakenPrePicFlag)
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical,5)
                        
                    }
                    else { // Post meal Checklist
                        Text("AFTER MEAL CHECKLIST")
                            .font(.title2)
                            .bold()
                            .underline()
                        
                        //Watch Sensor Check
                        HStack {
                            FourTapCheckTextItem_Plain(
                                // flag: connectivityManager.sensorFlag,
                                labelText: "Stop WATCH"
                            )
                            FourTapCheckStatusItem(flag: !(connectivityManager.sensorFlag))
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 3)
                        
                        
                        // Sensors actively recording Check
                        HStack {
                            Button (action: {
                                //print("\(waveRing.state)")
                                PhoneLogger.info(Subsystem: "CV", Msg: "Presed Stop Ring Button Pressed")
                                if (bluetoothViewModel.isRunning == true) { // if off, turn sensors off
                                    toggleRing(sensorSetTo: false)
                                }
                                else { // if on, turn sensors off
                                    PhoneLogger.warning(Subsystem: "CV", Msg: "Stop Ring Button Pressed while Ring was Off")
                                    // REMOVE from post meal menu
                                    // toggleRing(sensorSetTo: true)
                                }
                            }, label: {
                                Text("TAP HERE to Stop Ring")
                                    .font(.title3)
                                    .frame(maxWidth: .infinity, minHeight: 40)
                                    .background(Color(.systemGray))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            })
                            
                            FourTapCheckStatusItem(flag: !(bluetoothViewModel.isRunning))
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 3)
                        
                        // PrePic Check Button
                        HStack {
                            Button (action: {
                                PhoneLogger.info(Subsystem: "CV", Msg: "Pressed \(PrePostFlag ? "Post": "Pre") picture button")
                                isPostImagePickerDisplay.toggle()
                                
                            }, label: {
                                Text( "TAP HERE to Take After-Meal Pic")
                                    .font(.title3)
                                    .frame(maxWidth: .infinity, minHeight: 40)
                                    .background(Color(.systemGray))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            })
//                            FourTapCheckCameraButton(
//                                labelText: "Take After-Meal Pic",
//                                PrePostFlag: PrePostFlag,
//                                StartCameraViewFlag: $isPostImagePickerDisplay)
                            FourTapCheckStatusItem(flag: hasTakenPostPicFlag)
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 3)
                        
                        // Turn Ring On Check
                        HStack {
                            Button(action: {
                                PhoneLogger.info(Subsystem: "CV", Msg: "Navigating to Survey")
                                navigateToSurveyView = true
                            }, label: {
                                Text("TAP HERE to take Survey")
                                    .font(.title3)
                                    .frame(maxWidth: .infinity, minHeight: 40)
                                    .background(Color(.systemGray))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            })
                            
                            FourTapCheckStatusItem(flag: hasTakenSurveyFlag)
                            
                            NavigationLink(destination: SurveyView(
                                wasSurveySubmittedFlag: $wasSurveySubmittedFlag,
                                survey: EMAQuestions,
                                participantID: self.participantID), isActive: $navigateToSurveyView) {
                                EmptyView()
                            }
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 3)
                                            
                    }
                    
                    
                    // STATUS INDICATORS
                    
                    SensorStatusBar(
                        WatchStatus: connectivityManager.sensorFlag,
                        RingStatus: bluetoothViewModel.isRunning)
                    .padding(.vertical, 25) // extra space seperating status bar

                    
                    if DevViewFlag == true {
                        VStack{
                            Text("Current Transfer File \(connectivityManager.currentTxfrFileName)")
                                .font(.caption)
                                .bold()
                                .foregroundStyle(.green)
                            Text("File Progress \((connectivityManager.currentFileProgress)*100, specifier: "%.0f")%")
                                .font(.caption)
                                .bold()
                                .foregroundStyle(.green)
                        }
                    }
                    
                    VStack(alignment: .center) {
                        
                        
                        Group { // Photo Review Group
                            Button (action: {
                                PhoneLogger.info(Subsystem: "CV", Msg: "Navigating to Photo Review")
                                //Navigate to View; values are updated upon launch by View
                                navigateToPhotoView = true
                            }, label: {
                                Text("Photo Review")
                                    .bold()
                                    .font(.title2)
                                    .frame(width: 250)
                            })
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            
                            // Non-binding parameters version
                            NavigationLink(destination: PhotoReviewView(), isActive: $navigateToPhotoView) {
                                EmptyView()
                            }
                        }
                        

//                        // Debugging Button // Comment Out if not in Use //
//                        .padding()
//                        Button (action: {
//                            print("Debug Button")
//                            DebugFunc()
//                        }, label: {
//                            Text("Debug Button")
//                                .bold()
//                                .font(.title2)
//                                .frame(width: 250)
//                        })
//                        .buttonStyle(.borderedProminent)
//                        .controlSize(.large)
//                        //End of Debugging Button
                        

                    }
                    .padding(.vertical, 2)
                    
                    
                    
                }
            }
            .sheet(isPresented: self.$isPreImagePickerDisplay) {
                ImagePickerView(selectedImage: self.$selectedImage, sourceType: self.$sourceType, PrePostFlag: $PrePostFlag, participantID: self.$participantID, confirmPhotoTakenFlag: $hasTakenPrePicFlag)
            }
            .sheet(isPresented: self.$isPostImagePickerDisplay) {
                ImagePickerView(selectedImage: self.$selectedImage, sourceType: self.$sourceType, PrePostFlag: $PrePostFlag, participantID: self.$participantID, confirmPhotoTakenFlag: $hasTakenPostPicFlag)
            }
            .padding()
            
            //            .onChange(of: scenePhase) { newPhase in
            //                if newPhase == .background && self.ringConnection == true {
            //                    print("Background")
            //                    scheduleBackgroundTask()
            //                }
            //            }
            
            .onChange(of: bluetoothViewModel.isRunning) { state in
                if state == true && bluetoothViewModel.allowNotifications == true {
                    self.ringConnection = true
                }
                else {
                    self.ringConnection = false
                }
            }
            
            
            .onChange(of: connectivityManager.fileReceivedFlag) { currFlag in
                if currFlag == true {
                    print("connectivityManager.fileReceivedFlag onChange Happening!")
                    
                    if allowPayloadSubmission == true {
                        PhoneLogger.info(Subsystem: "CV", Msg: "Submitting Dropbox Payload from File Received Trigger")
                        submitPayload(participantID: participantID, LocationFlag: LocationFlag, iOSFiles: vm) { client in
                            if let client = client {
                                self.client = client
                            }
                            else {
                                PhoneLogger.error(Subsystem: "CV", Msg: "Error submitting payload")
                            }
                        }
                    }
                    else { // Keep Local files
                        print("DEBUG: Would have Uploaded received file. Keeping files local instead")
                    }
                    // Clear Flag
                    connectivityManager.fileReceivedFlag = false
                }
                else {
                    print("Resetting flag... no need to react.")
                }
            }
            
            
            // Monitor BT connection for errors; trigger alert if it happens
            .onChange(of: bluetoothViewModel.errorFlag) { btErrorFlag in
                if btErrorFlag == false {
                    print("ContentView Phone OnChange: btErrorFlag was cleared and now false")
                }
                else {
                    //                    HapticManager.instance.notification(type: .error)
                    PhoneLogger.error(Subsystem: "CV", Msg: "Bluetooth Ring Error occured.")
                    GeneralAlertSpecifier = .BT_error // 3 = bluetooth Error
                    GeneralAlertFlag = true
                    //clear flag now that alert has been notified
                    bluetoothViewModel.errorFlag = false
                }
            }
            
            // Monitor CM Error flag for watch unresponsive; trigger watch alert if needed
            .onChange(of: connectivityManager.errorFlag) { cmErrorFlag in
                if cmErrorFlag == false {
                    print("ContentView Phone OnChange: cmErrorFlag was cleared and now false")
                }
                else {
                    //                    HapticManager.instance.notification(type: .error)
                    PhoneLogger.error(Subsystem: "CV", Msg: "Connectivity Manager Error occured.")
                    GeneralAlertSpecifier = .WatchAlseepError // 3 = bluetooth Error
                    GeneralAlertFlag = true
                    //clear flag now that alert has been notified
                    connectivityManager.errorFlag = false
                }
            }
            
            //DB Alert now only happens on forced update in settings
            //If alert should happen upon standard upload, then trigger here
            //Else, these variables could be passed to the settings and never do work in the ContextView
            //            .onChange(of: showDBAlert) { dbErrorFlag in
            //                if dbErrorFlag == false {
            //                    print("ContentView Phone OnChange: dbErrorFlag was cleared and now false")
            //                }
            //                else {
            //                    print("ContentView Phone OnChange: dbErrorFlag was raised and now true.")
            //                    GeneralAlertSpecifier = .DropBoxUpdate // 3 = bluetooth Error
            //                    GeneralAlertFlag = true
            //                    //clear flag now that alert has been notified
            //                    showDBAlert = false
            //                }
            //            }
            
            // Monitor Future Feature flag if user tries to interact with something unimplemented yet.
            // Trigger a Alert if needed

            .onChange(of: futureFeatureErrorFlag) { ffErrorFlag in
                if ffErrorFlag == false {
                    print("ContentView Phone OnChange: ffErrorFlag was cleared and now false")
                    HapticManager.instance.notification(type: .success)
                }
                else {
                    //                    HapticManager.instance.notification(type: .success)
                    PhoneLogger.error(Subsystem: "CV", Msg: "Future Feature Error occured.")
                    GeneralAlertSpecifier = .FutureFeatureAlert // 3 = bluetooth Error
                    GeneralAlertFlag = true
                    //clear flag now that alert has been notified
                    futureFeatureErrorFlag = false
                }
            }
            
            .onChange(of: hasTakenPrePicFlag) { currFlag in
                if currFlag == true { // if user just took a first pre-pic
                    PhoneLogger.info(Subsystem: "CV", Msg: "First Pre-Pic of Meal Taken")
                    print("User has taken first pre-picture! Clearing post-pic and survey flags.")
                    hasTakenPostPicFlag = false
                    hasTakenSurveyFlag = false
                }
            }
            
            .onChange(of: hasTakenPostPicFlag) { currFlag in
                if currFlag == true { // if user just took a first pre-pic
                    PhoneLogger.info(Subsystem: "CV", Msg: "First Post-Pic of Meal Taken")
                    print("User has taken first pre-picture! Clearing pre-pic flags.")
                    hasTakenPrePicFlag = false
                }
            }
            
            .onChange(of: wasSurveySubmittedFlag) { currFlag in
                if currFlag == true {
                    PhoneLogger.info(Subsystem: "CV", Msg: "User submitted survey. Uploading results.")
                    if allowPayloadSubmission == true { //Default: Send Files to Dropbox

                        submitPayload(participantID: participantID, LocationFlag: LocationFlag, iOSFiles: vm) { client in
                            if let client = client {
                                self.client = client
                            }
                            else {
                                print("Error submitting payload")
                            }
                        }
                    }
                    else { //If keeping files local
                        print("DEBUG: Survey would have uploaded... Keeping files local.")
                    }
                    // set survey UI flag to true now that submission has occured
                    hasTakenSurveyFlag = true
                    
                    wasSurveySubmittedFlag = false
                }
            }
            
            // Unused since the single prepostflag can be done in the buttons themselves, not on change
//            .onChange(of: PreMealMenuFlag) {currFlag in
//                if (currFlag == true) {
//                    print(Changek)
//                }
//                else {
//                    
//                }
//            }
            
            // Catch for any alerts, since each view is limited to a single alert
            .alert(isPresented: $GeneralAlertFlag) {
                switch GeneralAlertSpecifier {
                case .WatchAlseepError:
                    return Alert(
                        title: Text("Please Tap Watch Screen"),
                        message: Text("Watch must be fully awake to allow the phone app to interface with the watch. Please tap screen to wake watch."),
                        dismissButton: .default(Text("OK")))
                case .DropBoxUpdate:
                    return Alert(
                        title: Text(alertDBTitle),
                        message: Text(alertDBMessage),
                        dismissButton: .default(Text("OK")))
                    
                case .BT_error:
                    return Alert(
                        title: Text("Ring not recording properly"),
                        message: Text("Please try resetting the ring by pressing, holding, and then releasing the top and bottom button at the same time. The buttons are located above and below the main daimond button."),
                        dismissButton: .default(Text("OK")))
                    
                case .FutureFeatureAlert:
                    return Alert(
                        title: Text("Feature Coming Soon!"),
                        message: Text("Currently this feaure is in development. Thank you for your patience as we continue to improve the app!"),
                        dismissButton: .default(Text("OK")))
                default:
                    return Alert(
                        title: Text("Unknown App Sequence"),
                        message: Text("You have found a bug within the app. Congratulations! Please contact the developers and tell them you managed to get a \"Default\" value of for your Alert Specifier."),
                        dismissButton: .default(Text("OK")))
                }
                
            }
            
            
        }
        .onAppear{
            print("onAppear")
            if viewDidLoadFlag == false { // Only perform code on first initialization
                viewDidLoadFlag = true
                print("viewDidLoad set to true")
            }
            //FIX BEFORE RELEASE AND DEBUG
            PhoneLogger.info(Subsystem: "CV", Msg: "Starting Phone App v1.3(1)")
            
            //Log machine OS and model version
            PhoneLogger.info(Subsystem: "CV", Msg: "OS = \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)")
            var size = 0
            sysctlbyname("hw.machine", nil, &size, nil, 0)
            var machine = [CChar](repeating: 0,  count: size)
            sysctlbyname("hw.machine", &machine, &size, nil, 0)
            PhoneLogger.info(Subsystem: "CV", Msg: "Model = \(UIDevice.current.model); Machine = \(String(cString:machine))")
            
            // Log Batter status
            UIDevice.current.isBatteryMonitoringEnabled = true
            PhoneLogger.info(Subsystem: "CV", Msg: "Battery at \(Int(roundf(UIDevice.current.batteryLevel * 100)))% Charge")
            UIDevice.current.isBatteryMonitoringEnabled = false //Clear flag if not needed
            
            // Log Watch settings of note
            PhoneLogger.info(Subsystem: "CV", Msg: "Study Location: \(LocationFlag)")
            PhoneLogger.info(Subsystem: "CV", Msg: "Wrist Side: \(WristSideFlag)")
            PhoneLogger.info(Subsystem: "CV", Msg: "Crown Side: \(CrownSideFlag)")
            
        }
    }
    
    // ///////////////////////////////////
    // ///////////////////////////////////
    // //////    END OF BODY    //////////
    // ///////////////////////////////////
    // ///////////////////////////////////

    // ///////////////////////////////////
    // ///////////////////////////////////
    // /////  Start of Routines  /////////
    // ///////////////////////////////////
    // ///////////////////////////////////
    
    func DebugFunc() {
        print("Dubugging Function Called")
        
        // INSERT DEBUG CODE HERE
        
        print("End of DebugFunc\n")
        
        
    }
    
    
    func toggleWatchSensors(sensorSetTo: Bool) {
        
        print("Toggling watch sensor to \(sensorSetTo) from Phone.")
        if (sensorSetTo == true) { // if currently off, turn on sensors
            WCSession.default.sendMessage(["sensor-flag-set" : true], replyHandler: { reply in
                print(reply)
                if let flag = reply["sensor-flag"] as? Bool {
                    print("Flag should be set: Value is \(flag)")
                    DispatchQueue.main.async {
                        connectivityManager.sensorFlag = flag
                    }
                }
            },
                                          errorHandler: { (error) in
                print("Error with button press")
            })
        }
        else { // if (sensorSetTo == false) {
            WCSession.default.sendMessage(["sensor-flag-clear" : true], replyHandler: { reply in
                print(reply)
                if let flag = reply["sensor-flag"] as? Bool {
                    print("Flag should be cleared: Value is \(flag)")
                    DispatchQueue.main.async {
                        connectivityManager.sensorFlag = flag
                    }
                }
            },
                                          errorHandler: { (error) in
                print("Error with button press")
            })
        }
        
    }
    
    func wakeUpWatch() {
        print("Attempting to wake up watch")
        if connectivityManager.session.isReachable {
            reachable = "Connected"
        }
        else {
            reachable = "Disconnected"
            startWatchApp(connectivityManager.session) { launched in
                if launched && connectivityManager.session.isReachable {
                    reachable = "Connected"
                    print("App launched and is reachable!")
                }
                else if launched {
                    print("launched app but watch still not reachable.")
                }
            }
        }
    }
    
    
    func connectToRing() {
        let date = Date()
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        bluetoothViewModel.filename = participantID+"-"+df.string(from: date)+"-ring.data"
        if ringUUIDString.isEmpty {
            PhoneLogger.error(Subsystem: "CV", Msg: "Ring UUID not assigned yet")
            return
        }
        PhoneLogger.info(Subsystem: "CV", Msg: "Attempting to connect with UUID: \(ringUUIDString)")
        bluetoothViewModel.allowNotifications = true
        guard let ringUUID = UUID(uuidString: self.ringUUIDString) else {
            PhoneLogger.error(Subsystem: "CV", Msg: "Error: UUID does not exist")
            return
        }
        
        guard let filename = bluetoothViewModel.filename else {
            print("Error: File name does not exist")
            return
        }
        bluetoothViewModel.currentURL = vm.getFilePath(fileName: filename)
        
        guard bluetoothViewModel.currentURL != nil else {
            print("Error: File path does not exist")
            return
        }
        
        bluetoothViewModel.connectWithUUID(ringUUID: ringUUID) //Has race condition to name the file from BTMan
        PhoneLogger.info(Subsystem: "CV", Msg: "Connected to Ring")
        // Remove starting the recording (opening the file) until after writing first data
        // The responsibility to open the file has been shifted to BluetoothManager
        // Responsibilty remains to update the BTManagers filename and currentURL
        //      with the proper name
        //Legacy //guard let currentURL = bluetoothViewModel.currentURL else { return}
        //bluetoothViewModel.startRecording(fileURL: currentURL)
    }
    
    /// Turns Ring on or off based on given Bool (ture for on, false for off)
    func toggleRing(sensorSetTo: Bool) {
        if sensorSetTo == true { // trying to connect to sensor and turn on
            print("Attempting to turn ring sensors on from phone.")
            connectToRing()
        }
        else {
            if let waveRing = bluetoothViewModel.connectedPeripheral {
                if waveRing.state == .connected {
                    print("Attempting to turn ring sensors off from phone.")
                    bluetoothViewModel.stopRecording()
                    bluetoothViewModel.disconnect(peripheral: waveRing)
                    ringConnection = false
                }
                else {
                    print("Attempted to turn sensors off, but ring state was not connected.")
                }
            }
            else {
                print("Attempted to turn sensors off, but ring was not connected.")
            }
        }
    }
    
}




//#Preview {
//    @State var FilePaths:[URL] = []
//    @State var totalPhotoCnt = 0
//    @State var currPhotoIdx = -1
//    PreviewProvider {
//        ContentView()
//    }
//}	

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

