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
  File: ViewModelWatch.swift
  Project: MealWatcher Watch App

  Created by Jimmy Nguyen on 6/9/23.
  Edited and Maintained by James Jolly since Dec 15, 2023

    Purpose:
 Manage WatchConnectivity session status on the Watch
*/

import Foundation
import WatchConnectivity

class ViewModelWatch : NSObject,  WCSessionDelegate, ObservableObject {
    var session: WCSession
    @Published var messageText = ""
    init(session: WCSession = .default){
        self.session = session
        super.init()
        session.delegate = self
        session.activate()
    }
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
            DispatchQueue.main.async {
                self.messageText = message["message"] as? String ?? "Unknown"
            }
        }
    
}
