//
//  ControllerButton.swift
//  datavyu
//
//  Created by Jesse Lingeman on 8/25/23.
//

import SwiftUI

struct ControllerButtonLabel: View {
    var buttonName: String

    var body: some View {
        switch buttonName {
        case "Set\nOnset":
            Image(systemName: "arrow.up.backward.bottomtrailing.rectangle")
        case "Set\nOffset":
            Image(systemName: "arrow.up.right.bottomleft.rectangle")
        case "Play":
            Image(systemName: "play")
        case "Stop":
            Image(systemName: "stop")
        case "Shuttle <":
            Image(systemName: "backward")
        case "Shuttle >":
            Image(systemName: "forward")
        case "Pause":
            Image(systemName: "pause")
        case "Prev":
            Image(systemName: "backward.frame")
        case "Next":
            Image(systemName: "forward.frame")
        case "Add\nCell":
            Image(systemName: "plus.rectangle")
        case "Set\nOffset\n+ Add":
            HStack {
                Image(systemName: "arrow.up.right.bottomleft.rectangle")
                Image(systemName: "plus.rectangle")
            }
        case "Jump":
            Image(systemName: "arrowshape.turn.up.backward")
        case "Find":
            Image(systemName: "magnifyingglass")
        default:
            Text(buttonName)
        }
    }
}

struct ControllerButton: View {
    var buttonName: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ControllerButtonLabel(buttonName: buttonName).font(.system(size: 20))
                .multilineTextAlignment(.center)
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary))
                .aspectRatio(1.5, contentMode: .fit)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 100, height: 80)
    }
}
