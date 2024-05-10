//
//  SaveController.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/18/23.
//

import Foundation
import ZIPFoundation
import Yams



func saveOpfFile(fileModel: FileModel, outputFilename: URL) -> Data {
    let db = saveDB(fileModel: fileModel)
    let project = saveProject(fileModel: fileModel)
    
    do {
        let archive = try Archive(url: outputFilename, accessMode: .create)
        
        guard let data = db.data(using: .utf8) else { return Data() }
        try? archive.addEntry(with: "db", type: .file, uncompressedSize: Int64(db.count), bufferSize: 4, provider: {
            (position: Int64, size) -> Data in
            return data.subdata(in: Data.Index(position)..<Int(position)+size)
        })
        try archive.addEntry(with: "project", type: .file, uncompressedSize: Int64(project.count), provider: {
            (position: Int64, size) -> Data in
            return data.subdata(in: Data.Index(position)..<Int(position)+size)
        })
        
        return data
    } catch {
        print("ERROR WRITING ZIP FILE: \(error)")
    }
    
    return Data()
}

func saveDB(fileModel: FileModel) -> String {
    var dbString = "#4\n"
    for column in fileModel.sheetModel.columns {
        let colstr = generateColumnString(columnModel: column)
        dbString += colstr
    }
    
    return dbString
}

private func generateColumnString(columnModel: ColumnModel) -> String {
    var s = "\(columnModel.columnName) (MATRIX,\(columnModel.hidden),)-"
    
    var argnames = [String]()
    for argument in columnModel.arguments {
        argnames.append("\(argument.name)|NOMINAL")
    }
    s += argnames.joined(separator: ",") + "\n"
    
    for cell in columnModel.getSortedCells() {
        var args = [String]()
        for argument in cell.arguments {
            args.append(argument.value)
        }
        let argstr = "(\(args.joined(separator: ",")))"
        let cellstr = "\(formatTimestamp(timestamp: cell.onset)),\(formatTimestamp(timestamp: cell.offset))," + argstr + "\n"
        
        s += cellstr
    }
    
    return s
}

func saveProject(fileModel: FileModel) -> String {
    /*
     !project
     dbFile: test.opf
     name: test
     origpath: /Users/jesse/Downloads
     version: 5
     viewerSettings:
     - !vs
     classifier: datavyu.video
     feed: /Users/jesse/Downloads/IMG_0822 2.MOV
     plugin: db3fc496-58a7-3706-8538-3f61278b5bec
     settingsId: '1'
     trackSettings: !ts
     bookmark: '-1'
     bookmarks: []
     locked: false
     version: 2
     version: 3
     */
    
    var viewerSettings = [ViewerSetting]()
    for video in fileModel.videoModels {
        let vs = ViewerSetting(classifier: "datavyu.video",
                               feed: video.videoFileURL.absoluteString,
                               plugin: "db3fc496-58a7-3706-8538-3f61278b5bec",
                               settingsId: "1",
                               trackSettings: video.trackSettings != nil ? video.trackSettings! : TrackSetting(), version: 2)
    }
    var project = ProjectFile(dbFile: fileModel.sheetModel.sheetName,
                              name: fileModel.sheetModel.sheetName,
                              origpath: "", version: 5,
                              viewerSettings: viewerSettings)
    
    do {
        let encodedYaml = try YAMLEncoder().encode(project)
        return encodedYaml
    } catch {
        print("ERROR encoding project file: \(error)")
    }
    return ""
}

func saveLegacyFiles(fileModel: FileModel) {
    
}

func loadOpfFile(inputFilename: URL) -> FileModel {
    let workingDirectory = NSTemporaryDirectory() + "/" + UUID().uuidString + "/"
    var db = FileModel()
    var media: [VideoModel] = []
    do {
        try FileManager.default.unzipItem(at: inputFilename, to: URL(filePath: workingDirectory))
        var items: [String]
        do {
            items = try FileManager.default.contentsOfDirectory(atPath: workingDirectory)
        } catch {
            print("Error reading zip file contents: \(error)")
            items = []
        }
        
        for item in items {
            switch item {
                case "db":
                    db = parseDbFile(sheetName: inputFilename.lastPathComponent, fileUrl: URL(filePath: "\(workingDirectory)/\(item)"))
                case "project":
                    print("Loading project")
                    media = parseProjectFile(fileUrl: URL(filePath: "\(workingDirectory)/\(item)"))
                    
                case let s where s.matchFirst(/^[0-9]+$/):
                    print(item)
                default:
                    print("Went beyond index of assumed files")
            }
        }
    } catch {
        print("Error opening opf file: \(error) for \(inputFilename.absoluteString)")
    }
    
    if !media.isEmpty {
        for vm in media {
            db.addVideo(videoModel: vm)
        }
    }

    return db
}


func parseProjectFile(fileUrl: URL) -> [VideoModel] {
    /*
     !project
     dbFile: test.opf
     name: test
     origpath: /Users/jesse/Downloads
     version: 5
     viewerSettings:
     - !vs
     classifier: datavyu.video
     feed: /Users/jesse/Downloads/IMG_0822 2.MOV
     plugin: db3fc496-58a7-3706-8538-3f61278b5bec
     settingsId: '1'
     trackSettings: !ts
     bookmark: '-1'
     bookmarks: []
     locked: false
     version: 2
     version: 3
     */
    var videoModels = [VideoModel]()
    do {
        let text = try String(contentsOf: fileUrl, encoding: .utf8)
        let project = try YAMLDecoder().decode(ProjectFile.self, from: text)
                
        for vs in project.viewerSettings {
            let videoPath = vs.feed
            let videoModel = VideoModel(videoFilePath: URL(fileURLWithPath: videoPath))
            videoModels.append(videoModel)
        }
        
    } catch { /* error handling here */
        print("ERROR \(error)")
    }
    
    return videoModels
}

func parseDbFile(sheetName: String, fileUrl: URL) -> FileModel {
    let sheet = SheetModel(sheetName: sheetName)
    let file = FileModel(sheetModel: sheet)
    var fileLoad = FileLoad(file: file)

    do {
        let text = try String(contentsOf: fileUrl, encoding: .utf8)
        print(text)
        for line in text.split(separator: "\n") {
            parseDbLine(sheetModel: sheet, line: line, fileLoad: &fileLoad)
        }
    } catch { /* error handling here */
        print("ERROR \(error)")
    }

    return file
}

func parseDbLine(sheetModel: SheetModel, line: Substring, fileLoad: inout FileLoad) {
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
        let column = ColumnModel(sheetModel: sheetModel, columnName: columnName, arguments: [], hidden: columnHidden == "true")

        let arguments = line.split(separator: "-")[1]
        for argument in arguments.split(separator: ",") {
            let argName = String(argument.split(separator: "|")[0])
            let arg = Argument(name: argName, column: column)
            column.addArgument(argument: arg)
        }

        print("Adding column \(columnName) with arguments \(arguments)")

        fileLoad.file.sheetModel.addColumn(column: column)
        fileLoad.currentColumn = column
    } else if line.firstMatch(of: /^[0-9]+:[0-9]+:[0-9]+:[0-9]+/) != nil { // Capture a timestamp
        let onset = line.split(separator: ",")[0]
        let offset = line.split(separator: ",")[1]
        let lineStripParens = String(line.replacing("(", with: "", maxReplacements: 1)).replacingLastOccurrenceOfString(")", with: "", caseInsensitive: false)

        let values = [String]()
        let cell = fileLoad.currentColumn.addCell(force: true)
        if cell != nil {
            cell!.setOnset(onset: String(onset))
            cell!.setOffset(offset: String(offset))
            
            var index = 0
            for value in lineStripParens.split(separator: ",")[2...] {
                cell!.setArgumentValue(index: index, value: String(value))
                index += 1
            }
            
            print("Adding cell \(onset) with values \(values)")
        }
    } else {
        print("ERROR LINE DID NOT MATCH")
    }
}
