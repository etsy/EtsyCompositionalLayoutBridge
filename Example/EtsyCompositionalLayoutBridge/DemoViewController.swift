//
//  DemoViewController.swift
//  EtsyCompositionalLayoutBridge
//
//  Created by Sharar Rahman on 05/21/2021.
//  Copyright (c) 2021 Sharar Rahman. All rights reserved.
//

import UIKit
import EtsyCompositionalLayoutBridge

enum CollectionViewSection: Int, CaseIterable {
    case flowLayoutGrid
    case compositionalLayoutHorizontalScrollingSection

    var numberOfItems: Int {
        switch self {
        case .flowLayoutGrid:
            return 8
        case .compositionalLayoutHorizontalScrollingSection:
            return 10
        }
    }

    var shouldShowHeader: Bool {
        switch self {
        case .flowLayoutGrid:
            return false
        case .compositionalLayoutHorizontalScrollingSection:
            return true
        }
    }

    var description: String {
        switch self {
        case .flowLayoutGrid:
            return "Classic flow layout grid"
        case .compositionalLayoutHorizontalScrollingSection:
            return "Compositional layout horizontal scrolling section with header from flow layout"
        }
    }
}

enum ReuseIdentifier: String {
    case header, cell
}

class DemoViewController: UIViewController {
    private let collectionView: UICollectionView


    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 150, height: 150)
        flowLayout.sectionInset = UIEdgeInsets(horizontalValue: .zero, verticalValue: 8)
        flowLayout.headerReferenceSize = CGSize(width: 100, height: 80)

        // We use the `flowLayout` as a placeholder `collectionViewLayout` for now.
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)

        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        // We create the bridge with all our components and then update the `collectionViewLayout` on `collectionView`.
        let bridge = EtsyCompositionalLayoutBridge(collectionView: collectionView, flowLayout: flowLayout, delegate: self, dataSource: self, flowLayoutDelegate: nil)
        collectionView.collectionViewLayout = bridge.layout()

        collectionView.dataSource = self

        collectionView.register(CollectionViewCell.self, forCellWithReuseIdentifier: ReuseIdentifier.cell.rawValue)
        collectionView.register(HeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ReuseIdentifier.header.rawValue)
    }

    required convenience init?(coder: NSCoder) {
        self.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        [
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ].forEach { $0.isActive = true }
    }
}

extension DemoViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return CollectionViewSection.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let section = CollectionViewSection(rawValue: section) else { return 0 }
        return section.numberOfItems
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: ReuseIdentifier.cell.rawValue, for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view =  collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ReuseIdentifier.header.rawValue, for: indexPath)
        if let view = view as? HeaderView,
           let section = CollectionViewSection(rawValue: indexPath.section) {
            view.setTitle(text: section.description)
        }

        return view
    }
}

extension DemoViewController: EtsyCompositionalLayoutBridgeDelegate {
    func compositionalLayoutBridge(_ bridge: EtsyCompositionalLayoutBridge, shouldUseFlowLayoutFor section: Int) -> Bool {
        guard let section = CollectionViewSection(rawValue: section) else { return true }

        return section == .flowLayoutGrid
    }

    func compositionalLayoutBridge(_ bridge: EtsyCompositionalLayoutBridge, layoutSectionFor section: Int, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        guard let sectionType = CollectionViewSection(rawValue: section),
              sectionType == .compositionalLayoutHorizontalScrollingSection else { return nil }

        let itemSize = NSCollectionLayoutSize(from: CGSize(width: 50, height: 50))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitems: [item])
        let layoutSection = NSCollectionLayoutSection(group: group)
        layoutSection.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
        layoutSection.interGroupSpacing = 16
        layoutSection.contentInsets = UIEdgeInsets(horizontalValue: .zero, verticalValue: 8).directionalInsets

        // Mixing and matching between flow layout and compositional layout by using the header from `UICollectionViewFlowLayout` header.
        layoutSection.boundarySupplementaryItems = bridge.boundaryItems(for: section, environment: environment)

        return layoutSection
    }
}
