//
//  EtsyCompositionalLayoutBridge.swift
//  EtsyKit
//
//  Created by Sharar Rahman on 2/1/21.
//  Copyright © 2021 Etsy. All rights reserved.
//

import UIKit

/**
 This class allows for a `UICollectionView` that uses `UICollectionViewFlowLayout` to be instead use a `UICollectionViewCompositionalLayout` without having to change any of the existing code written for the `UICollectionViewFlowLayout`. The class is able to query either a `UICollectionViewFlowLayout` or a `UICollectionViewDelegateFlowLayout` for information on how a collection view section is laid out and is then able to use that information to construct a `NSCollectionLayoutSection`. A `delegate` (`EtsyCompositionalLayoutBridgeDelegate`) of this class is queried on whether a particular `section` should be laid out as a flow layout section or as a compositional layout section.
 */
@objc
public class EtsyCompositionalLayoutBridge: NSObject {
    // MARK: private properties

    private unowned let collectionView: UICollectionView
    private let flowLayout: UICollectionViewFlowLayout

    // Hold weak references to these objects to prevent potential retain cycles.
    private weak var dataSource: UICollectionViewDataSource?
    private weak var flowLayoutDelegate: UICollectionViewDelegateFlowLayout?
    private weak var delegate: EtsyCompositionalLayoutBridgeDelegate?

    // MARK: initializers

    /// `flowLayoutDelegate` does not need to be passed in if item sizes and spacings are set on `flowLayout`.
    @objc
    public init(collectionView: UICollectionView,
                flowLayout: UICollectionViewFlowLayout,
                delegate: EtsyCompositionalLayoutBridgeDelegate,
                dataSource: UICollectionViewDataSource,
                flowLayoutDelegate: UICollectionViewDelegateFlowLayout?) {
        self.collectionView = collectionView
        self.dataSource = dataSource
        self.flowLayout = flowLayout
        self.flowLayoutDelegate = flowLayoutDelegate
        self.delegate = delegate
    }

    // MARK: layout generation

    @objc
    public func layout() -> UICollectionViewCompositionalLayout {
        return NestableCompositionalLayout { (sectionIndex, environment) -> NSCollectionLayoutSection? in
            guard let delegate = self.delegate else {
                return nil
            }

            if delegate.compositionalLayoutBridge(self, shouldUseFlowLayoutFor: sectionIndex) {
                return self.flowLayoutSection(environment: environment, sectionIndex: sectionIndex)
            } else {
                return delegate.compositionalLayoutBridge(self, layoutSectionFor: sectionIndex, environment: environment)
            }
        }
    }

    // MARK: private methods

    /// This method queries a `UICollectionViewDataSource` + `UICollectionViewFlowLayout` or a `UICollectionViewDelegateFlowLayout`, and uses that information to construct an `NSCollectionLayoutSection` that is visually the same.
    internal func flowLayoutSection(environment: NSCollectionLayoutEnvironment,
                                    sectionIndex: Int) -> NSCollectionLayoutSection? {
        guard let dataSource = dataSource else {
            return nil
        }

        let numberOfItemsInSection = dataSource.collectionView(collectionView, numberOfItemsInSection: sectionIndex)
        let allIndexPathsForSection: [IndexPath] = (0 ..< numberOfItemsInSection).map { index in
            return IndexPath(item: index, section: sectionIndex)
        }

        // Get all the measurements we need to create a compositional layout section out of a flow layout section
        let minimumInteritemSpacing = interitemSpacing(for: sectionIndex)
        let minimumLineSpacing = lineSpacing(for: sectionIndex)
        let sectionInset = inset(for: sectionIndex)
        let estimatedItemSize = flowLayout.estimatedItemSize

        let topLevelGroupForSection: NSCollectionLayoutGroup

        if numberOfItemsInSection == 0 {
            // This gracefully handles situations where there are no items shown in the section. It ensures that UIKit assertions, especially the one where an `NSCollectionLayoutGroup` is created with an empty array of `NSCollectionLayoutItem`s, aren't fired later.
            // This also accounts for the case where we may not have any items in the section but want to show a header or footer.
            let sizeForEmptyGroup = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                          heightDimension: .absolute(0.01)) // Using `0.0` may cause a UIKit assertion to fire in the future.
            let itemForEmptyGroup = NSCollectionLayoutItem(layoutSize: sizeForEmptyGroup)
            topLevelGroupForSection = NSCollectionLayoutGroup.horizontal(layoutSize: sizeForEmptyGroup, subitems: [itemForEmptyGroup])
        } else if estimatedItemSize != .zero {
            // Using `estimatedItemSize`
            topLevelGroupForSection = EtsyCompositionalLayoutBridge.horizontalGroup(with: estimatedItemSize, minimumInteritemSpacing: minimumInteritemSpacing)
        } else {
            // Not using `estimatedItemSize` and so each item in the collection view needs to have a corresponding `NSCollectionLayoutItem`.
            let itemSizes: [CGSize] = allIndexPathsForSection.map { size(forItemAt: $0) }
            topLevelGroupForSection = EtsyCompositionalLayoutBridge.verticalTopLevelGroupForFlowLayout(with: itemSizes, sectionInset: sectionInset, minimumInteritemSpacing: minimumInteritemSpacing, minimumLineSpacing: minimumLineSpacing, environment: environment)
        }

        let section = NSCollectionLayoutSection(group: topLevelGroupForSection)

        // The `interGroupSpacing` only ends up being applied by the layout system when we use `estimatedItemSize`.
        // When we aren't using `estimatedItemSize`, we only end up using one vertical `NSCollectionLayoutGroup` so `interGroupSpacing` doesn't get applied by the system.
        section.interGroupSpacing = minimumLineSpacing
        section.contentInsets = sectionInset.directionalInsets
        // Add sizes for header and footer, if needed.
        section.boundarySupplementaryItems = boundaryItems(for: sectionIndex, environment: environment)

        return section
    }

    // MARK: flow layout group generation - creating groups for estimated item sizes

    /**
     For a collection view flow layout that uses `estimatedItemSize`, its compositional layout equivalent is to create a single `NSCollectionLayoutItem` with estimated sizing and place that in a `.horizontal` `NSCollectionLayoutGroup`.
     The `NSCollectionLayoutGroup` takes the entire width of the screen - that way as rows get filled, the compositional layout will lay items on new lines, making it behave like a flow layout.
     */
    internal static func horizontalGroup(with estimatedItemSize: CGSize,
                                         minimumInteritemSpacing: CGFloat) -> NSCollectionLayoutGroup {
        // Note, the flow layout behavior where the last row of items is only left justified (instead of left + right) isn't replicated here. (see https://stackoverflow.com/questions/63319681/why-is-the-last-row-of-the-collectionview-not-aligned-properly)
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .estimated(estimatedItemSize.width),
                                                                             heightDimension: .estimated(estimatedItemSize.height)))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                          heightDimension: .estimated(estimatedItemSize.height)),
                                                       subitems: [item])
        group.interItemSpacing = .flexible(minimumInteritemSpacing)
        return group
    }

    // MARK: flow layout group generation - creating groups for flow layouts with item sizes

    /**
     For a collection view flow layout that specifies its item sizes either using `UICollectionViewFlowLayout.itemSize` or `UICollectionViewDelegateFlowLayout.collectionView(_:layout:sizeForItemAt:)`, we first create `.horizontal` `NSCollectionLayoutGroup`s that represent each row of items in the collection view, and then place those `NSCollectionLayoutGroup`s inside a `.vertical` `NSCollectionLayoutGroup`. The resulting `NSCollectionLayoutGroup` looks identical to what a `UICollectionViewFlowLayout` renders.

     This method creates the `.vertical` `NSCollectionLayoutGroup` that we eventually create an `NSCollectionLayoutSection` with.
     */
    internal static func verticalTopLevelGroupForFlowLayout(with itemSizes: [CGSize],
                                                            sectionInset: UIEdgeInsets,
                                                            minimumInteritemSpacing: CGFloat,
                                                            minimumLineSpacing: CGFloat,
                                                            environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutGroup {
        // Remove the horizontal section insets just like they're removed when sizing items in flow layout.
        let availableWidth = environment.container.effectiveContentSize.width - sectionInset.left - sectionInset.right

        // Create `.horizontal` `NSCollectionLayoutGroup`s that represent each row of items in a flow layout
        let horizontalGroups = horizontalLayoutGroupsForFlowLayout(using: itemSizes, interitemSpacing: minimumInteritemSpacing, availableWidth: availableWidth)

        // We need to determine the total height of our vertical group (equivalent to the height of the flow layout section) by adding the heights of all the rows of items (all the `.horizontal` `NSCollectionLayoutGroup`s) and then adding `lineSpacing` as needed
        let numberOfLineSpacings = max(0, CGFloat(horizontalGroups.count - 1))
        let combinedHeightOfGroups = horizontalGroups.reduce(CGFloat(0), { return $0 + $1.layoutSize.heightDimension.dimension })
        let heightForVerticalGroup = combinedHeightOfGroups + numberOfLineSpacings * minimumLineSpacing

        let verticalGroup = NSCollectionLayoutGroup.vertical(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(heightForVerticalGroup)), subitems: horizontalGroups)
        // in a `.vertical` `NSCollectionLayoutGroup`, `interItemSpacing` is applied vertically, which is equivalent to `minimumLineSpacing` in a `UICollectionViewFlowLayout`.
        verticalGroup.interItemSpacing = .fixed(minimumLineSpacing)
        return verticalGroup
    }

    /**
     This method returns an array of `.horizontal` `NSCollectionLayoutGroup`s, where each element in the array represents a row in a `UICollectionViewFlowLayout`.
     */
    private static func horizontalLayoutGroupsForFlowLayout(using itemSizes: [CGSize],
                                                     interitemSpacing: CGFloat,
                                                     availableWidth: CGFloat) -> [NSCollectionLayoutGroup] {
        var horizontalGroups: [NSCollectionLayoutGroup] = []
        var unusedItemSizes = itemSizes

        // We use a `for` loop instead of a `while` loop to prevent any potential infinite loops. Our max possible iteration count is equal to `itemSizes.count` and so we loop to that value.
        for _ in itemSizes {
            let (group, remainingItemSizes) = horizontalGroup(withItemSizes: unusedItemSizes, interitemSpacing: interitemSpacing, availableWidth: availableWidth)
            horizontalGroups.append(group)

            if remainingItemSizes.isEmpty {
                break // There are no more items to be added to a group, so break the loop.
            } else {
                // We still have items to size, so perform the next iteration of the loop with the `remainingItemSizes`
                unusedItemSizes = remainingItemSizes
            }
        }

        applyEdgeSpacing(forItemsIn: horizontalGroups)

        return horizontalGroups
    }

    /// This method returns a `.horizontal` group of as many items from `itemSizes` that can fit `availableWidth` while respecting `interitemSpacing`.
    /// Values from `itemSizes` that are used will be removed from the array.
    private static func horizontalGroup(withItemSizes itemSizes: [CGSize],
                                        interitemSpacing: CGFloat,
                                        availableWidth: CGFloat) -> (group: NSCollectionLayoutGroup, remainingItemSizes: [CGSize]) {
        var remainingItemSizes = itemSizes
        var itemSizesForCurrentGroup: [CGSize] = []
        var totalWidthForItemsInCurrentGroup: CGFloat = 0

        // Using a `for` loop instead of a `while` to prevent the possibility of infinite loops
        for itemSize in itemSizes {
            // Figure out the total amount of space that will be added between items
            // note we don't have to subtract `1` from `itemSizesForCurrentGroup.count` to determine the number of `interitemSpacings` as we haven't added in the new size yet.
            let totalInterItemSpacing = CGFloat(itemSizesForCurrentGroup.count) * interitemSpacing

            if itemSize.width + totalWidthForItemsInCurrentGroup + totalInterItemSpacing > availableWidth,
               !itemSizesForCurrentGroup.isEmpty { // if `itemSizesForCurrentGroup` is empty AND the item in question is larger than the screen width, we don't want to stop the loop. We want to add the item even if it's larger than the width.
                break // we've fitted as many items as we can into the available space, so `break` the loop

            } else if !remainingItemSizes.isEmpty {
                // We want to remove the element that we're adding to the group from `remainingItemSizes`.
                let itemToAddToGroup = remainingItemSizes.removeFirst()
                itemSizesForCurrentGroup.append(itemToAddToGroup)
                totalWidthForItemsInCurrentGroup += itemToAddToGroup.width
            }
        }

        // The height for the `.horizontal` group (or row of items) is the height of the tallest item in `itemSizesForCurrentGroup`
        let groupHeight = itemSizesForCurrentGroup.map { $0.height }.max() ?? 0

        let groupSize = NSCollectionLayoutSize(from: CGSize(width: availableWidth, height: groupHeight))

        // Create `NSCollectionLayoutItem`s (i.e. the actual items in the row of items) out of `itemSizesForCurrentGroup`
        let layoutItems: [NSCollectionLayoutItem] = horizontalGroupLayoutItems(itemSizesForCurrentGroup: itemSizesForCurrentGroup,
                                                                               maxWidthPerItem: availableWidth)
        let horizontalGroup = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: layoutItems)
        horizontalGroup.interItemSpacing = .fixed(interitemSpacing)

        return (horizontalGroup, remainingItemSizes)
    }

    /// This method returns an array of `NSCollectionLayoutItem`s where each element in the array represents an item in a row of items.
    private static func horizontalGroupLayoutItems(itemSizesForCurrentGroup: [CGSize],
                                                   maxWidthPerItem: CGFloat) -> [NSCollectionLayoutItem] {
        return itemSizesForCurrentGroup.map { itemSize in
            // `UICollectionViewCompositionalLayout` will not draw items if they're larger than the effective content size of the collection view, and so we set the width for the `NSCollectionLayoutItem` accordingly.
            let widthForItem = min(maxWidthPerItem, itemSize.width)
            let itemSizeFittedToScreenWidth = CGSize(width: widthForItem,
                                                        height: itemSize.height)
            let layoutItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(from: itemSizeFittedToScreenWidth))

            return layoutItem
        }
    }

    /// `UICollectionViewFlowLayout` will offset items in both vertically and horizontally in a row depending on various criteria. We seek to replicate the same behavior here by making use of `NSCollectionLayoutItem.edgeSpacing`.
    private static func applyEdgeSpacing(forItemsIn horizontalGroups: [NSCollectionLayoutGroup]) {
        // `UICollectionViewFlowLayout` may center items if there is one item in each row, so compute that to be used later.
        let allGroupsHaveOneItem = horizontalGroups.allSatisfy { $0.subitems.count == 1 }

        for (groupIndex, group) in horizontalGroups.enumerated() {
            let groupWidth = group.layoutSize.widthDimension.dimension
            let groupInteritemSpacing = group.interItemSpacing?.spacing ?? .zero
            let numberOfInteritemSpacings = CGFloat(group.subitems.count - 1)
            let totalWidthForItemsInGroup = group.subitems.reduce(CGFloat(0)) { $0 + $1.layoutSize.widthDimension.dimension }
            // `UICollectionViewFlowLayout` will left + right justify items in rows that are not completely filled instead of just left justifying.
            // To achieve that same behavior in our `NSCollectionLayoutGroup`, we need to distribute the width that remains after applying our item widths and interitem spacings.
            // We also want to set remaining width to 0 if we have items that are larger than `availableWidth`
            let remainingWidth: CGFloat = max(0, groupWidth - numberOfInteritemSpacings * groupInteritemSpacing - totalWidthForItemsInGroup)

            // We will use `remainingWidthPerItem` to apply horizontal offsets on items in rows to achieve left + right justification just like `UICollectionViewFlowLayout` does.
            var remainingWidthPerItem: CGFloat = 0
            if numberOfInteritemSpacings > 0 {
                remainingWidthPerItem = remainingWidth / numberOfInteritemSpacings
            } else if numberOfInteritemSpacings == 0 {
                // If there is one item in a row, then set `remainingWidthPerItem` to be `remainingWidth` so we don't divide by 0.
                remainingWidthPerItem = remainingWidth
            }

            let isFirstGroup = (groupIndex == 0)
            let isLastGroup = (groupIndex == horizontalGroups.count - 1)
            let groupHeight = group.layoutSize.heightDimension.dimension

            for (itemIndex, item) in group.subitems.enumerated() {
                let itemHorizontalEdgeSpacing = ItemHorizontalEdgeSpacing(groupWidth: groupWidth,
                                                                          itemWidth: item.layoutSize.widthDimension.dimension,
                                                                          groupInteritemSpacing: groupInteritemSpacing,
                                                                          remainingWidthPerItem: remainingWidthPerItem,
                                                                          itemIsInFirstGroup: isFirstGroup,
                                                                          itemIsInLastGroup: isLastGroup,
                                                                          groupContainsOneItem: group.subitems.count == 1,
                                                                          allGroupsHaveOneItem: allGroupsHaveOneItem)

                let itemVerticalEdgeSpacing = ItemVerticalEdgeSpacing(groupHeight: groupHeight,
                                                                      itemHeight: item.layoutSize.heightDimension.dimension)

                let isLastItemInGroup = (itemIndex == group.subitems.count - 1)

                item.edgeSpacing = NSCollectionLayoutEdgeSpacing(leading: itemHorizontalEdgeSpacing.leadingEdgeSpacing,
                                                                 top: itemVerticalEdgeSpacing.topEdgeSpacing,
                                                                 trailing: itemHorizontalEdgeSpacing.trailingEdgeSpacing(isLastItemInGroup: isLastItemInGroup),
                                                                 bottom: itemVerticalEdgeSpacing.bottomEdgeSpacing)

            }
        }
    }

    // MARK: sizing and spacing methods for collection view items.

    public func size(forItemAt indexPath: IndexPath) -> CGSize {
        var itemSize = flowLayout.itemSize
        if let delegateItemSize = flowLayoutDelegate?.collectionView?(collectionView, layout: flowLayout, sizeForItemAt: indexPath) {
            itemSize = delegateItemSize
        }
        return itemSize
    }

    public func interitemSpacing(for section: Int) -> CGFloat {
        var minimumInterItemSpacing = flowLayout.minimumInteritemSpacing
        if let delegateInterItemSpacing = flowLayoutDelegate?.collectionView?(collectionView,
                                                                              layout: flowLayout,
                                                                              minimumInteritemSpacingForSectionAt: section) {
            minimumInterItemSpacing = delegateInterItemSpacing
        }
        return minimumInterItemSpacing
    }

    public func lineSpacing(for section: Int) -> CGFloat {
        var minimumLineSpacing = flowLayout.minimumLineSpacing
        if let delegateMinimumLineSpacing = flowLayoutDelegate?.collectionView?(collectionView,
                                                                                layout: flowLayout, minimumLineSpacingForSectionAt: section) {
            minimumLineSpacing = delegateMinimumLineSpacing
        }
        return minimumLineSpacing
    }

    public func inset(for section: Int) -> UIEdgeInsets {
        var inset = flowLayout.sectionInset
        if let delegateSectionInset = flowLayoutDelegate?.collectionView?(collectionView,
                                                                          layout: flowLayout,
                                                                          insetForSectionAt: section) {
            inset = delegateSectionInset
        }
        return inset
    }

    // MARK: header and footer size bridging

    public func boundaryItems(for section: Int,
                              environment: NSCollectionLayoutEnvironment) -> [NSCollectionLayoutBoundarySupplementaryItem] {
        var boundaryItems: [NSCollectionLayoutBoundarySupplementaryItem] = []

        let headerSize = sizeForHeader(at: section)
        if headerSize != .zero {
            // The flow layout's behavior is to set the width to be the width of the collection view (ignoring insets). It only uses the height of the boundary item. We achieve that same behavior here. Note: `.fractionalWidth` applies insets, and so we can't use it here.
            let size = NSCollectionLayoutSize(widthDimension: .absolute(environment.container.contentSize.width),
                                              heightDimension: .absolute(headerSize.height))
            let boundaryHeaderItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: size,
                                                                                 elementKind: UICollectionView.elementKindSectionHeader,
                                                                                 alignment: .top)
            boundaryItems.append(boundaryHeaderItem)
        }

        let footerSize = sizeForFooter(at: section)
        if footerSize != .zero {
            // The flow layout's behavior is to set the width to be the width of the collection view (ignoring insets). It only uses the height of the boundary item. We achieve that same behavior here. Note: `.fractionalWidth` applies insets, and so we can't use it here.
            let size = NSCollectionLayoutSize(widthDimension: .absolute(environment.container.contentSize.width),
                                              heightDimension: .absolute(footerSize.height))
            let boundaryFooterItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: size,
                                                                                 elementKind: UICollectionView.elementKindSectionFooter,
                                                                                 alignment: .bottom)
            boundaryItems.append(boundaryFooterItem)
        }

        return boundaryItems
    }

    public func sizeForHeader(at section: Int) -> CGSize {
        var headerSize = flowLayout.headerReferenceSize
        if let delegateHeaderSize = flowLayoutDelegate?.collectionView?(collectionView,
                                                                        layout: flowLayout,
                                                                        referenceSizeForHeaderInSection: section) {
            headerSize = delegateHeaderSize
        }
        return headerSize
    }

    public func sizeForFooter(at section: Int) -> CGSize {
        var footerSize = flowLayout.footerReferenceSize
        if let delegateFooterSize = flowLayoutDelegate?.collectionView?(collectionView,
                                                                        layout: flowLayout,
                                                                        referenceSizeForFooterInSection: section) {
            footerSize = delegateFooterSize
        }
        return footerSize
    }
}

// MARK: NestableCompositionalLayout class

internal class NestableCompositionalLayout: UICollectionViewCompositionalLayout {
    override var collectionViewContentSize: CGSize {
        var defaultSize = super.collectionViewContentSize

        // Ensure that the height is at least `1.0`. If this property returns 0 then the collection view will not render when nested in another view.
        defaultSize.height = max(1.0, defaultSize.height)

        return defaultSize
    }
}
