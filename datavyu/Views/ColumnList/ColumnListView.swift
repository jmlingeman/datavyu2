//
//  OptionsView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 7/2/23.
//

import SwiftUI

struct ColumnListView: View {
    @ObservedObject var sheetModel: SheetModel
    
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedColumns = Set<ColumnModel.ID>()
    let config = Config()
    
    func hideColumns() {
        for colId in selectedColumns {
            let colModel = sheetModel.columns.first(where: {cm in
                cm.id == colId
            })
            if colModel != nil {
                colModel!.setHidden(val: true)
            }
            sheetModel.updates += 1
        }
    }
    
    func showColumns() {
        for colId in selectedColumns {
            let colModel = sheetModel.columns.first(where: {cm in
                cm.id == colId
            })
            if colModel != nil {
                colModel!.setHidden(val: false)
            }
            sheetModel.updates += 1
        }
    }
    
    var body: some View {
        VStack(alignment: .center) {
            Text("Columns").font(.system(size: 30))
                .frame(alignment: .topLeading).padding()
            HStack {
                Table(sheetModel.columns, selection: $selectedColumns) {
                    TableColumn("Column Name", value: \.columnName)
                    TableColumn("Hidden?", value: \.hidden.description)
                }.frame(width: 350, height: 200).padding()
            }.padding()
            HStack {
                Button("Hide Columns") {
                    hideColumns()
                }.padding()
                Button("Show Columns") {
                    showColumns()
                }.padding()
            }
            Button("Close") {
                dismiss()
            }.padding()
        }.padding()
        
        
    }
}
