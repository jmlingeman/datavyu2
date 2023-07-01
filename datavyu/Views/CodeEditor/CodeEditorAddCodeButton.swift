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
        print("adding arg")
        print(column.arguments)
        column.addArgument()
    }
    
    var body: some View {
        Button("+", action: addCode)
    }
}

struct CodeEditorAddCodeButton_Previews: PreviewProvider {
    static var previews: some View {
        let c = ColumnModel(columnName: "test1")
        CodeEditorAddCodeButton(column: c)
    }
}
