//  
//  FileVO.swift
//  Permanent
//
//  Created by Adrian Creteanu on 11/11/2020.
//

import Foundation

struct FileVO: Model {
    static let originalFormat = "file.format.original"
    static let accessCopyFormat = "file.format.archivematica.access"
    static let convertedFormat = "file.format.converted"

    let fileID, size: Int?
    let format: String?
    let parentFileID: Int?
    let contentType, contentVersion: String?
    let s3Version: JSONAny? // TODO
    let s3VersionID, md5Checksum, cloud1, cloud2: String?
    let cloud3: String?
    let archiveID, height, width: Int?
    let durationInSecs: Int?
    let fileURL, downloadURL: String?
    let urlDT, status, type, createdDT: String?
    let updatedDT: String?

    enum CodingKeys: String, CodingKey {
        case fileID = "fileId"
        case size, format
        case parentFileID = "parentFileId"
        case contentType, contentVersion, s3Version
        case s3VersionID = "s3VersionId"
        case md5Checksum, cloud1, cloud2, cloud3
        case archiveID = "archiveId"
        case height, width, durationInSecs, fileURL, downloadURL, urlDT, status, type, createdDT, updatedDT
    }
}

extension FileVO {
    /// The plain link first, as the web plays it; the download link only adds a "save as" header.
    var playbackURL: URL? {
        firstURL(of: [fileURL, downloadURL])
    }

    /// The download link first, as photos and PDFs have always loaded; the plain link stands in.
    var previewURL: URL? {
        firstURL(of: [downloadURL, fileURL])
    }

    private func firstURL(of links: [String?]) -> URL? {
        links.lazy.compactMap { $0 }.filter { !$0.isEmpty }.compactMap { URL(string: $0) }.first
    }
}

extension Array where Element == FileVO {
    /// The user's own upload. Stela lists a record's files in no fixed order, so the format decides.
    var original: FileVO? {
        first { $0.format == FileVO.originalFormat } ?? first
    }

    /// Audio and video in the web's order: the access copy, the original, then the conversion, which
    /// can play silent. A file without a link is left out.
    var playbackOrder: [FileVO] {
        ordered([FileVO.accessCopyFormat, FileVO.originalFormat, FileVO.convertedFormat], link: \.playbackURL)
    }

    /// Photos and PDFs: the original, then the access copy and the conversion, which only stand in
    /// when it cannot open. A file without a link is left out.
    var previewOrder: [FileVO] {
        ordered([FileVO.originalFormat, FileVO.accessCopyFormat, FileVO.convertedFormat], link: \.previewURL)
    }

    private func ordered(_ formats: [String], link: KeyPath<FileVO, URL?>) -> [FileVO] {
        let ordered = formats.compactMap { format in
            first { $0.format == format && $0[keyPath: link] != nil }
        }
        return ordered.isEmpty ? Array(prefix(1)) : ordered
    }
}
