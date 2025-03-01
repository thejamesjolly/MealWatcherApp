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
  File: ComponentViews.swift
  Project: MealWatcher Phone App

  Created by James Jolly on May 30, 2024.
 
    Purpose:
 Houses Small view components that are used (Typically in ContentView)
 so that these do not need to be in one MASSIVE and long file.
*/

import Foundation
import SwiftUI
import HealthKit
import WatchConnectivity
import SwiftyDropbox
import CoreBluetooth
//import BackgroundTasks





struct StandardButton: View {
    
    var title: String
    
    var body: some View {
        Text(title)
            .bold()
            .font(.title2)
            .frame(width: 250)
//            .frame(width: 280, height: 50)
//            .background(Color(.systemBlue))
//            .foregroundColor(.white)
//            .cornerRadius(10)
    }
}

struct SensorButton: View {
    
    var flag: Bool
    //var model: WatchConnectivityManager
    var body: some View {
        
        if (flag == true) {
            Text("ON")
                .bold()
                .font(.title2)
                .frame(width: 150, height: 200)
                .background(Color(.systemGreen))
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        else {
            Text("OFF")
                .bold()
                .font(.title2)
                .frame(width: 150, height: 200)
                .background(Color(.systemRed))
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
}


/* View Components Designed for Text and Check 4Tap Flow */

struct SensorStatusBar: View {
    var WatchStatus: Bool
    var RingStatus: Bool
    var body: some View {
        VStack (alignment: .center) {
            Divider()
                .frame(height: 3)
                .overlay(.gray)
                .padding(.vertical, 10)
            
            HStack {
                Spacer()
                Text("Sensor Status")
                
                Spacer()
                Divider()
                    .frame(width: 4) // Thicken the divider
                    .overlay(.gray)
                Spacer()
                
                Text("Watch")
                    .padding(.trailing, 4)
                OnOffStatusText(flag: WatchStatus)
                
                Spacer()
                Divider()
                    .frame(width: 4) // Thicken the divider
                    .overlay(.gray)
                Spacer()
                
                Text("Ring")
                    .padding(.trailing, 4)
                OnOffStatusText(flag: RingStatus)
                Spacer()
            }
            
            Divider()
                .frame(height: 3)
                .overlay(.gray)
                .padding(.vertical, 10)
        }
    }
}

struct OnOffStatusText: View {
    var flag: Bool
    
    let StatusWidth: CGFloat = 50
    let StatusHeight: CGFloat = 35
    var body: some View {
        if (flag == true) {
            Text("ON")
                .frame(width: StatusWidth, height: StatusHeight)
                .background(.green)
                .cornerRadius(5)
        }
        else {
            Text("OFF")
                .frame(width: StatusWidth, height: StatusHeight)
                .background(.red)
                .cornerRadius(5)
        }
    }
}


// No Color Button for camera check list completion
struct FourTapCheckCameraButton: View {
    var labelText: String
    var PrePostFlag: Bool
    @Binding var StartCameraViewFlag: Bool
    
    
    //var model: WatchConnectivityManager
    var body: some View {
        Group { // Single Text for checklist
            Button (action: {
                print("Taking \(PrePostFlag ? "Post": "Pre") picture button")
                StartCameraViewFlag.toggle()
                
            }, label: {
                Text(labelText)
                    .font(.title3)
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(Color(.systemGray))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            })
        }
        .frame(maxWidth: .infinity, minHeight: 30)
    }
}

// No Color Text for check list completion
struct FourTapCheckTextItem_Plain: View {
    var labelText: String
    
    //var model: WatchConnectivityManager
    var body: some View {
        Group { // Single Text for checklist
            
            Text(labelText) // Stack Full opaque text on top
                .font(.title3)
                .frame(maxWidth: .infinity, minHeight: 40)
//                .foregroundColor(.white)
                .cornerRadius(10)
//                .overlay( /// apply a rounded border
//                    RoundedRectangle(cornerRadius: 10)
//                        .stroke(Color.secondary, lineWidth: 2)
//                )
                .frame(alignment: .center)
            
            
        }
        .frame(maxWidth: .infinity, minHeight: 30)
    }
}



// Original Red Green Text for check list completion
struct FourTapCheckTextItem_RG: View {
    var flag: Bool
    var labelText: String
    
    //var model: WatchConnectivityManager
    var body: some View {
        Group { // Single Text for checklist
            if (flag == true) {
                ZStack {
                    Text(labelText) // Make slightly transparent background
                        .bold()
                        .font(.title3) // keep text in case it goes to multiline
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .frame(alignment: .center)
                        .background(.green)
                        .cornerRadius(10)
                        .opacity(0.5)
                    
                    Text(labelText) // Stack Full opaque text on top
                        .bold()
                        .font(.title3)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .foregroundColor(.white)
                        .cornerRadius(10)
//                        .overlay( /// apply a rounded border
//                            RoundedRectangle(cornerRadius: 10)
//                                .stroke(.green, lineWidth: 4)
//                        )
                }
            }
            else {
                ZStack {
                    Text(labelText) // Make slightly transparent background
                        .font(.title3) // keep text in case it goes to multiline
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(.red)
                        .cornerRadius(10)
                        .opacity(0.5)
                    Text(labelText) // Stack Full opaque text on top
                        .font(.title3)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .foregroundColor(.white)
                        .cornerRadius(10)
//                        .overlay( /// apply a rounded border
//                            RoundedRectangle(cornerRadius: 10)
//                                .stroke(.red, lineWidth: 4)
//                        )
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 30)
    }
}

struct FourTapCheckStatusItem: View {
    var flag: Bool
    
    //var model: WatchConnectivityManager
    var body: some View {
        Group { // Single Text for checklist, used to set group frame size
            if (flag == true) { // make green a checkmark for success
                ZStack {
                    Text("✔") // Transparent background
                        .bold()
                        .font(.title3)
                        .padding(2)
                        .frame(minWidth: 40, minHeight: 40)
                        .background(.mint)
                        .cornerRadius(10)

                    Text("✔")
                        .bold()
                        .font(.title3)
                        .padding(2)
                        .frame(minWidth: 40, minHeight: 40)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            else { // Make a empty Gray box
                Text("")
                    .font(.title3)
                    .frame(minWidth: 40, minHeight: 40)
                //                    .background(Color(.systemRed))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.gray, lineWidth: 2)
                    )
                                
            }
        }
        .frame(minHeight: 30)
    }
}

struct FourTapCheckView: View {
    var flag1: Bool
    var labelText1: String
    
    var flag2: Bool
    var labelText2: String
    
    var flag3: Bool
    var labelText3: String
    
    var flag4: Bool
    var labelText4: String
    
    var body: some View {
        // group in HStacks so text and status stay in line
        //    text may become multiline with large fonts
        VStack {
            HStack {
                FourTapCheckTextItem_RG(flag: flag1, labelText: labelText1)
                FourTapCheckStatusItem(flag: flag1)
            }
            .padding(.horizontal, 4)
            HStack {
                FourTapCheckTextItem_RG(flag: flag2, labelText: labelText2)
                FourTapCheckStatusItem(flag: flag2)
            }
            .padding(.horizontal, 4)
            HStack {
                FourTapCheckTextItem_RG(flag: flag3, labelText: labelText3)
                FourTapCheckStatusItem(flag: flag3)
            }
            .padding(.horizontal, 4)
            HStack {
                FourTapCheckTextItem_RG(flag: flag4, labelText: labelText4)
                FourTapCheckStatusItem(flag: flag4)
            }
            .padding(.horizontal, 4)
        }
        
    }

    
    
}


/* Other Control Buttons */

struct RingSensorButton: View {
    
    var state: Bool
    //var model: WatchConnectivityManager
    var body: some View {
        if (state == true) {
            Text("Running")
                .bold()
                .font(.title2)
                .frame(width: 120, height: 120)
                .background(Color(.systemGreen))
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        else {
            Text("Tap to Start")
                .bold()
                .font(.title2)
                .frame(width: 120, height: 120)
                .background(Color(.systemRed))
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
        
}

struct PictureModeCircle: View {
    
    @Binding var flag: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button(action: {
                    flag.toggle()
                }, label: {
                    if (flag == false) {
                        Image(systemName: "circle.fill")
                    }
                    else {
                        Image(systemName: "circle")
                    }
                })
                Button(action: {
                    flag.toggle()
                }, label: {
                    Text("pre")
                })
            }
            
            HStack {
                Button(action: {
                    flag.toggle()
                }, label: {
                    if (flag == true) {
                        Image(systemName: "circle.fill")
                    }
                    else {
                        Image(systemName: "circle")
                    }
                })
                Button(action: {
                    flag.toggle()
                }, label: {
                    Text("post")
                })
            }
        }
        .foregroundColor(.gray)
    }
}

struct CheckWatchConnection: View {
    @StateObject var PhoneLogger = PhoneAppLogger.shared
    
    var model: WatchConnectivityManager
    @Binding var reachable: String
    
    var body: some View {
        VStack {
//            Text("\(reachable)") // Removed to simplify UI
            Button(action: {
//                if model.session.isReachable {
//                    reachable = "Connected"
//                    HapticManager.instance.notification(type: .success)
//                }
//                else {
                //print("sensorFlag is set to: \(model.sensorFlag)")
                PhoneLogger.info(Subsystem: "CpV", Msg: "User Pressed Launch Watch App")
                reachable = "Testing..." //JPJ
                startWatchApp(model.session) { launched in
                    if launched && model.session.isReachable {
                        reachable = "Connected"
                        HapticManager.instance.notification(type: .success)
                        PhoneLogger.info(Subsystem: "CpV", Msg: "Launch Success")
                    }
                    else {
                        reachable = "Disconnected"
                        PhoneLogger.info(Subsystem: "CpV", Msg: "NoLaunch or Unreachable")
                        HapticManager.instance.notification(type: .error)
                    }
                }
                
            }) {
                Text("Launch\nWatch App")
            }
        }
    }
}

func startWatchApp(_ session: WCSession, completion: @escaping (Bool) -> Void) {
    if session.activationState == .activated && session.isWatchAppInstalled {
        let workoutConfiguration = HKWorkoutConfiguration()
        HKHealthStore().startWatchApp(with: workoutConfiguration, completion: { (success, error) in
            // Handle errors
            if !success {
                print("starting watch app failed with error: \(String(describing: error))")
                completion(false)
            }
            else {
                print("startWatchApp function passed!")
                completion(true)
               
                
            }
        })
                                
    }
    else {
        print("watch not active or not installed")
        completion(false)
    }
}


struct IDInputView: View {
    
    @Binding var participantID: String
//    @Binding var newParticipantID: String
    
    var body: some View {
        HStack() {
            Text("Participant ID: ")
            TextField("Input your participant ID", text: $participantID)
                .border(Color.gray, width: 50.0)
                .onSubmit {
                    
//                    WCSession.default.sendMessage(["participantID" : self.participantID], replyHandler: { reply in
//                        print(reply)
//                    },
//                    errorHandler: { (error) in
//                        print("Error with ID change!")
//                    })
                    
                    DispatchQueue.main.async {
                        do {
                            print("currentID \(participantID)")
                            try WCSession.default.updateApplicationContext(["participantID" : self.participantID])
                            print("Application Context Updated! ParticipantID changed.")
                        } catch {
                            print("Failed to send application context: \(error.localizedDescription)")
                        }
                        
                    }
                }
        }
    }
}


struct IDValidInputView: View {
    
    @Binding var safeParticipantID: String
    @Binding var newParticipantID: String
    //Variables used to sent an alert to the view if invalid input
    @Binding var showAlert: Bool
    @Binding var alertTitle: String
    @Binding var alertMessage: String
        
    var body: some View {
        HStack() {
            Text("Participant ID: ")
            TextField("Input your participant ID", text: $newParticipantID)
//                .textFieldStyle(.roundedBorder)
                .foregroundColor(.blue)
                .padding(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(.gray, lineWidth: 3)
                    )
//                .background(.gray.opacity(0.2))
//                .border(Color.gray, width: 50.0)
                .onSubmit {
                    
                    //Check Numeric Entries; return with default if not
                    if (!(newParticipantID.allSatisfy{($0.isNumber || $0.isLetter)})) {
                        print("WARNING: participant ID must only contain numbers or letters")
                        // replace with previous allowable Participant ID
                        newParticipantID = safeParticipantID
                        alertTitle = "INVALID: ID Must Be Alphanumeric"
                        alertMessage = "Valid Participant ID only contains numbers. Previous ID value has been restored."
                        showAlert = true
                        return // This is the error
                    }
                    
                    // Fix String length to 5 characters
                    let inputLength = newParticipantID.count
                    if (inputLength != 5) {
                        if (inputLength < 5) {
                            // No need to warn user since this doesn't change their input
                            print("Not enough digits given... appending zeros.")
                            for _ in 0..<(5-inputLength) {
                                newParticipantID = "0".appending(newParticipantID)
                            }
                        }
                        else if (newParticipantID.count > 5) {
                            print("Chopping digits to make 5 character length")
                            let startIdx = newParticipantID.startIndex
                            let finishIdx = newParticipantID.index(newParticipantID.startIndex, offsetBy: 5)
                            newParticipantID = String(newParticipantID[startIdx..<finishIdx])
                            // Send alert
                            alertTitle = "WARNING: ID Limited to 5 Digits"
                            alertMessage = "Valid Participant ID must capped at 5 digits. New Participant ID made with the first 5 digits typed in."
                            showAlert = true
                        }
                    }
                    
                    // If you get here, then the error checks passed
                    safeParticipantID = newParticipantID // Overwrite so settings view has newest update
                    
                    DispatchQueue.main.async {
                        do {
                            print("currentID \(newParticipantID)")
                            try WCSession.default.updateApplicationContext(["safeParticipantID" : self.newParticipantID])
                            try WCSession.default.updateApplicationContext(["participantID" : self.newParticipantID])
                            print("Application Context Updated! ParticipantID changed.")
                        } catch {
                            print("Failed to send application context: \(error.localizedDescription)")
                        }
                        
                    }
                }
        }
    }
}

struct IDInputWheelView: View {
    
    @Binding var participantID: String
    
    let pickerDigitLoc = "0123456789"
    let pickerOptions = ["0","1","2","3","4","5","6","7","8","9"]
//    @State var pickerSelectDigit0:Int = (pickerDigitLoc.firstIndex(of: participantID[0])).encodedOffset ?? 0
    @State var pickerSelectDigit0:Int = 0
    @State var pickerSelectDigit1:Int = 0
    @State var pickerSelectDigit2:Int = 0
//    @Binding var newParticipantID: String
    
    var body: some View {
        HStack() {
            Text("Participant ID: ")
            
            Picker("name",selection:$pickerSelectDigit0) {
                ForEach(0..<pickerOptions.count, id: \.self) { index in
                    Text(pickerOptions[index]).tag(index)
                }
            }
            Picker("name",selection:$pickerSelectDigit1) {
                ForEach(0..<pickerOptions.count, id: \.self) { index in
                    Text(pickerOptions[index]).tag(index)
                }
            }
            Picker("name",selection:$pickerSelectDigit2) {
                ForEach(0..<pickerOptions.count, id: \.self) { index in
                    Text(pickerOptions[index]).tag(index)
                }
            }
            
            .onSubmit {
                
                
                //                    WCSession.default.sendMessage(["participantID" : self.participantID], replyHandler: { reply in
                //                        print(reply)
                //                    },
                //                    errorHandler: { (error) in
                //                        print("Error with ID change!")
                //                    })
                
                DispatchQueue.main.async {
                    do {
                        print("currentID \(participantID)")
                        try WCSession.default.updateApplicationContext(["participantID" : self.participantID])
                        print("Application Context Updated! ParticipantID changed.")
                    } catch {
                        print("Failed to send application context: \(error.localizedDescription)")
                    }
                    
                }
            }
        }
    }
}




