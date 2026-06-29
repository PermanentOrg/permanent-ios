//
//  RedesignTagMapping.swift
//  Permanent
//
//  Maps the redesigned dashboard's chip labels to the app's existing onboarding
//  tag enums (1:1), so the "What's important to you?" and "Chart your path to
//  success" widgets feed the SAME `AccountEndpoint.addRemoveTags` endpoint the
//  legacy onboarding uses:
//    - "Chart your path"   chips → OnboardingPath          → goal: tags
//    - "What's important"  chips → OnboardingWhatsImportant → why: tags
//

import Foundation

enum RedesignTagMapping {
    /// "Chart your path to success" goal chip → OnboardingPath.
    static func goalPath(forLabel label: String) -> OnboardingPath? {
        switch label {
        case "Publish a legacy":              return .createPublicArchive
        case "Plan my digital legacy":        return .createPlan
        case "Share privately":               return .shareArchive
        case "Preserve memories":             return .capture
        case "Digitize my materials":         return .digitize
        case "Build an archive with someone": return .collaborate
        case "Organize my materials":         return .organize
        default:                              return nil
        }
    }

    /// "What's important to you?" chip → OnboardingWhatsImportant.
    static func whatsImportant(forLabel label: String) -> OnboardingWhatsImportant? {
        switch label {
        case "Digital preservation":   return .interest
        case "Collaboration":          return .collaborate
        case "Family history":         return .preserving
        case "Secure digital storage": return .access
        case "Supporting a nonprofit": return .supporting
        case "Business needs":         return .professional
        default:                       return nil
        }
    }

    /// Goal labels → OnboardingPath cases.
    static func goalPaths(for labels: Set<String>) -> [OnboardingPath] {
        labels.compactMap { goalPath(forLabel: $0) }
    }

    /// Goal labels → goal tag strings (e.g. "publish", "capture").
    static func goalTags(for labels: Set<String>) -> [String] {
        labels.compactMap { goalPath(forLabel: $0)?.tag }
    }

    /// "What's important" labels → OnboardingWhatsImportant cases.
    static func whatsImportant(for labels: Set<String>) -> [OnboardingWhatsImportant] {
        labels.compactMap { whatsImportant(forLabel: $0) }
    }
}
