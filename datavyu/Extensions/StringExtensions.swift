//
//  StringExtensions.swift
//  datavyu
//
//  Created by Jesse Lingeman on 7/7/23.
//

import Foundation

extension String {
    func replacingLastOccurrenceOfString(_ searchString: String,
                                         with replacementString: String,
                                         caseInsensitive: Bool = true) -> String
    {
        let options: String.CompareOptions
        if caseInsensitive {
            options = [.backwards, .caseInsensitive]
        } else {
            options = [.backwards]
        }

        if let range = range(of: searchString,
                             options: options,
                             range: nil,
                             locale: nil)
        {
            return replacingCharacters(in: range, with: replacementString)
        }
        return self
    }
}

extension String {
    func matchFirst(_ regex: Regex<Substring>) -> Bool {
        // errors count as "not match"
        (try? regex.firstMatch(in: self)) != nil
    }

    func matches(_ regex: String) -> Bool {
        range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }
}
