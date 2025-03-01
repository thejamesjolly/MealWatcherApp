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
 File: FileManagerPhoto.swift
 Project: MealWatcher Phone App

 Created by James Jolly on 3/9/24.

    Purpose:
 Manages photos in a permenant repository that will not be deleted upon dropbox upload for review purposes

 Currently separated from the standard data storage, which is found in FileManager.swift.
 Future Work could stitch these files and classes together, similar to Watch FileManager with Main folder and Repo folder.
*/


import Foundation
import SwiftUI

class LocalFileManagerPhoto {
    
    static let instance = LocalFileManagerPhoto()
    let mainPhotoFolderName = "MealWatcher_Photos"
    let fmDateFormatter = DateFormatter()
    
    init() {
        createMainFolderIfNeeded()
        fmDateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
    }
    
    func createMainFolderIfNeeded() {
        guard let path = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(mainPhotoFolderName)
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

    /// Delete all local data
    func deleteMainFolder () {
        guard let path = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(mainPhotoFolderName) else {
            return
        }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: nil, options: [])
            // Iterate through the contents and delete each item
            for itemURL in contents {
                try FileManager.default.removeItem(at: itemURL)
            }
            print("Success deleting contents")
        } catch let error {
            print("Error deleting contents. \(error)")
        }
    }
    
    // Possibly Unused
    func addNewFolder(folderName: String) {
        guard let path = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(mainPhotoFolderName)
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
    
    /// Used to save image from camera
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
    
    /// Grabs Image from filename that includes an extension
    func getImageFromFilename(imageName: String) -> UIImage? {
        
        guard let path = getPathForFile(fileName: imageName)?.path,
              FileManager.default.fileExists(atPath: path) else {
            print("Error getting path")
            return nil
        }
        
        return UIImage(contentsOfFile: path)
    }
    
    /// Gets full file from folder given the string filename (no '.jpg')
    /// FIXME folder name never used
    func getImageNoExtension(imageName: String, folderName: String) -> UIImage? {
        
        guard let path = getPathForImage(imageName: imageName)?.path,
              FileManager.default.fileExists(atPath: path) else {
            print("Error getting path")
            return nil
        }
        
        return UIImage(contentsOfFile: path)
    }
    
    ///Simply appends ".jpg" to file names and gets full folder path
    func getPathForImage(imageName: String) -> URL? { //folderName: String) -> URL? {
        
        guard let path = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(mainPhotoFolderName)
            //.appendingPathComponent(folderName)
            .appendingPathComponent("\(imageName).jpg") else {
            print("Error getting path")
            return nil
        }
        //print(path)
        return path
    }
    
    /// Deletes a file given string name without '.jpg' attached
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
    
    /// Return Current Count of Items in Folder
    func countPhotoFiles() -> Int {
        guard let path = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(mainPhotoFolderName) else {
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
    
    func countJustFiles() -> Int {
        guard let path = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(mainPhotoFolderName) else {
            return 0
        }
        do {
            let folderContents = try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: [.isDirectoryKey])
            
            // Count directories since there should be less of them then files
            var runningDirCount:Int = 0
            
            for currURL in folderContents {
                if currURL.hasDirectoryPath {
                    runningDirCount += 1 // increment count with each file
                }
            }
            
            
            print("Running Dir Count = \(runningDirCount)")
            return (folderContents.count - runningDirCount)
        }
        catch {
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
            .appendingPathComponent(mainPhotoFolderName) else {
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
    
    
    /// Simply returns the main folder path
    /// - Returns: URL?  of main folder path
    func getFolderPath(/*folderName: String*/) -> URL? {
        guard let path = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(mainPhotoFolderName) else {
            //.appendingPathComponent(folderName) else {
            print("Error getting path")
            return nil
        }
        return path
    }
    
    /// Possibly Unused
    /// Without folderName, simply gives the same value as countPhotoFiles
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
    
    
    func getPathForFileFromURL(/*folderName: String,*/fileURL: URL) -> URL? {
        guard let path = getFolderPath() else {return nil}
        let destinationURL = path.appendingPathComponent(fileURL.lastPathComponent)
        return destinationURL
    }
    
    /// Possibly Unused (goes through a function trace)
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
    
    /// Get path for generic file (STRING NEEDS TO INCLUDE EXTENSION)
    func getPathForFile(fileName: String) -> URL? {
        //Generic "getPathFor" function that assumes extension is in filename already
        guard let path = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(mainPhotoFolderName)
            .appendingPathComponent(fileName) else {
            print("Error getting path")
            return nil
        }
        //print(path.path)
        return path
    }
    
    /// Assumes a flat file system and returns all contents (folders, files, etc.)
    func getMainDirectoryFileNames() -> [String]? {
        guard let path = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(mainPhotoFolderName) else {
            print("Error getting path")
            return nil
        }
        
        do {
            // Get the contents of the directory
            let fileURLs = try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: nil)
            
            // If using a shallow (no subdirectory) system, use this
            var filenamesList: [String] = []
            for currURL in fileURLs {
                filenamesList.append(currURL.lastPathComponent)
            }
            return filenamesList
            
//            //Used for just getting the files if there is a folder within the directory
//            // print("All Files are: \(fileURLs)")
//
//            //Strip to just files (no directories)
//            let justFiles = fileURLs.filter{!($0.hasDirectoryPath)}
//            return justFiles
        } catch {
            // Handle the error, e.g., print an error message
            print("Error: \(error)")
            return nil
        }
    }
    
    /// Assumes a flat file system and returns all contents (folders, files, etc.)
    func getMainDirectoryFilePaths() -> [URL]? {
        guard let path = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(mainPhotoFolderName) else {
            print("Error getting path")
            return nil
        }
        
        do {
            // Get the contents of the directory
            let fileURLs = try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: nil)
            
            // If using a shallow (no subdirectory) system, use this
            return fileURLs
            
//            //Used for just getting the files if there is a folder within the directory
//            // print("All Files are: \(fileURLs)")
//
//            //Strip to just files (no directories)
//            let justFiles = fileURLs.filter{!($0.hasDirectoryPath)}
//            return justFiles
        } catch {
            // Handle the error, e.g., print an error message
            print("Error: \(error)")
            return nil
        }
    }
    
    /// Converts a list of URL paths into the list of file names by grabbing the last file component of each
    func FilePaths2FileNames(fileURLs: [URL]?) -> [String]? {
        // If using a shallow (no subdirectory) system, use this
        guard let guardFileURLs = fileURLs else {return nil}
        var filenamesList: [String] = []
        for currURL in guardFileURLs {
            filenamesList.append(currURL.lastPathComponent)
        }
        return filenamesList
    }
    
    /// Converts a list of file names to a list of file path URLs by grabbing adding Folder info to list of names given
    /// SHOULD ONLY BE USED WITH VALID PATHS: DOES NOT CHECK IF FILES EXIST
    func FileNames2FilePaths(fileNames: [String]?) -> [URL]? {
        // If using a shallow (no subdirectory) system, use this
        guard let guardFileNames = fileNames else {return nil}
        var fileURLList: [URL] = []
        for currName in guardFileNames {
            // Ensure no issues grabbing URL, then append to list
            guard let currURL = getPathForFile(fileName: currName) else {return nil}
            fileURLList.append(currURL)
        }
        return fileURLList
    }
    
    func deleteFile(at url: URL) throws {
        do {
            try FileManager.default.removeItem(at: url)
            print("File deleted successfully.")
            return
        } catch {
            print("Error Deleting file: \(error)")
            throw error
        }
    }

    
    
    
}


class FileManagerPhotoViewModel: ObservableObject {
    
    @Published var image: UIImage? = nil
    @Published var infoMessage: String = ""
    @Published var folderCount: Int = 0
    let imageName: String = "NoPhotoAvailable"
    let manager = LocalFileManagerPhoto.instance
    //@Published var currentTimeStamp: String = ""
    let vmDateFormatter = DateFormatter() // format Saved as "Weekday, Month Day, Year, 12HrTime"
    let vmDateFormatter_CalDate = DateFormatter() // format saved for "Day Month, Year"
    let vmDateFormatter_DayTime = DateFormatter() // format saved for "Weekday, 12HrTime"
    
    init () {
        getImageFromAssetsFolder()
        //image = getImageFromFileManager(pictureName: "TestPicture")
        //getImageFromFileManager(pictureName: "TestPicture")
        vmDateFormatter.dateFormat = "EEEE, MMM d, yyyy h:mm a"
        vmDateFormatter_CalDate.dateFormat = "d MMM, yyyy"
        vmDateFormatter_DayTime.dateFormat = "E, h:mm a"
    }
    
    // Possibly Unused
    func createNewFolder(folderName: String) {
        manager.addNewFolder(folderName: folderName)
    }
    
    func getImageFromAssetsFolder() {
        image = UIImage(named: imageName)
        //image = UIImage(systemName: "fork.knife.circle.fill")
    }
    
    
    func getImageFromFileManager(filename: String) -> UIImage? {
        guard let image = manager.getImageFromFilename(imageName: filename) else {return nil}
        print("PM: Grabbed Image from file.")
        return image
    }
    
    /// Used in Camera View Controller
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
    
    // Possbily Unused
    func deleteImage() {
        infoMessage = manager.deleteImage(name: imageName)
    }
    
    func listSize() -> Int {
        self.folderCount = manager.countPhotoFiles()
        return folderCount
    }
    
    func getFilenamesSortedByDate() -> [String]? {
        guard let dateSortedList = manager.sortMainFolderByDate() else {return nil}
        
        return dateSortedList
    }
    
    /// Deletes all  Photos stored in Photo File Manager
    func deleteAllData() {
        manager.deleteMainFolder()
    }
    
    
    func getFilePath(fileName: String) -> URL? {
        guard let dataURL = manager.getPathForFile(fileName: fileName) else {return nil}
        return dataURL
    }
    
    func getAllFilePaths() -> [URL]? {
        guard let URLs = manager.getMainDirectoryFilePaths() else {return nil}
        return URLs
    }
    
    func getAllFileNames() -> [String]? {
        guard let fileNames = manager.getMainDirectoryFileNames() else {return nil}
        return fileNames
    }
    
    func Paths2Names(fileURLs: [URL]?) -> [String]? {
        guard let fileNames = manager.FilePaths2FileNames(fileURLs: fileURLs) else {return nil}
        return fileNames
    }
    
    func Names2Paths(fileNames: [String]?) -> [URL]? {
        guard let filePaths = manager.FileNames2FilePaths(fileNames: fileNames) else {return nil}
        return filePaths
    }
    
    // Possibly Unused
    /// Returns date for a file given the filename
    func getDateFromFilename(fileName: String) -> Date? {
        return manager.GetDateFromFilename(fileName: fileName)
    }
    
    /// Returns formatted string to display date in user friendly Manner
    func getFormattedDateFromFilename(fileName: String) -> String {
        guard let currDate = manager.GetDateFromFilename(fileName: fileName) else {
            print("FMP: WARNING: Unable to determine date from filename")
            return "Unknown Date"
        }
        
        return vmDateFormatter.string(from: currDate)
    }
    
    /// Returns formatted string to display date in user friendly Manner
    func getFormattedDateFromFilename_CalDate(fileName: String) -> String {
        guard let currDate = manager.GetDateFromFilename(fileName: fileName) else {
            print("FMP: WARNING: Unable to determine date from filename")
            return "Unknown Date"
        }
        
        return vmDateFormatter_CalDate.string(from: currDate)
    }
    
    /// Returns formatted string to display date in user friendly Manner
    func getFormattedDateFromFilename_DayTime(fileName: String) -> String {
        guard let currDate = manager.GetDateFromFilename(fileName: fileName) else {
            print("FMP: WARNING: Unable to determine date from filename")
            return "Unknown Date"
        }
        
        return vmDateFormatter_DayTime.string(from: currDate)
    }
    
    func removeItem(fileURLToDelete: URL) {
        do {
            try manager.deleteFile(at: fileURLToDelete)
        } catch {
            print("Error deleting file: \(error)")
        }
    }
    
    func countJustFiles() -> Int {
        manager.countJustFiles()
    }

    
}
