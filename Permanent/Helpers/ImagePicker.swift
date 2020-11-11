//
//  ImagePicker.swift
//  Permanent
//
//  Created by Adrian Creteanu on 10/11/2020.
//

import UIKit

public protocol ImagePickerDelegate: class {
    func didSelect(image: UIImage?)
    
    
}

open class MediaRecorder: NSObject {
    private let pickerController: UIImagePickerController
    private weak var presentationController: UIViewController?
    private weak var delegate: ImagePickerDelegate?

    public init(presentationController: UIViewController, delegate: ImagePickerDelegate) {
        self.pickerController = UIImagePickerController()

        super.init()

        self.presentationController = presentationController
        self.delegate = delegate

        self.pickerController.delegate = self
        self.pickerController.allowsEditing = true // ??
        self.pickerController.mediaTypes = ["public.image", "public.movie"]

        self.pickerController.sourceType = .camera
    }

    private func pickerController(_ controller: UIImagePickerController, didSelect image: UIImage?) {
        controller.dismiss(animated: true, completion: nil)

        self.delegate?.didSelect(image: image)
    }

    func present() {
        self.presentationController?.present(self.pickerController, animated: true, completion: nil)
    }
}

extension MediaRecorder: UIImagePickerControllerDelegate {
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.pickerController(picker, didSelect: nil)
    }

    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any])
    {
        guard let image = info[.editedImage] as? UIImage else {
            return self.pickerController(picker, didSelect: nil)
        }
        
        
        
        
        self.pickerController(picker, didSelect: image)
    }
}

extension MediaRecorder: UINavigationControllerDelegate {}
