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

    func testRowsThatOpenOverTheScreen_KeepTheScreensRowLit() {
        XCTAssertTrue(DrawerOption.legacyPlanning.keepsScreen)
        XCTAssertTrue(DrawerOption.archiveSettings.keepsScreen)
        for screen in [DrawerOption.files, .shares, .publicFiles, .manageMembers, .manageTags, .publicGallery, .archives] {
            XCTAssertFalse(screen.keepsScreen, "\(screen) changes the screen")
        }
    }

    func testTapOnArchiveSettings_KeepsTheOpenScreensRowLit() {
        let menu = SideMenuViewController()
        menu.selectedMenuOption = .publicFiles
        let rows = MenuRowsStub()
        let table = UITableView()
        table.dataSource = rows
        table.reloadData()
        let archiveSettings = IndexPath(row: 0, section: LeftDrawerSection.archiveSettings.rawValue)
        table.selectRow(at: archiveSettings, animated: false, scrollPosition: .none)

        menu.tableView(table, didSelectRowAt: archiveSettings)

        XCTAssertEqual(menu.selectedMenuOption, .publicFiles)
        XCTAssertEqual(table.indexPathForSelectedRow, IndexPath(row: 2, section: LeftDrawerSection.files.rawValue))
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

    func testTheSameWorkspaceAgain_NewSelectModeStartsEmpty() {
        let drawer = drawer(showing: filesScreen(MyFilesViewModel()))
        AuthenticationManager.shared.session?.selectedFiles = [photo, photo, photo, photo]
        let reopened = MyFilesViewModel()
        drawer.changeRoot(viewController: filesScreen(reopened))

        reopened.startSelecting()

        XCTAssertTrue(reopened.isSelecting)
        XCTAssertEqual(reopened.selectedFiles?.count, 0, "files picked in an earlier select mode stay unpicked")
    }

    func testMoveWaitingForItsFolder_NewSelectModeKeepsItsFiles() {
        let drawer = drawer(showing: filesScreen(MyFilesViewModel()))
        pickPhotoForMove()
        let reopened = MyFilesViewModel()
        drawer.changeRoot(viewController: filesScreen(reopened))

        reopened.startSelecting()

        XCTAssertEqual(reopened.selectedFiles?.count, 1)
        XCTAssertEqual(AuthenticationManager.shared.session?.fileAction, .move)
    }

    func testSharesScreen_NewSelectModeStartsEmpty() {
        let shares = SharedFilesViewModel()
        shares.selectedFiles = [photo]

        shares.startSelecting()

        XCTAssertEqual(shares.selectedFiles?.count, 0)
    }
}

/// Gives the table as many rows as the side menu has, so a row can be selected without the menu's cells.
private final class MenuRowsStub: NSObject, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { 4 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 3 }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { UITableViewCell() }
}
