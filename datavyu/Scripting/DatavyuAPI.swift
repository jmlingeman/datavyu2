//
//  DatavyuAPI.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/6/23.
//

import Leaf
import Vapor

class FileServer: ObservableObject {
    // 1
    var app: Application

    // 2
    let port: Int
    
    init(port: Int) {
        self.port = port
        // 3
        app = Application(.development)
        // 4
        configure(app)
    }
    
    private func configure(_ app: Application) {
        // 1
        app.http.server.configuration.hostname = "127.0.0.1"
        app.http.server.configuration.port = port
        
        // 2
        app.views.use(.leaf)
        // 3
        app.leaf.cache.isEnabled = app.environment.isRelease
        // 4
        app.leaf.configuration.rootDirectory = Bundle.main.bundlePath
        // 5
        app.routes.defaultMaxBodySize = "50MB"
        
    }
    
    func start() {
        // 1
        Task {
            do {
                // 2
                try app.start()
            } catch {
                print("\(error)")
                fatalError(error.localizedDescription)
            }
        }
    }

        
}

