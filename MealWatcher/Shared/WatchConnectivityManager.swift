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
  File: WatchConnectivityManager.swift
  Project: MealWatcher Phone App & MealWatcher WatchApp

  Created by Jimmy Nguyen on 6/11/23.
  Edited and Maintained by James Jolly since Dec 15, 2023
 
    Purpose:
 This file manages communication and shared data between the phone and watch app.
 
 See the WatchConnectivity documentation on Apples website for additional support.
 Each App manages its own version of these variables and the shared class,
 which send messages or app context updates to the other devices WatchConnectivity instance.
 This file specifies the message API's used in the app, the app's responses,
 and methods for sending files back and forth between devices.
*/

import Foundation
import WatchConnectivity

struct NotificationMessage: Identifiable {
    let id = UUID()
    let text: String
}

class WatchConnectivityManager: NSObject, ObservableObject {
    
    static let shared = WatchConnectivityManager()
    var session: WCSession
    @Published var notificationMessage: NotificationMessage? = nil
    @Published var messageText = ""
    @Published var sensorFlag: Bool = false
    @Published var fileURL: URL? = nil
    @Published var fileData: Data?
    @Published var participantID: String = "99999"
    @Published var safeParticipantID: String = "99999"
    // Triggered by phone upon receiving a file from watch successfully
    @Published var deleteWatchFileFlag: Bool = false
    // set to filename of file to delete (no directories)
    // responsibility of whoever turns delete data flag to true,
    // and watch's responsibility to clear once delete happens
//    @Published var recievedFileNameToDelete: String = "Unknown"
    @Published var allRecievedFilesToDelete: [String] = []
    @Published var singleReceivedFileToDelete: String  = "default.txt"
    @Published var fileReceivedFlag:Bool = false
    
    @Published var DevViewFlag:Bool = false //set to false by default
    
    @Published var errorFlag: Bool = false
    
    #if os(iOS)
    var Logger = PhoneAppLogger.shared
    private var FileMan = FileManagerViewModel()
    @Published var currentFileProgress: Double = 0.0
    @Published var currentTxfrFileName: String = "None"
    #else // watchOS
    var Logger = WatchAppLogger.shared
    private var FileMan = FileManagerViewModelWatch()
    private var progressObservers: [String: NSKeyValueObservation] = [:]

    #endif

    
    init(session: WCSession = .default) {
        self.session = WCSession.default
        super.init()
        self.session.delegate = self
        self.session.activate()
        print("WCM: Finished watch session initialization")
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
            //print("Finished initialization")
        }
    }
    
    private let kMessageKey = "notif"
        
    func send(_ message: String) {
        guard WCSession.default.activationState == .activated else {
            print("WCM: default Activation!")
          return
        }
        #if os(iOS)
        guard WCSession.default.isWatchAppInstalled else {
            print("WCM: default Watch App is Installed!")
            return
        }
        #else
        guard WCSession.default.isCompanionAppInstalled else {
            print("WCM: default Companion Phone App is Installed!")
            return
        }
        #endif
        
        WCSession.default.sendMessage([kMessageKey : message], replyHandler: nil) { error in
            print("Cannot send message: \(String(describing: error))")
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String: Any]) -> Void) {
        print("incoming message")
        if let notificationText = message["notif"] as? String {
            print("Notification message received")
            DispatchQueue.main.async { [weak self] in
                self?.notificationMessage = NotificationMessage(text: notificationText)
            }
            return
        }
        
        // Should be unused: replaced with Set and clear flag messages
        if message["sensor-flag-toggle"] is Bool {
            DispatchQueue.main.async {
                self.sensorFlag.toggle()
                print("Message received and new flag value is: \(self.sensorFlag)")
                
                replyHandler([
                            "response": "properly formed Toggle message!",
                            "sensor-flag": self.sensorFlag
                        ])
            }
            return
        }
        
        //Turns sensor flag on (to turn watch sensors on)
        if message["sensor-flag-set"] is Bool {
            DispatchQueue.main.async {
                self.sensorFlag = true
                print("Message received and sensor flag set. Value is: \(self.sensorFlag)")
                
                replyHandler([
                            "response": "properly formed set sensor flag message!",
                            "sensor-flag": self.sensorFlag
                        ])
            }
            return
        }
        
        //Turns sensor flag off (to turn watch sensors off)
        if message["sensor-flag-clear"] is Bool {
            DispatchQueue.main.async {
                self.sensorFlag = false
                print("Message received and sensor flag cleared. Value is: \(self.sensorFlag)")
                
                replyHandler([
                            "response": "properly formed clear sensor flag message!",
                            "sensor-flag": self.sensorFlag
                        ])
            }
            return
        }
        
        if message["sensor-flag-query"] is Bool {
            DispatchQueue.main.async {
                print("Message received and queried watch sensor flag... value is: \(self.sensorFlag)")
                
                replyHandler([
                            "response": "properly formed Query message!",
                            "sensor-flag": self.sensorFlag
                        ])
            }
            return
        }
        
        // Update ParticipantID
        if message["participantID"] is String {
            DispatchQueue.main.async {
                self.participantID = message["participantID"] as! String
                print("Message received and new ID value is: \(self.participantID)")
            }
            
            replyHandler([
                "response" : "properly formed message!",
                "participantID" : self.participantID
                ])
            return
        }
        
        // Delete Received File
        if message["single-received-file-to-delete"] is String {
#if os(iOS)
            self.Logger.debug(Subsystem: "WCM", Msg: "LOG SHOULD APPEAR ON WATCH. Received File to Delete.")
#else
            let filenameToDelete = message["single-received-file-to-delete"] as! String
            print("Recieved acknowledgement to delete file: \(filenameToDelete)")
            if true { // Current version saves all files on watch: Future feature could delete from main and repo upon receive
                self.Logger.info(Subsystem: "wCV", Msg: "File Acknowledged, but not deleted: \(filenameToDelete)")
            }
            else {
                print("Attempting to Delete file...")
                DispatchQueue.main.async {
                    
                    // Delete file directly hear rather than using flags and intorducing race conditions
                    
                    guard let fileURL = self.FileMan.getFilePath(filename: filenameToDelete) else {
                        self.Logger.error(Subsystem: "wCV", Msg: "Did not find file to delete \(filenameToDelete).")
                        return
                    }
                    self.Logger.info(Subsystem: "wCV", Msg: "Deleting file: \(fileURL)")
                    self.FileMan.deleteDataFile(dataURL: fileURL)
                    self.Logger.info(Subsystem: "wCV", Msg: "File Deleted: \(fileURL)")
                }
            }
#endif

            replyHandler([
                "response" : "properly formed message!",
                "single-received-file-to-delete" : message["single-received-file-to-delete"] as! String
                ])
            return
        }
        // REMOVE IF TRANSFER WORKS
//        // FEATURE FILE_TXFR SECTION
//        // Update File Received and marked for Deletion
//        if message["additional-recieved-filename-to-delete"] is String {
//            DispatchQueue.main.async {
//                self.allRecievedFilesToDelete.append(message["recievedFileNameToDelete"] as! String)
//            }
//            print("Message received and new file added to delete queue: File is: \(self.allRecievedFilesToDelete[-1])")
//            replyHandler([
//                "response" : "properly formed message!",
//                "file-list-to-delete" : self.allRecievedFilesToDelete
//                ])
//            return
//        }
//        // REMOVE IF TRANSFER WORKS
//        // FEATURE FILE_TXFR SECTION
//        // Update File Received and marked for Deletion
//        if message["FilesDeletedUpdateList"] is String {
//            DispatchQueue.main.async {
//                self.allRecievedFilesToDelete.append(message["recievedFileNameToDelete"] as! String)
//            }
//            print("Message received and new file added to delete queue: File is: \(self.allRecievedFilesToDelete[-1])")
//            replyHandler([
//                "response" : "properly formed message!",
//                "file-list-to-delete" : self.allRecievedFilesToDelete
//                ])
//            return
//        }
        
        // Possibly add an update message to the phone once files are deleted
        // and the received list can be cleared.
        // May not be needed since the phone only sends a single file name message
        
        // REMOVE IF TRANSFER WORKS
//        // FEATURE FILE_TXFR SECTION
//        // Update the delete flag once the file has been received
//        if message["delete-watch-file-flag"] is Bool {
//            DispatchQueue.main.async {
//                self.deleteWatchFileFlag = true
//                print("Message received and delete watch file flag set... value is: \(self.deleteWatchFileFlag)")
//                
//                replyHandler([
//                            "response": "properly formed delete watch file message!",
//                            "delete-watch-file-flag": self.deleteWatchFileFlag
//                        ])
//            }
//            return
//        }
        
        
        
        
        
        
        print("Error receiving message!")
        self.Logger.error(Subsystem: "WCM", Msg: "Bad Message Format: \(message)")
        replyHandler([
                    "response": "improperly formed message!"
                ])
    }
    /* This function should be used to handle all relevant data between the two programs*/
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        // Handle the received data
        print("Application Context Received")
        print(applicationContext)
        if applicationContext["sensor-flag"] is Bool {
            DispatchQueue.main.async {
                self.sensorFlag.toggle()
                print("Application Context Read!")
            }
        }
        
        if applicationContext["DevViewFlag"] is Bool {
            DispatchQueue.main.async {
                self.DevViewFlag = applicationContext["DevViewFlag"] as! Bool
                print("Message received and new ID value is: \(self.DevViewFlag)")
            }
        }
        
        if applicationContext["participantID"] is String {
            DispatchQueue.main.async {
                self.participantID = applicationContext["participantID"] as! String
                print("Message received and new ID value is: \(self.participantID)")
            }
        }
        
        if applicationContext["safeParticipantID"] is String {
            DispatchQueue.main.async {
                self.safeParticipantID = applicationContext["safeParticipantID"] as! String
                print("Message received and new ID value is: \(self.participantID)")
            }
        }
        
    }
    
    // Implement the session(_:didReceiveFile:) method to handle the received file
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        #if os(iOS)
        Logger.info(Subsystem: "WCM", Msg: "didReceivedFile: \(file.fileURL)")
        DispatchQueue.main.async {
            guard let receivedFileContent = try? Data(contentsOf: file.fileURL) else {
                print("Data could not be received")
                return
            }
            
            print("Received data from fileURL")
            self.FileMan.saveFile(fileURL: file.fileURL, fileData: receivedFileContent) { completed in
                if completed {
                    do {
                        print(file.fileURL.lastPathComponent)
                        self.Logger.info(Subsystem: "WCM", Msg: "Application Context Updated! File to delete changed to \(file.fileURL.lastPathComponent).")
                        WCSession.default.sendMessage(["single-received-file-to-delete" : file.fileURL.lastPathComponent],
                                                          replyHandler: { reply in
                            print(reply)
                        },
                                                          errorHandler: { (error) in
                            self.Logger.error(Subsystem: "WCM", Msg: "Error with marking received file for deletion! \(error)")
                        })
                        
                    }
                }
                else {
                    self.Logger.error(Subsystem: "WCM", Msg: "Failed to save Transfered File: \(file.fileURL)")
                }
            }
            //self.fileData = receivedFileContent
            
            self.currentFileProgress = 1.0 // Update Progress variable for phone display
            
            self.fileReceivedFlag = true // Trigger for Phone to upload data to Dropbox
        }
        #else // WatchOS response
        Logger.debug(Subsystem: "WCM", Msg: "MESSAGE SHOULD BE ON PHONE LOG. Recieved File.")
        #endif
        // Handle the received file URL
    }
    
    func session(_ session: WCSession, didReceiveError error: Error) {
        // Handle the error
        print("Watch Connectivity error: \(error.localizedDescription)")
    }
    
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        print("Activation did complete with ActivationState")
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCM: Session did become inactive.")
    }
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCM: Session did deactivate.")
        session.activate()
    }
    #endif
    
    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        if let error = error {
            // Handle the error
            Logger.error(Subsystem: "WCM", Msg: "File transfer failed: \(error.localizedDescription)")
        } else {
            // File transfer completed successfully
            #if os(iOS)
            Logger.debug(Subsystem: "WCM", Msg: "THIS MESSAGE SHOULD BE ON WATCH LOG!!! CM finished File Transfer.")
            #else
            Logger.info(Subsystem: "WCM", Msg: "File transfer completed for \(fileTransfer.file.fileURL.lastPathComponent)")
            #endif
        }
    }
    
    
    #if os(iOS)
    
    
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let fraction = message["progressUpdate"] as? Double {
            DispatchQueue.main.async {
                self.currentFileProgress = fraction
                print("Phone: progressUpdate = \(fraction * 100)%")
                // Update filename as well
                if let txfrFileName = message["txfrFileName"] as? String {
                    self.currentTxfrFileName = txfrFileName
                }
                else {
                    print("Filename not included in message of progress update")
                }
            }
        }
    }
    
    #else // If WatchOS
    
    // Transfer File func. pass file URL and handle metadata
    func transferFileWatchToPhone(at fileURL: URL, metadata: [String : Any]? = nil) {
        // check if phone and watch are paird before sending
        guard WCSession.default.isReachable || WCSession.default.activationState == .activated else {
            print("WatchConnectivity session not ready or reachable.")
            return
        }
        
        // Use WCSession library calls to transfer file
        let fileTransfer = WCSession.default.transferFile(fileURL, metadata: metadata)
        print("File transfer initiated for: \(fileURL.lastPathComponent)")
        // Pass the fileTransfer to the progress observer
        observeFileTransferProgress(fileTransfer)
    }
    
    // Takes in object of type WCSessionFileTransfer
    private func observeFileTransferProgress(_ fileTransfer: WCSessionFileTransfer) {
        // Progress object that represents the ongoing file operation’s completion fraction.
        let progress = fileTransfer.progress
        let fileName = fileTransfer.file.fileURL.lastPathComponent
        
        // Watches changes to the fractionCompleted property of the Progress object, closure envoked every time fractionCompleted changes
        let observer = progress.observe(\.fractionCompleted, options: [.initial, .new]) { [weak self] progressObj, _ in
            guard let self = self else { return }
            
            // Represents the current percentage
            let fraction = progressObj.fractionCompleted
            print(String(format: "Watch: \(fileName) transfer progress: %0.1f %",(fraction * 100)))
            
            // Send partial progress if not complete
            if fraction < 1.0, WCSession.default.isReachable {
                WCSession.default.sendMessage(
                    ["progressUpdate": fraction,
                     "txfrFileName": fileName],
                    replyHandler: nil,
                    errorHandler: { error in
                        print("Watch: Error sending progress to phone: \(error.localizedDescription)")
                    }
                )
            }
            
            // Complete
            if fraction >= 1.0 {
                print("Watch: File transfer COMPLETE for \(fileName)")
                DispatchQueue.main.async {
                    // Remove from memory when done
                    self.progressObservers.removeValue(forKey: fileName)
                    // Move to Long Term Memory when complete
                    guard let repoURL = self.FileMan.getFilePath(filename: fileName, folderSelect: .dataRepoFolder) else {return} // Do nothing if no repo
                    if repoURL == fileTransfer.file.fileURL {
                        print("File already in repository, skipping move: \(fileName)")
                    }
                    else { // Move from main folder to repository if this is first successful transfer
                        if self.FileMan.moveFile(srcURL: fileTransfer.file.fileURL, destURL: repoURL) {
                            print("Successfully moved file \(fileName) to repository.")
                        }
                        else {
                            print("Error moving file \(fileName) to repository.")
                        }
                    }
                    
                }
            }
        }
        
        // Observer stays in memory for the duration of the transfer
        progressObservers[fileName] = observer
        
        // print("Current Progress Observers:\n\(progressObservers)")
    }
    
    
    
    #endif



    
}


