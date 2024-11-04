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
    @State var output: String = ""
    @State var errorOutput: String = ""

    /*
     Filter to remove system logging messages that leak through RubyGateway
     for some reason.
     */
    func filterErrorOutput(_ output: String) -> String {
        let lines = output.components(separatedBy: .newlines)
        var filteredLines: [String] = []
        for line in lines {
            if line.contains("Unable to open mach-O") {
                continue
            }
            if line.contains("flock failed to lock list file") {
                continue
            }
            if line.contains("ViewBridge to RemoteViewService Terminated") {
                continue
            }
            if line.contains("Ruby") {
                filteredLines.append(line)
            }
        }
        return filteredLines.joined(separator: "\n")
    }

    var body: some View {
        let timer = Timer.publish(every: 1.0, on: .current, in: .common).autoconnect()

        VStack {
            Text(url.lastPathComponent)
                .font(.headline)
            VStack(alignment: .trailing) {
                Button("Rerun Script") {
                    scriptEngine.runScript(url: url, fileModel: fileModel)
                }
            }
            Text("Output:")
            TextEditor(text: .constant(output))
            Text("Errors:")
            TextEditor(text: .constant(errorOutput)).foregroundColor(Color.red)
        }.onAppear {
            scriptEngine.runScript(url: url, fileModel: fileModel)
        }.onReceive(timer) { _ in
            if scriptEngine.outputURL != nil {
                do {
                    output = try String(contentsOf: scriptEngine.outputURL!, encoding: .utf8)
                } catch {
                    output = error.localizedDescription
                }
            }

            if scriptEngine.errorURL != nil {
                do {
                    let rawErrorOutput = try String(contentsOf: scriptEngine.errorURL!, encoding: .utf8)
                    errorOutput = filterErrorOutput(rawErrorOutput)
                } catch {
                    errorOutput = error.localizedDescription
                }
            }
        }
    }
}
