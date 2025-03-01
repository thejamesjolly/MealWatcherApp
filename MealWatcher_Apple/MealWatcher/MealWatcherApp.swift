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
  File: MealWatcherApp.swift
  Project: MealWatcher Phone App

  Created by Jimmy Nguyen on 6/6/23.
  Edited and Maintained by James Jolly since Dec 15, 2023
 
    Purpose:
 Main struct of the MealWatcher Phone App needed for Apple protocol.
 
 SwiftyDropbox is imported to manage file uploads, and setup with the App Key.
 This key is part of a DropBox Private App (created through DropBox account and website),
 with the function call found in a D
*/

import SwiftUI
import SwiftyDropbox
//import BackgroundTasks
//
//func scheduleAppRefresh() {
//    let request = BGAppRefreshTaskRequest(identifier: "myapprefresh")
//    try? BGTaskScheduler.shared.submit(request)
//}

@main
struct MealWatcherApp: App {
    @State private var lastRefresh = Date()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var phase
    
    init() {
        DropboxClientsManager.setupWithAppKey(AccessDropBoxKey())
        print("Initializing App in MealWatcherApp")
        
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
            //SettingsView()
        }
    }


}
