//
//  ArchiveDetailsViewTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class ArchiveDetailsViewTests: XCTestCase {

    // MARK: - OnboardingArchive Construction

    func testOnboardingArchive_CanBeCreated() {
        let archive = makeArchive()

        XCTAssertEqual(archive.fullname, "Test Archive")
        XCTAssertEqual(archive.accessType, "access.role.viewer")
        XCTAssertEqual(archive.status, .ok)
        XCTAssertEqual(archive.archiveID, 100)
    }

    func testOnboardingArchive_PendingStatus() {
        let archive = makeArchive(status: .pending)

        XCTAssertEqual(archive.status, .pending)
    }

    // MARK: - ArchiveDetailsView Rendering

    func testArchiveDetailsView_RendersWithDefaults() {
        let archive = makeArchive()
        let view = ArchiveDetailsView(archive: archive)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testArchiveDetailsView_RendersWithShowStatus() {
        let archive = makeArchive(status: .ok)
        let view = ArchiveDetailsView(archive: archive, showStatus: true)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testArchiveDetailsView_RendersWithPendingStatus() {
        let archive = makeArchive(status: .pending)
        let view = ArchiveDetailsView(archive: archive, showStatus: true)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testArchiveDetailsView_RendersWhileLoading() {
        let archive = makeArchive()
        let view = ArchiveDetailsView(archive: archive, showStatus: true, isLoading: true)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testArchiveDetailsView_RendersWithAcceptCallback() {
        var accepted = false
        let archive = makeArchive(status: .pending)
        let view = ArchiveDetailsView(archive: archive, showStatus: true, acceptArchive: { accepted = true })
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
        XCTAssertFalse(accepted)
    }

    func testArchiveDetailsView_RendersWithCustomThumbnail() {
        let archive = makeArchive()
        let view = ArchiveDetailsView(thumbnail: Image(systemName: "person.circle"), archive: archive)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    // MARK: - Helpers

    private func makeArchive(status: ArchiveVOData.Status = .ok) -> OnboardingArchive {
        OnboardingArchive(
            fullname: "Test Archive",
            accessType: "access.role.viewer",
            status: status,
            archiveID: 100,
            thumbnailURL: "",
            isThumbnailGenerated: false
        )
    }

    private func hostView<Content: View>(_ view: Content) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        return host
    }
}
