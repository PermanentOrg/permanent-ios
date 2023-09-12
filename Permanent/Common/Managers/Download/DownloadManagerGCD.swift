//
//  DownloadManager.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14.01.2021.
//

import Foundation

typealias GetRecordResponse = (_ file: RecordVO?, _ errorMessage: Error?) -> Void
typealias GetFolderResponse = (_ folder: FolderVO?, _ errorMessage: Error?) -> Void

class DownloadManagerGCD: Downloader {
    fileprivate var operation: APIOperation?
 
    init() {
    }
    
    func fileVO(forRecordVO recordVO: RecordVO, fileType: FileType) -> FileVO? {
        if fileType == .video,
           let fileVO = recordVO.recordVO?.fileVOS?.first(where: {$0.format == "file.format.converted"}) {
            return fileVO
        } else {
            return recordVO.recordVO?.fileVOS?.first
        }
    }
    
    func download(_ file: FileModel,
                  onDownloadStart: @escaping VoidAction,
                  onFileDownloaded: @escaping DownloadResponse,
                  progressHandler: ProgressHandler?,
                  completion: VoidAction?) {
        let downloadInfo = FileDownloadInfoVM(
            fileType: file.type,
            folderLinkId: file.folderLinkId,
            parentFolderLinkId: file.parentFolderLinkId
        )
        
        startDownload(downloadInfo, onDownloadStart: onDownloadStart, onFileDownloaded: onFileDownloaded, progressHandler: progressHandler, completion: completion)
    }
    
    func download(_ file: FileDownloadInfo,
                  onDownloadStart: @escaping VoidAction,
                  onFileDownloaded: @escaping DownloadResponse,
                  progressHandler: ProgressHandler?,
                  completion: VoidAction? = nil) {
        startDownload(file, onDownloadStart: onDownloadStart, onFileDownloaded: onFileDownloaded, progressHandler: progressHandler, completion: completion)
    }
    
    func cancelDownload() {
        operation?.cancel()
    }
    
    fileprivate func startDownload(_ file: FileDownloadInfo,
                                   onDownloadStart: @escaping VoidAction,
                                   onFileDownloaded: @escaping DownloadResponse,
                                   progressHandler: ProgressHandler?,
                                   completion: VoidAction? = nil) {
        onDownloadStart()
        
        downloadFile(file, progressHandler: progressHandler) { [weak self] url, error in
            self?.operation = nil
                
            if let url = url {
                onFileDownloaded(url, nil)
            } else {
                onFileDownloaded(nil, error)
            }
            
            completion?()
        }
    }
    
    func downloadFile(_ file: FileDownloadInfo, progressHandler: ProgressHandler?, then handler: @escaping DownloadResponse) {
        getRecord(file) { [weak self] record, errorMessage in
            guard let record = record else {
                return handler(nil, errorMessage)
            }
            
            self?.downloadFileData(record: record, fileType: file.fileType, progressHandler: progressHandler, then: handler)
        }
    }
    
    func getRecord(_ file: FileDownloadInfo, then handler: @escaping GetRecordResponse) {
        let apiOperation = APIOperation(FilesEndpoint.getRecord(itemInfo: (file.folderLinkId, file.parentFolderLinkId)))
        self.operation = apiOperation
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<RecordVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<RecordVO>.decoder
                    ),
                    model.isSuccessful
                    
                else {
                    handler(nil, APIError.invalidResponse)
                    return
                }
                 
                handler(model.results.first?.data?.first, nil)
                    
            case .error(let error, _):
                handler(nil, error)
                    
            default:
                break
            }
        }
    }
    
    func getFolder(_ file: FileDownloadInfo, then handler: @escaping GetFolderResponse) {
        let apiOperation = APIOperation(FilesEndpoint.getFolder(itemInfo: (file.folderLinkId, file.parentFolderLinkId)))
        self.operation = apiOperation
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<FolderVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<FolderVO>.decoder
                    ),
                    model.isSuccessful
                    
                else {
                    handler(nil, APIError.invalidResponse)
                    return
                }
                 
                handler(model.results.first?.data?.first, nil)
                    
            case .error(let error, _):
                handler(nil, error)
                    
            default:
                break
            }
        }
    }
    
    func downloadFileData(record: RecordVO, fileType: FileType, progressHandler: ProgressHandler?, then handler: @escaping DownloadResponse) {
        guard
            let fileVO = fileVO(forRecordVO: record, fileType: fileType),
            let downloadURL = fileVO.downloadURL,
            let url = URL(string: downloadURL),
            let uploadFileName = record.recordVO?.uploadFileName,
            let displayName = record.recordVO?.displayName
        else {
            return handler(nil, APIError.invalidResponse)
        }
        
        // If the file was converted, then it most certainly is an mp4
        // Otherwise, the file was not converted, we use the original filename + extension
        let fileName: String
        if fileType == .video && fileVO.contentType == "video/mp4" {
            fileName = displayName + ".mp4"
        } else {
            fileName = uploadFileName
        }
        
        let apiOperation = APIOperation(FilesEndpoint.download(url: url, filename: fileName, progressHandler: progressHandler))
        self.operation = apiOperation
        
        apiOperation.execute(in: APIRequestDispatcher(networkSession: CDNSession())) { result in
            switch result {
            case .file(let fileURL, _):
                guard let url = fileURL else {
                    handler(nil, APIError.invalidResponse)
                    return
                }
            
                handler(url, nil)
    
            case .error(let error, _):
                handler(nil, error as? APIError)
                
            default:
                break
            }
        }
    }
}

class DownloadManagerMock: Downloader {
    func download(_ file: FileModel,
                  onDownloadStart: @escaping VoidAction,
                  onFileDownloaded: @escaping DownloadResponse,
                  progressHandler: ProgressHandler?,
                  completion: VoidAction?) {
        onDownloadStart()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            onFileDownloaded(nil, nil)
            completion?()
        }
    }

    func download(_ file: FileDownloadInfo,
                  onDownloadStart: @escaping VoidAction,
                  onFileDownloaded: @escaping DownloadResponse,
                  progressHandler: ProgressHandler?,
                  completion: VoidAction?) {
        onDownloadStart()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            onFileDownloaded(nil, nil)
            completion?()
        }
    }

    func cancelDownload() {
    }

    func mockRecordVO() -> RecordVO {
        let recordJSON =
                "{\"Results\":[{\"data\":[{\"RecordVO\":{\"recordId\":67934,\"archiveId\":1858,\"archiveNbr\":\"00oc-001p\",\"publicDT\":null,\"note\":null,\"displayName\":\"IMG_0006\",\"downloadName\":null,\"downloadNameOk\":false,\"uploadFileName\":\"IMG_0006.HEIC\",\"uploadAccountId\":1648,\"size\":2808983,\"description\":null,\"displayDT\":\"2018-03-30T19:14:18\",\"displayEndDT\":null,\"derivedDT\":\"2018-03-30T19:14:18\",\"derivedEndDT\":null,\"derivedCreatedDT\":\"2021-08-07T09:54:19\",\"locnId\":1952,\"timeZoneId\":134,\"view\":null,\"viewProperty\":null,\"imageRatio\":\"0.75\",\"metaToken\":\"1PYOUNDD8T\",\"refArchiveNbr\":null,\"type\":\"type.record.image\",\"thumbStatus\":\"status.generic.ok\",\"thumbURL200\":\"https:\\/\\/stagingcdn.permanent.org\\/00oc-001p.thumb.w200?t=1681458544&Expires=1681458544&Signature=jL6HEDlrJj4zB06lT64JLlWgyBOQykV9Oh9aX8P7i2i5kWCSvKT~nA4q4FJCma0XEtQoIphJ-0GxBj~DqewMS3D9zuCAHghA-n0ImgBCVY7OY13gsfOHpUqR8aKKwIMRJqDJkvkcuIdmNb6qEDzHu~t8NnGMNA9d~uLJ~uVf7yFulmCb4tgYJj1TRN8bGtqsBKi4LFGUbFYJt7vehr-3gPk592Rojr4brQHt8YiIZn3rlBh-cNHkVNXsLovICQWXxcit-JdjIzj2jYZRY9ksCxuNCKfB~V5ynx-aISfPI4bMOm6iyJ9xWMzC2g-4VMN8RMkDy67WqGM9KB8vsFqLcA__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q\",\"thumbURL500\":\"https:\\/\\/stagingcdn.permanent.org\\/00oc-001p.thumb.w500?t=1681458544&Expires=1681458544&Signature=XA3d-87tPu3VnfLhzNHEN1UP7W2SUSK2U-dvn2lIXPe8gkKasiL2Sb0KOT8lZhh9tYbuXiFdU~01xolOUxmfSavvzKwNdBVfas5J3hYlW3mgWt5z0ME7m3tn2~5XvwrPAOAQP2PdWjzkpRa-1bUultbsevwivkrFm1POWaRZO18nkskfaIZDFNpuaJIhhypVlEDs70bOaMKOmx3B5SPahqEVqaLKLUeQVRbXu3hG97MJvRW3-AGXR-K8zij1KYU6MVVTwIxX5h-e-j8P~o7DWqJtbFG78MXLi7m3980LadkYaIfCyqPRUlz3O7Jil~6ubZolaHc0rFh5xi2AkKm0Pg__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q\",\"thumbURL1000\":\"https:\\/\\/stagingcdn.permanent.org\\/00oc-001p.thumb.w1000?t=1681458544&Expires=1681458544&Signature=gKauy1vvFsCrNlk11MqcfzrVJxek2zYW53W971TGCMRK0HIdhMxl5L~-ep9jmPH8KrZorJVWW8druhE8aEOxi7iHnyRnDOu-v6rlFKcJbKMUGfcHzfYcHq0UQYU4B2s1fQZOmjGoBUEEi-EzxJHW1y0rSfmt58E34mWQn2mInWhZ0royNLK5Hr4JPjR2ZuZNf-pvnhPLgZTmgAT5stbxt-3aFUajctl~gOHGFZLSopQ5HiPBAUkDkQ6IFSzVyyNgFvOCaTmiF~6LiRt4yR-AiWIf6HzqbVwKi3-9MtIus0Yy940EIE73wCIWn22PBmrS~8M8bWJeDfqHRACJMjZ2QA__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q\",\"thumbURL2000\":\"https:\\/\\/stagingcdn.permanent.org\\/00oc-001p.thumb.w2000?t=1681458544&Expires=1681458544&Signature=Y2h-ZM6379zNMe5jlGjQR42x1dtfhhptxe2obWvZYPRWzyNxqxviTMz2aihnQNfnHFKSH-LbSsDpRIRw8v1C6Us55lvYeZzNoObj72ZHSq1AIbjZOvYQ6wQSRJKxNaCmIHqMrFI9ffmdDjrJwlf25vpB~MHzSFCGlBk6pTseSAnsNY2qX6UbTNllwW6fjnZ0nBSAU5EShU6ZJTVYZTSXXr7epTNFuolpT5VwxUIA7gXf1UbTMPvc3BmsuEjHGzBMatoqSqjVfbuw2FjhgnsEaymCZE3TaEzJjl36IUz69qaMRDh85l1WV9yyZN8rEVM-KLcQMeK9Er4O-n334OMhbw__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q\",\"thumbDT\":\"2023-04-14T07:49:04\",\"fileStatus\":\"status.generic.ok\",\"status\":\"status.generic.ok\",\"processedDT\":\"2022-01-17T15:16:55\",\"FolderLinkVOs\":[{\"folder_linkId\":111145,\"archiveId\":1858,\"folderId\":null,\"recordId\":67934,\"parentFolder_linkId\":109517,\"parentFolderId\":43324,\"position\":1,\"linkCount\":1,\"accessRole\":\"access.role.owner\",\"type\":\"type.folder_link.private\",\"status\":\"status.generic.ok\",\"shareDT\":null,\"createdDT\":\"2022-01-17T15:16:40\",\"updatedDT\":\"2022-01-17T15:16:40\"}],\"folder_linkId\":111145,\"parentFolderId\":43324,\"position\":1,\"accessRole\":\"access.role.owner\",\"folderArchiveId\":1858,\"folder_linkType\":\"type.folder_link.private\",\"pathAsFolder_linkId\":null,\"pathAsText\":null,\"parentFolder_linkId\":109517,\"ParentFolderVOs\":[{\"folderId\":43324,\"archiveNbr\":\"00oc-0008\",\"archiveId\":1858,\"displayName\":\"My Files\",\"downloadName\":null,\"downloadNameOk\":false,\"displayDT\":\"2009-10-09T19:09:20\",\"displayEndDT\":\"2022-11-24T09:41:59\",\"derivedDT\":\"2009-10-09T19:09:20\",\"derivedEndDT\":\"2022-11-24T09:41:59\",\"note\":null,\"description\":\"pages.private.description\",\"special\":null,\"sort\":\"sort.alphabetical_asc\",\"locnId\":null,\"timeZoneId\":88,\"view\":\"folder.view.grid\",\"viewProperty\":null,\"thumbArchiveNbr\":null,\"imageRatio\":\"1.00\",\"type\":\"type.folder.root.private\",\"thumbStatus\":\"status.generic.ok\",\"thumbURL200\":\"https:\\/\\/stagingcdn.permanent.org\\/00oc-0008.thumb.w200?t=1681458543&Expires=1681458543&Signature=RZXTpu8QePtaDzVvFMQsksxMQmhyd-ACEuaYyAfLQfWx0i0eobhYgH8Z3DLJbYkUYLH0yoaIcm466vwWBgqyysK9DftLS8B1RAnqkRWhHww8JTCdlCsjie8WGz0XjxmTTeIoRd3pu7oXa66vH0JLIVOH-p-r5TsOuRTwPTRnjazA97ae30lQ2Qd8ucHlv5T7AVc6z9KB1f3sDM1pF5pj3cC7VzAJKoKdKi9OOo1QSUrhciKcm2~~~o-gwSG3ZS68cicC86DbhRgjYqKgubElB1aVqjcPeeee2ueF8lk2Q5csxPgdLKCYeMHgJOYVLamRZ95LXE5MD6-eqJAQXA7T4A__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q\",\"thumbURL500\":\"https:\\/\\/stagingcdn.permanent.org\\/00oc-0008.thumb.w500?t=1681458543&Expires=1681458543&Signature=YRpSjyvXt5VAsR4Za1u8AjI56KEpbTznzacDlPDLYWAKVjtzwwVQt1jMsNto9S0JvYT8ojzN-0Ut7siT8cXIJcadZ0U7l-emPnCqCwAd8QQo-MknmH1E9X1CQkraE6oM0kfxlSMuABRe16kjDGGTYX0FPrDm63B9Izusf~H-GFu9xxMr-HIuzS6FK3TgPJoVmEsefk2GuFXSLFLfyX0g26v0En3FHvSW-cUzPmDcjWYrRRfX3TcNAa5AUICJsBPaRuTmcviTzkBg0hD00O1z5TeeebgOhbv8ZQT-pdWj05tgOTzF21Gfj6s81VKOHWSSld05XOQ8aL8O2rnHHAO5Wg__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q\",\"thumbURL1000\":\"https:\\/\\/stagingcdn.permanent.org\\/00oc-0008.thumb.w1000?t=1681458543&Expires=1681458543&Signature=DYip6l~ktASJflYjCeo0472mDfzqRYePczvSo3hK~EAo27DDaiSsm8BklvV8oE10rR9-YKutHYtrFiiFCNZdhcAuTTisPgEJD80jZ~BbtOhl5WF1V1ZBRIEGWjYDnQgGGEPM9~uuB8PGnKu2ZzpqsRC3vAtVeZydSdrh40YWdjypoOKltEr3GETOiGwB1zgoC~bRssEmTNmqm6yuKSrBeh~9aeeQQyqROXeAYL0OgkkbNJTO~2dhSwxHmI8MdUoK4lGVRsb6THoU0j0Zk8YwAt7VLEs~EW9JhRZwxbnnr-PsteZQb--z2jq8UTEYMjUfdOmLNuD36B0PR-SOSl~DPA__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q\",\"thumbURL2000\":\"https:\\/\\/stagingcdn.permanent.org\\/00oc-0008.thumb.w2000?t=1681458543&Expires=1681458543&Signature=bjzl8oPfyvPLDPfNMVPO1ZtiYRG1kwKdMsEPQBNooYDrs4EEJ9VdOzlDZfHl1oTCy4~9kNU5QwMQ8J4AOlFh09qtKtCTsuwdDiexO5rtZ72IMAKVeqC5wDJxPDlNEhsXYhFF42~4rkGfYmth7HTuDMPHS5LycCR1sDDNl~p6CAvuZRSTufM-k4DqbFmKgi8jTltuxZxNhXrPHfu0N~ygwzinMdFfvq8Q2~F1hnqfAfjVUYPmKEzdzlvxmyDNqPUmbf-W29C6Kwn9CvEFWZb0KElnW-NbsgLttjso9AtkCKh7jtkMGrJPtTocS84iwIPkNt8Vqo9KX8R1zv2ZecbXsw__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q\",\"thumbDT\":\"2023-04-14T07:49:03\",\"status\":\"status.generic.ok\",\"publicDT\":null,\"parentFolderId\":43322,\"folder_linkType\":\"type.folder_link.root.private\",\"FolderLinkVOs\":[{\"folder_linkId\":109517,\"archiveId\":1858,\"folderId\":43324,\"recordId\":null,\"parentFolder_linkId\":109515,\"parentFolderId\":43322,\"position\":1,\"linkCount\":1,\"accessRole\":\"access.role.owner\",\"type\":\"type.folder_link.root.private\",\"status\":\"status.generic.ok\",\"shareDT\":null,\"createdDT\":\"2021-08-27T08:49:20\",\"updatedDT\":\"2021-08-27T08:49:20\"}],\"accessRole\":\"access.role.owner\",\"position\":1,\"shareDT\":null,\"pathAsFolder_linkId\":null,\"pathAsText\":[],\"folder_linkId\":109517,\"parentFolder_linkId\":109515,\"ParentFolderVOs\":[],\"parentArchiveNbr\":null,\"parentDisplayName\":null,\"pathAsArchiveNbr\":[],\"ChildFolderVOs\":[],\"RecordVOs\":[],\"LocnVO\":null,\"TimezoneVO\":{\"timeZoneId\":88,\"displayName\":\"Central Time\",\"timeZonePlace\":\"America\\/Chicago\",\"stdName\":\"Central Standard Time\",\"stdAbbrev\":\"CST\",\"stdOffset\":\"-06:00\",\"dstName\":\"Central Daylight Time\",\"dstAbbrev\":\"CDT\",\"dstOffset\":\"-05:00\",\"countryCode\":\"US\",\"country\":\"United States\",\"status\":\"status.timezone.ok\",\"type\":\"type.generic.placeholder\",\"createdDT\":\"2017-05-26T00:00:00\",\"updatedDT\":\"2017-05-26T00:00:00\"},\"TagVOs\":[],\"SharedArchiveVOs\":[],\"FolderSizeVO\":null,\"ChildItemVOs\":[],\"ShareVOs\":[],\"AccessVO\":null,\"AccessVOs\":null,\"archiveArchiveNbr\":\"00oc-0000\",\"returnDataSize\":null,\"posStart\":null,\"posLimit\":null,\"searchScore\":null,\"createdDT\":\"2021-08-27T08:49:20\",\"updatedDT\":\"2022-11-24T09:42:58\"}],\"parentArchiveNbr\":null,\"parentDisplayName\":null,\"pathAsArchiveNbr\":null,\"LocnVO\":{\"locnId\":1952,\"displayName\":null,\"geoCodeLookup\":\"\",\"streetNumber\":\"1398\",\"streetName\":\"Great Highway\",\"postalCode\":\"94122\",\"locality\":\"San Francisco\",\"adminOneName\":\"California\",\"adminOneCode\":\"CA\",\"adminTwoName\":\"San Francisco County\",\"adminTwoCode\":\"San Francisco County\",\"country\":\"United States\",\"countryCode\":\"US\",\"geometryType\":\"Point\",\"latitude\":37.760246,\"longitude\":-122.50959,\"boundSouth\":37.760147,\"boundWest\":-122.509651,\"boundNorth\":37.760342,\"boundEast\":-122.509529,\"geometryAsArray\":\"[-122.5095867,37.7602459]\",\"geoCodeType\":\"Feature\",\"geoCodeResponseAsXml\":\"{\\\"type\\\":\\\"Feature\\\",\\\"geometry\\\":{\\\"type\\\":\\\"Point\\\",\\\"coordinates\\\":[-122.5095867,37.7602459]},\\\"properties\\\":{\\\"providedBy\\\":\\\"google_maps\\\",\\\"streetNumber\\\":\\\"1398\\\",\\\"streetName\\\":\\\"Great Highway\\\",\\\"postalCode\\\":\\\"94122\\\",\\\"locality\\\":\\\"San Francisco\\\",\\\"adminLevels\\\":{\\\"1\\\":{\\\"name\\\":\\\"California\\\",\\\"code\\\":\\\"CA\\\",\\\"level\\\":1},\\\"2\\\":{\\\"name\\\":\\\"San Francisco County\\\",\\\"code\\\":\\\"San Francisco County\\\",\\\"level\\\":2}},\\\"country\\\":\\\"United States\\\",\\\"countryCode\\\":\\\"US\\\"},\\\"bounds\\\":{\\\"south\\\":37.7601465,\\\"west\\\":-122.5096496,\\\"north\\\":37.7603408,\\\"east\\\":-122.5095303}}\",\"timeZoneId\":134,\"status\":\"status.generic.ok\",\"type\":\"type.locn.coord\",\"createdDT\":\"2021-06-16T12:36:00\",\"updatedDT\":\"2021-06-16T12:36:00\"},\"TimezoneVO\":{\"timeZoneId\":134,\"displayName\":\"Pacific Time\",\"timeZonePlace\":\"America\\/Los_Angeles\",\"stdName\":\"Pacific Standard Time\",\"stdAbbrev\":\"PST\",\"stdOffset\":\"-08:00\",\"dstName\":\"Pacific Daylight Time\",\"dstAbbrev\":\"PDT\",\"dstOffset\":\"-07:00\",\"countryCode\":\"US\",\"country\":\"United States\",\"status\":\"status.timezone.ok\",\"type\":\"type.generic.placeholder\",\"createdDT\":\"2017-05-26T00:00:00\",\"updatedDT\":\"2017-05-26T00:00:00\"},\"FileVOs\":[{\"fileId\":1278512,\"size\":2808983,\"format\":\"file.format.original\",\"parentFileId\":null,\"contentType\":\"image\\/heic\",\"contentVersion\":\"1.0\",\"s3Version\":null,\"s3VersionId\":\"\",\"md5Checksum\":\"24fe87a508407a3ca5f19e81b7835f01\",\"cloud1\":\"permanent-staging\",\"cloud2\":\"permanent-staging\",\"cloud3\":\"perm-b2-staging\",\"archiveId\":1858,\"height\":null,\"width\":null,\"durationInSecs\":null,\"fileURL\":\"https:\\/\\/stagingcdn.permanent.org\\/1278512?t=1684827604&Expires=1684827604&Signature=MknZ4Bj5MHrrT1aYIU7LOr026lliECZ0cLJUVFQsXeCruawmcn1DR4XThOLeOmYLfotkfRL-vrvtHKN5OXyaxRrTprh~na65-XDnDYchRWvCRUd3VXpV8gdxJiSBKMzG~dWeudcYSZmMs4GZmzxx--GsNIBfk4N0WPsPvW7~UoFrSehfpl2kSvK37OxAbn~wIz0kVKZRM27LR~0KzT1l4inbMoNYg6JD2gRCoz5kv8g9SPY2sU72lCYXymCbRWh5kok7eWDfwE0SFUZp4rsmnTHejI2AMCF7n9Nh9AWt30s0NJbXFMkadP5PnHEh0HVQDu1DgIGVRKIwVr6tmKGoVQ__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q\",\"downloadURL\":\"https:\\/\\/stagingcdn.permanent.org\\/1278512?t=1684827604&response-content-disposition=attachment%3B+filename%3DIMG_0006.HEIC&Expires=1684827604&Signature=LkROUZ4qPP6ohuDJFwz47ovyXGFs5feD~b7KANNnQwXXY8E2VqXf9iG3wRjCwkhYEQ82Q615fQ1GONJ7lgVsY~AMTo~ulKlPi5UsMAK5PlSj0nQ8vETzkdTh7FxY3xngpUQwQ~6mGWUtz3a-j5Mhgvq9hlXFT3SXM04OS0eDZPbwV94GJMSHuKBxl3sF93IZnXusfRkfNw5FlK5jJmwkE9K3bRD21xU2HTTj7HG8i9PpYhhsvYT2V72pE0fKVQ3pBgqkhP6JZ9dcN7MZUHavH3g0cY-zBrdPwPVfVoaCLqRdW4R0SMU3xAUSKrOwSOXHRyEfGvL8rNYBM5G-PUqQ3g__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q\",\"urlDT\":\"2023-05-23T08:40:04\",\"status\":\"status.generic.ok\",\"type\":\"type.file.image.heic\",\"createdDT\":\"2022-01-17T15:16:40\",\"updatedDT\":\"2022-11-23T08:40:04\"},{\"fileId\":1278513,\"size\":4718504,\"format\":\"file.format.converted\",\"parentFileId\":1278512,\"contentType\":\"image\\/jpeg\",\"contentVersion\":\"1.0\",\"s3Version\":null,\"s3VersionId\":\"\",\"md5Checksum\":\"ddb1c07ea632a264af19a9a89e74d09d\",\"cloud1\":\"permanent-staging\",\"cloud2\":\"permanent-staging\",\"cloud3\":null,\"archiveId\":1858,\"height\":3024,\"width\":4032,\"durationInSecs\":null,\"fileURL\":\"https:\\/\\/stagingcdn.permanent.org\\/1278513?t=1684827604&Expires=1684827604&Signature=IfX1hkMeoeOXzQSh6KnVTJzxJcCVYvjE3z55G4NXNG67fvtK~8nnLyNbJA9D12uocZjzEZI7UcgV1C-OC8-u6FBqT8HBln9ydh7wwdorbQ74z9dpzLApGTN7Dys6tY~OhmTP3gZds6DsIsbnIbklUMUhYbY91ad-5sweg2Dvvjv4zXazt5hJoz6il4qnz51hIzsxEq38W17UT~xKN~Jkj5RCEXbrvoFpdF-BrEZ~M~d19VIISl7ljEcR4kmrz942ywtwHzGwkrJD~pCw6Gj~sEc-kDOsczIcpbL5FCCl5eldBaIlJurWBBW4wingZg3Q5e0imlNKPYdGEzFpupBO3g__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q\",\"downloadURL\":\"https:\\/\\/stagingcdn.permanent.org\\/1278513?t=1684827604&response-content-disposition=attachment%3B+filename%3DIMG_0006.HEIC&Expires=1684827604&Signature=Q8CQdk6UttfrV4FMJZDw7AK9Xu2ffb8goNzUxgtzrhp7nH-mvInQgXOaygOkXhuH8tfrLN6SVM6dEz4FD2aW5fth0dIDGroqnyKdh~fOQp~z3q1Vr2d8DdajRLbp4WSslRAV3mBpzP8WZnkVNe8D6tPHwj1wG1MLI4Bt74IrMp1VTS7h3Bn8tXWCl8SS8-LKoo2s1M4Tv9nOGzYURBjlCDC3o7C7UDQtr0mc4-UjvchieRU6miMtirKwm2eUE~cof2kjY9JuzhGn~DqBL15YZ1w2NImCOQSTHJVRFDOxpaTePS7b3Kj-~LM4BfR8MNqfBS0rltprY8EyXNF8NqLIMA__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q\",\"urlDT\":\"2023-05-23T08:40:04\",\"status\":\"status.generic.ok\",\"type\":\"type.file.image.jpg\",\"createdDT\":\"2022-01-17T15:16:53\",\"updatedDT\":\"2022-11-23T08:40:04\"}],\"TagVOs\":[],\"TextDataVOs\":[],\"ArchiveVOs\":[],\"saveAs\":null,\"uploadUri\":null,\"fileDurationInSecs\":null,\"RecordExifVO\":{\"record_exifId\":28339,\"recordId\":67934,\"height\":3024,\"width\":4032,\"shutterSpeed\":7.704,\"focalLength\":6,\"aperture\":2.526,\"fNumber\":\"2.4\",\"exposure\":0.005,\"iso\":16,\"brightness\":8.455,\"flash\":\"No Flash\",\"whiteBalance\":0,\"xdpi\":72,\"ydpi\":72,\"createdDT\":\"2022-01-17T15:16:42\",\"updatedDT\":\"2022-01-17T15:16:42\"},\"ShareVOs\":[{\"shareId\":1874,\"folder_linkId\":111145,\"archiveId\":1850,\"accessRole\":\"access.role.curator\",\"type\":\"type.share.record\",\"status\":\"status.generic.pending\",\"requestToken\":\"633442b551a7f216c8fba68206dba953b9a1ca31e1d4ccea2b74d6ed9ca87ab5\",\"previewToggle\":null,\"FolderVO\":null,\"RecordVO\":null,\"ArchiveVO\":{\"ChildFolderVOs\":[],\"FolderSizeVOs\":[],\"RecordVOs\":[],\"accessRole\":null,\"fullName\":\"iOS Current Sprint\",\"spaceTotal\":null,\"spaceLeft\":null,\"fileTotal\":null,\"fileLeft\":null,\"relationType\":null,\"homeCity\":null,\"homeState\":null,\"homeCountry\":null,\"ItemVOs\":[],\"birthDay\":null,\"company\":null,\"description\":null,\"archiveId\":1850,\"publicDT\":\"2021-08-26T10:24:59\",\"archiveNbr\":\"00o4-0000\",\"public\":0,\"allowPublicDownload\":true,\"view\":null,\"viewProperty\":null,\"thumbArchiveNbr\":null,\"imageRatio\":\"1.00\",\"type\":\"type.archive.person\",\"thumbStatus\":\"status.generic.ok\",\"thumbURL200\":\"https:\\/\\/stagingcdn.permanent.org\\/00o4-0000.thumb.w200?t=1696591376&Expires=1696591376&Signature=SM6oc8lqCW8HPxearLN4VKf1j5EPnD6I2yVwRRaOVaPR~8xTdRgVh6VtQ4u3pUEpvNOM2tooF9GdJF488tpLTNss41f8IT7oIFofnaz5QVdPu6N3tLDmY7montidiEQ3TMokaf2Oi5DmdNiyDuXaITbCmfQkHs8KHqRFZFQSHlggsPJlowjJ-dEeTJcVtl7BthmXScNFrvK1DqeAQ9xWnxJf8bQkBlhDOjpB-DiOrJGXAS5TuuZ8qxnY2S6zAqwwqFqXrmufe2t8RtEKGW~6PqndqMoh-cKfJIbf5ONYP6iSNzZtsCaeKsHqXicrnswmmG1A0aNOdpiuuZ10gFl1oA__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q\",\"thumbURL500\":\"https:\\/\\/stagingcdn.permanent.org\\/00o4-0000.thumb.w500?t=1696591376&Expires=1696591376&Signature=LlheC9Ge2IorvVBjvyD6Qc5gTGr-jiYnZ8gpyLNysrbw77RnIyu5mkqqoYe-X5RcFpMVISX1XJovQTYTXgYfy46J7vPU~A0UCa1RKNre8Wc5or39gR9SQFehg-ujVenjx38SSjQr9ntm2ulkrb1UYUu59xcvg~YA82-JPZlKWQ6B37-s5RoiYcSH~Q2q-aTJRWPO66vdNhZmWSAeoC3FgDdVyNqUazU42pO2hdIdI7PP7PArHkM-14mhahQyLLH8Q4Jr7tK7g57ZpGf~b9leLOV9ZTvsZykTLr22w4DnxihT6JSJ87MtRvkXm6jrHUoY4S56GrXBzDPMDf4bytB1Gw__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q\",\"thumbURL1000\":\"https:\\/\\/stagingcdn.permanent.org\\/00o4-0000.thumb.w1000?t=1696591376&Expires=1696591376&Signature=kE2DvuiWo9paeFf0uGkc6~D3EgsKIGc9ZDRxIzKIUpfEn0ryoykeXyVNgI81~ULCtgw9QsUYFm1pE3enXZ7wFPrLV9v-wQITdaeKUUCEJezVgnqjYgg1l7lVCPEP4jCGQeYNno7RyZaGz9m~4PtCPrM3cb~IO4-24jJtgDkRMLHaTOgkTqc2FoCxzCZT688FgiyG~KDOs5MpesCSKD~VsSFagStfmlZk2G0dawSf64nmkf4AQGeSHoD0q~78zCiUJO78gwxcPmyiBJSpZHHHgGL4dhY3tOqePv3~JQCzrfSINqQBsd-2lyFDOOK0vmnlSS5MiCXOtcz7YWU8B-eWXA__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q\",\"thumbURL2000\":\"https:\\/\\/stagingcdn.permanent.org\\/00o4-0000.thumb.w2000?t=1696591376&Expires=1696591376&Signature=JQ3GV0iFDXrDe81~FQX~XyzY8gH1hj4ON8eq5lvua1sa6WxGCqgJpxWQ8afHH7wQwBKP940iQQlb~jJWRtmT~~DqYjFRjUPkZ-2l429ufq43yg-wOepnLH-SGNwwJlunBzjUvFTql4gXGtQhYmBsxSl5VxDjhflyJwR8DXEk3UuEfsBwlTr0ptcrCxSyV145t7eLldMSa2~ZJpovg-RYNJkr502xwtZmNBDNY4EG9RQs4TL2dFWA9wuKBpQzpe1Zyn6FZfibnVnWHfkANYJV4SiTcx0diMdS-Oe4fuGGq9z5cu0J~kgS0njuFmjTCCPrwOWLnIvJLff8S3-0uCaDXA__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q\",\"thumbDT\":\"2023-10-06T11:22:56\",\"status\":\"status.generic.ok\",\"createdDT\":\"2021-08-26T10:24:59\",\"updatedDT\":\"2022-10-06T11:22:56\"},\"AccountVO\":null,\"createdDT\":\"2022-11-25T16:51:50\",\"updatedDT\":\"2022-12-07T10:35:34\"},{\"shareId\":1876,\"folder_linkId\":111145,\"archiveId\":1856,\"accessRole\":\"access.role.contributor\",\"type\":\"type.share.record\",\"status\":\"status.generic.ok\",\"requestToken\":null,\"previewToggle\":null,\"FolderVO\":null,\"RecordVO\":null,\"ArchiveVO\":{\"ChildFolderVOs\":[],\"FolderSizeVOs\":[],\"RecordVOs\":[],\"accessRole\":null,\"fullName\":\"Demo\",\"spaceTotal\":null,\"spaceLeft\":null,\"fileTotal\":null,\"fileLeft\":null,\"relationType\":null,\"homeCity\":null,\"homeState\":null,\"homeCountry\":null,\"ItemVOs\":[],\"birthDay\":null,\"company\":null,\"description\":null,\"archiveId\":1856,\"publicDT\":\"2021-08-26T14:21:47\",\"archiveNbr\":\"00oa-0000\",\"public\":0,\"allowPublicDownload\":true,\"view\":null,\"viewProperty\":null,\"thumbArchiveNbr\":null,\"imageRatio\":\"1.00\",\"type\":\"type.archive.family\",\"thumbStatus\":\"status.generic.ok\",\"thumbURL200\":\"https:\\/\\/stagingcdn.permanent.org\\/00oa-0000.thumb.w200?t=1696591376&Expires=1696591376&Signature=CnMATBUKtUeK03Li5UKu6~JErMtNkwokpQhwLd150QJn6GQmI36gRccswrDdtU9Nt0BPl9Rqd59ztVdYqDq5~DBXSrye6vJOdh-XiHRfOa~v7zRFJ0JQN1bDvThYpfNvh3iR-jj5yGZykpbeI6Uj8BnneL-07OzzBnS3XnIR2CLa4p4vTwaNZhpD4vxfFZN1k1W7Hrj68qxKpTAOsO28lHoC~yiZxb9OIpTGikoY3~LQsfpFq9QaoaMySuhPVUVrmj57kqUEOPv2uYqdTqL5-VGpsYCCxhlzEQVa6wt1OgcSKMIwg67uUWzhfQ2lZzsFyNNTQetHyuBG~hAF7CUGAQ__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q\",\"thumbURL500\":\"https:\\/\\/stagingcdn.permanent.org\\/00oa-0000.thumb.w500?t=1696591376&Expires=1696591376&Signature=DzcMfu~r~W1e9v8M0~HXMqQoM3cldW7gAtIpVuynVDC2d-ieGzdi2Je65Nfk3QUDmWLfK3zXaTilmQmwiVK-CXK-yZ7IkV6g75x443MbGI3d1AzLdWGw3Wg705OQx5mTXc8IaYv0QsZBzVFnHW4vwjAefmnTfP5LM15MFy30~PjnLDx7gfFsPVGnYjXgw5~7T70pvY2keZ1G1WtjScx7V-RmdI6c0rpczYjdoMlyU6e0oqrq6ss18BGcFwsT0H9np2p~HuFJCdqXif-qBWUlV5bZytTJ1kz4y0zFH5583Hyo14n9wUS9bMrqJQFY1nYPjNyQMFStiFNlctPGfUiGMw__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q\",\"thumbURL1000\":\"https:\\/\\/stagingcdn.permanent.org\\/00oa-0000.thumb.w1000?t=1696591376&Expires=1696591376&Signature=HcxJVzlGuTYBIkAfNrsLoHOFBvf3jhXgrX6iR2Pn9zJ0NhjSh6JdxqNXziJkZCYDmLFfXy~Fs~~xqQoU9ORnsjiWA-iHkWpBDplTd3fxVUm7yMdhnemrx6FBzGbWs0gwiy-uEmRh3cGIHh0C8Im470nUBs42vP3JInm43MUBEsSD3OSsys9vSazQymls8bvsep2~x1lKQ2~TZNHpqhWecNxvCUjzElFf-JpNKWcaDkHjiE5z2lb-vODyuBFmfY2KEMhkAae6~lQKbv-YFVt1PlVb9~eLNE0-c3-X-AQ8XGXfZ4uTA0B0v-ml0NcP7JoySR9BK1SLArflWVoSMoCAlg__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q\",\"thumbURL2000\":\"https:\\/\\/stagingcdn.permanent.org\\/00oa-0000.thumb.w2000?t=1696591376&Expires=1696591376&Signature=RCCt5oqQy8l866aAquCy-7Z5ESsa~r-4l1zUjWvAbHqYoshrJm2NuNzFfQHDmuA6WP9-mDr4g-Pc9KjUhZLn7hQ7-kM49-O4Wj0UU8QHD3TX-ovx16DH0-qLd7TQW82fD5RKctqvSH~ieUTd8vIGIf~5vhU9aKYk2YOVVJ95nKVZ8~8uYkdtlpW5sBG3fNs-1yASG9X8ikbGhB9loqzD0S~WG3Ehx2aa6WLgapch-yp2IQZz2UcgO93AKGYbuUbnnwH-5oViVqdyngouNJ7Mk7azWPAprOxNZ8f5n5pTvkgPrWDJiRimmZ05xhvkxEeKt3iYowziJWIuFDi-PeqAPQ__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q\",\"thumbDT\":\"2023-10-06T11:22:56\",\"status\":\"status.generic.ok\",\"createdDT\":\"2021-08-26T14:21:47\",\"updatedDT\":\"2022-10-06T11:22:56\"},\"AccountVO\":null,\"createdDT\":\"2022-11-30T12:35:11\",\"updatedDT\":\"2022-11-30T12:35:11\"}],\"AccessVO\":null,\"searchScore\":null,\"archiveArchiveNbr\":\"00oc-0000\",\"createdDT\":\"2022-01-17T15:16:40\",\"updatedDT\":\"2022-10-14T07:49:04\"}}],\"message\":[\"RecordId 67934 has been retrieved.\"],\"status\":true,\"resultDT\":\"2022-12-07T12:13:28\",\"createdDT\":null,\"updatedDT\":null}],\"isSuccessful\":true,\"actionFailKeys\":[],\"isSystemUp\":true,\"systemMessage\":\"Everything is A-OK\",\"csrf\":\"82c96e94642df8fdd3a2d6b5744c1286\",\"createdDT\":null,\"updatedDT\":null}"
        let data = recordJSON.data(using: .utf8)!

        let decoder = JSONDecoder()
        let model: APIResults<RecordVO> = try! decoder.decode(APIResults<RecordVO>.self, from: data)

        return model.results.first!.data!.first!
    }

    func mockFolderVO() -> FolderVO {
        let json = "{\"Results\":[{\"data\":[{\"FolderVO\":{\"folderId\":45017,\"archiveNbr\":\"00oc-00qn\",\"archiveId\":1858,\"displayName\":\"files with owner access\",\"downloadName\":\"files with owner access\",\"downloadNameOk\":true,\"displayDT\":\"2018-03-30T19:14:18\",\"displayEndDT\":\"2022-11-24T09:41:59\",\"derivedDT\":\"2018-03-30T19:14:18\",\"derivedEndDT\":\"2022-11-24T09:41:59\",\"note\":null,\"description\":null,\"special\":null,\"sort\":\"sort.alphabetical_asc\",\"locnId\":null,\"timeZoneId\":88,\"view\":\"folder.view.grid\",\"viewProperty\":null,\"thumbArchiveNbr\":null,\"imageRatio\":\"1.00\",\"type\":\"type.folder.private\",\"thumbStatus\":\"status.generic.ok\",\"thumbURL200\":\"https:\\/\\/stagingcdn.permanent.org\\/00oc-00qn.thumb.w200?t=1684917737&Expires=1684917737&Signature=iY3nl-4QRUCEVqgjVZlLAM8SkbUuKWYHFJKUfo8Kfq2SCZvQKC2xYOqqmyeIGr6mqWYRrSVqnuV1C2aq76QVXC1KRs9opjZNEp-e5CiRdTrWux1isO-naGeTgqpfydiV74-OEUE3CxjPygnDokOPzeW6OOpBjabHbn4mzCGOj1U4t5ABZSb0eyt6UnUFaWIhXMAJDbZR~TmFYLNaH~ZYxjD3~jBkXD8dJxDkexjx8U2cxdQxYeGdLxUlKoqLvVc0CeRQeR1g92qQbTBE4R8RU9jL0Ys-lpBivxL70fzqpsMu4hZ4uC9P2TzPktW8K9~NAlsBS89fD0b5LODPO5zhWA__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q\",\"thumbURL500\":\"https:\\/\\/stagingcdn.permanent.org\\/00oc-00qn.thumb.w500?t=1684917737&Expires=1684917737&Signature=iVmj0TJRKMPDGrYucDh6bj3PjyB83fnk~7FuKaVxxi5XE~k5PMpiO0Jjam9JH~AnWWAq~8q8r15FCk8qv~oPeUkw~l~wtciArYtbJNSkQA4sZ-dn1v-VfTVnao1BasvFpCb-eeXIZQDFW8Os0TOT~Xs~0pWbH-XjEScPeZlX7KXvTLELRVG42T1-YBFePBilm4uFTcZ0tNcbAcQvC0RbW0U2TuRBtm4Za7ORrAd~sh5QWMepkjGfbSMLSMDgz0LaSF9BBka6eLF3CHXS9Q~uZSMs~E8r0W3XrNmTucn5kUzS2C825PUfkIUa2O4r1ZMaHdJ-vt8lFSfv1lpOga9nlQ__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q\",\"thumbURL1000\":\"https:\\/\\/stagingcdn.permanent.org\\/00oc-00qn.thumb.w1000?t=1684917737&Expires=1684917737&Signature=PKgVreDeSqYNv1CllX1A2~3uLU01r6HAQiWBqs93We8YHRSifVITfsTGr2WXFIBnaGaRAhHO5O3tG664p6uQJt9tVFuW0DQsdDvQhqAY-cv3EyNYFxa3YaWrOSm4PJiVkT3lmX8M-7xpTGM7M29FfSNWuJfDk5Fz-qH4b1SjBKFAeTjD2O3yC~p8WU7biNrbQlVhJ6~SwWb2ozRyr3n5mfAK7HSbnHZFcjywqi6eZW9lZyrUikUeIcn404UaGOr2bBiNPmn1dp26L4b9OvMx~YKKNPz7fMYXzTUxAPF0AzZhk~ICT4Qs9IseRsuSuPctqD82AWp9i5TuplDS8PxufA__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q\",\"thumbURL2000\":\"https:\\/\\/stagingcdn.permanent.org\\/00oc-00qn.thumb.w2000?t=1684917737&Expires=1684917737&Signature=jJ9MUebpZwH4pideSEiX4AzaK3LbpVo4IjpckaWiXlftpL8m6ck4U37QylYLrEMse2bKfb673K2Sksvqg0X9yYW4WTjO82sNmmmjK2lIRBGUPvdiCqCjehWV786A7vEub5XtGJZjge3eFq34gOBGS0SXIi~MaObXAx~Llku~iYChqQm-PKHjjF7-CosUU3wdr6Vd1NcAwPND7xeXfIiYft4PtNlv9VZxET1koQ5fmHl2qXlClMrR2ULOBQLmfFxVjt-IgsQMbXBcPp0mOTnFKYteO1lUf7Hb6Bx7qAGOFXS2F3DylvWueNM1lFXVwU2Mz-VuES3NYguX2CcV-f6BXg__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q\",\"thumbDT\":\"2023-05-24T09:42:17\",\"status\":\"status.generic.ok\",\"publicDT\":null,\"parentFolderId\":43324,\"folder_linkType\":\"type.folder_link.private\",\"FolderLinkVOs\":[{\"folder_linkId\":116185,\"archiveId\":1858,\"folderId\":45017,\"recordId\":null,\"parentFolder_linkId\":109517,\"parentFolderId\":43324,\"position\":1,\"linkCount\":1,\"accessRole\":\"access.role.owner\",\"type\":\"type.folder_link.private\",\"status\":\"status.generic.ok\",\"shareDT\":null,\"createdDT\":\"2022-09-09T10:48:06\",\"updatedDT\":\"2022-09-09T10:48:06\"}],\"accessRole\":\"access.role.owner\",\"position\":1,\"shareDT\":null,\"pathAsFolder_linkId\":null,\"pathAsText\":[],\"folder_linkId\":116185,\"parentFolder_linkId\":109517,\"ParentFolderVOs\":[],\"parentArchiveNbr\":null,\"parentDisplayName\":null,\"pathAsArchiveNbr\":[],\"ChildFolderVOs\":[],\"RecordVOs\":[],\"LocnVO\":null,\"TimezoneVO\":{\"timeZoneId\":88,\"displayName\":\"Central Time\",\"timeZonePlace\":\"America\\/Chicago\",\"stdName\":\"Central Standard Time\",\"stdAbbrev\":\"CST\",\"stdOffset\":\"-06:00\",\"dstName\":\"Central Daylight Time\",\"dstAbbrev\":\"CDT\",\"dstOffset\":\"-05:00\",\"countryCode\":\"US\",\"country\":\"United States\",\"status\":\"status.timezone.ok\",\"type\":\"type.generic.placeholder\",\"createdDT\":\"2017-05-26T00:00:00\",\"updatedDT\":\"2017-05-26T00:00:00\"},\"TagVOs\":[],\"SharedArchiveVOs\":[],\"FolderSizeVO\":{\"folder_sizeId\":null,\"folder_linkId\":null,\"archiveId\":null,\"folderId\":null,\"parentFolder_linkId\":null,\"parentFolderId\":null,\"myFileSizeShallow\":0,\"myFileSizeDeep\":0,\"myFolderCountShallow\":0,\"myFolderCountDeep\":0,\"myRecordCountShallow\":0,\"myRecordCountDeep\":0,\"myAudioCountShallow\":0,\"myAudioCountDeep\":0,\"myDocumentCountShallow\":0,\"myDocumentCountDeep\":0,\"myExperienceCountShallow\":0,\"myExperienceCountDeep\":0,\"myImageCountShallow\":0,\"myImageCountDeep\":0,\"myVideoCountShallow\":0,\"myVideoCountDeep\":0,\"allFileSizeShallow\":0,\"allFileSizeDeep\":0,\"allFolderCountShallow\":0,\"allFolderCountDeep\":0,\"allRecordCountShallow\":0,\"allRecordCountDeep\":0,\"allAudioCountShallow\":0,\"allAudioCountDeep\":0,\"allDocumentCountShallow\":0,\"allDocumentCountDeep\":0,\"allExperienceCountShallow\":0,\"allExperienceCountDeep\":0,\"allImageCountShallow\":0,\"allImageCountDeep\":0,\"allVideoCountShallow\":0,\"allVideoCountDeep\":0,\"lastExecuteDT\":null,\"lastExecuteReason\":null,\"nextExecuteDT\":null,\"displayName\":null,\"description\":null,\"type\":null,\"status\":null,\"position\":null,\"recursive\":null,\"createdDT\":null,\"updatedDT\":null},\"ChildItemVOs\":[],\"ShareVOs\":[{\"shareId\":1804,\"folder_linkId\":116185,\"archiveId\":2167,\"accessRole\":\"access.role.owner\",\"type\":\"type.share.folder\",\"status\":\"status.generic.ok\",\"requestToken\":null,\"previewToggle\":null,\"FolderVO\":null,\"RecordVO\":null,\"ArchiveVO\":{\"ChildFolderVOs\":[],\"FolderSizeVOs\":[],\"RecordVOs\":[],\"accessRole\":null,\"fullName\":\"automatic test\",\"spaceTotal\":null,\"spaceLeft\":null,\"fileTotal\":null,\"fileLeft\":null,\"relationType\":null,\"homeCity\":null,\"homeState\":null,\"homeCountry\":null,\"ItemVOs\":[],\"birthDay\":null,\"company\":null,\"description\":null,\"archiveId\":2167,\"publicDT\":\"2022-09-08T10:35:02\",\"archiveNbr\":\"00wx-0000\",\"public\":0,\"allowPublicDownload\":true,\"view\":null,\"viewProperty\":null,\"thumbArchiveNbr\":null,\"imageRatio\":\"1.00\",\"type\":\"type.archive.person\",\"thumbStatus\":\"status.generic.ok\",\"thumbURL200\":\"https:\\/\\/stagingcdn.permanent.org\\/00wx-0000.thumb.w200?t=1694169308&Expires=1694169308&Signature=dkI42Bd13U5IttET950RhwJPaXG1hrVJfes6027DxC1nSjXjV5ZhrlnIpr3y-X4WqEQHYWENKT-S7wW-NI9rjZsGs7ZE7o4xKGyGoWm~KIoiggPcunX3fHO5UyaFkvL0Zg4M7fLOOmRxYdL0~UpfnV6~x-zcaqq4kJ1Rv6RX-2obXRJh9t0UhXJBZ2hvyFrMPy-VhKzi1ahX3PYQIu6CBkQ4ttHrno8ba8a7YlFb0SWe4QnHsVw~j9u6StPcF1nYIL93~R~1BF8R6uUKakj5s-ZKNs~moyQ4X0P-v3W0E~K2lOwGP2KkARAR5CDb-dL6ADi-IwmFIaAo6KrAHhPo-g__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q\",\"thumbURL500\":\"https:\\/\\/stagingcdn.permanent.org\\/00wx-0000.thumb.w500?t=1694169308&Expires=1694169308&Signature=b8ZPhONx~By0qR1mkxi8sM4H-BX84XmUUvpW6~qCWhVKczutH-Kt6ogM4~vrSo6MolvuALJD9Q5I53jY0Q3BbcdzsWJBBfTD61gwTZr5MrGedVpunYr6J7XJCCT0aWKN~tmWrlIkHEo~LpEwE1WM5rpQzl6tgmX3B3KaELUbKPgkzEjngOqt2vDJR9ognwrR2rjSDSl-qlsnrGR9XbI5O2QCaeQ~cjihv9eoXoY~TsscnTo255MQGxtNOyHHI5CAqIKwdB7N5V2RIO8I~i4vRldWeFt0D0RssChK5bGdOqcKvoQ0Ys3xfRBqQlwqtNxr9eCNdcB6tkYXjMpry0Nrhw__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q\",\"thumbURL1000\":\"https:\\/\\/stagingcdn.permanent.org\\/00wx-0000.thumb.w1000?t=1694169308&Expires=1694169308&Signature=ilIGHfQMyAHgfI9LDwyEPEmRBiHNoOcgLoZT3wBjUx1Upp0fCPyo43Ih~J7q20UCLIsx~HAn3sXpPwwKEz1hyhzp1BdGWmdJ094usmxmQ7jXN-CU1HTysrlbZ0QKgotewve-aR3rAa~S6gi6ZOADgBZPGsVzGHA7ZjSnG7VXpidaE-fVU4A4ad5hG5nDtLhiAG~ExetohiN93IKGZ8x0sg1nQXIxz4hYik2bAlqtcV6hIQYOnKA7SO~IdNcv7Ewkpj49VlVIYxgDq-hJ2goPnfgvqk5S76xlq6d0Sr-iGnzzT1EfMM8YA1NER0D~3C-KEYl8VD9GTkP-xcMJSF2ylw__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q\",\"thumbURL2000\":\"https:\\/\\/stagingcdn.permanent.org\\/00wx-0000.thumb.w2000?t=1694169308&Expires=1694169308&Signature=aGL-8~Lk37uuidnAn1nOmg3hUX~KBbMYsoC5mz9dcpkGQuu3zJxsT-9-dX6O9Rkpos0gaaiTMLVzfAkal~1Xt6wCMgiOJfGzL3kCooO71dGB2Io7ce21uk3hDdEfOni4QtNvZOKpM8bNqY0obpmBc63HhJyJlD2tEq79tA-SvGdrYkyifC9v0BOg4r1J6m2tR90-AMcA7qhzcUiTJnFmULPAR44ZhnkVu3dHKeHKr3DXZJ5kVPDpM31x-r5Dt2Ip64vbXl4suqCJbcklL47RinlbMcYa5y-qomEe0vAROglPBltItQalmHD4CxAzl6rE57BpXbnI6sTNL7EP6MZsiQ__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q\",\"thumbDT\":\"2023-09-08T10:35:08\",\"status\":\"status.generic.ok\",\"createdDT\":\"2022-09-08T10:35:02\",\"updatedDT\":\"2022-09-08T10:35:08\"},\"AccountVO\":null,\"createdDT\":\"2022-09-09T10:48:33\",\"updatedDT\":\"2022-09-09T10:48:33\"}],\"AccessVO\":null,\"AccessVOs\":null,\"archiveArchiveNbr\":\"00oc-0000\",\"returnDataSize\":null,\"posStart\":null,\"posLimit\":null,\"searchScore\":null,\"createdDT\":\"2022-09-09T10:48:06\",\"updatedDT\":\"2022-11-24T09:42:58\"}}],\"message\":[\"Folder has been retrieved\"],\"status\":true,\"resultDT\":\"2022-12-07T12:16:25\",\"createdDT\":null,\"updatedDT\":null}],\"isSuccessful\":true,\"actionFailKeys\":[],\"isSystemUp\":true,\"systemMessage\":\"Everything is A-OK\",\"csrf\":\"82c96e94642df8fdd3a2d6b5744c1286\",\"createdDT\":null,\"updatedDT\":null}\n"

        let data = json.data(using: .utf8)!

        let decoder = JSONDecoder()
        let model: APIResults<FolderVO> = try! decoder.decode(APIResults<FolderVO>.self, from: data)

        return model.results.first!.data!.first!
    }

    func getRecord(_ file: FileDownloadInfo, then handler: @escaping GetRecordResponse) {
        handler(mockRecordVO(), nil)
    }

    func getFolder(_ file: FileDownloadInfo, then handler: @escaping GetFolderResponse) {
        handler(mockFolderVO(), nil)
    }
}
