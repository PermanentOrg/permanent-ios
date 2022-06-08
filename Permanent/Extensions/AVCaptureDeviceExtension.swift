//
//  AVCaptureDeviceExtension.swift
//  Permanent
//
//  Created by Lucian Cerbu on 08.06.2022.
//
import AVFoundation

extension AVCaptureDevice {
    enum AuthorizationStatus {
        case justDenied
        case alreadyDenied
        case restricted
        case justAuthorized
        case alreadyAuthorized
        case unknown
    }

    class func authorizeVideo(completion: ((AuthorizationStatus) -> Void)?) {
        AVCaptureDevice.authorize(mediaType: AVMediaType.video, completion: completion)
    }

    class func authorizeAudio(completion: ((AuthorizationStatus) -> Void)?) {
        AVCaptureDevice.authorize(mediaType: AVMediaType.audio, completion: completion)
    }

    private class func authorize(mediaType: AVMediaType, completion: ((AuthorizationStatus) -> Void)?) {
        let result = AVCaptureDevice.authorizationStatus(for: mediaType)
        switch result {
        case .authorized:
            completion?(.alreadyAuthorized)
            
        case .denied:
            completion?(.alreadyDenied)
            
        case .restricted:
            completion?(.restricted)
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: mediaType, completionHandler: { (granted) in
                DispatchQueue.main.async {
                    if granted {
                        completion?(.justAuthorized)
                    } else {
                        completion?(.justDenied)
                    }
                }
            })
        @unknown default:
            completion?(.unknown)
        }
    }
}
