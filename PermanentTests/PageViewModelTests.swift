//
//  PageViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class PageViewModelTests: XCTestCase {

    // MARK: - Mock Delegate

    private class MockPageDelegate: PageViewModelDelegate {
        var numberOfVCs: Int = 3
        var createdVCsCalled = false
        var setVCIndex: Int?

        func createViewControllers() {
            createdVCsCalled = true
        }

        func setViewController(of index: Int) {
            setVCIndex = index
        }

        func numberOfViewControllers() -> Int {
            return numberOfVCs
        }
    }

    // MARK: - Initialization

    func testInit_CurrentPageIsZero() {
        let vm = PageViewModel()
        XCTAssertEqual(vm.currentPage, 0)
    }

    func testInit_DelegateIsNil() {
        let vm = PageViewModel()
        XCTAssertNil(vm.delegate)
    }

    func testInit_OnCurrentPageChangeIsNil() {
        let vm = PageViewModel()
        XCTAssertNil(vm.onCurrentPageChange)
    }

    // MARK: - nextPageIndex

    func testNextPageIndex_ReturnsNextIndex() {
        let vm = PageViewModel()
        let delegate = MockPageDelegate()
        delegate.numberOfVCs = 5
        vm.delegate = delegate

        let next = vm.nextPageIndex(after: 0)
        XCTAssertEqual(next, 1)
    }

    func testNextPageIndex_AtLastPage_ReturnsNil() {
        let vm = PageViewModel()
        let delegate = MockPageDelegate()
        delegate.numberOfVCs = 3
        vm.delegate = delegate

        let next = vm.nextPageIndex(after: 2)
        XCTAssertNil(next)
    }

    func testNextPageIndex_BeyondLastPage_ReturnsNil() {
        let vm = PageViewModel()
        let delegate = MockPageDelegate()
        delegate.numberOfVCs = 3
        vm.delegate = delegate

        let next = vm.nextPageIndex(after: 5)
        XCTAssertNil(next)
    }

    func testNextPageIndex_MiddlePage() {
        let vm = PageViewModel()
        let delegate = MockPageDelegate()
        delegate.numberOfVCs = 5
        vm.delegate = delegate

        let next = vm.nextPageIndex(after: 2)
        XCTAssertEqual(next, 3)
    }

    // MARK: - beforePageIndex

    func testBeforePageIndex_ReturnsBeforeIndex() {
        let vm = PageViewModel()
        let delegate = MockPageDelegate()
        delegate.numberOfVCs = 5
        vm.delegate = delegate

        let before = vm.beforePageIndex(before: 2)
        XCTAssertEqual(before, 1)
    }

    func testBeforePageIndex_AtFirstPage_ReturnsNil() {
        let vm = PageViewModel()
        let delegate = MockPageDelegate()
        delegate.numberOfVCs = 3
        vm.delegate = delegate

        let before = vm.beforePageIndex(before: 0)
        XCTAssertNil(before)
    }

    func testBeforePageIndex_FromSecondPage_ReturnsFirst() {
        let vm = PageViewModel()
        let delegate = MockPageDelegate()
        delegate.numberOfVCs = 3
        vm.delegate = delegate

        let before = vm.beforePageIndex(before: 1)
        XCTAssertEqual(before, 0)
    }

    // MARK: - moveToNextPage

    func testMoveToNextPage_IncrementsCurrentPage() {
        let vm = PageViewModel()
        let delegate = MockPageDelegate()
        delegate.numberOfVCs = 5
        vm.delegate = delegate

        let moved = vm.moveToNextPage()
        XCTAssertTrue(moved)
        XCTAssertEqual(vm.currentPage, 1)
    }

    func testMoveToNextPage_AtLastPage_ReturnsFalse() {
        let vm = PageViewModel()
        let delegate = MockPageDelegate()
        delegate.numberOfVCs = 3
        vm.delegate = delegate
        vm.currentPage = 2

        let moved = vm.moveToNextPage()
        XCTAssertFalse(moved)
        XCTAssertEqual(vm.currentPage, 2)
    }

    func testMoveToNextPage_MultipleTimes() {
        let vm = PageViewModel()
        let delegate = MockPageDelegate()
        delegate.numberOfVCs = 4
        vm.delegate = delegate

        XCTAssertTrue(vm.moveToNextPage())
        XCTAssertEqual(vm.currentPage, 1)
        XCTAssertTrue(vm.moveToNextPage())
        XCTAssertEqual(vm.currentPage, 2)
        XCTAssertTrue(vm.moveToNextPage())
        XCTAssertEqual(vm.currentPage, 3)
        XCTAssertFalse(vm.moveToNextPage())
        XCTAssertEqual(vm.currentPage, 3)
    }

    // MARK: - onCurrentPageChange callback

    func testOnCurrentPageChange_CalledOnPageChange() {
        let vm = PageViewModel()
        let delegate = MockPageDelegate()
        delegate.numberOfVCs = 5
        vm.delegate = delegate

        var receivedPage: Int?
        var receivedTotal: Int?
        vm.onCurrentPageChange = { page, total in
            receivedPage = page
            receivedTotal = total
        }

        vm.currentPage = 2
        XCTAssertEqual(receivedPage, 2)
        XCTAssertEqual(receivedTotal, 5)
    }

    // MARK: - viewDidLoad

    func testViewDidLoad_CallsCreateViewControllers() {
        let vm = PageViewModel()
        let delegate = MockPageDelegate()
        vm.delegate = delegate

        vm.viewDidLoad()

        XCTAssertTrue(delegate.createdVCsCalled)
        XCTAssertEqual(delegate.setVCIndex, 0)
    }
}
