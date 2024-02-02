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
    @ObservedObject var fileController: FileControllerModel
    
    init(fileController: FileControllerModel, port: Int) {
        self.port = port
        self.app = Application(.development)
        self.fileController = fileController
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
            try app.register(collection: FileWebRouteCollection(fileModel: fileController.activeFileModel))
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
        router.get("getcolumnlist", use: getColumnList)
        router.post("savedb") { req in
            let filename = try req.content.decode(String.self)
            self.saveDB(filename: filename)
            return HTTPStatus.ok
        }
        
        router.post("loaddb") { req in
            let filename = try req.content.decode(String.self)
            self.loadDB(filename: filename)
            return HTTPStatus.ok
        }
    }
    
    func saveDB(filename: String) {
        DispatchQueue.main.async {
            saveOpfFile(fileModel: self.fileModel, outputFilename: URL(fileURLWithPath: filename))
        }
    }
    
    func loadDB(filename: String) {
        DispatchQueue.main.async {
            let fileModel = loadOpfFile(inputFilename: URL(fileURLWithPath: filename))
            // TODO
            // Going to need this to be called from the fileMOdel object so it can change itself.
            // so the listeners arent destroyed.
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
        return ColumnModel(sheetModel: fileModel.sheetModel, columnName: "")
    }
    
    func getColumnList(req: Request) async throws -> [String] {
        var colList: [String] = []
        for col in fileModel.sheetModel.columns {
            colList.append(col.columnName)
        }
        return colList
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
