//
//  ThumbnailSkeletonTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 06.10.2026.
//

import XCTest
import SDWebImage
@testable import Permanent

final class ThumbnailSkeletonTests: XCTestCase {
    private let sweeps = !UIAccessibility.isReduceMotionEnabled

    private func shown(_ view: UIView, size: CGSize) -> UIWindow {
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        view.frame = window.bounds
        window.addSubview(view)
        window.isHidden = false
        addTeardownBlock { window.isHidden = true }
        return window
    }

    private func makeRow(grid: Bool = false) throws -> FileCollectionViewCell {
        let nib = UINib(nibName: grid ? "FileCollectionViewGridCell" : "FileCollectionViewCell", bundle: Bundle(for: FileCollectionViewCell.self))
        let cell = try XCTUnwrap(nib.instantiate(withOwner: nil).first as? FileCollectionViewCell)
        _ = shown(cell, size: grid ? CGSize(width: 186, height: 225) : CGSize(width: 390, height: 74))
        cell.layoutIfNeeded()
        return cell
    }

    private func file(_ fields: String) throws -> FileModel {
        let json = "{ \"items\": [ { \(fields) } ] }"
        let response = try FolderChildrenV2Response.decoder.decode(FolderChildrenV2Response.self, from: Data(json.utf8))
        return FileModel(model: try XCTUnwrap(response.items?.first), permissions: [.read], accessRole: .viewer)
    }

    private func photo(thumbnail: URL?) throws -> FileModel {
        let thumb = thumbnail.map { ", \"thumbUrl200\": \"\($0.absoluteString)\"" } ?? ""
        return try file("\"recordId\": \"1001\", \"displayName\": \"photo.jpg\", \"archiveNumber\": \"0001-1\", \"type\": \"type.record.image\", \"status\": \"ok\", \"folderLinkId\": \"1\"\(thumb)")
    }

    /// A small picture on disk under a new name, so no image cache already holds it.
    private func pictureFile() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("thumb-\(UUID().uuidString).png")
        let picture = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 20)).image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 20, height: 20))
        }
        try XCTUnwrap(picture.pngData()).write(to: url)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    private func waitUntil(_ condition: () -> Bool, timeout: TimeInterval = 30, _ message: String, file: StaticString = #filePath, line: UInt = #line) {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.02))
        }
        XCTAssertTrue(condition(), message, file: file, line: line)
    }

    // MARK: - The shared sweep

    func testTheSweep_RunsOnScreen_HoldsStillWhenOffOrUnderReduceMotion_AndComesBackAfterReuse() {
        let host = UIView()
        _ = shown(host, size: CGSize(width: 390, height: 74))
        var reducesMotion = false
        let shimmer = SkeletonShimmer(in: host, reducesMotion: { reducesMotion })
        shimmer.layout(lighting: UIBezierPath(roundedRect: CGRect(x: 14, y: 17, width: 38, height: 38), cornerRadius: 6))
        XCTAssertTrue(shimmer.isSweeping)

        shimmer.isOn = false
        XCTAssertFalse(shimmer.isSweeping, "off holds the shapes still")

        shimmer.isOn = true
        reducesMotion = true
        shimmer.update()
        XCTAssertFalse(shimmer.isSweeping, "Reduce Motion holds them still")

        reducesMotion = false
        host.layer.sublayers?.forEach { $0.removeAllAnimations() }
        shimmer.update()
        XCTAssertTrue(shimmer.isSweeping, "reuse drops the animation, and the next update brings it back")
    }

    func testTheSkeletonRows_SweepUnlessHeldStill() {
        let cell = FileSkeletonCollectionViewCell(frame: .zero)
        _ = shown(cell, size: CGSize(width: 390, height: 74))
        cell.configure(isGrid: false, accessibilityLabel: nil, shimmers: true)
        cell.layoutIfNeeded()
        XCTAssertEqual(cell.shimmer.isSweeping, sweeps)

        cell.configure(isGrid: false, accessibilityLabel: nil, shimmers: false)
        XCTAssertFalse(cell.shimmer.isSweeping, "under the retry footer nothing is loading")
    }

    // MARK: - A file row's picture slot

    func testARowWaitingForItsPicture_SweepsUntilThePictureFadesIn() throws {
        let cell = try makeRow()
        let picture = try photo(thumbnail: try pictureFile())
        cell.updateCell(model: picture, fileAction: .none, isGridCell: false, isSearchCell: false)

        XCTAssertFalse(cell.thumbnailSkeleton.isHidden, "the picture is still on its way")
        XCTAssertEqual(cell.thumbnailSkeleton.shimmer.isSweeping, sweeps)
        XCTAssertNil(cell.fileImageView.image, "no grey placeholder over the square")
        XCTAssertEqual(cell.fileImageView.sd_imageTransition?.duration, FileCollectionViewCell.thumbnailFade, "it fades in rather than snaps")

        waitUntil({ cell.thumbnailSkeleton.isHidden }, "the picture faded in and the square went")
        XCTAssertNotNil(cell.fileImageView.image)
        XCTAssertFalse(cell.thumbnailSkeleton.shimmer.isSweeping)

        // Back on screen, as after a scroll: the picture is in memory now.
        cell.prepareForReuse()
        cell.updateCell(model: picture, fileAction: .none, isGridCell: false, isSearchCell: false)
        XCTAssertTrue(cell.thumbnailSkeleton.isHidden, "a picture already in memory shows at once")
        XCTAssertNotNil(cell.fileImageView.image)
    }

    func testAFailedDownload_HoldsTheSquareStill() throws {
        let cell = try makeRow()
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent("missing-\(UUID().uuidString).png")
        cell.updateCell(model: try photo(thumbnail: missing), fileAction: .none, isGridCell: false, isSearchCell: false)
        XCTAssertEqual(cell.thumbnailSkeleton.shimmer.isSweeping, sweeps, "it sweeps while the download runs")

        waitUntil({ !cell.thumbnailSkeleton.shimmer.isOn }, "the download ended")
        XCTAssertFalse(cell.thumbnailSkeleton.isHidden, "the square stays where the picture would be")
        XCTAssertNil(cell.fileImageView.image)
    }

    func testAPictureNotMadeYet_SweepsWithoutASpinner() throws {
        let cell = try makeRow()
        cell.updateCell(model: try photo(thumbnail: nil), fileAction: .none, isGridCell: false, isSearchCell: false)

        cell.layoutIfNeeded()
        XCTAssertFalse(cell.thumbnailSkeleton.isHidden)
        XCTAssertEqual(cell.thumbnailSkeleton.shimmer.isSweeping, sweeps)
        XCTAssertEqual(cell.thumbnailSkeleton.shimmer.litRect, cell.thumbnailSkeleton.bounds, "the band lights the whole square")
        XCTAssertEqual(cell.thumbnailSkeleton.bounds.size, CGSize(width: 38, height: 38))
        XCTAssertFalse(cell.activityIndicator.isAnimating, "one look for every wait")
        XCTAssertNil(cell.fileImageView.image, "the nib's folder image does not cover the square")
    }

    func testAFolder_AndAReusedRow_ShowNoSquare() throws {
        let cell = try makeRow()
        cell.updateCell(model: try photo(thumbnail: nil), fileAction: .none, isGridCell: false, isSearchCell: false)
        cell.prepareForReuse()
        XCTAssertTrue(cell.thumbnailSkeleton.isHidden, "a reused row starts clean")

        let folder = try file("\"folderId\": \"10\", \"displayName\": \"Trips\", \"type\": \"private\", \"status\": \"ok\", \"folderLinkId\": \"11\", \"archiveNumber\": \"0001-test\"")
        cell.updateCell(model: folder, fileAction: .none, isGridCell: false, isSearchCell: false)
        XCTAssertTrue(cell.thumbnailSkeleton.isHidden, "a folder shows its mark at once")
        XCTAssertEqual(cell.thumbnailSkeleton.shimmer.isSweeping, false)
    }

    func testAGridTile_ShowsTheSquareOverItsWholePicture() throws {
        let cell = try makeRow(grid: true)
        cell.updateCell(model: try photo(thumbnail: nil), fileAction: .none, isGridCell: true, isSearchCell: false)
        cell.layoutIfNeeded()

        XCTAssertEqual(cell.thumbnailSkeleton.frame, cell.fileImageView.frame)
        XCTAssertEqual(cell.thumbnailSkeleton.shimmer.isSweeping, sweeps)
        XCTAssertEqual(cell.thumbnailSkeleton.shimmer.litRect, cell.thumbnailSkeleton.bounds)
    }
}
