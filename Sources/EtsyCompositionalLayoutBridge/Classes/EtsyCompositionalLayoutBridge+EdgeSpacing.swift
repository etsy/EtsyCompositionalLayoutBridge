//
//  EtsyCompositionalLayoutBridge+EdgeSpacing.swift
//  EtsyKit
//
//  Created by Sharar Rahman on 4/14/21.
//  Copyright © 2021 Etsy. All rights reserved.
//

import Foundation
import UIKit

extension EtsyCompositionalLayoutBridge {
    // MARK: Edge spacing helpers

    /// `UICollectionViewFlowLayout` features behaviors where items in a row may be left justified or left + right justified according to various criteria. This struct takes in various details about a row of items and determines whether or not an item in a row should be horizontally offset from its base position and if so, by what amount. We achieve justification behavior in `UICollectionViewCompositionalLayout` using `NSCollectionLayoutItem.edgeSpacing`.
    struct ItemHorizontalEdgeSpacing {
        /// Typically the 'drawable' width of the collection view (the width of the collection view after insets are removed)
        let groupWidth: CGFloat
        let itemWidth: CGFloat
        let groupInteritemSpacing: CGFloat
        let remainingWidthPerItem: CGFloat
        let itemIsInFirstGroup: Bool
        let itemIsInLastGroup: Bool
        let groupContainsOneItem: Bool
        let allGroupsHaveOneItem: Bool

        var leadingEdgeSpacing: NSCollectionLayoutSpacing {
            // `UICollectionViewFlowLayout` may center the items in a particular row depending on various criteria, which we replicate here:
            let shouldCenterHorizontally: Bool
            if itemIsInFirstGroup, itemIsInLastGroup {
                // For sections with one row, the flow layout may center the item or left align it depending on the size of the item.
                shouldCenterHorizontally = (2 * itemWidth + groupInteritemSpacing) > groupWidth
            } else if itemIsInLastGroup {
                shouldCenterHorizontally = allGroupsHaveOneItem
            } else if groupContainsOneItem {
                shouldCenterHorizontally = true
            } else {
                shouldCenterHorizontally = false
            }

            guard shouldCenterHorizontally else {
                return .fixed(.zero)
            }
            return .fixed(remainingWidthPerItem / 2)
        }

        func trailingEdgeSpacing(isLastItemInGroup: Bool) -> NSCollectionLayoutSpacing {
            // We apply some trailing edge spacing to all items except the last item to match flow layout's behavior where the flow layout will add additional spacing between items when the row isn't full.
            // The flow layout behavior where the last row of items is only left justified (instead of left + right) is replicated here. (see https://stackoverflow.com/questions/63319681/why-is-the-last-row-of-the-collectionview-not-aligned-properly)
            guard leadingEdgeSpacing.spacing == .zero,
                  !isLastItemInGroup,
                  !itemIsInLastGroup else {
                return .fixed(.zero)
            }

            return .fixed(remainingWidthPerItem)
        }
    }

    /// `UICollectionViewFlowLayout` features a behavior where items in a row are always vertically centered in the row. This struct takes in various details about a row of items and determines whether or not a particular item in a row should be vertically centered, and if so, by what amount. We achieve vertical centering behavior in a `UICollectionViewCompositionalLayout` using `NSCollectionLayoutItem.edgeSpacing`.
    struct ItemVerticalEdgeSpacing {
        let groupHeight: CGFloat
        let itemHeight: CGFloat

        var topEdgeSpacing: NSCollectionLayoutSpacing {
            return .fixed((groupHeight - itemHeight) / 2)
        }

        var bottomEdgeSpacing: NSCollectionLayoutSpacing? {
            return nil
        }
    }

}
