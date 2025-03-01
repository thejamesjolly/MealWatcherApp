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
  File: PhotoReviewView.swift
  Project: MealWatcher Phone App

  Created by James Jolly on 3/9/24.
 
    Purpose:
 Defines Phone Review View, which is used to access and peruse through all previous photos taken in the app.
*/

import SwiftUI

struct PhotoReviewView: View {

    @ObservedObject var fileManager = FileManagerViewModel()
    @ObservedObject var photoFM = FileManagerPhotoViewModel()

    // Logger
    var PhoneLogger = PhoneAppLogger.shared
    
    @State var photoFilePaths: [URL] = []
    @State var photoNamesList: [String] = []
    @State var totalPhotoCnt: Int = 0
    @State var currPhotoIdx: Int = -2 // changes onAppear to -1 or 0, so -2 triggers onUpdate
    
    @State var currDisplayImage: UIImage = UIImage(imageLiteralResourceName: "NoPhotosAvailable")
    @State var currDisplayText_CalDate: String = "No Date"
    @State var currDisplayText_DayTime: String = "No Time"
    
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center) {
                
                Text("Photo Review")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .onAppear {
                        PhoneLogger.info(Subsystem: "PhotoReview", Msg: "Loaded PhotoReviewView!")
                        
                        //Testing getting sorted list
                        photoNamesList = photoFM.getFilenamesSortedByDate() ?? []
                        photoFilePaths = photoFM.Names2Paths(fileNames: photoNamesList) ?? []
                        
                        //        photoFilePaths = photoFM.getAllFilePaths() ?? []
                        //        photoNamesList = photoFM.Paths2Names(fileURLs: photoFilePaths) ?? []
                        totalPhotoCnt = photoFilePaths.count
                        if (totalPhotoCnt == 0) {
                            print("CV: No photos in Images folder for view. Clearing photo index to nil.")
                            currPhotoIdx = -1
                            currDisplayImage = UIImage(imageLiteralResourceName: "NoPhotosAvailable")
                            currDisplayText_CalDate = "No Date"
                            currDisplayText_DayTime = "No Time"
                        }
                        else {
                            print("CV: There "+(totalPhotoCnt == 1 ? "is 1 photo" : "are \(totalPhotoCnt) photos")+". Setting photo index to \(totalPhotoCnt - 1).")
                            currPhotoIdx = totalPhotoCnt - 1
                            currDisplayImage = photoFM.getImageFromFileManager(filename: photoNamesList[currPhotoIdx]) ?? UIImage(imageLiteralResourceName: "NoPhotosAvailable")
                            currDisplayText_CalDate = photoFM.getFormattedDateFromFilename_CalDate(fileName: photoNamesList[currPhotoIdx])
                            currDisplayText_DayTime = photoFM.getFormattedDateFromFilename_DayTime(fileName: photoNamesList[currPhotoIdx])
                        }
                        
                        // Testing when and how often this onAppear happens
                        //                        currPhotoIdx = (currPhotoIdx+2) % totalPhotoCnt
                        //                        print("attempting to upset photo index")
                    }
                
                //Current Photo name
                if totalPhotoCnt == 0 {
                    Text("No Photos in Images Folder")
                        .font(.title2)
                        .padding()
                }
                else {
                    //                // Text("\(photoFilePaths[currPhotoIdx].lastPathComponent)")
                    //                Text(photoFM.getFormattedDateFromFilename(fileName: photoNamesList[currPhotoIdx]))
                    //                    .padding()
                    
                    HStack {
                        // Slightly enlarge the text since there isn't much to display on entire row
                        Text(currDisplayText_CalDate)
                            .font(.title2)
                        Spacer() // Space to opposite sides of the row
                        Text(currDisplayText_DayTime)
                            .font(.title2)
                    }
                    .padding()
                }
                
                
                if totalPhotoCnt == 0 {
                    Image("NoPhotosAvailable")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(10)
                        .padding()
                }
                else {
                    Image(uiImage: currDisplayImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(10)
                        .padding()
                }
                
                
                
                //            if let myImage = UIImage(named:"NoPhotosAvailable.jpg") {
                //                Image(uiImage: myImage)
                //                    .padding()
                //            }
                //            else {
                //                let myImage = Image(systemName: "fork.knife.circle.fill")
                //                Image(uiImage: myImage!)
                //            }
                //            
                
                
                HStack(alignment: .center) {
                    
                    
                    Button(action: {
                        if totalPhotoCnt == 0  {
                            print("No Photos, so counter not incremented.")
                        }
                        else {
                            // Add a single totlaPhotoCnt to the index before modulo to deal with negative
                            currPhotoIdx = (totalPhotoCnt + currPhotoIdx-1) % totalPhotoCnt
                            print("Looping through photos: Index updated to \(currPhotoIdx).")
                        }
                    }, label: {
                        Text("PREV")
                            .font(.title2)
                    })
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    
                    .padding()
                    
                    // Include a current photo and total photos display
                    Text("\(currPhotoIdx+1) / \(totalPhotoCnt)") // +1 for 1 indexing to user]
                        .multilineTextAlignment(.trailing)
                        .font(.title3)
                    
                    
                        .padding()
                    
                    Button(action: {
                        if totalPhotoCnt == 0  {
                            print("No Photos, so counter not incremented.")
                        }
                        else {
                            currPhotoIdx = (currPhotoIdx+1) % totalPhotoCnt
                            print("Looping through photos: Index updated to \(currPhotoIdx).")
                        }
                    }, label: {
                        Text("NEXT")
                            .font(.title2)
                    })
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .padding()
                    
                    
                }
                .padding()
                
                
                //            // Debug Button
                //            Button(action: {
                //                let myCount = photoFM.getFilenamesSortedByDate()
                //                print(myCount)
                //                print("PRV: Testing New FM Feature.")
                //                
                //            }, label: {
                //                Text("DEBUG FOLDER")
                //            })
                //            .buttonStyle(.borderedProminent)
                //            .controlSize(.regular)
                
            }
        }
        .onChange(of: currPhotoIdx) { newIndex in
            // Update all display values here upon new index so the photoFM functions are not continually invoked
            if (newIndex == -1) {
                print("Index value is -1, loading default image...")
                currDisplayImage = UIImage(imageLiteralResourceName: "NoPhotosAvailable")
                currDisplayText_CalDate = "No Date"
                currDisplayText_DayTime = "No Time"
            }
            else{
                print("New Index, loading next image at index \(currPhotoIdx)...")
                currDisplayImage = photoFM.getImageFromFileManager(filename: photoNamesList[currPhotoIdx]) ?? UIImage(imageLiteralResourceName: "NoPhotosAvailable")
                currDisplayText_CalDate = photoFM.getFormattedDateFromFilename_CalDate(fileName: photoNamesList[currPhotoIdx])
                currDisplayText_DayTime = photoFM.getFormattedDateFromFilename_DayTime(fileName: photoNamesList[currPhotoIdx])
            }
        }
    }
    
    func getStingName() -> String {
        print("Grabbing Asset Image...)")
        return "NoPhotosAvailable"
    }
    
        
    
}


//
//#Preview {
//    @State var FilePaths:[URL] = []
//    @State var totalPhotoCnt = 0
//    @State var currPhotoIdx = -1
//    PhotoReviewView(photoFilePaths: $FilePaths, totalPhotoCnt: $totalPhotoCnt, currPhotoIdx: $currPhotoIdx)
//    EmptyView()
//}
