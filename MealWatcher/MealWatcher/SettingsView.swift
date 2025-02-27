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
  File: SettingsView.swift
  Project: MealWatcher Phone App

  Created by Jimmy Nguyen on 10/5/23.
  Edited and Maintained by James Jolly since Dec 15, 2023
 
    Purpose:
 Settings View of the app, handling initial setup variables and features which should not be needed in routine use of the app.
 
 Credits:
Long Press Button features modeled after tutorial by Peter Steinberger
at https://steipete.com/posts/supporting-both-tap-and-longpress-on-button-in-swiftui/
*/

import SwiftUI
import WatchConnectivity
import SwiftyDropbox
var examplePID: String = "99999"
var exampleRID: String = "00000000-1111-2222-3333-444455556666"

struct SettingsView: View {
    
    
    @StateObject var PhoneLogger = PhoneAppLogger.shared

    //Extra PID for Validation
    @Binding var safeParticipantID: String
    @Binding var participantID: String
    @Binding var selectedOptionLocationFlag: Int
    @Binding var selectedOptionWristSideFlag: Int
    @Binding var selectedOptionCrownSideFlag: Int
    @Binding var ringUUIDString: String
    @Binding var client: DropboxClient
    @Binding var showDBAlert: Bool
    @Binding var alertDBTitle: String
    @Binding var alertDBMessage: String
    @Binding var DevViewFlag: Bool
    // // No longer binding, trigger onAppear instead
//     @Binding var fileCount: Int
//     @Binding var photoCount: Int
    
    @State var fileCount: Int = 0
    @State var photoCount: Int = 0
    
    @State var newPartID = "000"
    @State var watchID: String?
    @State var examplePID: String = "99999"
    @State var exampleRID: String = "00000000-1111-2222-3333-444455556666"
    @State private var previousOptionLocationFlag = 0
    @State private var previousOptionWristSideFlag = 0
    @State private var previousOptionCrownSideFlag = 0
    
    // Variables used by the ID text input to validate input
    @State private var showIDAlert:Bool = false
    @State private var alertIDTitle:String = ""
    @State private var alertIDMessage:String = "" // Default
    
    let options = ["No Option Selected","1", "2", "3","4","5","6","7","8","9","10","11","12","13","14","15","16"]
    let optionsLocations = ["No Option Selected","Clemson, SC", "Providence, RI", "Developer"]
    let optionsWristSide = ["Not Selected", "Right", "Left"]
    let optionsCrownSide = ["Not Selected", "Right", "Left"]
    @State private var hasAlertBeenPresented: Bool = false // only show alert on first change
    @State private var showLocAlert = false
    @State private var showWristAlert = false
    @State private var showCrownAlert = false
    @State private var disableAlert = false
    @State private var deleteDataAlert = false
    
    // Variables used to handle long press of sensor button
    @State var didLongPress = false
    @GestureState private var isDetectingLongPress = false
    @State private var completedLongPress = false
    
    @ObservedObject var vm = FileManagerViewModel()
    @ObservedObject private var bluetoothViewModel = BluetoothViewModel.instance
    @ObservedObject var photoFM = FileManagerPhotoViewModel()
    
    var body: some View {
        ScrollView {
            VStack (alignment: .leading) {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .onAppear {
                        if let deviceId = UIDevice.current.identifierForVendor?.uuidString {
                            self.watchID = deviceId
                        } else {
                            self.watchID = "Unable to retrieve device UUID"
                        }
                        fileCount = vm.countJustFiles()
                        photoCount = photoFM.listSize()
                        print("Current files: \(fileCount) to upload; \(photoCount) images.")
                        PhoneLogger.info(Subsystem: "Settings", Msg: "Loaded Settings View!")
                    }
                    .padding(.vertical)
                DropBoxView(client: $client, participantID: participantID, LocationFlag: selectedOptionLocationFlag, iOSFiles: vm, showAlert: $showDBAlert, alertTitle: $alertDBTitle, alertMessage: $alertDBMessage)
                    .alert(isPresented: $showDBAlert, content: {
                        Alert(
                            title: Text(alertDBTitle),
                            message: Text(alertDBMessage),
                            dismissButton: .default(Text("OK"),
                                                    action: {fileCount = vm.countJustFiles()}
                                                   ))
                    })
                    .padding(.vertical)
                
                HStack {
                    Text("File to Upload: \(fileCount)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                    
                    Spacer()
                    
                    Text("Review Photos: \(photoCount)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                }
                .padding(.bottom)
                
                
                //            // Unguarded Text Input for Participant ID
                //            IDInputView(participantID: $participantID)
                //                .padding(.vertical)
                
                IDValidInputView(safeParticipantID: $safeParticipantID, newParticipantID: $participantID, showAlert: $showIDAlert, alertTitle: $alertIDTitle, alertMessage: $alertIDMessage)
                    .padding(.vertical)
                    .alert(isPresented: $showIDAlert, content: {
                        Alert(
                            title: Text(alertIDTitle),
                            message: Text(alertIDMessage),
                            dismissButton: .default(Text("OK"),
                                                    action: {}
                                                   ))
                    })
                
                // Unused in Apple, but Android lets you select a ring number.
                //            HStack {
                //                Text("Select a Ring ID:")
                //                Picker("Select a Ring ID", selection: $selectedOption) {
                //                    ForEach(0..<options.count, id: \.self) { index in
                //                        Text(options[index]).tag(index)
                //                    }
                //                }
                //            }
                
                // Location Selection
                HStack {
                    Text("Select a Study Location:")
                    Picker("Select a Study Location", selection: $selectedOptionLocationFlag) {
                        ForEach(0..<optionsLocations.count, id: \.self) { index in
                            Text(optionsLocations[index]).tag(index)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding(.bottom, 5)
                
                // Wrist Selection
                HStack {
                    Text("Select Wrist Side:")
                    Picker("Select Wrist Side", selection: $selectedOptionWristSideFlag) {
                        ForEach(0..<optionsWristSide.count, id: \.self) { index in
                            Text(optionsWristSide[index]).tag(index)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding(.bottom, 5)
                
                //Crown Orientation
                HStack {
                    Text("Select Crown Side:")
                    Picker("Select Crown Side", selection: $selectedOptionCrownSideFlag) {
                        ForEach(0..<optionsCrownSide.count, id: \.self) { index in
                            Text(optionsCrownSide[index]).tag(index)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                }
                .padding(.bottom)
                                     
                       
                // Pair Ring Button
                Button(action: {
                    // tried to implement switching to multiple rings within a single session on settings.
                    // Commented out to instead have user close app to connect to new ring and clear lists on startup
                    //                bluetoothViewModel.DeleteScanList() //
                    bluetoothViewModel.allowNotifications = false
                    
                    guard let waveRing = bluetoothViewModel.waveRing else {
                        print("wave ring checkpoint #1")
                        return
                    }
                    // See comment above about switching multiple rings
                    //                print(waveRing)
                    //                if (bluetoothViewModel.connectedPeripheral?.identifier.uuidString != waveRing.identifier.uuidString){
                    //                    bluetoothViewModel.DeleteConnectedDevice()
                    //                }
                    bluetoothViewModel.connect(peripheral: waveRing)
                    guard let ringUUID = bluetoothViewModel.getUUID(peripheral: waveRing) else {
                        print("wave ring checkpoint #2")
                        // EDIT: Must allow to happen because if you disconnect too quickly the UUID is never grabbed
                        // Connection may happen asynchronously, so sent disconnect command anyways
                        // CANNOT DO SEE EDIT // bluetoothViewModel.NoFileDisconnect(peripheral: waveRing)
                        return
                    }
                    print("wave ring checkpoint #3")
                    PhoneLogger.info(Subsystem: "Set", Msg: "Paired Ring and saved UUID. Disconnecting.")
                    self.ringUUIDString = ringUUID.uuidString
                    bluetoothViewModel.NoFileDisconnect(peripheral: waveRing) //JPJ disconnect the established connection now that ring UUID is setcon
                }, label: {
                    Text("Pair Wave Ring")
                })
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .padding(.bottom)
                
                // Implemented Forget Ring
//                // Text prompt for how to pair a new ring if desired
//                // Until Unpair button is implemented (if it does happen),
//                // Inlcude text command for pairing new ring.
//                Text("Tap \"Pair\" twice for a new ring.")
//                Text("\tRing UUID should update.")
//                    .multilineTextAlignment(.leading)
//                    .padding(.bottom)
                
                
                //// UNPAIR Wave Ring button: FIXME on Future Releases
                // Until Implemented, leave text saying to tap pair ring twice
                Button("Forget/Unpair Wave Ring") {
                    // Disconnect ring if it is already connected
                    if let waveRing = bluetoothViewModel.waveRing {
                        PhoneLogger.warning(Subsystem: "Set", Msg: "Currently Connected to ring... Disconnecting before forgetting.")
                        bluetoothViewModel.NoFileDisconnect(peripheral: waveRing) //JPJ disconnect the established connection now that ring UUID is setcon
                    }
                    
                    // Clear all variables saved when pairing
                    // NOTE: .waveRing must be left in since the didDiscover cannot
                    //      add it again without restarting the app
//                  // bluetoothViewModel.waveRing = nil
                    self.ringUUIDString = ""
                    bluetoothViewModel.allowNotifications = false
                    
                    PhoneLogger.info(Subsystem: "Set", Msg: "Cleared all saved values for pairing to ring.")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .padding(.bottom)
                
                
                // Show Ring UUID for visual of when Ring Changes
                Text("Ring UUID:")
                Text("\(ringUUIDString)")
                    .foregroundColor(.purple)
                    .padding(.bottom)
                
                // Developer View ToggleFlag
                HStack {
                    
                    
                    
                    Button(action: {
                        if didLongPress {
                            didLongPress = false
                        } else { // If a short tap
                            PhoneLogger.info(Subsystem: "Settings", Msg: "DevViewButton Tapped")
                        }
                    }, label: {
                        Text("Toggle Developer View")
                    })
                    .buttonStyle(.bordered)
                    .padding(.trailing)
                    // None of this ever fires on Mac Catalyst :(
                    .simultaneousGesture(LongPressGesture(minimumDuration: 10.0).onEnded { _ in
                        didLongPress = true
                        
                        DevViewFlag.toggle()
                        PhoneLogger.info(Subsystem: "Settings", Msg: "Changing Developer View Flag to \(DevViewFlag)")
                        
                        // Update DevView on Watch
                        DispatchQueue.main.async {
                            do {
                                try WCSession.default.updateApplicationContext(["DevViewFlag" : self.DevViewFlag])
                                print("Application Context Updated! DevViewFlag changed.")
                            } catch {
                                print("Failed to send application context: \(error.localizedDescription)")
                            }
                        }
                    })
                    .simultaneousGesture(TapGesture().onEnded {
                        didLongPress = false
                    })
                    
                    
                    
                    
                    FourTapCheckStatusItem(flag: (DevViewFlag))
                }
                .padding(.bottom)
                
                // Optional Developer Items
                if DevViewFlag == true {
                    // Show watch ID for displaying info to user that a watch is linked to app
                    Text("Watch ID:")
                    Text("\(watchID ?? "Unknown")")
                        .foregroundColor(.purple)
                        .padding(.bottom,20)
                    
                    // Delete all Data Button
                    Button(action: {
                        deleteDataAlert.toggle()
                    }, label: {
                        Text("Delete All Data")
                    })
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .alert(isPresented: $deleteDataAlert) {
                        Alert(
                            title: Text("Confirmation"),
                            message: Text("Are you sure you wish to discard all data?"),
                            primaryButton: .default(Text("Yes")) {
                                PhoneLogger.info(Subsystem: "Set", Msg: "Deleting all old data files from app.")
                                vm.deleteAllData()
                                fileCount = vm.listSize()
                                
                                // Update Photo Review folder
                                photoFM.deleteAllData()
                                photoCount = photoFM.countJustFiles()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                    .padding(.bottom)
                }


                Spacer() // Fill the bottom of the screen
                
            }
            .padding()
            .onChange(of: selectedOptionLocationFlag) { [oldValue = selectedOptionLocationFlag] newValue in
                previousOptionLocationFlag = oldValue
                selectedOptionLocationFlag = newValue
                if hasAlertBeenPresented == false {
                    if disableAlert == false {
                        PhoneLogger.info(Subsystem: "Set", Msg: "LocationFlag set from \(oldValue) to \(newValue)")
                        showLocAlert = true
                    }
                    else {
                        PhoneLogger.info(Subsystem: "Set", Msg: "Changes Cancelled and setting LocFlag back from \(oldValue) to \(newValue)")
                        disableAlert = false
                    }
                }
                else { // triggers if changes have already been confirmed in settings
                    PhoneLogger.info(Subsystem: "Set", Msg: "LocFlag set from \(oldValue) to \(newValue)")
                }
            }
            .overlay(
                AlertView(isPresented: $showLocAlert,
                          selectedOption: $selectedOptionLocationFlag,
                          previousOption: $previousOptionLocationFlag,
                          discardChangesSelected: $disableAlert,
                          hasConfirmedChanges: $hasAlertBeenPresented)
            )
            .onChange(of: selectedOptionWristSideFlag) { [oldValue = selectedOptionWristSideFlag] newValue in
                previousOptionWristSideFlag = oldValue
                selectedOptionWristSideFlag = newValue
                if hasAlertBeenPresented == false {
                    if disableAlert == false {
                        PhoneLogger.info(Subsystem: "Set", Msg: "WristSideFlag set from \(oldValue) to \(newValue)")
                        showWristAlert = true
                    }
                    else {
                        PhoneLogger.info(Subsystem: "Set", Msg: "Changes Cancelled and setting WristSideFlag back from \(oldValue) to \(newValue)")
                        disableAlert = false
                    }
                }
                else { // triggers if changes have already been confirmed in settings
                    PhoneLogger.info(Subsystem: "Set", Msg: "WristSideFlag set from \(oldValue) to \(newValue)")
                }
            }.overlay(
                AlertView(isPresented: $showWristAlert,
                          selectedOption: $selectedOptionWristSideFlag,
                          previousOption: $previousOptionWristSideFlag,
                          discardChangesSelected: $disableAlert,
                          hasConfirmedChanges: $hasAlertBeenPresented)
            )
            .onChange(of: selectedOptionCrownSideFlag) { [oldValue = selectedOptionCrownSideFlag] newValue in
                previousOptionCrownSideFlag = oldValue
                selectedOptionCrownSideFlag = newValue
                if hasAlertBeenPresented == false {
                    if disableAlert == false {
                        PhoneLogger.info(Subsystem: "Set", Msg: "CrownSideFlag set from \(oldValue) to \(newValue)")
                        showCrownAlert = true
                    }
                    else {
                        PhoneLogger.info(Subsystem: "Set", Msg: "Changes Cancelled and setting CrownSideFlag back from \(oldValue) to \(newValue)")
                        disableAlert = false
                    }
                }
                else { // triggers if changes have already been confirmed in settings
                    PhoneLogger.info(Subsystem: "Set", Msg: "CrownSideFlag set from \(oldValue) to \(newValue)")
                }
            }
            .overlay(
                AlertView(isPresented: $showCrownAlert,
                          selectedOption: $selectedOptionCrownSideFlag,
                          previousOption: $previousOptionCrownSideFlag,
                          discardChangesSelected: $disableAlert,
                          hasConfirmedChanges: $hasAlertBeenPresented)
            )
            
        }
    }


}

//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsView()
//    }
//}

struct AlertView: View {
    @Binding var isPresented: Bool
    @Binding var selectedOption: Int
    @Binding var previousOption: Int
    @Binding var discardChangesSelected: Bool
    @Binding var hasConfirmedChanges: Bool
    

    var body: some View {
        if isPresented {
            ZStack {
                Color.gray.opacity(0.4).ignoresSafeArea()

                VStack {
                    Text("Confirmation")
                        .font(.headline)
                        .padding()
                        .foregroundColor(.black)
                    
                    Text("You are changing settings. Do you want to keep changes?")
                        .multilineTextAlignment(.center)
                        .padding()
                        .foregroundColor(.black)
                    
                    HStack {
                        Button("No, Discard") {
                            // set to not trigger alert when reverting values to previous
                            discardChangesSelected = true
                            // Revert Option
                            selectedOption = previousOption
                            // Clear Alert View
                            isPresented = false
                        }
                        .padding()
                        
                        Spacer()
                        
                        Button("Confirm Changes") {
                            // Set to not trigger again on future changes
                            hasConfirmedChanges = true
                            // Clear Alert View
                            isPresented = false
                        }
                        .padding()
                    }
                }
                .background(Color.white)
                .cornerRadius(10)
                .padding()
            }
            .transition(.opacity)
        }
    }
}




