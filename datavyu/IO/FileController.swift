//
//  SaveController.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/18/23.
//

import Foundation
import ZipArchive

struct FileLoad {
    let file: FileModel
    var currentColumn: ColumnModel = ColumnModel(columnName: "")
}

func saveOpfFile(outputFilename: String) {
    
}

//func loadOpfFile(inputFilename: String) -> FileModel {
//    let workingDirectory = NSTemporaryDirectory()
//    let success: Bool = SSZipArchive.unzipFile(atPath: inputFilename, toDestination: workingDirectory)
//    
//    if success {
//        var items: [String]
//        do {
//            items = try FileManager.default.contentsOfDirectory(atPath: workingDirectory)
//        } catch {
//            return FileModel()
//        }
//        
//        var db: FileModel
//        var media: [VideoModel] = []
//        for (index, item) in items.enumerated() {
//            switch item {
//            case "db":
//                db = parseDbFile(filename: item)
//                return db
//            default:
//                print("Went beyond index of assumed files")
//            }
//        }
//    } else {
//        print("Error: File could not be unzipped and may be corrupted.")
//    }
//}

func parseDbFile(fileUrl: URL) -> FileModel {
    
    
    let sheet = SheetModel(sheetName: fileUrl.lastPathComponent)
    let file = FileModel(sheetModel: sheet)
    var fileLoad = FileLoad(file: file)
    
    do {
        let text = try String(contentsOf: fileUrl, encoding: .utf8)
        print(text)
        for line in text.split(separator: "\n") {
            parseDbLine(line: line, fileLoad: &fileLoad)
        }
    }
    catch {/* error handling here */
        print("ERROR \(error)")
    }
    
    return file
}

func parseDbLine(line: Substring, fileLoad: inout FileLoad) {
    /*
     #4
     test (MATRIX,true,)-code01|NOMINAL,code02|NOMINAL,code03|NOMINAL
     00:00:00:000,00:00:00:000,(fasdfaf,"test",)
     00:00:00:000,00:00:00:000,(,,)
     asdf (MATRIX,true,)-code01|NOMINAL
     asdfaaf (MATRIX,true,)-code01|NOMINAL
     00:00:00:000,00:00:00:000,()
     */
    print(line)
    print(line.matches(of: /^[0-9a-zA-Z]+(?:\s+)/))
    if line.starts(with: "#") {
        fileLoad.file.version = String(line)
    } else if line.firstMatch(of: /^[0-9a-zA-Z]+(?:\s+)/) != nil { // Capture a column name followed by a space
        let columnName = String(line.split(separator: " ").first!)
        let columnHidden = line.split(separator: "(")[1].split(separator: ")")[0].split(separator: ",")[1]
        let column = ColumnModel(columnName: columnName, arguments: [], hidden: columnHidden == "true")

        let arguments = line.split(separator: "-")[1]
        for argument in arguments.split(separator: ",") {
            let argName = String(argument.split(separator: "|")[0])
            let arg = Argument(name: argName)
            column.addArgument(argument: arg)
        }
        
        print("Adding column \(columnName) with arguments \(arguments)")
        
        fileLoad.file.sheetModel.addColumn(column: column)
        fileLoad.currentColumn = column
    } else if line.firstMatch(of: /^[0-9]+:[0-9]+:[0-9]+:[0-9]+/) != nil {
        let onset = line.split(separator: ",")[0]
        let offset = line.split(separator: ",")[1]
        let lineStripParens = String(line.replacing("(", with: "", maxReplacements: 1)).replacingLastOccurrenceOfString(")", with: "", caseInsensitive: false)
        
        let values = [String]()
        let cell = fileLoad.currentColumn.addCell()
        cell.setOnset(onset: String(onset))
        cell.setOffset(offset: String(offset))
        
        var index = 0
        for value in lineStripParens.split(separator: ",")[2...] {
            cell.setArgumentValue(index: index, value: String(value))
            index += 1
        }
        
        print("Adding cell \(onset) with values \(values)")
    } else {
        print("ERROR LINE DID NOT MATCH")
    }
}
