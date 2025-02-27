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
  File: Camera.swift
  Project: MealWatcher Phone App

  Created by Jimmy Nguyen on 6/8/23.
  Edited and Maintained by James Jolly since Dec 15, 2023
 
    Purpose:
 View which manages the camera overlay and photo taking parts of the app.
 
 Context provided manages the properties of the selected photos (knowing when a photo is confirmed or cancelled),
 as well as a UIImage extension allowing for resizing of images

Resizing Code taken from following page by James Jolly
https://medium.com/@grujic.nikola91/resize-uiimage-in-swift-3e51f09f7a02
*/

import UIKit
import SwiftUI
import AVFoundation

public extension UIImage {
    /// Resize image while keeping the aspect ratio. Original image is not modified.
    /// - Parameters:
    ///   - width: A new width in pixels.
    ///   - height: A new height in pixels.
    /// - Returns: Resized image.
    func resize(_ width: Int, _ height: Int) -> UIImage {
        // Keep aspect ratio
        let maxSize = CGSize(width: width, height: height)

        let availableRect = AVFoundation.AVMakeRect(
            aspectRatio: self.size,
            insideRect: .init(origin: .zero, size: maxSize)
        )
        let targetSize = availableRect.size

        // Set scale of renderer so that 1pt == 1px
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)

        // Resize the image
        let resized = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        return resized
    }
}



struct ImagePickerView: UIViewControllerRepresentable {

    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var isPresented
    @Binding var sourceType: UIImagePickerController.SourceType
    @Binding var PrePostFlag: Bool
    @Binding var participantID: String
    
    @Binding var confirmPhotoTakenFlag: Bool // Used to confirm that the photo was finished and not cancelled
        
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = self.sourceType
        imagePicker.delegate = context.coordinator // confirming the delegate
        return imagePicker
    }
   
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    }
    
    // Connecting the Coordinator class with this struct
    func makeCoordinator() -> Coordinator {
        return Coordinator(picker: self, participantID: self.participantID)
    }
    
    
}

class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var picker: ImagePickerView
    var participantID: String
    @ObservedObject var vm = FileManagerViewModel()
    @ObservedObject var photoFM = FileManagerPhotoViewModel()
    
    
    
    init(picker: ImagePickerView, participantID: String) {
        self.picker = picker
        self.participantID = participantID
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard var selectedImage = info[.originalImage] as? UIImage else { return }
        let orientationFlag = selectedImage.imageOrientation
        print("Orientation of Image is : \(orientationFlag)")
        // "UP" is landscape if you held the phone in your right hand
        if (orientationFlag == UIImage.Orientation.up || orientationFlag == UIImage.Orientation.down){
            print("Landscape Orientation Check")
            selectedImage = selectedImage.resize(1280, 720)
        }
        else if (orientationFlag == UIImage.Orientation.right || orientationFlag == UIImage.Orientation.left){
            print("Portrait Orientation Check")
            selectedImage = selectedImage.resize(720, 1280)
        }


         self.picker.selectedImage = selectedImage

        
        print(selectedImage.size) //Check the Size of the newly downsized image
        
        let date = Date()
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let filename = participantID+"-"+df.string(from: date)
        
        vm.saveImage(imageCapture: selectedImage, filename: filename, PrePostFlag: self.picker.PrePostFlag)
        vm.image = selectedImage
        photoFM.saveImage(imageCapture: selectedImage, filename: filename, PrePostFlag: self.picker.PrePostFlag)
        vm.image = selectedImage
        
        toggleConfirmFlag(in: &self.picker)
        
        //toggleFlag(in: &self.picker)
        self.picker.isPresented.wrappedValue.dismiss()
    }
    
    func toggleConfirmFlag(in ImagePickerView: inout ImagePickerView) {
        ImagePickerView.confirmPhotoTakenFlag = true
        print("Set Image Picker Confirmation Flag!")
    }
    
    
    func toggleFlag(in ImagePickerView: inout ImagePickerView) {
        ImagePickerView.PrePostFlag.toggle()
        print("Toggled Image Picker Flag!")
    }
    
}
