//
//  UIViewControllerExtension.swift
//  Permanent
//
//  Created by Adrian Creteanu on 05/10/2020.
//

import UIKit
import SwiftUI

private var spinnerViewKey: UInt8 = 0

extension UIViewController {
    /// One overlay per screen. A single shared slot let one screen's hide remove another screen's
    /// overlay, or turn its show into a no-op, leaving a spinner nothing could dismiss.
    private var spinnerView: UIView? {
        get { objc_getAssociatedObject(self, &spinnerViewKey) as? UIView }
        set { objc_setAssociatedObject(self, &spinnerViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    func showSpinner(colored color: UIColor = .primary) {
        if spinnerView != nil {
            return
        }

        let overlay = UIView(frame: self.view.bounds)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.32)

        let hostingController = UIHostingController(rootView: SpinnerOverlayContent())
        hostingController.view.backgroundColor = UIColor.clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            hostingController.view.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            hostingController.view.widthAnchor.constraint(equalToConstant: 150),
            hostingController.view.heightAnchor.constraint(equalToConstant: 100)
        ])

        overlay.alpha = 0
        self.view.addSubview(overlay)
        UIView.animate(withDuration: 0.3) {
            overlay.alpha = 1
        }

        spinnerView = overlay
    }

    func hideSpinner() {
        guard let overlay = spinnerView else { return }
        spinnerView = nil

        for subview in overlay.subviews {
            subview.removeFromSuperview()
        }

        UIView.animate(withDuration: 0.3, animations: {
            overlay.alpha = 0
        }, completion: { _ in
            overlay.removeFromSuperview()
        })
    }
    
    public func showToast(message: String, seconds: Double = 3.0) {
        let toast = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        toast.view.alpha = 0.5
        present(toast, animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            toast.dismiss(animated: true)
        }
    }
}

extension UIViewController {
    static func create(withIdentifier id: ViewControllerId, from storyboard: StoryboardName) -> UIViewController {
        let storyboard = UIStoryboard(name: storyboard.name, bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: id.value)
    }
}

extension UIViewController {
    func addDismissKeyboardGesture() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboardTouchOutside))
               tap.cancelsTouchesInView = false
               view.addGestureRecognizer(tap)
            }
            
    @objc private func dismissKeyboardTouchOutside() {
        view.endEditing(true)
    }
}

private struct SpinnerOverlayContent: View {
    @State private var rotate = false

    var body: some View {
        ZStack {
            SpinnerSemiCircle()
                .stroke(Gradient.purpleYellowGradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 25, height: 25)
                .rotationEffect(.degrees(rotate ? 360 : 0))
                .animation(Animation.linear(duration: 4).repeatForever(autoreverses: false), value: rotate)
            SpinnerSemiCircle()
                .stroke(Gradient.yellowPurpleGradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(rotate ? 360 : 0))
                .animation(Animation.linear(duration: 2).repeatForever(autoreverses: false), value: rotate)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        }
        .frame(width: 50, height: 50)
        .onAppear { rotate = true }
    }
}

private struct SpinnerSemiCircle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
        return path
    }
}
