//
//  DatavyuAPI.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/6/23.
//

import Leaf
import SwiftUI
import Vapor

class DatavyuAPIServer {
    var app: Application
    let port: Int
    @ObservedObject var fileController: FileControllerModel
    @ObservedObject var appState: AppState

    init(fileController: FileControllerModel, appState: AppState, port: Int) {
        self.port = port
        app = Application(.development)
        self.fileController = fileController
        self.appState = appState
        configure(app)

        // Hack so Vapor works in unit tests
        app.environment.arguments = [app.environment.arguments[0]]
    }

    private func configure(_ app: Application) {
        // Listen only to localhost, no outside comms
        app.http.server.configuration.hostname = "127.0.0.1"
        app.http.server.configuration.port = port
        app.views.use(.leaf)
        app.leaf.cache.isEnabled = app.environment.isRelease
        app.leaf.configuration.rootDirectory = Bundle.main.bundlePath
        app.routes.defaultMaxBodySize = "50MB"
        app.logger.logLevel = .critical

        do {
            try app.register(collection: FileWebRouteCollection(fileController: fileController, appState: appState))
        } catch {
            Logger.info("\(error)")
        }
    }

    func start() {
        // 1
        Task {
            do {
                try await app.startup()
            } catch {
                Logger.info("\(error)")
                fatalError(error.localizedDescription)
            }
        }
    }
}

class FileWebRouteCollection: RouteCollection {
    @ObservedObject var fileController: FileControllerModel
    @ObservedObject var appState: AppState

    init(fileController: FileControllerModel, appState: AppState) {
        self.fileController = fileController
        self.appState = appState
    }

    func boot(routes: RoutesBuilder) throws {
        let router = routes.grouped("api")
        router.get("getcolumn", use: getColumn)
        router.post("setcolumn") { req in
            let column = try req.content.decode(ColumnModel.self)
            try! await self.setColumn(column: column)
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

        router.post("settings/jumpback") { req in
            let jumpbackValue = try req.content.decode(Int.self) // Milliseconds
            self.appState.jumpValue = formatTimestamp(timestamp: jumpbackValue)
            return HTTPStatus.ok
        }

        router.post("videos/set") { req in
            let videos = try req.content.decode([VideoModel].self)
            self.fileController.activeFileModel.videoController?.fileModel.videoModels = videos
            return HTTPStatus.ok
        }
    }

    func saveDB(filename: String) {
        DispatchQueue.main.async {
            let _ = saveOpfFile(fileModel: self.fileController.activeFileModel, outputFilename: URL(fileURLWithPath: filename))
        }
    }

    func loadDB(filename: String) {
        DispatchQueue.main.async {
            let fileModel = loadOpfFile(inputFilename: URL(fileURLWithPath: filename))
            // TODO:
            // Going to need this to be called from the fileMOdel object so it can change itself.
            // so the listeners arent destroyed.
        }
    }

    func getColumn(req: Request) async throws -> ColumnModel {
        guard let columnName = req.query[String.self, at: "columnName"] else {
            throw Abort(.badRequest)
        }
        for col in fileController.activeFileModel.sheetModel.columns {
            if col.columnName == columnName {
                return col
            }
        }

        return ColumnModel(sheetModel: fileController.activeFileModel.sheetModel, columnName: "")
    }

    func getColumnList(req _: Request) async throws -> [String] {
        var colList: [String] = []
        for col in fileController.activeFileModel.sheetModel.columns {
            colList.append(col.columnName)
        }
        return colList
    }

    func setColumn(column: ColumnModel) async throws {
        try! await fileController.activeFileModel.sheetModel.setColumn(column: column)
        column.isSelected = true
        fileController.activeFileModel.updates += 1
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
