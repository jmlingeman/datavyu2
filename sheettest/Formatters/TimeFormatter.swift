//
//  TimeFormatter.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import Foundation
import TimecodeKit

extension Timecode.TextFormatter {
    override public func getObjectValue(
        _ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?,
        for string: String,
        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?
    ) -> Bool {
        do {
            print(string)
            obj?.pointee = try string.toTimecode(at: ._29_97) as AnyObject
        } catch {
            print("Error")
        }
        return true
    }
    
    override public func string(for obj: Any?) -> String? {
        if let tc = obj as? Timecode {
            return tc.stringValue
        } else {
            return ""
        }
    }
}
