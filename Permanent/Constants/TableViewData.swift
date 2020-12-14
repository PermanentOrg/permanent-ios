//  
//  TableViewData.swift
//  Permanent
//
//  Created by Adrian Creteanu on 25.11.2020.
//

import UIKit.UIColor

struct TableViewData {

    static let drawerData: [DrawerSection: [DrawerOption]] = [
        DrawerSection.files: [
            DrawerOption(icon: .folder, title: .myFiles, isSelected: true),
            DrawerOption(icon: .share, title: .shares, isSelected: false),
            DrawerOption(icon: .public, title: .public, isSelected: false)
        ],
        
        DrawerSection.others: [
            DrawerOption(icon: .relationships, title: .relationships, isSelected: false),
            DrawerOption(icon: .group, title: .members, isSelected: false),
            DrawerOption(icon: .power, title: .apps, isSelected: false),
        ]
    ]
    
    static let sharedByMeData: [SharedFileData] = [
        .init(fileName: "Around the world",
              date: "2020-12-10",
              thumbnailURL: "https://stagingcdn.permanent.org/00do-0062.thumb.w200?t=1608117269&Expires=1608117269&Signature=N~hnsJsKD6mdeQnFuBgJEHM32BhtggOUuHw-oMISMjfvvKQJQyq6eAwUTjzixtxXperKHc2Ljr6ZPbIL-ZiikVeuwK9EV7UhNh3UVDV1RRJnnq93hGVFqKZEhqGWo1DXX9kLUDv0QPlCV1HSTuNqUqAhvAjxGqRY-8grscncA9PDEia4cziUP85oriBQDriKeZZQJ28erTGoVqSPTytw9-7SDPnmQ316KQqODM6uGDrJRiSrmgwNpA49b2GXsk4S8Vnv-827TrXHIf-rz8-~JKT8I7srgeEm4jdib9VRIr8K1HOmOzmFXgy3Nq~JlsSjtP8QKySXO3z5C91kq8xnWg__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q",
              archiveThumbnailURL: "https://stagingcdn.permanent.org/00dz-0000.thumb.w200?t=1633421696&Expires=1633421696&Signature=YI~JvL4N5X4CJ3QV3877tkxFxzQ2vwEBDr~AUXJcvQ2NllEl7qgGkcKH6wy8LlZ1dl7L0fW2FPlMRFBwKjxe~3GumOX24T0NVubgw~0rcyCTmfTKDt~vTIEv49dyXk0R9CgGmWpONjpe~2IH0Zjf7fNnAF97~9-bzykNWyo8ktfilJyis-tplzW0--ffUTodr2trcBAJgqxf2Bl1Lsrg03p0mvAbIIr2Iaj35-HEb~m4y0S2UX0cvanWKggtcbxvvmbZn56wmR45lQ6wmjxMKTE0tFSeAuQcwOxvGBbvkb7HozrBMJig1JUbDFM2e4yAmm6hfdHgtoPs4jfKsY5Lkg__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q"),
        
        .init(fileName: "Around the world 2",
              date: "2020-12-15",
              thumbnailURL: "https://stagingcdn.permanent.org/00do-0062.thumb.w200?t=1608117269&Expires=1608117269&Signature=N~hnsJsKD6mdeQnFuBgJEHM32BhtggOUuHw-oMISMjfvvKQJQyq6eAwUTjzixtxXperKHc2Ljr6ZPbIL-ZiikVeuwK9EV7UhNh3UVDV1RRJnnq93hGVFqKZEhqGWo1DXX9kLUDv0QPlCV1HSTuNqUqAhvAjxGqRY-8grscncA9PDEia4cziUP85oriBQDriKeZZQJ28erTGoVqSPTytw9-7SDPnmQ316KQqODM6uGDrJRiSrmgwNpA49b2GXsk4S8Vnv-827TrXHIf-rz8-~JKT8I7srgeEm4jdib9VRIr8K1HOmOzmFXgy3Nq~JlsSjtP8QKySXO3z5C91kq8xnWg__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q",
              archiveThumbnailURL: "https://stagingcdn.permanent.org/00dz-0000.thumb.w200?t=1633421696&Expires=1633421696&Signature=YI~JvL4N5X4CJ3QV3877tkxFxzQ2vwEBDr~AUXJcvQ2NllEl7qgGkcKH6wy8LlZ1dl7L0fW2FPlMRFBwKjxe~3GumOX24T0NVubgw~0rcyCTmfTKDt~vTIEv49dyXk0R9CgGmWpONjpe~2IH0Zjf7fNnAF97~9-bzykNWyo8ktfilJyis-tplzW0--ffUTodr2trcBAJgqxf2Bl1Lsrg03p0mvAbIIr2Iaj35-HEb~m4y0S2UX0cvanWKggtcbxvvmbZn56wmR45lQ6wmjxMKTE0tFSeAuQcwOxvGBbvkb7HozrBMJig1JUbDFM2e4yAmm6hfdHgtoPs4jfKsY5Lkg__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q"),
    ]
    
    static let sharedWithMeData: [SharedFileData] = [
        .init(fileName: "Around the world",
              date: "2020-12-10",
              thumbnailURL: "https://stagingcdn.permanent.org/00do-0062.thumb.w200?t=1608117269&Expires=1608117269&Signature=N~hnsJsKD6mdeQnFuBgJEHM32BhtggOUuHw-oMISMjfvvKQJQyq6eAwUTjzixtxXperKHc2Ljr6ZPbIL-ZiikVeuwK9EV7UhNh3UVDV1RRJnnq93hGVFqKZEhqGWo1DXX9kLUDv0QPlCV1HSTuNqUqAhvAjxGqRY-8grscncA9PDEia4cziUP85oriBQDriKeZZQJ28erTGoVqSPTytw9-7SDPnmQ316KQqODM6uGDrJRiSrmgwNpA49b2GXsk4S8Vnv-827TrXHIf-rz8-~JKT8I7srgeEm4jdib9VRIr8K1HOmOzmFXgy3Nq~JlsSjtP8QKySXO3z5C91kq8xnWg__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q",
              archiveThumbnailURL: "https://stagingcdn.permanent.org/00dz-0000.thumb.w200?t=1633421696&Expires=1633421696&Signature=YI~JvL4N5X4CJ3QV3877tkxFxzQ2vwEBDr~AUXJcvQ2NllEl7qgGkcKH6wy8LlZ1dl7L0fW2FPlMRFBwKjxe~3GumOX24T0NVubgw~0rcyCTmfTKDt~vTIEv49dyXk0R9CgGmWpONjpe~2IH0Zjf7fNnAF97~9-bzykNWyo8ktfilJyis-tplzW0--ffUTodr2trcBAJgqxf2Bl1Lsrg03p0mvAbIIr2Iaj35-HEb~m4y0S2UX0cvanWKggtcbxvvmbZn56wmR45lQ6wmjxMKTE0tFSeAuQcwOxvGBbvkb7HozrBMJig1JUbDFM2e4yAmm6hfdHgtoPs4jfKsY5Lkg__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q"),
        
        .init(fileName: "Around the world 2",
              date: "2020-12-15",
              thumbnailURL: "https://stagingcdn.permanent.org/00do-0062.thumb.w200?t=1608117269&Expires=1608117269&Signature=N~hnsJsKD6mdeQnFuBgJEHM32BhtggOUuHw-oMISMjfvvKQJQyq6eAwUTjzixtxXperKHc2Ljr6ZPbIL-ZiikVeuwK9EV7UhNh3UVDV1RRJnnq93hGVFqKZEhqGWo1DXX9kLUDv0QPlCV1HSTuNqUqAhvAjxGqRY-8grscncA9PDEia4cziUP85oriBQDriKeZZQJ28erTGoVqSPTytw9-7SDPnmQ316KQqODM6uGDrJRiSrmgwNpA49b2GXsk4S8Vnv-827TrXHIf-rz8-~JKT8I7srgeEm4jdib9VRIr8K1HOmOzmFXgy3Nq~JlsSjtP8QKySXO3z5C91kq8xnWg__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q",
              archiveThumbnailURL: "https://stagingcdn.permanent.org/00dz-0000.thumb.w200?t=1633421696&Expires=1633421696&Signature=YI~JvL4N5X4CJ3QV3877tkxFxzQ2vwEBDr~AUXJcvQ2NllEl7qgGkcKH6wy8LlZ1dl7L0fW2FPlMRFBwKjxe~3GumOX24T0NVubgw~0rcyCTmfTKDt~vTIEv49dyXk0R9CgGmWpONjpe~2IH0Zjf7fNnAF97~9-bzykNWyo8ktfilJyis-tplzW0--ffUTodr2trcBAJgqxf2Bl1Lsrg03p0mvAbIIr2Iaj35-HEb~m4y0S2UX0cvanWKggtcbxvvmbZn56wmR45lQ6wmjxMKTE0tFSeAuQcwOxvGBbvkb7HozrBMJig1JUbDFM2e4yAmm6hfdHgtoPs4jfKsY5Lkg__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q"),
        
        .init(fileName: "Around the world 3",
              date: "2020-02-22",
              thumbnailURL: "https://stagingcdn.permanent.org/00do-00i4.thumb.w200?t=1608117269&Expires=1608117269&Signature=JcaSrVA36Me27pMS4406512yAzkgm~zD2kVDUvsPMfg8S6EPp8tZRn-x8VNw8ABJmTG5opAqumYFDkXT~MAYNVRkR80PPtg7ej30avotpkotL~e568tPKtqeihM9P042gY7YozyQk7~S~H2VQ7ZY-S1-q0xX-3HS7dyi7QghMzBH0I~tYE9FPyPNTQDdAtOVCmytNpcF2Dskeg8NTkZhdC4UKbf2XtfG~M0mbji9dK~atX38ihNV-8Ov7DIt1-CZY0Xg-X~Sdzrzb6VmVw2QHeK4fukdAcPPkitUGWzbGKcXOvvSSrZ9xgfkQv06AL~x~DBpaW4GMqN75QjTQD4YxA__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q",
              archiveThumbnailURL: "https://stagingcdn.permanent.org/00dz-0000.thumb.w200?t=1633421696&Expires=1633421696&Signature=YI~JvL4N5X4CJ3QV3877tkxFxzQ2vwEBDr~AUXJcvQ2NllEl7qgGkcKH6wy8LlZ1dl7L0fW2FPlMRFBwKjxe~3GumOX24T0NVubgw~0rcyCTmfTKDt~vTIEv49dyXk0R9CgGmWpONjpe~2IH0Zjf7fNnAF97~9-bzykNWyo8ktfilJyis-tplzW0--ffUTodr2trcBAJgqxf2Bl1Lsrg03p0mvAbIIr2Iaj35-HEb~m4y0S2UX0cvanWKggtcbxvvmbZn56wmR45lQ6wmjxMKTE0tFSeAuQcwOxvGBbvkb7HozrBMJig1JUbDFM2e4yAmm6hfdHgtoPs4jfKsY5Lkg__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q"),
    ]
    
    
}

struct StaticData {
    static let shareLinkButtonsConfig: [(title: String, bgColor: UIColor)] = [
        (.copyLink, .primary),
        (.manageLink, .primary),
        (.revokeLink, .destructive)
    ]
}


struct SharedFileData {
    let fileName: String
    let date: String
    let thumbnailURL: String
    let archiveThumbnailURL: String
}
