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
  File: FileManager.swift
  Project: MealWatcher Watch App

  Created by Jimmy Nguyen on 6/19/23.
  Edited and Maintained by James Jolly since Dec 15, 2023
 
    Purpose:
 Create class and delegate for managaing app files and data in the watch app.
 
 Moves, names, organizes, and accesses data files, images, and log files for watch app.
 Has access to two main folders:
    1) "Main" folder: contains active files and any files the watch has not observed fully transfering to phone,
    2) "Repository" folder: long term storage of files the watch has observed transfering to the phone but does not delete in case they need to be access later.
 Even if all data recorded on watch in normal data collection (~5 days) stays on the watch, the average memory usage would be ~150MB,
 which is less than 0.5% of Apple Watch Memory (32GB). A button to deleting files in repository to free memory is provided in Developer View of watch App.
 
 Single shared instance of the manager is created, though several API Observable Objects may be made in app.
*/

import Foundation
import SwiftUI

public class LocalFileManager {
    
    static let instance = LocalFileManager()
    let mainFolderName = "BiteCounter_Data"
    let FullDataFolderName = "FullDataRepo"
    var mainFolderURL: URL? = nil

    var DataRepoURL: URL? = nil
    
    var currentRecordingURL: URL? = nil
    var isRecordingActive: Bool = false
    
    init() {
        mainFolderURL = createFolderIfNeeded(folderName: mainFolderName)
        // Add for full data repo
        DataRepoURL = createFolderIfNeeded(folderName: FullDataFolderName)
    }
    
    func createFolderIfNeeded(folderName: String) -> URL? {
        guard let path = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(folderName) else {
            return nil
        }
        
        if !FileManager.default.fileExists(atPath: path.path) {
            do {
                try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
                print("Success creating folder")
            } catch let error {
                print("Error creating folder \(error)")
                return nil
            }
        }
        
        return path
    }
    
    
    func AccessFolderNames(selectFolder: Int) -> URL? {
        if selectFolder == 0 {
            return mainFolderURL
        }
        else if selectFolder == 1 {
            return DataRepoURL
        }
        else {
            return mainFolderURL // Default to main folder
        }
    }

    /* delete all local data */
    func deleteMainFolder (folderURL: URL) {
        
        do {
            let contentsFull = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil, options: [])
            // remove current and active log file from deletion
            var contents: [URL] = []
            if (folderURL == mainFolderURL) {
                contents = removeCurrentLogFile(fileList: contentsFull)
            }
            else {
                contents = contentsFull
            }
            // Iterate through the contents and delete each item
            for itemURL in contents {
                try FileManager.default.removeItem(at: itemURL)
            }
            print("Success deleting contents")
        } catch let error {
            print("Error deleting contents. \(error)")
        }
    }
    
    
    func printPath(folderURL: URL) -> Int {

        //let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        do {
            let folderContents = try FileManager.default.contentsOfDirectory(atPath: folderURL.path)
            print("Counting contents in Watch File Folder: Contains \(folderContents.count) items.")
            print("Folder Contents: \(folderContents)")
//            print("The folder contains \(folderContents.count) items.")
            return folderContents.count
        } catch {
            print("Error reading folder contents: \(error.localizedDescription)")
            return 0
        }
    }
    
    
    func printPathNames(folderURL: URL) -> [String] {
        do {
            let folderContents = try FileManager.default.contentsOfDirectory(atPath: folderURL.path)
            print("Folder Contents: \(folderContents)")
            print("The folder contains \(folderContents.count) items")
            
            
            return folderContents
        } catch {
            print("Error reading folder contents: \(error.localizedDescription)")
            return []
        }
    }
    
    
    /// NOTE: TAKES NAMES AND RETURN URL
    func getPathForFile(folderURL: URL, fileName: String) -> URL? {
        
        let path = folderURL.appendingPathComponent(fileName)
        return path
    }
    
    /// NOTE: TAKES NAMES AND RETURN URL
    func getPathForFolder(folderName: String, fileName: String) -> URL? {
        
        guard let path = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(folderName)
            .appendingPathComponent(fileName) else {
            print("Error getting path")
            return nil
        }
        
        //print(path.path)
        return path
    }
    
    func getFolderFilePaths(folderURL: URL) -> [URL]? {
        do {
            // Get the contents of the directory
            let fileURLs = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            // If using a shallow (no subdirectory) system, use this
            return fileURLs
            
        } catch {
            // Handle the error, e.g., print an error message
            print("Error: \(error)")
            return nil
        }
    }
    
    
    
    func deleteData(dataURL: URL) {
        // Given a URL, delete the file if it exists.
        // Validity of file URL is up to caller
        do {
            try FileManager.default.removeItem(at: dataURL)
            print("Successfully deleted.")
        } catch let error {
            print("Error deleting file. \(error)")
        }
    }
    
    func removeCurrentLogFile(fileList: [URL]) -> [URL] {
        var latestLogFileName = "0000-00-00-00-00-00-watch.log" // entry should be beaten by any log file found
        var latestLogFileURL: URL? = nil
        var currFileName = ""
        for i in 0..<fileList.count {
            currFileName = String(fileList[i].lastPathComponent.suffix(29))
            if (currFileName.hasSuffix("watch.log")) {
                // Prints for debugging
//                print("Found Log File!")
//                print("FileName is :\(currFileName)")
                if currFileName > latestLogFileName {
                    latestLogFileURL = fileList[i]
                    latestLogFileName = currFileName
                }
            }
        }
        guard let URL2Remove = latestLogFileURL else {return fileList} // return latest if it exists
        print("Removing current log file list: \(URL2Remove)")
        let fileList_trimmed = fileList.filter { $0 != URL2Remove }
        return fileList_trimmed
    }
    
    func removeCurrentRecordingFile(fileList: [URL]) -> [URL] {
        if (self.isRecordingActive) {
            guard let URL2Remove = self.currentRecordingURL else {return fileList} // return latest if it exists
            print("Removing current active recording from list: \(URL2Remove)")
            let fileList_trimmed = fileList.filter { $0.lastPathComponent != URL2Remove.lastPathComponent }
            return fileList_trimmed
        }
        else {
            print("No Recording Active: Keeping entire file list.")
            return fileList
        }
    }
    
}

class FileManagerViewModelWatch: ObservableObject {
    
    enum FolderType {
        case mainFolder
        case dataRepoFolder
    }
    
    @Published var image: UIImage? = nil
    @Published var infoMessage: String = ""
    @Published var folderCount: Int = 0
    let manager = LocalFileManager.instance
    //@Published var currentTimeStamp: String = ""

    var mainFolderURL: URL? = nil
    var DataRepoFolderURL: URL? = nil
    
    init () {
        self.mainFolderURL = manager.AccessFolderNames(selectFolder: 0)
        self.DataRepoFolderURL = manager.AccessFolderNames(selectFolder: 1)
    }
    
    
    func listSize(folderSelect: FolderType = .mainFolder) -> Int {
        guard let currFolderURL : URL = {
            switch folderSelect {
            case .mainFolder:
                return self.mainFolderURL
            case .dataRepoFolder:
                return self.DataRepoFolderURL
            }
        }() else {return -3}
        
        folderCount = manager.printPath(folderURL: currFolderURL)
        
        if (manager.isRecordingActive) {
            return (folderCount - 2) // subtract current recording and log files
        }
        else {
            return (folderCount - 1) // subtract current log file
        }
        
    }
    
    
    func getFilePath(filename: String, folderSelect: FolderType = .mainFolder) -> URL? {
        guard let currFolderURL : URL = {
            switch folderSelect {
            case .mainFolder:
                return self.mainFolderURL
            case .dataRepoFolder:
                return self.DataRepoFolderURL
            }
        }() else {return nil}
        
        guard let fileURL = manager.getPathForFile(folderURL: currFolderURL, fileName: filename) else {
            print("Error getting data file URL")
            return nil
        }
        return fileURL
    }
    
    func getAllFilePaths(folderSelect: FolderType = .mainFolder) -> [URL]? {
        guard let currFolderURL : URL = {
            switch folderSelect {
            case .mainFolder:
                return self.mainFolderURL
            case .dataRepoFolder:
                return self.DataRepoFolderURL
            }
        }() else {return nil}
        
        guard let URLs = manager.getFolderFilePaths(folderURL: currFolderURL) else {return nil}
        // if files exist, then trim the current log file from list so it does not get deleted
        var trimURLs: [URL] = []
        if (folderSelect == .mainFolder) { // current log file is only in main folder
            trimURLs = manager.removeCurrentLogFile(fileList: URLs)
        }
        else {
            trimURLs = URLs
        }
        
        trimURLs = manager.removeCurrentRecordingFile(fileList: trimURLs)
//        if (manager.isRecordingActive) {
//            let extraTrimURLs = trimURLs.filter { $0 != manager.currentRecordingURL }
//            return extraTrimURLs
//        }
//        else {
//            return trimURLs
//        }
        trimURLs.sort { $0.lastPathComponent < $1.lastPathComponent }
        return trimURLs
    }
    
    func getAllFileNames(folderSelect: FolderType = .mainFolder) -> [String] {
        guard let currFolderURL : URL = {
            switch folderSelect {
            case .mainFolder:
                return self.mainFolderURL
            case .dataRepoFolder:
                return self.DataRepoFolderURL
            }
        }() else {return []}
        
        guard let URLs = manager.getFolderFilePaths(folderURL: currFolderURL) else {return []}
        // if files exist, then trim the current log file from list so it does not get deleted
        var trimURLs: [URL] = []
        if (folderSelect == .mainFolder) { // current log file is only in main folder
            trimURLs = manager.removeCurrentLogFile(fileList: URLs)
        }
        else {
            trimURLs = URLs
        }
        trimURLs = manager.removeCurrentRecordingFile(fileList: trimURLs)
        print("isRecordingActive = \(manager.isRecordingActive)")
        print("CurrFile is \(String(describing: manager.currentRecordingURL?.lastPathComponent))")
//        if (manager.isRecordingActive) { // trim if there is an active recording
//            trimURLs = trimURLs.filter { $0 != manager.currentRecordingURL }
//            print("Removing \(String(describing: manager.currentRecordingURL?.lastPathComponent)) from file list")
//            print(trimURLs)
//        }
        var FileNames: [String] = []
        for currURL in trimURLs {
            FileNames.append(currURL.lastPathComponent)
        }
        // alphabetize the list for convenience
        FileNames.sort()
        return FileNames
    }
    
    
    
    func deleteDataFile(dataURL: URL) {
        manager.deleteData(dataURL: dataURL)
    }
    
    // Functions Used to mark the current recording
    // to safeguard it from other actions by the file manager mid-recording
    func newRecordingFile(startedFileURL: URL) -> Bool {
        manager.isRecordingActive = true
        manager.currentRecordingURL = startedFileURL
        print("currentRecordingURL is now \(startedFileURL)")
        return true
    }
    
    func finishedRecordingFile() -> Bool {
        manager.isRecordingActive = false
        manager.currentRecordingURL = nil
        print("currentRecordingURL is now nil")
        return true
    }
    
    func copyFile(srcURL: URL, destURL: URL) -> Bool {
        do {
            try FileManager.default.copyItem(at: srcURL, to: destURL)
            return true
        }
        catch let error {
            print("Error in copying file \(error)")
            return false
        }
    }
    
    func moveFile(srcURL: URL, destURL: URL) -> Bool {
        do {
            try FileManager.default.moveItem(at: srcURL, to: destURL)
            return true
        }
        catch let error {
            print("Error in copying file \(error)")
            return false
        }
    }
    
    func generateFillerFile(filename: String, kBytesToWrite: Int) ->Bool {
        let folderSelect = FolderType.mainFolder
        guard let currFolderURL : URL = {
            switch folderSelect {
            case .mainFolder:
                return self.mainFolderURL
            case .dataRepoFolder:
                return self.DataRepoFolderURL
            }
        }() else {return false}
        guard let fileURL = manager.getPathForFile(folderURL: currFolderURL, fileName: filename) else {return false}
        guard let outputStream = OutputStream(url: fileURL, append: true) else {return false}
        outputStream.open()
        
        var data: String = ""
        for i in (1...250) {
            data.append("\(i),")
        }
        data.append("\n")
//        let binaryData = Data(bytes: &data, count: MemoryLayout.size(ofValue: data.index(after: data.startIndex))*data.count)
        let encodedDataArray = [UInt8](data.utf8)
        
//        let buffer = [UInt8](binaryData)
        
        for i in (0..<kBytesToWrite) {
            if false {
                do {
                    try data.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
                }
                catch {
                    print("Error in writing to file")
                    return false
                }
                
                
            }
            else {
                let bytesWritten = outputStream.write(encodedDataArray, maxLength: encodedDataArray.count)

                if bytesWritten < 0 {
                    print("Write error")
                    outputStream.close()
                    manager.deleteData(dataURL: fileURL)
                    return false
                }
            }
            if ((kBytesToWrite > 100) && (i % 1000 == 0)) {
                print("Through \(i) of \(kBytesToWrite) lines")
            }
        }
        
        outputStream.close()
        
        return true
    }
    
    
}
