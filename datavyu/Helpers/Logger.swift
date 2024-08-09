//
//  Logger.swift
//  datavyu
//
//  Created by Jesse Lingeman on 8/8/24.
//

import Logging

class Logger {
    static let logger = Logging.Logger(label: "Datavyu2")

    static func info(_ messages: Any...) {
        for message in messages {
            logger.info(Logging.Logger.Message(stringLiteral: String(describing: message)))
        }
    }

    static func error(_ messages: Any...) {
        for message in messages {
            logger.error(Logging.Logger.Message(stringLiteral: String(describing: message)))
        }
    }

    static func debug(_ messages: Any...) {
        for message in messages {
            logger.debug(Logging.Logger.Message(stringLiteral: String(describing: message)))
        }
    }
}
