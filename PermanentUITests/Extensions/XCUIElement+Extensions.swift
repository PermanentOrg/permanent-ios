//
//  XCUIElement+Extensions.swift
//  PermanentUITests
//
//  Created by Vlad Alexandru Rusu on 09.09.2022.
//

import XCTest

extension XCUIElement {
    func pullToRefresh() {
        let startCoord = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25))
        let endCoord = startCoord.withOffset(CGVector(dx: 0.0, dy: 500));
        startCoord.press(forDuration: 0.5, thenDragTo: endCoord)
    }

    /// `true` once the element can take a tap and its frame is the same on two looks in a row.
    func waitUntilSettled(timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        var lastFrame = CGRect.null
        while Date() < deadline {
            if exists && isHittable {
                if frame == lastFrame { return true }
                lastFrame = frame
            }
            Thread.sleep(forTimeInterval: 0.25)
        }
        return false
    }
}

extension XCUIElement {
    func selectAndDeleteText(inApp app: XCUIApplication) {
        if buttons["Clear text"].exists {
            buttons["Clear text"].tap()
        }
    }
    
    func clearTextView() {
        guard let stringValue = value as? String else {
            XCTFail("Tried to clear and enter text into a non string value")
            return
        }
        
        let lowerRightCorner = coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.9))
        lowerRightCorner.tap()
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
    }
}
