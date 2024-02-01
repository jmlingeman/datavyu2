//
//  TimestampTransformer.swift
//  datavyu
//
//  Created by Jesse Lingeman on 1/30/24.
//

import Foundation
import AppKit

class TimestampTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSString.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        print("Transforming \(value)")
        if let timestamp = value as? Int {
            return formatTimestamp(timestamp: timestamp)
        }
        else if let timestamp = value as? Float {
            return formatTimestamp(timestamp: Int(timestamp))
        }
        else if let timestamp = value as? String {
            return timestringToTimestamp(timestring: timestamp)
        }
        else {
            return formatTimestamp(timestamp: 0)
        }
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        if let timestamp = value as? Int {
            return formatTimestamp(timestamp: timestamp)
        }
        else if let timestamp = value as? Float {
            return formatTimestamp(timestamp: Int(timestamp))
        }
        else if let timestamp = value as? String {
            return timestringToTimestamp(timestring: timestamp)
        }
        else {
            return formatTimestamp(timestamp: 0)
        }
    }
}

extension NSValueTransformerName {
    static let classNameTransformerName = NSValueTransformerName(rawValue: "TimestampTransformer")
}

