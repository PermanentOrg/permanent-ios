//
//  ImagePreviewViewController.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 02.03.2021.
//

import UIKit

protocol ImagePreviewViewControllerDelegate: AnyObject {
    func imagePreviewViewControllerDidZoom(_ vc: ImagePreviewViewController, scale: CGFloat)
}

class ImagePreviewViewController: UIViewController {
    var scrollView: UIScrollView!
    var imageView = UIImageView(frame: CGRect.zero)
    var initialZoomScale: CGFloat?

    weak var delegate: ImagePreviewViewControllerDelegate?
    
    var image: UIImage? {
        didSet {
            initialZoomScale = nil
            imageView.image = image
            imageView.sizeToFit()
            
            if isViewLoaded {
                setZoomScale()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.delegate = self
        scrollView.delaysContentTouches = false
        
        view.addSubview(scrollView)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.backgroundColor = .black
        scrollView.contentInsetAdjustmentBehavior = .never

        imageView.sizeToFit()
        scrollView.addSubview(imageView)
        scrollView.contentSize = imageView.bounds.size
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        resetZoomScale()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        setZoomScale()
    }
    
    func newImageLoaded() {
        initialZoomScale = nil
        imageView.sizeToFit()
        
        if isViewLoaded {
            setZoomScale()
        }
    }
    
    func setZoomScale() {
        // Skip until both the image and the scroll view have a real size. Computing the scale
        // from a zero/partial layout would divide by zero (or fit to a stale frame) and the bogus
        // initialZoomScale would stick — viewDidLayoutSubviews only recomputes while it is nil.
        guard initialZoomScale == nil,
              imageView.bounds.width > 0, imageView.bounds.height > 0,
              scrollView.frame.width > 0, scrollView.frame.height > 0 else { return }

        let widthScale = scrollView.frame.size.width / imageView.bounds.width
        let heightScale = scrollView.frame.size.height / imageView.bounds.height
        let minScale = min(widthScale, heightScale)
        scrollView.minimumZoomScale = minScale
        // Fit-to-screen is the resting scale. For originals SMALLER than the screen minScale is
        // > 1, so raise the maximum to match — otherwise the default maximumZoomScale of 1.0
        // clamps the image to its native size, so it renders narrower than the full-width blur
        // placeholder and appears to shrink when the blur fades out. Large images (minScale < 1)
        // keep the maximum at 1.0, so fit-to-screen resting + pinch-zoom up to 100% is unchanged.
        scrollView.maximumZoomScale = max(1.0, minScale)
        scrollView.zoomScale = minScale

        initialZoomScale = minScale
    }
    
    func resetZoomScale() {
        // The layout mechanism needs an extra cycle to set the scrollView frames correctly.
        DispatchQueue.main.async {
            self.initialZoomScale = nil
            self.setZoomScale()
            self.scrollViewDidZoom(self.scrollView)
            self.view.layoutIfNeeded()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate { (ctx) in
            self.resetZoomScale()
        } completion: { (ctx) in
        }
    }
}

extension ImagePreviewViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let horizontalOffest = (scrollView.bounds.width > scrollView.contentSize.width) ? ((scrollView.bounds.width - scrollView.contentSize.width) * 0.5): 0.0
        let verticalOffset = (scrollView.bounds.height > scrollView.contentSize.height) ? ((scrollView.bounds.height - scrollView.contentSize.height) * 0.5): 0.0
        
        imageView.center = CGPoint(x: scrollView.contentSize.width * 0.5 + horizontalOffest, y: scrollView.contentSize.height * 0.5 + verticalOffset)
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        delegate?.imagePreviewViewControllerDidZoom(self, scale: scale / (initialZoomScale ?? scale))
    }
}
