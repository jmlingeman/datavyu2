//
//  TimestampTransformer.swift
//  datavyu
//
//  Created by Jesse Lingeman on 1/30/24.
//

import AppKit
import Foundation

class TimestampFormatter: Formatter {
    override func string(for obj: Any?) -> String? {
        guard let timeInt = obj as? Int else { return nil }
        return formatTimestamp(timestamp: timeInt)
    }

    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription _: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        obj?.pointee = timestringToTimestamp(timestring: string) as AnyObject
        return true
    }
}

class TimestampTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        NSString.self
    }

    override class func allowsReverseTransformation() -> Bool {
        true
    }

    override func transformedValue(_ value: Any?) -> Any? {
        if let timestamp = value as? Int {
            return formatTimestamp(timestamp: timestamp)
        } else if let timestamp = value as? Float {
            return formatTimestamp(timestamp: Int(timestamp))
        } else if let timestamp = value as? String {
            return timestringToTimestamp(timestring: timestamp)
        } else {
            return formatTimestamp(timestamp: 0)
        }
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        if let timestamp = value as? Int {
            return formatTimestamp(timestamp: timestamp)
        } else if let timestamp = value as? Float {
            return formatTimestamp(timestamp: Int(timestamp))
        } else if let timestamp = value as? String {
            return timestringToTimestamp(timestring: timestamp)
        } else {
            return formatTimestamp(timestamp: 0)
        }
    }
}

extension NSValueTransformerName {
    static let classNameTransformerName = NSValueTransformerName(rawValue: "TimestampTransformer")
}
