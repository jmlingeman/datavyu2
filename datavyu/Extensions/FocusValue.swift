//
//  FocusValue.swift
//  Datavyu2
//
//  Created by Jesse Lingeman on 7/14/24.
//

import Foundation
import SwiftUI

extension FocusedValues {
    struct DocumentFocusedValues: FocusedValueKey {
        typealias Value = Binding<FileModel>
    }

    var document: Binding<FileModel>? {
        get {
            self[DocumentFocusedValues.self]
        }
        set {
            self[DocumentFocusedValues.self] = newValue
        }
    }
}
