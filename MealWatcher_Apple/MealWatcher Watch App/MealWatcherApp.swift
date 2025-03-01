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
  Project: MealWatcher Watch App

  Created by Jimmy Nguyen on 6/6/23.
  Edited and Maintained by James Jolly since Dec 15, 2023
 
    Purpose:
 Main struct of the MealWatcher Watch App needed for Apple protocol.
*/

import SwiftUI


@main
struct MealWatcherApp: App {
    @WKApplicationDelegateAdaptor private var extensionDelegate: ExtensionDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
               // .environment(\.appDelegate, delegate)
        }
    }
}

struct DelegateKey: EnvironmentKey {
    typealias Value = ExtensionDelegate?
    static let defaultValue: ExtensionDelegate? = nil
}

extension EnvironmentValues {
    var appDelegate: DelegateKey.Value {
        get {
            return self[DelegateKey.self]
        }
        set {
            self[DelegateKey.self] = newValue
        }
    }
}
