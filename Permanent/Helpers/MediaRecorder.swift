//
//  ImagePicker.swift
//  Permanent
//
//  Created by Adrian Creteanu on 10/11/2020.
//

import UIKit
import AVFoundation

public protocol MediaRecorderDelegate: AnyObject {
    func didSelect(url: URL?, isLocal: Bool)
}

/// Helper class used to take images and record videos.

open class MediaRecorder: NSObject {
    private let pickerController: UIImagePickerController
    private weak var presentationController: UIViewController?
    private weak var delegate: MediaRecorderDelegate?

    private lazy var fileHelper = { FileHelper() }()

    public init(presentationController: UIViewController, delegate: MediaRecorderDelegate) {
        self.pickerController = UIImagePickerController()

        super.init()

        self.presentationController = presentationController
        self.delegate = delegate

        self.pickerController.delegate = self
        self.pickerController.allowsEditing = false
        self.pickerController.mediaTypes = ["public.image", "public.movie"]
        self.pickerController.sourceType = .camera
    }

    private func pickerController(_ controller: UIImagePickerController, didSelect url: URL?, isLocal: Bool) {
        controller.dismiss(animated: true, completion: nil)

        self.delegate?.didSelect(url: url, isLocal: isLocal)
    }

    func present() {
        AVCaptureDevice.authorizeVideo { status in
            switch status {
            case .justDenied, .alreadyDenied:
                let alertController = UIAlertController(title: "Camera permission required".localized(), message: "Please go to Settings and turn on the permissions.".localized(), preferredStyle: .alert)
                
                let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                        return
                    }
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in })
                    }
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
                
                alertController.addAction(cancelAction)
                alertController.addAction(settingsAction)
                
                DispatchQueue.main.async {
                    self.presentationController?.present(alertController, animated: true, completion: nil)
                }
                
            case .restricted:
                let alertController = UIAlertController(title: "Unable to Access Camera".localized(), message: "Please remove any restrictions on the camera to use this feature.".localized(), preferredStyle: .alert)
                let okayAction = UIAlertAction(title: "Okay".localized(), style: .default, handler: nil)
                alertController.addAction(okayAction)
                
                DispatchQueue.main.async {
                    self.presentationController?.present(alertController, animated: true, completion: nil)
                }
                
            case .justAuthorized, .alreadyAuthorized:
                self.presentationController?.present(self.pickerController, animated: true)
                
            default:
                break
            }
        }
    }
    
    func clearTemporaryFile(withURL url: URL?) {
        guard let url = url else { return }
        
        fileHelper.deleteFile(at: url)
    }
}

extension MediaRecorder: UIImagePickerControllerDelegate {
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage, let imageData = image.jpegData(compressionQuality: 1.0) {
            let imageName = "IMG_\(DateUtils.fileTimestamp)"
            let url = self.fileHelper.saveFile(imageData, named: imageName, withExtension: "jpeg")
            return self.pickerController(picker, didSelect: url, isLocal: true)
        } else {
            let url = info[.mediaURL] as? URL
            self.pickerController(picker, didSelect: url, isLocal: false)
        }
    }
}

extension MediaRecorder: UINavigationControllerDelegate {}
