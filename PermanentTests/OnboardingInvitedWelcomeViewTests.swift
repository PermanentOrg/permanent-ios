//
//  OnboardingInvitedWelcomeViewTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class OnboardingInvitedWelcomeViewTests: XCTestCase {

    // MARK: - OnboardingInvitedWelcomeViewModel Initial State

    func testViewModel_InitialState() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingInvitedWelcomeViewModel(containerViewModel: container)

        XCTAssertFalse(vm.isArchiveAccepted)
        XCTAssertFalse(vm.isLoading)
        XCTAssertFalse(vm.showAlert)
        XCTAssertTrue(vm.containerViewModel === container)
    }

    // MARK: - OnboardingInvitedWelcomeViewModel Properties

    func testViewModel_AllPropertiesCanBeSet() {
        let container = OnboardingContainerViewModel(username: "user@test.com", password: "pass")
        let vm = OnboardingInvitedWelcomeViewModel(containerViewModel: container)

        vm.isArchiveAccepted = true
        vm.isLoading = true
        vm.showAlert = true

        XCTAssertTrue(vm.isArchiveAccepted)
        XCTAssertTrue(vm.isLoading)
        XCTAssertTrue(vm.showAlert)
        XCTAssertTrue(vm.containerViewModel.allArchives.isEmpty)
    }

    // MARK: - OnboardingInvitedWelcomeView Rendering Tests

    func testView_RendersWithoutCrash() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingInvitedWelcomeViewModel(containerViewModel: container)
        let view = OnboardingInvitedWelcomeView(
            viewModel: vm,
            nextButtonAction: {},
            newArchiveButtonAction: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testView_RendersWhileLoading() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        container.isLoading = true
        let vm = OnboardingInvitedWelcomeViewModel(containerViewModel: container)
        let view = OnboardingInvitedWelcomeView(
            viewModel: vm,
            nextButtonAction: {},
            newArchiveButtonAction: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testView_CallbacksAreStored() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingInvitedWelcomeViewModel(containerViewModel: container)

        var nextCalled = false
        var newArchiveCalled = false

        let view = OnboardingInvitedWelcomeView(
            viewModel: vm,
            nextButtonAction: { nextCalled = true },
            newArchiveButtonAction: { newArchiveCalled = true }
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
        XCTAssertFalse(nextCalled)
        XCTAssertFalse(newArchiveCalled)
    }

    // MARK: - All-accepted onboarding lockout

    /// The user reached onboarding with archives ALL already accepted and no archive
    /// selected → adopt the first accepted one so "Next" can enable.
    func testArchiveToAdopt_AllAccepted_NoSelectedArchive_ReturnsFirstOk() {
        let container = makeContainer(archives: [(1, .ok), (2, .ok)])
        setSession(selectedArchive: nil)
        defer { AuthenticationManager.shared.session = nil }

        let vm = OnboardingInvitedWelcomeViewModel(containerViewModel: container)

        XCTAssertEqual(vm.archiveToAdoptOnAppear()?.archiveID, 1)
    }

    /// A pending invite still has an Accept button, so there's nothing to auto-adopt.
    func testArchiveToAdopt_OnlyPending_ReturnsNil() {
        let container = makeContainer(archives: [(1, .pending)])
        setSession(selectedArchive: nil)
        defer { AuthenticationManager.shared.session = nil }

        let vm = OnboardingInvitedWelcomeViewModel(containerViewModel: container)

        XCTAssertNil(vm.archiveToAdoptOnAppear())
    }

    /// Never override an archive the user (or an accept) already selected.
    func testArchiveToAdopt_ArchiveAlreadySelected_ReturnsNil() {
        let container = makeContainer(archives: [(1, .ok)])
        setSession(selectedArchive: makeArchiveVOData(archiveID: 99, status: .ok))
        defer { AuthenticationManager.shared.session = nil }

        let vm = OnboardingInvitedWelcomeViewModel(containerViewModel: container)

        XCTAssertNil(vm.archiveToAdoptOnAppear())
    }

    /// All accepted, none selected → "Next" should enable.
    func testShouldEnableNext_AllAccepted_True() {
        let container = makeContainer(archives: [(1, .ok), (2, .ok)])
        setSession(selectedArchive: nil)
        defer { AuthenticationManager.shared.session = nil }

        let vm = OnboardingInvitedWelcomeViewModel(containerViewModel: container)
        XCTAssertTrue(vm.shouldEnableNextForAcceptedArchive())
    }

    /// A remaining .pending invite means the Accept button is the intended path — don't
    /// auto-enable, and don't silently switch the current archive.
    func testShouldEnableNext_MixedWithPending_False() {
        let container = makeContainer(archives: [(1, .ok), (2, .pending)])
        setSession(selectedArchive: nil)
        defer { AuthenticationManager.shared.session = nil }

        let vm = OnboardingInvitedWelcomeViewModel(containerViewModel: container)
        XCTAssertFalse(vm.shouldEnableNextForAcceptedArchive())
        XCTAssertNil(vm.archiveToAdoptOnAppear())
    }

    /// Returning to this screen after an archive was already adopted (fresh view model,
    /// archive now selected) must re-enable "Next" — the regression this fix guards against.
    func testShouldEnableNext_AlreadySelected_True() {
        let container = makeContainer(archives: [(1, .ok)])
        setSession(selectedArchive: makeArchiveVOData(archiveID: 1, status: .ok))
        defer { AuthenticationManager.shared.session = nil }

        let vm = OnboardingInvitedWelcomeViewModel(containerViewModel: container)
        XCTAssertTrue(vm.shouldEnableNextForAcceptedArchive())
        XCTAssertNil(vm.archiveToAdoptOnAppear())   // already selected → nothing to adopt
    }

    /// Installs a minimal session carrying the given archive. No full account is needed, since
    /// `archiveToAdoptOnAppear` only reads `session.selectedArchive`.
    private func setSession(selectedArchive: ArchiveVOData?) {
        let session = PermSession(token: "t")
        session.selectedArchive = selectedArchive
        AuthenticationManager.shared.session = session
    }

    private func makeArchiveVOData(archiveID: Int, status: ArchiveVOData.Status) -> ArchiveVOData {
        ArchiveVOData(
            childFolderVOS: nil, folderSizeVOS: nil, recordVOS: nil,
            accessRole: "access.role.owner", fullName: "Archive \(archiveID)",
            spaceTotal: nil, spaceLeft: nil, fileTotal: nil, fileLeft: nil,
            relationType: nil, homeCity: nil, homeState: nil, homeCountry: nil,
            itemVOS: nil, birthDay: nil, company: nil, archiveVODescription: nil,
            archiveID: archiveID, publicDT: nil, archiveNbr: "\(archiveID)-0000",
            view: nil, viewProperty: nil, archiveVOPublic: nil, vaultKey: nil,
            thumbArchiveNbr: nil, type: nil, thumbStatus: nil, imageRatio: nil, thumbnail256: nil,
            thumbURL200: nil, thumbURL500: nil, thumbURL1000: nil, thumbURL2000: nil,
            thumbDT: nil, createdDT: nil, updatedDT: nil, status: status)
    }

    private func makeContainer(archives: [(id: Int, status: ArchiveVOData.Status)]) -> OnboardingContainerViewModel {
        // Build with no session so the container's init (which reads session.account and can
        // otherwise fire a network fetch) is a safe no-op.
        AuthenticationManager.shared.session = nil
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        container.allArchives = archives.map {
            OnboardingArchive(fullname: "Archive \($0.id)", accessType: "access.role.owner",
                              status: $0.status, archiveID: $0.id,
                              thumbnailURL: "", isThumbnailGenerated: false)
        }
        container.allArchivesVO = archives.map {
            ArchiveVO(archiveVO: makeArchiveVOData(archiveID: $0.id, status: $0.status))
        }
        return container
    }

    // MARK: - Helpers

    private func hostView<Content: View>(_ view: Content) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        return host
    }
}
