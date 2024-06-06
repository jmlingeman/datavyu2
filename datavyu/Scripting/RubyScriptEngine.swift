

import Foundation
import RubyGateway

// https://johnfairh.github.io/RubyGateway/

class RubyEngine {
    public func runScript(url: URL, fileModel _: FileModel) {
        // The script will interface w/ data models thru the REST API
        // so we just need to make sure it loads the correct Datavyu_API.rb
        // and then run the script, dont need anything fancier.
        do {
            Ruby.verbose = RbGateway.Verbosity.full
            Ruby.debug = true
            try Ruby.load(filename: "Datavyu_API.rb")
            try Ruby.load(filename: url.absoluteString)

            let result = try Ruby.eval(ruby: "'a' * 4")
            print(result)

        } catch {}
    }
}
