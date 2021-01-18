// Copyright © 2021 Metabolist. All rights reserved.

import Foundation

extension Locale {
    static let fallbackLanguageCode = "en"

    static var preferred: Locale? {
        guard let identifier = preferredLanguages.first else { return nil }

        return Self(identifier: identifier)
    }

    var languageCodeWithScriptIfNecessary: String? {
        guard let languageCode = languageCode else { return nil }

        if scriptCode == "Hant" {
            return "zh_Hant"
        } else {
            return languageCode
        }
    }

    var languageCodeWithCoercedRegionCodeIfNecessary: String? {
        guard let languageCode = languageCode else { return nil }

        switch languageCode {
        case "es":
            if regionCode == "AR" {
                return "es-AR"
            } else {
                return "es"
            }
        case "pt":
            if regionCode == "PT" {
                return "pt-PT"
            } else {
                return "pt-BR"
            }
        case "zh":
            if let regionCode = regionCode,
               regionCode == "CN" || regionCode == "HK" || regionCode == "TW" {
                return "zh-".appending(regionCode)
            } else if scriptCode == "Hant" {
                return "zh-TW"
            } else {
                return "zh-CN"
            }
        default:
            return languageCode
        }
    }
}
