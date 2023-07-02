//
//  OptionsView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 7/2/23.
//

import SwiftUI

enum ColorOptions {
    case auto
    case light
    case dark
}

struct OptionsView: View {
    @Environment(\.dismiss) var dismiss
    @State var colorscheme: ColorOptions = ColorOptions.auto
    
    var body: some View {
        ScrollView(.vertical) {
            Text("Options").font(.system(size: 30)).frame(alignment: .topLeading).padding()
            HStack {
                Picker(selection: $colorscheme, label: Text("Colorscheme:")) {
                    Text("Match System Setting").tag(ColorOptions.auto)
                    Text("Light").tag(ColorOptions.light)
                    Text("Dark").tag(ColorOptions.dark)
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
