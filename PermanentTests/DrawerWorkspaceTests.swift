//
//  DrawerWorkspaceTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 30.09.2026.
//

import XCTest
@testable import Permanent

@MainActor
final class DrawerWorkspaceTests: XCTestCase {
    private var previousSession: PermSession?
    private let photo = FileModel(name: "August_Hike_003.jpg", recordId: 1, folderLinkId: 11, archiveNbr: "0001", type: "type.record.image", permissions: [.read, .move])

    override func setUp() {
        super.setUp()
        previousSession = AuthenticationManager.shared.session
        AuthenticationManager.shared.session = PermSession(token: "test_token")
    }

    override func tearDown() {
        AuthenticationManager.shared.session = previousSession
        super.tearDown()
    }

    private func filesScreen(_ viewModel: MyFilesViewModel) -> MainViewController {
        let screen = MainViewController()
        screen.viewModel = viewModel
        return screen
    }

    private func drawer(showing screen: UIViewController) -> DrawerViewController {
        DrawerViewController(rootViewController: RootNavigationController(viewController: screen), leftSideMenuController: SideMenuViewController())
    }

    /// A photo picked for Move, which Private and Public Files keep in the session.
    private func pickPhotoForMove() {
        AuthenticationManager.shared.session?.selectedFiles = [photo]
        AuthenticationManager.shared.session?.fileAction = .move
    }

    func testEachScreen_BelongsToItsWorkspace() {
        XCTAssertEqual(DrawerViewController.workspace(of: filesScreen(MyFilesViewModel())), .files)
        XCTAssertEqual(DrawerViewController.workspace(of: filesScreen(PublicFilesViewModel())), .publicFiles)
        XCTAssertEqual(DrawerViewController.workspace(of: SharesViewController()), .shares)
        XCTAssertNil(DrawerViewController.workspace(of: UIViewController()))
    }

    func testAnotherWorkspace_DropsThePickedFiles() {
        let drawer = drawer(showing: filesScreen(MyFilesViewModel()))
        pickPhotoForMove()

        drawer.changeRoot(viewController: SharesViewController())

        XCTAssertNil(AuthenticationManager.shared.session?.selectedFiles)
        XCTAssertNil(AuthenticationManager.shared.session?.fileAction, "no Move Here waits in Shared")
    }

    func testPublicFiles_IsAnotherWorkspace_ThoughItKeepsItsPicksInTheSameSession() {
        let drawer = drawer(showing: filesScreen(MyFilesViewModel()))
        pickPhotoForMove()

        drawer.changeRoot(viewController: filesScreen(PublicFilesViewModel()))

        XCTAssertNil(AuthenticationManager.shared.session?.selectedFiles)
        XCTAssertNil(AuthenticationManager.shared.session?.fileAction)
    }

    func testAScreenOutsideTheWorkspaces_DropsThePickedFiles() {
        let drawer = drawer(showing: filesScreen(MyFilesViewModel()))
        pickPhotoForMove()

        drawer.changeRoot(viewController: UIViewController())

        XCTAssertNil(AuthenticationManager.shared.session?.selectedFiles)
    }

    func testTheSameWorkspaceAgain_KeepsThePickedFiles() {
        let drawer = drawer(showing: filesScreen(MyFilesViewModel()))
        pickPhotoForMove()

        drawer.changeRoot(viewController: filesScreen(MyFilesViewModel()))

        XCTAssertEqual(AuthenticationManager.shared.session?.selectedFiles?.count, 1)
        XCTAssertEqual(AuthenticationManager.shared.session?.fileAction, .move)
    }
}
