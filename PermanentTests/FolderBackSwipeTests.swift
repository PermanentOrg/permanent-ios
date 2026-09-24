//
//  FolderBackSwipeTests.swift
//  PermanentTests
//

import XCTest
@testable import Permanent

final class FolderBackSwipeTests: XCTestCase {
    func testLettingGoPastAThird_GoesBack() {
        XCTAssertTrue(FolderBackSwipe.goesBack(travel: 140, speed: 0, width: 400))
        XCTAssertFalse(FolderBackSwipe.goesBack(travel: 120, speed: 0, width: 400))
    }

    func testAFlick_GoesBackFromAShortDrag() {
        XCTAssertTrue(FolderBackSwipe.goesBack(travel: 30, speed: 800, width: 400))
    }

    func testAFlickTheOtherWay_SpringsBackEvenFarAcross() {
        XCTAssertFalse(FolderBackSwipe.goesBack(travel: 300, speed: -800, width: 400))
    }
}
