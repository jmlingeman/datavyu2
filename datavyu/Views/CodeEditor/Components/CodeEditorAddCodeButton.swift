//
//  CodeEditorAddCodeButton.swift
//  datavyu
//
//  Created by Jesse Lingeman on 7/1/23.
//

import SwiftUI

struct CodeEditorAddCodeButton: View {
    @ObservedObject var column: ColumnModel
    
    func addCode() {
        column.addArgument()
    }
    
    var body: some View {
        Button("+", action: addCode)
    }
}
