//
//  ScriptOutputWindow.swift
//  Datavyu2
//
//  Created by Jesse Lingeman on 6/16/24.
//

import SwiftUI

struct ScriptOutputWindow: View {
    var url: URL
    @ObservedObject var fileModel: FileModel
    @ObservedObject var scriptEngine: RubyScriptEngine

    var body: some View {
        VStack {
            Text("Script Output")
                .font(.headline)
            TextEditor(text: .constant(scriptEngine.stdout))
        }.onAppear {
            scriptEngine.runScript(url: url, fileModel: fileModel)
        }
    }
}
