//
//  OptionsView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 7/2/23.
//

import SwiftUI

struct OptionsView: View {
    @Environment(\.dismiss) var dismiss

    @AppStorage("colorscheme") private var colorscheme: String = "auto"

    let config = Config()

    var body: some View {
        ScrollView(.vertical) {
            Text("Options").font(.system(size: 30)).frame(alignment: .topLeading).padding()
            HStack {
                Picker(selection: $colorscheme, label: Text("Colorscheme:")) {
                    Text("Match System Setting").tag("auto")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }.padding()
            }.padding()
            Button("Close") {
                dismiss()
            }.padding()
        }
    }
}

struct OptionsView_Previews: PreviewProvider {
    static var previews: some View {
        OptionsView()
    }
}
