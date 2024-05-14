//
//  CodeEditorRemoveCodeButton.swift
//  datavyu
//
//  Created by Jesse Lingeman on 8/27/23.
//

import SwiftUI

struct CodeEditorRemoveCodeButton: View {
    @ObservedObject var column: ColumnModel

    func removeCode() {
        column.removeArgument()
    }

    var body: some View {
        Button("-", action: removeCode)
    }
}
