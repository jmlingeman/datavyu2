//
//  SwiftUIView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 8/25/23.
//

import SwiftUI

struct ControllerButton: View {
    var buttonName: String
    var action: () -> Void
    var gr: GeometryProxy
    
    var body: some View {
        Button(action: action) {
            Text(buttonName).font(.system(size: 10))
                .multilineTextAlignment(.center)
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary))
                .aspectRatio(1.5, contentMode: .fit)
                .frame(minWidth: gr.size.width/5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
