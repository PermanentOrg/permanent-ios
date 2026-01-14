import XCTest
@testable import Permanent

@MainActor
final class SharePreviewSwiftUIViewModelTests: XCTestCase {
    func testCancelLoadingResetsIsLoading() async {
        let repo = DelayedRepo()
        let vm = SharePreviewSwiftUIViewModel(shareToken: "test-token", repository: repo)

        vm.start()
        // Give the Task a moment to start
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertTrue(vm.isLoading, "isLoading should be true after start")

        vm.cancelLoadingTask()
        // Let cancellation propagate
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertFalse(vm.isLoading, "isLoading should be false after cancelLoading")
        XCTAssertNil(vm.errorMessage, "errorMessage should be nil after cancellation")
    }

    func testRepositoryCancellationPropagates() async {
        let repo = CancelableRepo()
        let vm = SharePreviewSwiftUIViewModel(shareToken: "test-token", repository: repo)

        vm.start()
        try? await Task.sleep(nanoseconds: 50_000_000)
        vm.cancelLoadingTask()

        // Wait for repo to observe cancellation
        try? await Task.sleep(nanoseconds: 200_000_000)

        let didCancel = await repo.didCancel
        XCTAssertTrue(didCancel, "Repository should observe cancellation when task is cancelled")
    }
}

// MARK: - Helpers

private struct DelayedRepo: SharePreviewRepositoryProtocol {
    func fetchSharePreview(shareToken: String) async throws -> SharebyURLVOData {
        // Delay to simulate network work
        try await Task.sleep(nanoseconds: 300_000_000)
        return try await SharePreviewMockRepository().fetchSharePreview(shareToken: shareToken)
    }

    func requestShareAccess(shareToken: String) async throws -> ShareVOData {
        try await Task.sleep(nanoseconds: 100_000_000)
        return try await SharePreviewMockRepository().requestShareAccess(shareToken: shareToken)
    }
}

private actor CancelableRepo: SharePreviewRepositoryProtocol {
    private(set) var didCancel = false

    func fetchSharePreview(shareToken: String) async throws -> SharebyURLVOData {
        do {
            try await Task.sleep(nanoseconds: 300_000_000)
        } catch {
            if Task.isCancelled {
                didCancel = true
                throw CancellationError()
            }
            throw error
        }
        return try await SharePreviewMockRepository().fetchSharePreview(shareToken: shareToken)
    }

    func requestShareAccess(shareToken: String) async throws -> ShareVOData {
        do {
            try await Task.sleep(nanoseconds: 100_000_000)
        } catch {
            if Task.isCancelled {
                didCancel = true
                throw CancellationError()
            }
            throw error
        }
        return try await SharePreviewMockRepository().requestShareAccess(shareToken: shareToken)
    }
}