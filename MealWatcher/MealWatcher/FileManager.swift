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
  Project: MealWatcher Phone App

  Created by Jimmy Nguyen on 6/19/23.
  Edited and Maintained by James Jolly since Dec 15, 2023
 
    Purpose:
 Create class and delegate for managaing app files and data in the phone app.
 
 Moves, names, organizes, and accesses data files, images, and log files for phone app.
 Single shared instance of the manager is created, though several API Observable Objects may be made in app.
 
 Currently separated from the long-term photo storage, which is found in FileManagerPhoto.swift.
 Future Work could stitch these files and classes together, similar to Watch FileManager with Main folder and Repo folder.
*/

import Foundation
import SwiftUI

class LocalFileManager {
    
    static let instance = LocalFileManager()
    let mainFolderName = "MealWatcher_Data"
    let fmDateFormatter = DateFormatter()
    var currentRecordingURL: URL? = nil
    var isRecordingActive: Bool = false
    
    init() {
        createMainFolderIfNeeded()
        //Save Date Formatter as the standard expected in the file Format
        fmDateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
    }
    
    func createMainFolderIfNeeded() {
        guard let path = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(mainFolderName)
            .path else {
            return
        }
        
        if !FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
                print("Success creating folder")
            } catch let error {
                print("Error creating folder \(error)")
            }
        }
    }

    /* delete all local data */
    func deleteMainFolder () {
        guard let path = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(mainFolderName) else {
            return
        }
        
        do {
            let contentsFull = try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: nil, options: [])
            // remove current and active log file from deletion
            let contents = removeCurrentLogFile(fileList: contentsFull)
            // Iterate through the contents and delete each item
            for itemURL in contents {
                try FileManager.default.removeItem(at: itemURL)
            }
            print("Success deleting contents")
        } catch let error {
            print("Error deleting contents. \(error)")
        }
    }
    
    func addNewFolder(folderName: String) {
        guard let path = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(mainFolderName)
            .appendingPathComponent(folderName)
            .path else {
            return
        }
        print("new folder path:", path)
        
        if !FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
                print("Success creating folder")
            } catch let error {
                print("Error creating folder \(error)")
            }
        }
    }
    
    /// Returns the date encoded into the timestamp using our standard file format with 5 digit participant ID
    /// Returns nil if dates are improperly formatted
    func GetDateFromFilename (fileName: String) -> Date? {
        let startOffset:Int = 1 + 5 // 1 digit for the dash, then length of participant ID
        let dateLen:Int = "yyyy-MM-dd-HH-mm-ss".count
        // Assuming a 5 digit Participant ID and a '-' for start index offset
        // Assuming format listed in dateformatter plus start for end index offset
        let startDateIndex = fileName.index(fileName.startIndex, offsetBy: startOffset)
        let endDateIndex = fileName.index(fileName.startIndex, offsetBy: startOffset+dateLen)
        let dateString = String(fileName[startDateIndex..<endDateIndex])
        
        guard let fileDate = fmDateFormatter.date(from: dateString) else {
            print("FMP: Error pulling date from file name: \(fileName)")
            return nil // return if error in formatting
        }
        
        return fileDate // if through guard, then return date
    }
    
    
    func saveImage(image: UIImage, imageName: String) -> String { //folderName: String) -> String {
        
        guard let data = image.jpegData(compressionQuality: 1.0)
        else {
            print("Error getting data.")
            return "Error getting data."
        }
        
        guard let path = getPathForImage(imageName: imageName)
        else {
            print("Error getting path")
            return "Error getting path."
        }
        print(path)
        do {
            try data.write(to: path)
            //print(path)
            return "Success saving"
        } catch let error {
            return "Error saving. \(error)"
        }
    }
    
    func getImage(imageName: String, folderName: String) -> UIImage? {
        
        guard let path = getPathForImage(imageName: imageName)?.path,
              FileManager.default.fileExists(atPath: path) else {
            print("Error getting path")
            return nil
        }
        
        return UIImage(contentsOfFile: path)
    }
    
    func getPathForImage(imageName: String) -> URL? { //folderName: String) -> URL? {
        
        guard let path = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(mainFolderName)
            //.appendingPathComponent(folderName)
            .appendingPathComponent("\(imageName).jpg") else {
            print("Error getting path")
            return nil
        }
        //print(path)
        return path
    }
    
    func deleteImage(name: String) -> String {
        
        guard let path = getPathForImage(imageName: name),
              FileManager.default.fileExists(atPath: path.path) else {
            return "Error getting path"
            
        }
        
        do {
            try FileManager.default.removeItem(at: path)
            return "Successfully deleted."
        } catch let error {
            return "Error deleting image. \(error)"
        }
    }
    
    func countFolderContents() -> Int {
        guard let path = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(mainFolderName) else {
            return 0
        }
        do {
            let folderContents = try FileManager.default.contentsOfDirectory(atPath: path.path)
            //print("Folder Contents: \(folderContents)")
            //print("The folder contains \(folderContents.count) files")
            return folderContents.count
        } catch {
            print("Error reading folder contents: \(error.localizedDescription)")
            return 0
        }
    }
    
    func countFolderContent() -> Int {
        guard let path = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(mainFolderName) else {
            return 0
        }
        do {
            let folderContents = try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: [.isDirectoryKey])
//            let folderContents1 = try FileManager.default.contentsOfDirectory(atPath: path.path)
            //print("Folder Contents: \(folderContents)")
            //print("The folder contains \(folderContents.count) files")
            return folderContents.count
        } catch {
            print("Error reading folder contents: \(error.localizedDescription)")
            return 0
        }
    }
    
    
    /// Returns a sorted list of files in folder... Unsure if it actually works
    func sortMainFolderByDate() -> [String]? {
        guard let path = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(mainFolderName) else {
            return nil
        }
        do {
            let folderContents = try FileManager.default.contentsOfDirectory(atPath: path.path)
            print(folderContents)
            
            let sortedFolderContents = folderContents.sorted { filename1, filename2 in
                // Consolidated to function since string protocol is unsightly
                if let date1 = GetDateFromFilename(fileName: filename1), let date2 = GetDateFromFilename(fileName: filename2) {
                    return date1 < date2
                } else { // if either date fails to format, assume the first one is less than the second
                    return false
                }
            }
            
            print("Sorted folder contents:")
            for i in 0..<sortedFolderContents.count {
                print("\(sortedFolderContents[i])")
            }
            
            return sortedFolderContents
        } catch {
            print("Error reading folder contents: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Possibly Unused
    func getFolderName(index: Int) -> (String?) {
        guard let path = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(mainFolderName) else {
            return nil
        }
        do {
            let folderContents = try FileManager.default.contentsOfDirectory(atPath: path.path)
            let folderName = folderContents[index]
            print("Folder name: \(folderName)")
            return folderName
        } catch {
            print("Error reading folder contents: \(error.localizedDescription)")
            return nil
        }
    }
    
    
    func getFolderPath(/*folderName: String*/) -> URL? {
        guard let path = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(mainFolderName) else {
            //.appendingPathComponent(folderName) else {
            print("Error getting path")
            return nil
        }
        return path
    }
    
    func getFolderSize(/*folderName: String*/) -> Int? {
        guard let path = getFolderPath() else {return nil}
        do {
            let folderContents = try FileManager.default.contentsOfDirectory(atPath: path.path)
            print("Data folder: contains \(folderContents.count) files")//folders")
            return folderContents.count
        } catch {
            print("Error reading folder contents: \(error.localizedDescription)")
            return nil
        }
    }
    
    
    
    func getPathForCSV(/*folderName: String,*/fileURL: URL) -> URL? {
        guard let path = getFolderPath() else {return nil}
        let destinationURL = path.appendingPathComponent(fileURL.lastPathComponent)
        return destinationURL
    }
    
    func getPathForFileFromURL(/*folderName: String,*/fileURL: URL) -> URL? {
        guard let path = getFolderPath() else {return nil}
        let destinationURL = path.appendingPathComponent(fileURL.lastPathComponent)
        return destinationURL
    }
    
    func importFile(/*folderName: String,*/fileURL: URL, data: Data) {

        guard let path = getPathForFileFromURL(fileURL: fileURL) else {return}
        //print(path)
        do {
            try data.write(to: path)
            print("File saved at: \(path)")

        } catch {
            // Error occurred while saving the file
            print("Failed to save file: \(error.localizedDescription)")
        }
    }
    
    
    func fetchData(/*folderName: String,*/index: Int) -> (data: Data?, fileName: String?)? {
        guard let path = getFolderPath() else {return (nil,nil)}
        do {
            let folderContents = try FileManager.default.contentsOfDirectory(atPath: path.path)
            let itemName = folderContents[index]
            let itemPath = path.appendingPathComponent(itemName)
            let data = try Data(contentsOf: itemPath)
            return (data, itemName)
            // Convert the itemURL to URL if necessary
        } catch {
            print("Error reading folder contents: \(error.localizedDescription)")
            return (nil, nil)
        }
    }
    
    func getPathForSurvey(surveyName: String) -> URL? { //folderName: String) -> URL? {
        
        guard let path = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(mainFolderName)
            //.appendingPathComponent(folderName)
            .appendingPathComponent(surveyName) else {
            print("Error getting path")
            return nil
        }
        return path
    }
    
    
    func closeFile(filename: String) {
        // Create file in directory, get path of file
        guard let path = getPathForFile(fileName: filename) else {return}
        
        do {
            let fileHandle = try FileHandle(forWritingTo: path)
            fileHandle.closeFile()
            print("Successfully closed the file")
        } catch {
            print("Error writing to file: \(error)")
        }
    }
    
    func getPathForData(fileName: String) -> URL? {
        
        guard let path = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(mainFolderName)
            .appendingPathComponent("\(fileName).data") else {
            print("Error getting path")
            return nil
        }
        //print(path.path)
        return path
    }
    
    func getPathForFile(fileName: String) -> URL? {
        //Generic "getPathFor" function that assumes extension is in filename already
        guard let path = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(mainFolderName)
            .appendingPathComponent(fileName) else {
            print("Error getting path")
            return nil
        }
        //print(path.path)
        return path
    }
    
    func getMainDirectoryFilePaths() -> [URL]? {
        guard let path = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(mainFolderName) else {
            print("Error getting path")
            return nil
        }
        
        do {
            // Get the contents of the directory
            let fileURLs = try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: nil)
            // If using a shallow (no subdirectory) system, use this
            return fileURLs
            
        } catch {
            // Handle the error, e.g., print an error message
            print("Error: \(error)")
            return nil
        }
    }
    
    func deleteFile(at url: URL) throws {
        do {
            try FileManager.default.removeItem(at: url)
            print("File deleted successfully.")
        } catch {
            throw error
        }
    }
    
    
    func countJustFiles() -> Int {
        guard let path = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(mainFolderName) else {
            return 0
        }
        do {
            let folderContents = try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: [.isDirectoryKey])
            
            var runningDirCount:Int = 0
            for currURL in folderContents {
                
                if currURL.hasDirectoryPath { // Count Directories to remove from file count
                    runningDirCount += 1 // increment count with each file
                }
            }

            
            print("Running Dir Count = \(runningDirCount)")
            return (folderContents.count - runningDirCount)
            
        } catch {
            print("Error reading folder contents: \(error.localizedDescription)")
            return 0
        }
    }
    
    func removeCurrentLogFile(fileList: [URL]) -> [URL] {
        var latestLogFileName = "0000-00-00-00-00-00-phone.log" // entry should be beaten by any log file found
        var latestLogFileURL: URL? = nil
        var currFileName = ""
        for i in 0..<fileList.count {
            currFileName = String(fileList[i].lastPathComponent.suffix(29))
            if (currFileName.hasSuffix("phone.log")) {
                // Prints used in debugging
//                print("Found Log File!")
//                print("FileName Date is: \(currFileName)")
                if currFileName > latestLogFileName {
                    latestLogFileURL = fileList[i]
                    latestLogFileName = currFileName
                }
            }
        }
        guard let URL2Remove = latestLogFileURL else {return fileList} // return latest if it exists
        print("Removing current log file from list: \(latestLogFileName)")
        let fileList_trimmed = fileList.filter { $0 != URL2Remove }
        return fileList_trimmed
    }

    func removeCurrentRecordingFile(fileList: [URL]) -> [URL] {
        if (self.isRecordingActive) {
            guard let URL2Remove = self.currentRecordingURL else {return fileList} // return latest if it exists
            print("Removing current active recording file from list: \(URL2Remove)")
            let fileList_trimmed = fileList.filter { $0.lastPathComponent != URL2Remove.lastPathComponent }
            return fileList_trimmed
        }
        else {
            return fileList
        }
    }
    
}


/// Interface for managing App Files
/// NOTE: Cannot use Logger in these functions since seperate instances of manager made in many other classes.
///             Rather, it is the responsibility of calling functions to log before or after calling FileManager Functions.
class FileManagerViewModel: ObservableObject {
    
    @Published var image: UIImage? = nil
    @Published var infoMessage: String = ""
    @Published var folderCount: Int = 0
    let imageName: String = "3Falls_Niagara"
    let manager = LocalFileManager.instance
    //@Published var currentTimeStamp: String = ""
    
    
    init () {
        getImageFromAssetsFolder()
        //image = getImageFromFileManager(pictureName: "TestPicture")
        //getImageFromFileManager(pictureName: "TestPicture")
    }
    
    func createNewFolder(folderName: String)
    {
        manager.addNewFolder(folderName: folderName)
    }
    
    // Potentially Unused
    func getImageFromAssetsFolder() {
        image = UIImage(named: imageName)
        //image = UIImage(systemName: "fork.knife.circle.fill")
    }
    
    func getImageFromFileManager(filenamePrefix: String, PrePostFlag: Bool) -> UIImage? {
        var pictureName: String = filenamePrefix
        if PrePostFlag {
            pictureName = filenamePrefix + "-post"
        }
        else {
            pictureName = filenamePrefix + "-pre"
        }
        guard let image = manager.getImage(imageName: pictureName, folderName: filenamePrefix) else {return nil}
        return image
    }
    
    func saveImage(imageCapture: UIImage?, filename: String, PrePostFlag: Bool) {
        //guard let image = image else {return}
        var pictureName: String = filename
        guard let image = imageCapture else {return}
        if PrePostFlag {
            pictureName = filename + "-post"
            print("current time stamp is",filename)
        }
        else {
            pictureName = filename + "-pre"
            print("current time stamp is",filename)
            //manager.addNewFolder(folderName: timeStamp)
        }
        infoMessage = manager.saveImage(image: image, imageName: pictureName)
        print(infoMessage)
    }
    
    func deleteImage() {
        infoMessage = manager.deleteImage(name: imageName)
    }
    
    func listSize() -> Int {
// FolderCount was async, but since it is needed for settings UI, it is now a sync commmand
//        DispatchQueue.main.async { [self] in
//            self.folderCount = manager.printPath()
//            print("ASYNC FILE COUNT COMPLETED")
//        }
        self.folderCount = manager.countFolderContent()
        return folderCount
    }
    
    func getFilenamesSortedByDate() -> [String]? {
        guard let dateList = manager.sortMainFolderByDate() else {return nil}
        return dateList
    }
    
    func saveFile(fileURL: URL, fileData: Data, completion: @escaping (Bool) -> Void) {
        //print("time stamp is: \(timeStamp)")
        manager.importFile(fileURL: fileURL, data: fileData)
        completion(true)
    }
    
    func getDropBoxDataPackage(/*folderName: String,*/index: Int) -> (data: Data?, fileName: String?)? {
        guard let package = manager.fetchData(index: index) else {return (nil,nil)}
        return (package.data, package.fileName)
    }
    
    // Possibly Unused
    func getFolderName(index: Int) -> String? {
        guard let folderName = manager.getFolderName(index: index) else {return nil}
        return folderName
    }
    
    func getFolderSize(/*folderName: String*/) -> Int? {
        guard let folderSize = manager.getFolderSize() else {return nil}
        return folderSize
    }
    
    func getSurveyURL(surveyName: String) -> URL? {
        guard let surveyURL = manager.getPathForSurvey(surveyName: surveyName) else {return nil}
        return surveyURL
    }
    
    func deleteAllData() {
        manager.deleteMainFolder()
    }
    
    //Should be obselete; changing to have file extension in fileName
    func getDataFilePath(fileName: String) -> URL? {
        guard let dataURL = manager.getPathForData(fileName: fileName) else {return nil}
        return dataURL
    }
    
    func getFilePath(fileName: String) -> URL? {
        guard let dataURL = manager.getPathForFile(fileName: fileName) else {return nil}
        return dataURL
    }
    
    func getAllFilePaths() -> [URL]? {
        guard let URLs = manager.getMainDirectoryFilePaths() else {return nil}
        // if files exist, then trim the current log file from list so it does not get deleted
        var trimURLs = manager.removeCurrentLogFile(fileList: URLs)
        trimURLs = manager.removeCurrentRecordingFile(fileList: trimURLs)
        return trimURLs
    }
    
    func removeUploadedItem(fileURLToDelete: URL) {
        do {
            try manager.deleteFile(at: fileURLToDelete)
        } catch {
            print("Error deleting file: \(error)")
        }
    }

    func countJustFiles() -> Int {
        let folderCount = manager.countJustFiles()
        if (manager.isRecordingActive) {
            return (folderCount - 2) // subtract current recording and log files
        }
        else {
            print("folder Count \(folderCount)")
            return (folderCount - 1) // subtract current log file
        }
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
    
    
}
