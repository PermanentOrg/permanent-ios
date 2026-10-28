//
//  FileInfoOpenTransitionTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 28.10.2026.
//

import Testing
import UIKit
@testable import Permanent

/// The photo's path into the Info screen's picture slot, and when the opening only fades.
@MainActor
struct FileInfoOpenTransitionTests {
    @Test("An aspect-fit image centres in its frame at the fitting scale")
    func fittedRect() {
        let frame = CGRect(x: 0, y: 100, width: 400, height: 400)

        #expect(FileInfoOpenTransition.fittedRect(for: CGSize(width: 2000, height: 1000), in: frame) == CGRect(x: 0, y: 200, width: 400, height: 200))
        #expect(FileInfoOpenTransition.fittedRect(for: CGSize(width: 1000, height: 2000), in: frame) == CGRect(x: 100, y: 100, width: 200, height: 400))
        #expect(FileInfoOpenTransition.fittedRect(for: .zero, in: frame) == frame)
    }

    @Test("The photo moves only when there is one and motion is not reduced")
    func movesPhoto() {
        let photo = UIImageView(image: UIImage(systemName: "photo"))

        #expect(FileInfoOpenTransition(from: photo, reducesMotion: false).movesPhoto)
        #expect(FileInfoOpenTransition(from: photo, reducesMotion: false).transitionDuration(using: nil) == FileInfoOpenTransition.moveDuration)
        #expect(!FileInfoOpenTransition(from: photo, reducesMotion: true).movesPhoto)
        #expect(!FileInfoOpenTransition(from: UIImageView(), reducesMotion: false).movesPhoto)
        #expect(!FileInfoOpenTransition(from: nil, reducesMotion: false).movesPhoto)
        #expect(FileInfoOpenTransition(from: nil, reducesMotion: false).transitionDuration(using: nil) == FileInfoOpenTransition.fadeDuration)
    }

    @Test("The way back moves the photo under the same rules and takes the same time")
    func closeMirrorsOpen() {
        let photo = UIImageView(image: UIImage(systemName: "photo"))

        #expect(FileInfoCloseTransition(to: photo, reducesMotion: false).movesPhoto)
        #expect(FileInfoCloseTransition(to: photo, reducesMotion: false).transitionDuration(using: nil) == FileInfoOpenTransition.moveDuration)
        #expect(!FileInfoCloseTransition(to: photo, reducesMotion: true).movesPhoto)
        #expect(!FileInfoCloseTransition(to: nil, reducesMotion: false).movesPhoto)
        #expect(FileInfoCloseTransition(to: nil, reducesMotion: false).transitionDuration(using: nil) == FileInfoOpenTransition.fadeDuration)
    }
}
