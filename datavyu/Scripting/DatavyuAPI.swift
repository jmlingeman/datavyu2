//
//  DatavyuAPI.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/6/23.
//

import Leaf
import Vapor
import SwiftUI

class FileServer: ObservableObject {

    var app: Application
    let port: Int
    @ObservedObject var fileModel: FileModel
    
    init(port: Int) {
        self.port = port
        self.fileModel = FileModel()
        // 3
        app = Application(.development)
        // 4
        configure(app)
    }
    
    private func configure(_ app: Application) {
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
    
    func start(fileModel: FileModel) {
        self.fileModel = fileModel
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

struct FileWebRouteCollection: RouteCollection {
    @ObservedObject var fileModel: FileModel
    
    func boot(routes: RoutesBuilder) throws {
        let router = routes.grouped("api")
        router.get(use: getColumn)
        router.post("setcolumn") { req in
            let column = try req.content.decode(ColumnModel.self)
            setColumn(column: column)
            return HTTPStatus.ok
        }
        
//        todos.group(":id") { todo in
//            todo.get(use: show)
//            todo.put(use: update)
//            todo.delete(use: delete)
//        }
    }
    
    func getColumn(req: Request) async throws -> ColumnModel {
        guard let columnName = req.query[String.self, at: "columnName"] else {
            throw Abort(.badRequest)
        }
        print(req.parameters)
        for col in fileModel.sheetModel.columns {
            if col.columnName == columnName {
                return col
            }
        }
        
        return ColumnModel(columnName: "")
    }
    
    func setColumn(column: ColumnModel) {
        return fileModel.sheetModel.setColumn(column: column)
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
