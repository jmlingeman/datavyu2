

import Foundation
import RubyGateway

// https://johnfairh.github.io/RubyGateway/
// https://stackoverflow.com/questions/70560903/swiftui-async-redirect-output-on-view-like-console-output-realtime

class RubyScriptEngine: ObservableObject {
    @Published var outputURL: URL? = nil
    @Published var errorURL: URL? = nil

    public func runScript(url: URL, fileModel _: FileModel) {
        // The script will interface w/ data models thru the REST API
        // so we just need to make sure it loads the correct Datavyu_API.rb
        // and then run the script, dont need anything fancier.
        do {
            Ruby.verbose = RbGateway.Verbosity.none
            Ruby.debug = false

            let apiLocation = Bundle.main.url(forResource: "Datavyu_API", withExtension: "rb")!

            // Have ruby log stdout and stderr to a file that we'll
            // read in
            outputURL = URL(fileURLWithPath: NSTemporaryDirectory() + UUID().uuidString + "_stdout")
            errorURL = URL(fileURLWithPath: NSTemporaryDirectory() + UUID().uuidString + "_stderr")
            try Ruby.eval(ruby: "$stdout = $stdout.reopen(\"\(outputURL!.path())\")")
            try Ruby.eval(ruby: "$stderr = $stderr.reopen(\"\(errorURL!.path())\")")

            try Ruby.eval(ruby: "$LOAD_PATH.unshift(File.expand_path(\"\(apiLocation.deletingLastPathComponent().path(percentEncoded: false).replacingOccurrences(of: "file://", with: ""))\"))")
            try Ruby.load(filename: url.path(percentEncoded: false).replacingOccurrences(of: "file://", with: ""))

        } catch {
            Logger.info(error)
        }
    }
}
