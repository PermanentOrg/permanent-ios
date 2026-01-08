//
//  CameraPickerView.swift
//  Permanent
//
//  Created on 19.12.2025.
//

import SwiftUI
import UIKit
import AVFoundation
import UniformTypeIdentifiers

/// A SwiftUI view that wraps UIImagePickerController for camera capture.
/// Supports capturing both images and videos.
@available(iOS 17.0, *)
struct CameraPickerView: UIViewControllerRepresentable {
    
    // MARK: - Properties
    
    /// The media types to capture (images, videos, or both)
    let mediaTypes: [String]
    
    /// Video quality preset (only applies to video capture)
    let videoQuality: UIImagePickerController.QualityType
    
    /// Maximum video duration in seconds (0 for unlimited)
    let videoMaximumDuration: TimeInterval
    
    /// Callback when an image is captured
    let onImageCaptured: ((UIImage) -> Void)?
    
    /// Callback when a video is captured
    let onVideoCaptured: ((URL) -> Void)?
    
    /// Callback when the picker is cancelled
    let onCancel: () -> Void
    
    /// Callback for errors
    let onError: ((CameraError) -> Void)?
    
    // MARK: - Initialization
    
    /// Creates a new CameraPickerView
    /// - Parameters:
    ///   - mediaTypes: The media types to capture (default: images and videos)
    ///   - videoQuality: Video quality preset (default: medium)
    ///   - videoMaximumDuration: Maximum video duration in seconds (default: 60)
    ///   - onImageCaptured: Callback when an image is captured
    ///   - onVideoCaptured: Callback when a video is captured
    ///   - onCancel: Callback when picker is cancelled
    ///   - onError: Callback for errors
    init(
        mediaTypes: [String] = [UTType.image.identifier, UTType.movie.identifier],
        videoQuality: UIImagePickerController.QualityType = .typeMedium,
        videoMaximumDuration: TimeInterval = 60,
        onImageCaptured: ((UIImage) -> Void)? = nil,
        onVideoCaptured: ((URL) -> Void)? = nil,
        onCancel: @escaping () -> Void = {},
        onError: ((CameraError) -> Void)? = nil
    ) {
        self.mediaTypes = mediaTypes
        self.videoQuality = videoQuality
        self.videoMaximumDuration = videoMaximumDuration
        self.onImageCaptured = onImageCaptured
        self.onVideoCaptured = onVideoCaptured
        self.onCancel = onCancel
        self.onError = onError
    }
    
    // MARK: - Camera Availability Check
    
    /// Checks if the camera is available on the device
    static var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    /// Checks if the device has a front camera
    static var hasFrontCamera: Bool {
        UIImagePickerController.isCameraDeviceAvailable(.front)
    }
    
    /// Checks if the device has a rear camera
    static var hasRearCamera: Bool {
        UIImagePickerController.isCameraDeviceAvailable(.rear)
    }
    
    // MARK: - UIViewControllerRepresentable
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        
        guard Self.isCameraAvailable else {
            // Return an empty picker - the coordinator will handle the error
            DispatchQueue.main.async {
                self.onError?(.cameraNotAvailable)
                self.onCancel()
            }
            return picker
        }
        
        picker.sourceType = .camera
        picker.mediaTypes = mediaTypes
        picker.videoQuality = videoQuality
        picker.videoMaximumDuration = videoMaximumDuration
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        
        // Set camera device (prefer rear camera)
        if Self.hasRearCamera {
            picker.cameraDevice = .rear
        } else if Self.hasFrontCamera {
            picker.cameraDevice = .front
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        
        let parent: CameraPickerView
        
        init(_ parent: CameraPickerView) {
            self.parent = parent
        }
        
        // MARK: - UIImagePickerControllerDelegate
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            // Check the media type
            guard let mediaType = info[.mediaType] as? String else {
                parent.onError?(.unknownMediaType)
                picker.dismiss(animated: true)
                return
            }
            
            if mediaType == UTType.image.identifier {
                // Handle image capture
                if let image = info[.originalImage] as? UIImage {
                    parent.onImageCaptured?(image)
                } else {
                    parent.onError?(.imageCaptureFailed)
                }
            } else if mediaType == UTType.movie.identifier {
                // Handle video capture
                if let videoURL = info[.mediaURL] as? URL {
                    parent.onVideoCaptured?(videoURL)
                } else {
                    parent.onError?(.videoCaptureFailed)
                }
            } else {
                parent.onError?(.unknownMediaType)
            }
            
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Camera Error

@available(iOS 17.0, *)
enum CameraError: Error, LocalizedError {
    case cameraNotAvailable
    case imageCaptureFailed
    case videoCaptureFailed
    case unknownMediaType
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .cameraNotAvailable:
            return "Camera is not available on this device"
        case .imageCaptureFailed:
            return "Failed to capture image"
        case .videoCaptureFailed:
            return "Failed to capture video"
        case .unknownMediaType:
            return "Unknown media type captured"
        case .permissionDenied:
            return "Camera permission was denied"
        }
    }
}

// MARK: - Convenience Initializers

@available(iOS 17.0, *)
extension CameraPickerView {
    
    /// Creates a camera picker for photos only
    static func photoOnly(
        onImageCaptured: @escaping (UIImage) -> Void,
        onCancel: @escaping () -> Void = {},
        onError: ((CameraError) -> Void)? = nil
    ) -> CameraPickerView {
        CameraPickerView(
            mediaTypes: [UTType.image.identifier],
            onImageCaptured: onImageCaptured,
            onCancel: onCancel,
            onError: onError
        )
    }
    
    /// Creates a camera picker for videos only
    static func videoOnly(
        videoQuality: UIImagePickerController.QualityType = .typeMedium,
        videoMaximumDuration: TimeInterval = 60,
        onVideoCaptured: @escaping (URL) -> Void,
        onCancel: @escaping () -> Void = {},
        onError: ((CameraError) -> Void)? = nil
    ) -> CameraPickerView {
        CameraPickerView(
            mediaTypes: [UTType.movie.identifier],
            videoQuality: videoQuality,
            videoMaximumDuration: videoMaximumDuration,
            onVideoCaptured: onVideoCaptured,
            onCancel: onCancel,
            onError: onError
        )
    }
}

// MARK: - Camera Picker Modifier

@available(iOS 17.0, *)
struct CameraPickerModifier: ViewModifier {
    
    @Binding var isPresented: Bool
    let mediaTypes: [String]
    let onImageCaptured: ((UIImage) -> Void)?
    let onVideoCaptured: ((URL) -> Void)?
    let onCancel: () -> Void
    let onError: ((CameraError) -> Void)?
    
    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented) {
                if CameraPickerView.isCameraAvailable {
                    CameraPickerView(
                        mediaTypes: mediaTypes,
                        onImageCaptured: { image in
                            isPresented = false
                            onImageCaptured?(image)
                        },
                        onVideoCaptured: { url in
                            isPresented = false
                            onVideoCaptured?(url)
                        },
                        onCancel: {
                            isPresented = false
                            onCancel()
                        },
                        onError: onError
                    )
                    .ignoresSafeArea()
                } else {
                    CameraUnavailableView {
                        isPresented = false
                        onError?(.cameraNotAvailable)
                    }
                }
            }
    }
}

// MARK: - Camera Unavailable View

@available(iOS 17.0, *)
struct CameraUnavailableView: View {
    
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("Camera Not Available")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("This device does not have a camera or camera access is not available.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("Dismiss") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

@available(iOS 17.0, *)
extension View {
    
    /// Presents a camera picker as a full screen cover
    /// - Parameters:
    ///   - isPresented: Binding to control presentation
    ///   - mediaTypes: The media types to capture
    ///   - onImageCaptured: Callback when an image is captured
    ///   - onVideoCaptured: Callback when a video is captured
    ///   - onCancel: Callback when picker is cancelled
    ///   - onError: Callback for errors
    func cameraPicker(
        isPresented: Binding<Bool>,
        mediaTypes: [String] = [UTType.image.identifier, UTType.movie.identifier],
        onImageCaptured: ((UIImage) -> Void)? = nil,
        onVideoCaptured: ((URL) -> Void)? = nil,
        onCancel: @escaping () -> Void = {},
        onError: ((CameraError) -> Void)? = nil
    ) -> some View {
        modifier(
            CameraPickerModifier(
                isPresented: isPresented,
                mediaTypes: mediaTypes,
                onImageCaptured: onImageCaptured,
                onVideoCaptured: onVideoCaptured,
                onCancel: onCancel,
                onError: onError
            )
        )
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview("Camera Picker") {
    struct PreviewWrapper: View {
        @State private var showCamera = false
        @State private var capturedImage: UIImage?
        @State private var errorMessage: String?
        
        var body: some View {
            VStack(spacing: 20) {
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .cornerRadius(12)
                }
                
                Button("Open Camera") {
                    showCamera = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(!CameraPickerView.isCameraAvailable)
                
                if !CameraPickerView.isCameraAvailable {
                    Text("Camera not available on this device")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding()
            .cameraPicker(
                isPresented: $showCamera,
                onImageCaptured: { image in
                    capturedImage = image
                },
                onError: { error in
                    errorMessage = error.localizedDescription
                }
            )
        }
    }
    
    return PreviewWrapper()
}

@available(iOS 17.0, *)
#Preview("Camera Unavailable") {
    CameraUnavailableView {
        print("Dismissed")
    }
}
