//
//  FileControllerModel.swift
//  datavyu
//
//  Created by Jesse Lingeman on 9/1/23.
//

import Foundation

class FileControllerModel: ObservableObject, Identifiable {
    @Published var fileModels: [FileModel]
    @Published var activeFileModel: FileModel
    
    init() {
        let defaultFileModel = FileModel()
        fileModels = [defaultFileModel]
        activeFileModel = defaultFileModel
    }
    
    init(fileModels: [FileModel]) {
        if fileModels.count > 0 {
            activeFileModel = fileModels.first!
            self.fileModels = fileModels
        } else {
            let defaultFileModel = FileModel()
            activeFileModel = defaultFileModel
            self.fileModels = [defaultFileModel]
        }
    }
    
    func openFile(inputFilename: URL) {
        var fileModel = loadOpfFile(inputFilename: inputFilename)
        self.fileModels.append(fileModel)
        self.activeFileModel = fileModel
    }
    
    func newFile() {
        var fileModel = FileModel()
        self.fileModels.append(fileModel)
        self.activeFileModel = fileModel
    }
    
    func closeFile() {
        
    }
    
    func saveFile() {
        
    }
}
