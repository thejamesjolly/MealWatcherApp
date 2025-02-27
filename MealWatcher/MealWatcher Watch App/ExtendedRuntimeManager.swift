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
  File: ExtendedRuntimeManager.swift
  Project: MealWatcher Watch App

  Created by Jimmy Nguyen on 7/27/23.
  Edited and Maintained by James Jolly since Dec 15, 2023
 
    Purpose:
  Functions used to help establish extended Workout sessions on the watch to record motion in the background
*/

import Foundation
import WatchConnectivity
import WatchKit

class ExtendedRuntimeManager: NSObject, WKExtendedRuntimeSessionDelegate, ObservableObject {
    
    var WatchLogger = WatchAppLogger.shared
    
    @Published var mostRecentFileName: String = "Unknown"
    let cmutils = CMUtils()
    @Published var vmWatch = FileManagerViewModelWatch()
    // MARK:- Extended Runtime Session Delegate Methods
    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        // Track when your session starts.
        WatchLogger.info(Subsystem: "wERM", Msg: "Extended runtime session is starting")
    }


    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        // Finish and clean up any tasks before the session ends.
        WatchLogger.info(Subsystem: "wERM", Msg: "Extended runtime session is expired")
        cmutils.stopUpdates(filename: mostRecentFileName)
        print("Attempting to send CSV file")
        guard let fileURL = vmWatch.getFilePath(filename: mostRecentFileName) else {return}
        if WCSession.default.isReachable {
            print(fileURL)
            WCSession.default.transferFile(fileURL, metadata: nil)
        } else {
            WatchLogger.warning(Subsystem: "wERM", Msg: "iOS app not reachable")
        }
    }
        
    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        // Track when your session ends.
        WatchLogger.info(Subsystem: "wERM", Msg: "Extended runtime session is ending")
        // Also handle errors here.
        
        print("didInvalidateWithReason: \(reason)")
        
        if error != nil {
            WatchLogger.error(Subsystem: "wERM", Msg: "Errors Encountered: \(String(describing: error))")
            //print(error)
        }
        else {
            return
        }
    }
    
}


