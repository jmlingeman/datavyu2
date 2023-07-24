//
//  OptionsView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 7/2/23.
//

import SwiftUI



struct ColumnNameDialog: View {
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var column: ColumnModel
    
    @FocusState private var focusedField: Bool
    
    
    let config = Config()
    
    var body: some View {
        VStack {
            Text("Enter new column name").font(.system(size: 20)).frame(alignment: .topLeading).padding()
            HStack {
                TextField("Column Name", text: $column.columnName).onSubmit {
                    dismiss()
                }.focused($focusedField, equals: true)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {  /// Anything over 0.5 seems to work
                            self.focusedField = true
                        }
                    }
            }.padding()
            HStack {
                Button("OK") {
                    dismiss()
                }
            }.padding()
        }.padding()
        
    }
}
