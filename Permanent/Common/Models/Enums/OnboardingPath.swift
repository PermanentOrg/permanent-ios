//
//  OnboardingPath.swift
//  Permanent
//
//  Created by Lucian Cerbu on 09.05.2024.

import Foundation

enum OnboardingPath: String, CaseIterable, Identifiable {
    var id: String { return self.rawValue }
    
    case capture, digitize, collaborate, createPublicArchive, shareArchive, createPlan, organize, somethingElse = ""
    
    var description: String {
        switch self {
        case .capture:
            return "Capture and preserve memories for storytelling"
        case .digitize:
            return "Digitize or transfer my materials securely"
        case .collaborate:
            return "Collaborate with others to build my archive"
        case .createPublicArchive:
            return "Create a public archive to share a legacy"
        case .shareArchive:
            return "Share my archive with others securely"
        case .createPlan:
            return "Create a plan for passing on my digital materials"
        case .organize:
            return "Organize my materials"
        case .somethingElse:
            return "Something else"
        }
    }
    
    var tag: String {
        switch self {
        case .capture:
            return "capture"
        case .digitize:
            return "digitize"
        case .collaborate:
            return "collaborate"
        case .createPublicArchive:
            return "publish"
        case .shareArchive:
            return "share"
        case .createPlan:
            return "legacy"
        case .organize:
            return "organize"
        case .somethingElse:
            return "undefined"
        }
    }
}
