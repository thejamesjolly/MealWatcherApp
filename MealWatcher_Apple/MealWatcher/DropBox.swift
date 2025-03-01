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
  File: DropBox.swift
  Project: MealWatcher Phone App

  Created by Jimmy Nguyen on 6/28/23.
  Edited and Maintained by James Jolly since Dec 15, 2023
 
    Purpose:
 Button and functions which manage file upload capabilities to speciifed DropBox server
 
 NOTE: Credentials are removed from public repository for DropBox account security purposes.
        Example Credentials (for formatting) are provided
*/

import Foundation
import SwiftyDropbox
import SwiftUI


func refreshTokenRequest(completion: @escaping (String?) -> Void) {
    
    // PRIVATE STRINGS FOUND IN PRIVATE FILE. MUST GENERATE WITH YOUR OWN DROPBOX ACCOUNT
    let (refreshToken, clientID, clientSecret) = AccessDropBoxCredential()
    // EXAMPLE STRINGS AND FORMATTING CAN BE FOUND WITH THIS FUNCTION CALL
    // let (refreshToken, clientID, clientSecret) = Example_AccessDropBoxCredential()
    
    let url = URL(string: "https://api.dropbox.com/oauth2/token")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    let parameters: [String: String] = [
        "refresh_token": refreshToken,
        "grant_type": "refresh_token",
        "client_id": clientID,
        "client_secret": clientSecret
    ]
    let postData = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
    let postDataEncoded = postData.data(using: .utf8)
    
    request.httpBody = postDataEncoded
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

    URLSession.shared.dataTask(with: request) { (data, response, error) in
        if let error = error {
            print("Error: \(error.localizedDescription)")
            completion(nil)
            return
        }
        
        guard let data = data else {
            print("No data received")
            completion(nil)
            return
        }
        
        // Process the response data here
        // Example: Decode the JSON response
        if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            //print("Response JSON: \(json)")
            if let accessToken = json["access_token"] as? String {
                completion(accessToken)
                return
            }
        }
        completion(nil)
    }.resume()
}

func submitPayload(participantID: String, LocationFlag: Int, iOSFiles: FileManagerViewModel, completion: @escaping (DropboxClient?) -> Void) {
    
    //DEBUG CANCEL CONNECTION
//    return;
    
    refreshTokenRequest { accessToken in
        if let accessToken = accessToken {
//            print("Access Token: \(accessToken)")
            let client = DropboxClient(accessToken: accessToken)
            // Perform further actions with the access token
            //let dataCount = iOSFiles.listSize()
            //print("There are \(dataCount) files saved")
            guard let filePaths = iOSFiles.getAllFilePaths() else {return}
            
            var filesCommitInfo = [URL : Files.CommitInfo]()
            print("Pre-loop: current File.CommitInfo = \(filesCommitInfo)")
            
            for filePath in filePaths {
                let fileUrl: URL! = filePath
                var uploadToPath = ""
                if LocationFlag == 1 {
                    uploadToPath = "/WATCH/Clemson/"+participantID+"/\(fileUrl.lastPathComponent)"
                }
                else if LocationFlag == 2 {
                    uploadToPath = "/WATCH/Brown/"+participantID+"/\(fileUrl.lastPathComponent)"
                }
                else if LocationFlag == 3 {
                    uploadToPath = "/WATCH/Developer/"+participantID+"/\(fileUrl.lastPathComponent)"
                }
                else if LocationFlag == 0 {
                    uploadToPath = "/WATCH/No_Location/"+participantID+"/\(fileUrl.lastPathComponent)"
                }
                else {
                    print("WARNING: UNKNOWN LOCATION PATH. USING Defualt.")
                    uploadToPath = "/WATCH/No_Location/"+participantID+"/\(fileUrl.lastPathComponent)"
                }
                filesCommitInfo[fileUrl] = Files.CommitInfo(path: uploadToPath, mode: Files.WriteMode.overwrite)
            }
            print("Post-loop: current File.CommitInfo = \(filesCommitInfo)")
            
            client.files.batchUploadFiles(
                fileUrlsToCommitInfo: filesCommitInfo,
                responseBlock: { (uploadResults: [URL: Files.UploadSessionFinishBatchResultEntry]?,
                                  finishBatchRequestError: CallError<Async.PollError>?,
                                  fileUrlsToRequestErrors: [URL: CallError<Async.PollError>]) -> Void in

                    if let uploadResults = uploadResults {
                        for (clientSideFileUrl, result) in uploadResults {
                            switch(result) {
                                case .success(let metadata):
                                    let dropboxFilePath = metadata.pathDisplay!
                                    print("Upload \(clientSideFileUrl.absoluteString) to \(dropboxFilePath) succeeded")
                                    iOSFiles.removeUploadedItem(fileURLToDelete: clientSideFileUrl)
                                case .failure(let error):
                                    print("Upload \(clientSideFileUrl.absoluteString) failed: \(error)")
                            }
                        }
                    }
                    else if let finishBatchRequestError = finishBatchRequestError {
                        print("Error uploading file: possible error on Dropbox server: \(finishBatchRequestError)")
                    } else if fileUrlsToRequestErrors.count > 0 {
                        print("Error uploading file: \(fileUrlsToRequestErrors)")
                    }
            })
            
//            alertTitle = "Success!"
//            alertMessage = "The data is being uploaded currently. "
//            showAlert.toggle()
            HapticManager.instance.notification(type: .success)
            completion(client)
        } else {
//            print("Failed to get access token")
//            alertTitle = "Connection to DropBox Failed"
//            alertMessage = "Cannot connect to DropBox. There may be an issue with your connection or the app."
            HapticManager.instance.notification(type: .error)
            completion(nil)
            return
        }
    }
    
}

struct DropBoxView: View {
    
    @Binding var client: DropboxClient
    //var connectivityManager: WatchConnectivityManager
    var participantID: String
    var LocationFlag: Int
    var iOSFiles: FileManagerViewModel
    var completedFlagClient: DropboxClient?
    //var dataCount: Int
    @Binding var showAlert: Bool
    @Binding var alertTitle: String
    @Binding var alertMessage: String
    @State private var connection: Bool = false
    
    var body: some View {
        HStack () {
            Button(action: {
                /* first check if the user has submitted a participant ID, else prompt them to*/
                if participantID.isEmpty {
                    print("Please enter your participant ID")
                    alertTitle = "Missing Participant ID"
                    alertMessage = "Please type in your participant ID before uploading any data."
                    showAlert.toggle() //Must do so after the title and message have been updated
                    HapticManager.instance.notification(type: .error)
                    return
                }
                else {
                    print("Submitting to Dropbox from DropboxView!")
                    submitPayload(participantID: participantID, LocationFlag: LocationFlag, iOSFiles: iOSFiles) { completedFlagClient in
                        if (completedFlagClient != nil) {
                            alertTitle = "Success!"
                            alertMessage = "The data is being uploaded currently. "
                            showAlert.toggle()
                            HapticManager.instance.notification(type: .success)
                        } else {
                            print("Failed to get access token")
                            alertTitle = "Connection to DropBox Failed"
                            alertMessage = "Cannot connect to DropBox. There may be an issue with your connection or the app."
                            HapticManager.instance.notification(type: .error)
                        }
                        return
                    }
                }
            }, label: {
                Text("Send Data to DropBox")
            })
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            //.padding(.horizontal)
            
        }
    }
    
    func testDropBoxConnection(completion: @escaping (Bool) -> Void)
    {
        client.users.getCurrentAccount().response { response, error in
            if let _ = response {
                // Connection is successful
                print("Client connection is successful.")
                //let connection = true
                completion(true)
                // Proceed with uploading
            } else if let error = error {
                // Connection error occurred
                print("Error testing client connection: \(error)")
                completion(false)
                //let connection = false
            }
        }
    }
}







