//
//  ImagePicker.swift
//  Permanent
//
//  Created by Adrian Creteanu on 10/11/2020.
//

import UIKit

public protocol MediaRecorderDelegate: class {
    func didSelect(url: URL?)
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

    private func pickerController(_ controller: UIImagePickerController, didSelect url: URL?) {
        controller.dismiss(animated: true, completion: nil)

        self.delegate?.didSelect(url: url)
    }

    func present() {
        self.presentationController?.present(self.pickerController, animated: true)
    }
    
    func clearTemporaryFile(withURL url: URL?) {
        guard let url = url else { return }
        
        fileHelper.deleteFile(at: url)
    }
}

extension MediaRecorder: UIImagePickerControllerDelegate {
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.pickerController(picker, didSelect: nil)
    }

    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage, let imageData = image.jpegData(compressionQuality: 1.0) {
            let imageName = "IMG_\(DateUtils.fileTimestamp)"
            let url = self.fileHelper.saveFile(imageData, named: imageName, withExtension: "jpeg")
            return self.pickerController(picker, didSelect: url)
        } else {
            let url = info[.mediaURL] as? URL
            self.pickerController(picker, didSelect: url)
        }
    }
}

extension MediaRecorder: UINavigationControllerDelegate {}
