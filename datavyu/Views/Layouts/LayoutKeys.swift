//
//  LayoutKeys.swift
//  datavyu
//
//  Created by Jesse Lingeman on 7/22/23.
//

import SwiftUI

struct OnsetKey: LayoutValueKey {
    static var defaultValue: Int = 0
}

struct OffsetKey: LayoutValueKey {
    static var defaultValue: Int = 0
}

struct ColumnKey: LayoutValueKey {
    static var defaultValue: Int = 0
}

struct ObjectType: LayoutValueKey {
    static var defaultValue: String = ""
}

struct CellIdx: LayoutValueKey {
    static var defaultValue: String = ""
}

struct Overlap: LayoutValueKey {
    static var defaultValue: Bool = false
}

extension LayoutSubview {
    var onset: Int {
        self[OnsetKey.self]
    }
    
    var offset: Int {
        self[OffsetKey.self]
    }
    
    var columnIdx: Int {
        self[ColumnKey.self]
    }
    
    var objectType: String {
        self[ObjectType.self]
    }
    
    var cellIdx: String {
        self[CellIdx.self]
    }
    
    var overlap: Bool {
        self[Overlap.self]
    }
}

extension View {
    func setOnset(_ onset: Binding<Int>) -> some View {
        layoutValue(key: OnsetKey.self, value: onset.wrappedValue)
    }
    
    func setOffset(_ offset: Binding<Int>) -> some View {
        layoutValue(key: OffsetKey.self, value: offset.wrappedValue)
    }
    
    func setColumnIdx(_ colIdx: Int) -> some View {
        layoutValue(key: ColumnKey.self, value: colIdx)
    }
    
    func setObjectType(_ objectType: String) -> some View {
        layoutValue(key: ObjectType.self, value: objectType)
    }
    
    func setCellIdx(_ cellIdx: String) -> some View {
        layoutValue(key: CellIdx.self, value: cellIdx)
    }
    
    func setOverlap(_ overlap: Bool) -> some View {
        layoutValue(key: Overlap.self, value: overlap)
    }
    
}
