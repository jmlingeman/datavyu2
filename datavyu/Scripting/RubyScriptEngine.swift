

import Foundation
import RubyGateway

// https://johnfairh.github.io/RubyGateway/
// https://stackoverflow.com/questions/70560903/swiftui-async-redirect-output-on-view-like-console-output-realtime

class RubyScriptEngine: ObservableObject {
    @Published var stdout: String = ""
    @Published var stderr: String = ""
    var running = false

    public func runScript(url: URL, fileModel _: FileModel) {
        // The script will interface w/ data models thru the REST API
        // so we just need to make sure it loads the correct Datavyu_API.rb
        // and then run the script, dont need anything fancier.
        do {
            running = true
            Ruby.verbose = RbGateway.Verbosity.full
            Ruby.debug = true

            let apiLocation = Bundle.main.url(forResource: "Datavyu_API", withExtension: "rb")!

//            let logArgsSpec = RbMethodArgsSpec(leadingMandatoryCount: 1,
//                                               optionalKeywordValues: ["priority" : 0])
//            try Ruby.defineGlobalFunction("print",
//                                          argsSpec: logArgsSpec) { _, method in
//                self.stdout += String(method.args.mandatory[0])!
//                return .nilObject
//            }

            // Have ruby log stdout and stderr to a file that we'll
            // read in
            let stdoutFilePath = URL(fileURLWithPath: NSTemporaryDirectory() + UUID().uuidString + "_stdout")
            try Ruby.eval(ruby: "$stdout = $stdout.reopen(\"\(stdoutFilePath)\")")

            DispatchQueue.main.async {
                while self.running {
                    do {
//                        stdout = try String(contentsOf: stdoutFilePath, encoding: .utf8)
                    } catch {
                        print(error)
                    }
                }
            }

            try Ruby.eval(ruby: "$LOAD_PATH.unshift(File.expand_path(\"\(apiLocation.deletingLastPathComponent().path().replacingOccurrences(of: "file://", with: ""))\"))")
            try Ruby.load(filename: url.path().replacingOccurrences(of: "file://", with: ""))

        } catch {
            print(error)
        }
    }

    func runCommand(cmd: String, args: String...) -> (output: [String], error: [String], exitCode: Int32) {
        var output: [String] = []
        var error: [String] = []

        let task = Process()
        task.launchPath = cmd
        task.arguments = args

        let outpipe = Pipe()
        task.standardOutput = outpipe
        let errpipe = Pipe()
        task.standardError = errpipe

        task.launch()

        // TODO: Hook up outpipe and errpipe to a screen

        task.waitUntilExit()
        let status = task.terminationStatus

        return (output, error, status)
    }
}
