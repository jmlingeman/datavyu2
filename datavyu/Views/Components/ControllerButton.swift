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
        case "Point Cell":
            Image(systemName: "plus.circle")
        default:
            Text(buttonName)
        }
    }
}

struct ControllerButtonKeyLabel: View {
    var buttonName: String

    var body: some View {
        switch buttonName {
        case "Set\nOnset":
            Text("7")
        case "Set\nOffset":
            Text("9")
        case "Play":
            Text("8")
        case "Stop":
            Text("5")
        case "Shuttle <":
            Text("4")
        case "Shuttle >":
            Text("6")
        case "Pause":
            Text("2")
        case "Prev":
            Text("1")
        case "Next":
            Text("3")
        case "Add\nCell":
            Image(systemName: "return")
        case "Set\nOffset\n+ Add":
            Text("0")
        case "Jump":
            Text("-")
        case "Find":
            Text("+")
        case "Point Cell":
            Text("/")
        default:
            Text("")
        }
    }
}

struct ControllerButton: View {
    var buttonName: String
    var action: () -> Void
    var numColumns: Int = 1

    var body: some View {
        ZStack {
            ControllerButtonKeyLabel(buttonName: buttonName).offset(x: -20, y: -18)
            Button(action: action) {
                ControllerButtonLabel(buttonName: buttonName).font(.system(size: 20))
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary))
                    .aspectRatio(1.5, contentMode: .fit)
            }
            .buttonStyle(PlainButtonStyle())

        }.frame(width: CGFloat(100 * numColumns), height: 80)
    }
}
