//
//  AppKitCellView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 1/5/24.
//

import AppKit


final class AppKitCellViewItem: NSCollectionViewItem {
    static let identifier: String = "AppKitCellViewItem"
    
    override func loadView() {
        self.view = NSView()
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = .clear
    }
    
    func configureCell(_ article: CellModel, size: NSSize) {
        for v in self.view.subviews {
            v.removeFromSuperview()
        }
//        let contentView = NSHostingView(rootView:
//                                            Cell(cellDataModel: article)
//        )
//        contentView.translatesAutoresizingMaskIntoConstraints = false
//        self.view.addSubview(contentView)
//        
//        contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
//        contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
//        contentView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
//        contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        
        
    }
    
    override func keyDown(with event: NSEvent) {
        print("AA")
    }
    
}


#Preview {
    return AppKitCellViewItem()
}
