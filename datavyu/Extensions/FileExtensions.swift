//
//  FileExtensions.swift
//  datavyu
//
//  Created by Jesse Lingeman on 5/9/24.
//

import Foundation
import UniformTypeIdentifiers

extension UTType {
    static var opf: UTType {
        UTType(exportedAs: "com.datavyu.opf", conformingTo: .zip)
    }

    static var rscript: UTType {
        UTType(importedAs: "com.R.script")
    }
}
