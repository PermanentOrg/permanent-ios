//
//  ImagePreviewViewController.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 02.03.2021.
//

import UIKit

protocol ImagePreviewViewControllerDelegate: class {
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
        view.addSubview(scrollView)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.backgroundColor = .black
        scrollView.contentInsetAdjustmentBehavior = .never

        imageView.sizeToFit()
        scrollView.addSubview(imageView)
        scrollView.contentSize = imageView.bounds.size
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        setZoomScale()
    }
    
    func setZoomScale() {
        if initialZoomScale == nil {
            let widthScale = scrollView.frame.size.width / imageView.bounds.width
            let heightScale = scrollView.frame.size.height / imageView.bounds.height
            let minScale = min(widthScale, heightScale)
            scrollView.minimumZoomScale = minScale
            scrollView.zoomScale = minScale
            
            initialZoomScale = minScale
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
        
        imageView.center = CGPoint(x: scrollView.contentSize.width * 0.5 + horizontalOffest,  y: scrollView.contentSize.height * 0.5 + verticalOffset)
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        delegate?.imagePreviewViewControllerDidZoom(self, scale: scale / (initialZoomScale ?? scale))
    }
}
