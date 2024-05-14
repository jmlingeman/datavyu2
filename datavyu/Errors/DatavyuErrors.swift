//
//  DatavyuErrors.swift
//  datavyu
//
//  Created by Jesse Lingeman on 7/7/23.
//

import Foundation

enum DatavyuError: Error {
    // Throw when an invalid password is entered
    case fileError

    // Throw when an expected resource is not found
    case notFound

    // Throw in all other cases
    case unexpected(code: Int)
}
