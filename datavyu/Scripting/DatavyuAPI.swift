//
//  DatavyuAPI.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/6/23.
//

import Leaf
import Vapor
import SwiftUI

class DatavyuAPIServer {

    var app: Application
    let port: Int
    @ObservedObject var fileModel: FileModel
    
    init(fileModel: FileModel, port: Int) {
        self.port = port
        self.fileModel = fileModel
        self.app = Application(.development)
        configure(app)
    }
    
    private func configure(_ app: Application) {
        // Listen only to localhost, no outside comms
        app.http.server.configuration.hostname = "127.0.0.1"
        app.http.server.configuration.port = port
        app.views.use(.leaf)
        app.leaf.cache.isEnabled = app.environment.isRelease
        app.leaf.configuration.rootDirectory = Bundle.main.bundlePath
        app.routes.defaultMaxBodySize = "50MB"
        
        do {
            try app.register(collection: FileWebRouteCollection(fileModel: fileModel))
        } catch {
            print("\(error)")
        }
    }
    
    func start() {
        // 1
        Task {
            do {
                try app.start()
            } catch {
                print("\(error)")
                fatalError(error.localizedDescription)
            }
        }
    }

        
}

class FileWebRouteCollection: RouteCollection {
    @ObservedObject var fileModel: FileModel
    
    init(fileModel: FileModel) {
        self.fileModel = fileModel
    }
    
    func boot(routes: RoutesBuilder) throws {
        let router = routes.grouped("api")
        router.get("getcolumn", use: getColumn)
        router.post("setcolumn") { req in
            let column = try req.content.decode(ColumnModel.self)
            self.setColumn(column: column)
            return HTTPStatus.ok
        }
    }
    
    func getColumn(req: Request) async throws -> ColumnModel {
        guard let columnName = req.query[String.self, at: "columnName"] else {
            throw Abort(.badRequest)
        }
        for col in fileModel.sheetModel.columns {
            if col.columnName == columnName {
                return col
            }
        }
        return ColumnModel(columnName: "")
    }
    
    func setColumn(column: ColumnModel) {
        DispatchQueue.main.async {
            self.fileModel.sheetModel.setColumn(column: column)
            self.fileModel.updates += 1
        }
    }
//
//    func show(req: Request) throws -> String {
//        guard let id = req.parameters.get("id") else {
//            throw Abort(.internalServerError)
//        }
//        // ...
//    }
//
//    func update(req: Request) throws -> String {
//        guard let id = req.parameters.get("id") else {
//            throw Abort(.internalServerError)
//        }
//        // ...
//    }
//
//    func delete(req: Request) throws -> String {
//        guard let id = req.parameters.get("id") else {
//            throw Abort(.internalServerError)
//        }
//        // ...
//    }
}
