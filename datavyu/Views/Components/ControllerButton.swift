//
//  ControllerButton.swift
//  datavyu
//
//  Created by Jesse Lingeman on 8/25/23.
//

import SwiftUI

struct ControllerButton: View {
    var buttonName: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(buttonName).font(.system(size: 10))
                .multilineTextAlignment(.center)
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary))
                .aspectRatio(1.5, contentMode: .fit)
                
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 100, height: 80)
    }
}
