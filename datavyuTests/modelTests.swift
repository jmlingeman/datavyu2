//
//  modelTests.swift
//  sheettestTests
//
//  Created by Jesse Lingeman on 5/28/23.
//

@testable import Datavyu2
import XCTest

final class datavyuTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func executeRunLoop() {
        RunLoop.current.run(until: Date())
    }

    func testArgument() throws {
        var arg = Argument()
        arg.setValue(value: "10")
        arg.setName(name: "test")

        XCTAssertEqual(arg.value, "10")
        XCTAssertEqual(arg.name, "test")
    }

    func dispatchFunctionWrapper(_ function: @escaping () -> Void) {
        let expectation = XCTestExpectation(description: "testing")
        DispatchQueue.main.async {
            function()
            expectation.fulfill()
        }
        wait(for: [expectation])
    }

    func testCell() throws {
        var cell = CellModel()

        dispatchFunctionWrapper {
            cell.setOnset(onset: 1.0)
        }
        XCTAssertEqual(cell.onset, 1000)

        dispatchFunctionWrapper {
            cell.setOnset(onset: 1000)
        }
        XCTAssertEqual(cell.onset, 1000)

        dispatchFunctionWrapper {
            cell.setOnset(onset: "00:00:01:000")
        }
        XCTAssertEqual(cell.onset, 1000)

        dispatchFunctionWrapper {
            cell.setOnset(onset: "00:00:10:000")
        }
        XCTAssertEqual(cell.onset, 1000 * 10)

        dispatchFunctionWrapper {
            cell.setOnset(onset: "00:01:00:000")
        }
        XCTAssertEqual(cell.onset, 1000 * 60)

        dispatchFunctionWrapper {
            cell.setOnset(onset: "01:00:00:000")
        }
        XCTAssertEqual(cell.onset, 1000 * 60 * 60)

        dispatchFunctionWrapper {
            cell.setOffset(offset: 1000)
        }
        XCTAssertEqual(cell.offset, 1000)

        dispatchFunctionWrapper {
            cell.setOffset(offset: "00:00:10:000")
        }
        XCTAssertEqual(cell.offset, 1000 * 10)

        dispatchFunctionWrapper {
            cell.setOffset(offset: "00:01:00:000")
        }
        XCTAssertEqual(cell.offset, 1000 * 60)

        dispatchFunctionWrapper {
            cell.setOffset(offset: "01:00:00:000")
        }
        XCTAssertEqual(cell.offset, 1000 * 60 * 60)
    }

    func testColumn() throws {
        var column = ColumnModel()

        dispatchFunctionWrapper {
            let _ = column.addCell(cell: CellModel())
        }
        XCTAssertEqual(column.cells.count, 1)
        XCTAssertEqual(column.arguments.count, 1)
        XCTAssertEqual(column.cells.first!.arguments.count, 1)

        dispatchFunctionWrapper {
            column.addArgument()
        }
        XCTAssertEqual(column.cells.count, 1)
        XCTAssertEqual(column.arguments.count, 2)
        XCTAssertEqual(column.cells.first!.arguments.count, 2)

        dispatchFunctionWrapper {
            column.addArgument(argument: Argument(name: "test", column: column))
        }
        XCTAssertEqual(column.cells.count, 1)
        XCTAssertEqual(column.arguments.count, 3)
        XCTAssertEqual(column.cells.first!.arguments.count, 3)

        dispatchFunctionWrapper {
            column.removeArgument()
        }
        XCTAssertEqual(column.cells.count, 1)
        XCTAssertEqual(column.arguments.count, 2)
        XCTAssertEqual(column.cells.first!.arguments.count, 2)
        XCTAssertNotEqual(column.cells.last!.arguments.last!.name, "test")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
}
