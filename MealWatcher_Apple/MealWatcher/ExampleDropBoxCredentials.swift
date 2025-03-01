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
  File: ExampleDropBoxCredentials.swift
 Project: MealWatcher Phone App

  Created by James Jolly on 2/19/25.
 
    Purpose:
 Provide Example of functions to access any confidential credentials not uploaded to GitHub Repository (fill in with your own DropBox Data and upload tokens)
 
 Tutorial on how to access tokens and client information found at the following URL as of Feb 21, 2025
 https://www.dropboxforum.com/discussions/101000014/get-refresh-token-from-access-token/596739
*/

func Example_AccessDropBoxCredential () -> (refreshToken: String, clientID: String, clientSecret: String) {
    let refreshToken = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" // Alphabetical (maybe numeric)
    let clientID = "1y1y1y1y1y1y1y1" // Alphanumeric
    let clientSecret = "2z2z2z2z2z2z2z2" // Alphanumeric
    
    return (refreshToken, clientID, clientSecret) // return
}

func Example_AccessDropBoxKey () -> String {
    return "0w0w0w0w0w0w0w0" // Alphanumeric
}
