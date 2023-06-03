//
//  ContentView.swift
//  sheettest
//
//  Created by Jesse Lingeman on 5/28/23.
//

import SwiftUI
import WrappingHStack
import TimecodeKit

struct ContentView: View {
    var body: some View {
        HStack {
            VideoView()
            ScrollView {
                Sheet()
            }
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}


