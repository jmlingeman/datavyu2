//
//  TimeFormatter.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import Foundation
import TimecodeKit

public extension Timecode.TextFormatter {
    override func getObjectValue(
        _ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?,
        for string: String,
        errorDescription _: AutoreleasingUnsafeMutablePointer<NSString?>?
    ) -> Bool {
        do {
            print(string)
            obj?.pointee = try string.toTimecode(at: ._29_97) as AnyObject
        } catch {
            print("Error")
        }
        return true
    }

    override func string(for obj: Any?) -> String? {
        if let tc = obj as? Timecode {
            tc.stringValue
        } else {
            ""
        }
    }
}
