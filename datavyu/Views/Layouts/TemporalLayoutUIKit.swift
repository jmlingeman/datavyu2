import SwiftUI
import AppKit
final class HostingCellView: NSCollectionViewItem {
    func setView<Content>(_ newValue: Content) where Content: View {
        for view in self.view.subviews {
            view.removeFromSuperview()
        }
        let view = NSHostingView(rootView: newValue)
        view.autoresizingMask = [.width, .height]
        self.view.addSubview(view)
    }
}
struct CollectionCell: View {
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("Cell")
    var body: some View {
        Text("Cell")
    }
}

final class HostingSupplementaryView: NSView, NSCollectionViewElement {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func setView<Content>(_ newValue: Content) where Content: View {
        for view in self.subviews {
            view.removeFromSuperview()
        }
        let view = NSHostingView(rootView: newValue)
        view.autoresizingMask = [.width, .height]
        self.addSubview(view)
    }
}
struct Header: View {
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("Header")
    var body: some View {
        Text("Header")
    }
}
struct Footer: View {
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("Footer")
    var body: some View {
        Text("Footer")
    }
}

struct Collection: NSViewRepresentable {
    static let headerIdentifier = "ViewHeader"
    static let footerIdentifier = "ViewFooter"
    typealias NSViewType = NSCollectionView
    
    func makeNSView(context: Context) -> NSCollectionView {
        
        let view = NSCollectionView()
        view.delegate = context.coordinator
        
        view.register(HostingCellView.self, forItemWithIdentifier: CollectionCell.reuseIdentifier)
        view.register(HostingSupplementaryView.self, forSupplementaryViewOfKind: Self.headerIdentifier, withIdentifier: Header.reuseIdentifier)
        view.register(HostingSupplementaryView.self, forSupplementaryViewOfKind: Self.footerIdentifier, withIdentifier: Footer.reuseIdentifier)
        
        view.collectionViewLayout = NSCollectionViewCompositionalLayout { (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitem: item, count: 1)
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous
            let supplementarySize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44))
            let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: supplementarySize, elementKind: Self.headerIdentifier, alignment: .topLeading)
            let footer = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: supplementarySize, elementKind: Self.footerIdentifier, alignment: .bottomTrailing)
            section.boundarySupplementaryItems = [header, footer]
            return section
        }
        
        let dataSource = NSCollectionViewDiffableDataSource<Int, Int>(collectionView: view) { (view, indexPath, sectionIndex) -> NSCollectionViewItem? in
            guard let item = view.makeItem(withIdentifier: CollectionCell.reuseIdentifier, for: indexPath) as? HostingCellView else {
                fatalError()
            }
            item.setView(CollectionCell())
            return item
        }
        
        dataSource.supplementaryViewProvider = { (view: NSCollectionView, kind: String, indexPath: IndexPath) -> (NSView & NSCollectionViewElement)? in
            switch kind {
            case Self.headerIdentifier:
                guard let supplementary = view.makeSupplementaryView(ofKind: kind, withIdentifier: Header.reuseIdentifier, for: indexPath) as? HostingSupplementaryView else {
                    fatalError()
                }
                supplementary.setView(Header())
                return supplementary
            case Self.footerIdentifier:
                guard let supplementary = view.makeSupplementaryView(ofKind: kind, withIdentifier: Footer.reuseIdentifier, for: indexPath) as? HostingSupplementaryView else {
                    fatalError()
                }
                supplementary.setView(Footer())
                return supplementary
            default:
                return nil
            }
        }
        context.coordinator.dataSource = dataSource
        return view
    }
    
    func updateNSView(_ nsView: NSCollectionView, context: Context) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0])
        //        snapshot.appendItems(Array<Int>(0..<10), toSection: 0)
        context.coordinator.dataSource?.apply(snapshot, animatingDifferences: true)
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject {
        let view: Collection
        var dataSource: NSCollectionViewDiffableDataSource<Int, Int>? = nil
        init(_ view: Collection) {
            self.view = view
        }
    }
}

extension Collection.Coordinator: NSCollectionViewDelegate {}
