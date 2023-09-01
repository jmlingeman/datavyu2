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
        var defaultFileModel = FileModel()
        fileModels = [defaultFileModel]
        activeFileModel = defaultFileModel
    }
    
    init(fileModels: [FileModel]) {
        if fileModels.count > 0 {
            activeFileModel = fileModels.first!
            self.fileModels = fileModels
        } else {
            var defaultFileModel = FileModel()
            activeFileModel = defaultFileModel
            self.fileModels = [defaultFileModel]
        }
    }
    
    func openFile() {
        
    }
    
    func closeFile() {
        
    }
    
    func saveFile() {
        
    }
}
