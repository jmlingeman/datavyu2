

import Foundation
import RubyGateway

// https://johnfairh.github.io/RubyGateway/

class RubyEngine {
    var outPipe = Pipe()
    var errPipe = Pipe()

    public func runScript(url: URL, fileModel _: FileModel) {
        // The script will interface w/ data models thru the REST API
        // so we just need to make sure it loads the correct Datavyu_API.rb
        // and then run the script, dont need anything fancier.
        do {
            Ruby.verbose = RbGateway.Verbosity.full
            Ruby.debug = true

            let apiLocation = Bundle.main.url(forResource: "Datavyu_API", withExtension: "rb")!

            try Ruby.eval(ruby: "$LOAD_PATH.unshift(File.expand_path(\"\(apiLocation.deletingLastPathComponent())\")")
//            try Ruby.load(filename: "Datavyu_API.rb")
            try Ruby.load(filename: url.absoluteString)

            let result = try Ruby.eval(ruby: "'a' * 4")
            print(result)

        } catch {}
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
