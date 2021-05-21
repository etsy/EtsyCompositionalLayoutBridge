//
//  CompositionalLayoutBridgeTests.swift
//  EtsyKitTests
//
//  Created by Sharar Rahman on 2/8/21.
//  Copyright © 2021 Etsy. All rights reserved.
//

@testable import EtsyCompositionalLayoutBridge
import XCTest

class CompositionalLayoutBridgeTests: XCTestCase {
    var flowLayout: UICollectionViewFlowLayout?
    var collectionView: UICollectionView?
    var mockController: (UICollectionViewDataSource & EtsyCompositionalLayoutBridgeDelegate)?
    let defaultItemCount = 20
    let defaultContentSize: CGSize = CGSize(width: 375, height: 750)

    override func setUp() {
        super.setUp()
        let layout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        flowLayout = layout
        mockController = MockViewController(numberOfItems: defaultItemCount)
        XCTAssertNotNil(flowLayout)
        XCTAssertNotNil(collectionView)
        XCTAssertNotNil(mockController)
    }

    override func tearDown() {
        flowLayout = nil
        collectionView = nil
        super.tearDown()
    }

    func testThatSectionPropertiesGetSetCorrectly() {
        let minimumLineSpacing: CGFloat = 50
        let insetValue: CGFloat = 60
        let sectionInset: UIEdgeInsets = UIEdgeInsets(top: insetValue, left: insetValue, bottom: insetValue, right: insetValue)
        let sectionInsetAsDirectionalInset: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: insetValue, leading: insetValue, bottom: insetValue, trailing: insetValue)
        flowLayout?.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        flowLayout?.minimumLineSpacing = minimumLineSpacing
        flowLayout?.sectionInset = sectionInset


        let bridge = EtsyCompositionalLayoutBridge(collectionView: collectionView!,
                                                   flowLayout: flowLayout!,
                                                   delegate: mockController!,
                                                   dataSource: mockController!,
                                                   // no delegate as we're using estimated sizing
                                                   flowLayoutDelegate: nil)

        let section = bridge.flowLayoutSection(environment: MockEnvironment(), sectionIndex: 0)!

        // The section object gives us limited information and so we can only test a limited subset of its features.
        XCTAssertNotNil(section)
        XCTAssertEqual(section.contentInsets, sectionInsetAsDirectionalInset)
        // lineSpacing should make it to interGroupSpacing
        XCTAssertEqual(section.interGroupSpacing, minimumLineSpacing)
    }

    func testThatEstimatedSizingCreatesSingleGroup() {
        let minimumInteritemSpacing: CGFloat = 13

        let group = EtsyCompositionalLayoutBridge.horizontalGroup(with: UICollectionViewFlowLayout.automaticSize, minimumInteritemSpacing: minimumInteritemSpacing)

        // Test group properties
        // height is estimated, but width should be the full relative width on the top level group.
        XCTAssertTrue(group.layoutSize.heightDimension.isEstimated)
        XCTAssertTrue(group.layoutSize.widthDimension.isFractionalWidth)
        XCTAssertEqual(group.layoutSize.widthDimension.dimension, 1.0)
        // Check interitemSpacing gets set correctly.
        XCTAssertTrue(group.interItemSpacing!.isFlexible)
        XCTAssertEqual(group.interItemSpacing!.spacing, minimumInteritemSpacing)

        // There should be only one subitem in our group
        XCTAssertEqual(group.subitems.count, 1)

        let firstSubitem = group.subitems.first!
        // Ensure the firstSubitem doesn't have any nested groups
        XCTAssertFalse(firstSubitem is NSCollectionLayoutGroup)

        // Test item properties
        XCTAssertTrue(firstSubitem.layoutSize.widthDimension.isEstimated)
        XCTAssertTrue(firstSubitem.layoutSize.heightDimension.isEstimated)
    }

    func testGroupForFlowLayoutWithFixedItemSizes() {
        let contentInsets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        let sectionInset: UIEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        let minimumInteritemSpacing: CGFloat = 15
        let minimumLineSpacing: CGFloat = 18

        // count is set to the number of items as we want in our collection view
        let itemsSizes = Array(repeating: CGSize(width: 20, height: 20), count: defaultItemCount)

        let mockEnvironment = MockEnvironment(contentSize: defaultContentSize, contentInsets: contentInsets)
        let group = EtsyCompositionalLayoutBridge.verticalTopLevelGroupForFlowLayout(with: itemsSizes,
                                                                                     sectionInset: sectionInset,
                                                                                     minimumInteritemSpacing: minimumInteritemSpacing,
                                                                                     minimumLineSpacing: minimumLineSpacing,
                                                                                     environment: mockEnvironment)
        // Test that the total number of items in all subitems is equal to the number of elements drawn on the screen
        XCTAssertEqual(group.totalNumberOfItems(), defaultItemCount)

        // given the sizes above, there should be three rows (so three horizontal groups)
        XCTAssertEqual(group.subitems.count, 3)
        group.subitems.forEach { XCTAssertTrue($0 is NSCollectionLayoutGroup) }
        XCTAssertTrue(group.interItemSpacing!.isFixed)
        XCTAssertEqual(group.interItemSpacing!.spacing, minimumLineSpacing) // should be the same as minimumLineSpacing as above (interitemSpacing for a vertical group is applied vertically, not horizontally)

    }

    func testThatFlowLayoutDelegateMethodsGetBridgedOnSection() {
        let interitemSpacing: CGFloat = 12
        let lineSpacing: CGFloat = 13
        let sectionInset: UIEdgeInsets = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        let headerSize = CGSize(width: 15, height: 15)
        let footerSize = CGSize(width: 16, height: 16)

        let mockViewController = MockViewControllerWithFlowLayoutDelegate(numberOfItems: defaultItemCount, sizeForItemGenerator: { _ -> CGSize in
            // picking an arbitrary size
            return CGSize(width: 10, height: 10)
        }, interitemSpacing: interitemSpacing, lineSpacing: lineSpacing, sectionInset: sectionInset, headerSize: headerSize, footerSize: footerSize)

        let bridge = EtsyCompositionalLayoutBridge(collectionView: collectionView!,
                                                   flowLayout: flowLayout!,
                                                   delegate: mockViewController,
                                                   dataSource: mockViewController,
                                                   // This time our sizing and spacing comes from this mock view controller.
                                                   flowLayoutDelegate: mockViewController)

        // Test section
        let section = bridge.flowLayoutSection(environment: MockEnvironment(contentSize: defaultContentSize, contentInsets: .zero), sectionIndex: 0)!
        XCTAssertNotNil(section)

        XCTAssertEqual(section.interGroupSpacing, lineSpacing) // should be same as lineSpacing on flow layout
        XCTAssertEqual(section.contentInsets, sectionInset.directionalInsets) // should be same as sectionInset from above
        XCTAssertEqual(section.boundarySupplementaryItems.count, 2) // there should be a header and a footer, so 2 boundary supplementary items

        // Test boundary items
        var elementAlignments: Set<NSRectAlignment> = []
        for boundaryItem in section.boundarySupplementaryItems {
            XCTAssertTrue(boundaryItem.layoutSize.widthDimension.isAbsolute)
            XCTAssertTrue(boundaryItem.layoutSize.heightDimension.isAbsolute)

            if boundaryItem.alignment == .top {
                // our header is 15x15 in the mock view controller above, but our implementation ignores the width and instead makes it contentSize.width (just like UICollectionViewFlowLayout would)
                XCTAssertEqual(boundaryItem.layoutSize.widthDimension.dimension, defaultContentSize.width)
                XCTAssertEqual(boundaryItem.layoutSize.heightDimension.dimension, headerSize.height)
            } else if boundaryItem.alignment == .bottom {
                // our footer is 16x16 in the mock view controller above, but our implementation ignores the width and instead makes it contentSize.width (just like UICollectionViewFlowLayout would)
                XCTAssertEqual(boundaryItem.layoutSize.widthDimension.dimension, defaultContentSize.width)
                XCTAssertEqual(boundaryItem.layoutSize.heightDimension.dimension, footerSize.height)
            }
            // ensure there are exactly two alignments (`.top` and `.bottom`) by putting in a set
            elementAlignments.insert(boundaryItem.alignment)
        }
        XCTAssertEqual(elementAlignments.count, 2)
    }

    func testThatHeaderAndFootersAreOmitted() {
        // Create header and footer to size zero and ensure they get omitted from the section.
        let mockViewController = MockViewControllerWithFlowLayoutDelegate(numberOfItems: defaultItemCount, sizeForItemGenerator: { _ -> CGSize in
            // returning an arbitrary size for our items
            return .zero
        }, interitemSpacing: .zero, lineSpacing: .zero, sectionInset: .zero, headerSize: .zero, footerSize: .zero) // when the header and footer sizes are zero, they are omitted from the section.

        let bridge = EtsyCompositionalLayoutBridge(collectionView: collectionView!,
                                                   flowLayout: flowLayout!,
                                                   delegate: mockViewController,
                                                   dataSource: mockViewController,
                                                   // This time our sizing and spacing comes from this mock view controller.
                                                   flowLayoutDelegate: mockViewController)
        let section = bridge.flowLayoutSection(environment: MockEnvironment(), sectionIndex: 0)!
        XCTAssertNotNil(section)

        // no boundary supplementary items should be added
        XCTAssertEqual(section.boundarySupplementaryItems.count, 0)
    }

    // MARK: ItemHorizontalEdgeSpacing tests

    /// Test horizontal edge spacing when each row contains one **narrow** item: all groups have one item for this test.
    func testItemHorizontalEdgeSpacingForOneNarrowItemInRow() {
        let itemWidth: CGFloat = 50
        let groupWidth: CGFloat = defaultContentSize.width
        let remainingWidthPerItem = (groupWidth - 1 * itemWidth) / 1

        GroupPosition.allCases.forEach { groupOrder in
            let horizontalEdgeSpacing = EtsyCompositionalLayoutBridge.ItemHorizontalEdgeSpacing(groupWidth: groupWidth,
                                                                                                itemWidth: itemWidth,
                                                                                                groupInteritemSpacing: .zero,
                                                                                                remainingWidthPerItem: remainingWidthPerItem,
                                                                                                itemIsInFirstGroup: groupOrder.isInFirstGroup,
                                                                                                itemIsInLastGroup: groupOrder.isInLastGroup,
                                                                                                groupContainsOneItem: true,
                                                                                                allGroupsHaveOneItem: true)

            XCTAssertTrue(horizontalEdgeSpacing.leadingEdgeSpacing.isFixed)
            XCTAssertTrue(horizontalEdgeSpacing.trailingEdgeSpacing(isLastItemInGroup: true).isFixed)
            // With one item per row (`allGroupsHaveOneItem == true`), `isLastItemInGroup` is always true, we don't need to test with the other case.
            XCTAssertEqual(horizontalEdgeSpacing.trailingEdgeSpacing(isLastItemInGroup: true).spacing, .zero)

            switch groupOrder {
            case .firstAndLastGroup:
                // The item is too small, flow layout will left align this item and so verify that happens.
                XCTAssertEqual(horizontalEdgeSpacing.leadingEdgeSpacing.spacing, .zero)
            case .firstButNotLastGroup, .groupThatIsNotFirstOrLast, .lastGroup:
                // Since there are multiple rows of items and all rows contain one item, the item will be centered.
                XCTAssertEqual(horizontalEdgeSpacing.leadingEdgeSpacing.spacing, remainingWidthPerItem / 2)
            }
        }
    }

    /// Test horizontal edge spacing when each row contains one **wide** item: all groups have one item for this test.
    func testItemHorizontalEdgeSpacingForOneWideItemPerRow() {
        let itemWidth: CGFloat = 200
        let groupWidth: CGFloat = defaultContentSize.width
        // For an item width of 200, we can fit 1 items within `groupWidth`
        let remainingWidthPerItem = (groupWidth - 1 * itemWidth) / 1

        GroupPosition.allCases.forEach { groupOrder in
            let horizontalEdgeSpacing = EtsyCompositionalLayoutBridge.ItemHorizontalEdgeSpacing(groupWidth: groupWidth,
                                                                                                itemWidth: itemWidth,
                                                                                                groupInteritemSpacing: .zero,
                                                                                                remainingWidthPerItem: remainingWidthPerItem,
                                                                                                itemIsInFirstGroup: groupOrder.isInFirstGroup,
                                                                                                itemIsInLastGroup: groupOrder.isInLastGroup,
                                                                                                groupContainsOneItem: true,
                                                                                                allGroupsHaveOneItem: true)

            // The wide item should always be centered.
            XCTAssertEqual(horizontalEdgeSpacing.leadingEdgeSpacing.isFixed, true)
            XCTAssertTrue(horizontalEdgeSpacing.trailingEdgeSpacing(isLastItemInGroup: true).isFixed)
            XCTAssertTrue(horizontalEdgeSpacing.trailingEdgeSpacing(isLastItemInGroup: false).isFixed)
            XCTAssertEqual(horizontalEdgeSpacing.leadingEdgeSpacing.spacing, remainingWidthPerItem / 2)
            // With one item per row (`allGroupsHaveOneItem == true`), `isLastItemInGroup` is always true, we don't need to test with the other case.
            XCTAssertEqual(horizontalEdgeSpacing.trailingEdgeSpacing(isLastItemInGroup: true).spacing, .zero)
        }
    }

    /// Test horizontal edge spacing when each row contains multiple narrow items.
    func testItemHorizontalEdgeSpacingForMultipleNarrowItemsPerRow() {
        let itemWidth: CGFloat = 100
        let groupWidth: CGFloat = defaultContentSize.width
        // For an item width of 100, we can fit 3 items within `groupWidth`
        let remainingWidthPerItem = (groupWidth - 3 * itemWidth) / 3

        GroupPosition.allCases.forEach { groupOrder in
            let horizontalEdgeSpacing = EtsyCompositionalLayoutBridge.ItemHorizontalEdgeSpacing(groupWidth: groupWidth,
                                                                                                itemWidth: itemWidth,
                                                                                                groupInteritemSpacing: .zero,
                                                                                                remainingWidthPerItem: remainingWidthPerItem,
                                                                                                itemIsInFirstGroup: groupOrder.isInFirstGroup,
                                                                                                itemIsInLastGroup: groupOrder.isInLastGroup,
                                                                                                groupContainsOneItem: false,
                                                                                                allGroupsHaveOneItem: false)

            // Test things that apply for all cases.
            XCTAssertEqual(horizontalEdgeSpacing.leadingEdgeSpacing.isFixed, true)
            XCTAssertTrue(horizontalEdgeSpacing.trailingEdgeSpacing(isLastItemInGroup: true).isFixed)
            XCTAssertTrue(horizontalEdgeSpacing.trailingEdgeSpacing(isLastItemInGroup: false).isFixed)
            XCTAssertEqual(horizontalEdgeSpacing.leadingEdgeSpacing.spacing, .zero)
            XCTAssertEqual(horizontalEdgeSpacing.trailingEdgeSpacing(isLastItemInGroup: true).spacing, .zero)

            switch groupOrder {
            case .firstAndLastGroup, .lastGroup:
                // No additional spacing is added after the item (Note: `interItemSpacing` may still be added on an actual collection view, but `ItemHorizontalEdgeSpacing` is not responsible for that and so it is out of scope here)
                XCTAssertEqual(horizontalEdgeSpacing.trailingEdgeSpacing(isLastItemInGroup: false).spacing, .zero)
            case .firstButNotLastGroup, .groupThatIsNotFirstOrLast:
                // Add some spacing after the item if it's not the last item to add some additional spacing (on top of `interItemSpacing) to the next item.
                XCTAssertEqual(horizontalEdgeSpacing.trailingEdgeSpacing(isLastItemInGroup: false).spacing, remainingWidthPerItem)
            }
        }
    }

    /// Test horizontal edge spacing when rows contain varying number of items, which happens if widths vary across cells. We are testing what happens to a narrow cell that gets isolated into its own row.
    func testHorizontalEdgeSpacingWithVaryingItemSizesAcrossRows() {
        let itemWidth: CGFloat = 100
        let groupWidth: CGFloat = defaultContentSize.width
        // For an item width of 100, we can typically fit 3 items within `groupWidth`, but for the purposes of this test we're saying a single narrow item is showing on a row as mentioned in the description above.
        let remainingWidthPerItem = (groupWidth - 1 * itemWidth) / 1

        GroupPosition.allCases.forEach { groupOrder in
            let horizontalEdgeSpacing = EtsyCompositionalLayoutBridge.ItemHorizontalEdgeSpacing(groupWidth: groupWidth,
                                                                                                itemWidth: itemWidth,
                                                                                                groupInteritemSpacing: .zero,
                                                                                                remainingWidthPerItem: remainingWidthPerItem,
                                                                                                itemIsInFirstGroup: groupOrder.isInFirstGroup,
                                                                                                itemIsInLastGroup: groupOrder.isInLastGroup,
                                                                                                groupContainsOneItem: true,
                                                                                                allGroupsHaveOneItem: groupOrder == .firstAndLastGroup)
            // Test things that apply for all cases.
            XCTAssertEqual(horizontalEdgeSpacing.leadingEdgeSpacing.isFixed, true)
            XCTAssertTrue(horizontalEdgeSpacing.trailingEdgeSpacing(isLastItemInGroup: true).isFixed)
            XCTAssertEqual(horizontalEdgeSpacing.trailingEdgeSpacing(isLastItemInGroup: true).spacing, .zero)

            switch groupOrder {
            case .firstAndLastGroup, .lastGroup:
                // The narrow item is left aligned.
                XCTAssertEqual(horizontalEdgeSpacing.leadingEdgeSpacing.spacing, .zero)
            case .firstButNotLastGroup, .groupThatIsNotFirstOrLast:
                // The narrow item is centered.
                XCTAssertEqual(horizontalEdgeSpacing.leadingEdgeSpacing.spacing, remainingWidthPerItem / 2)
            }
        }
    }

    // MARK: ItemVerticalEdgeSpacing tests

    func testThatItemsAreVerticallyCenteredForUniformItemSizes() {
        let itemHeightForTallestItemInRow: CGFloat = 30
        let itemHeightForAnItemInRow: CGFloat = 30

        let verticalEdgeSpacing = EtsyCompositionalLayoutBridge.ItemVerticalEdgeSpacing(groupHeight: itemHeightForTallestItemInRow, itemHeight: itemHeightForAnItemInRow)
        XCTAssertEqual(verticalEdgeSpacing.topEdgeSpacing.isFixed, true)
        // Items don't need to be vertically offset if they're the same height as the tallest item.
        XCTAssertEqual(verticalEdgeSpacing.topEdgeSpacing.spacing, 0)
        XCTAssertNil(verticalEdgeSpacing.bottomEdgeSpacing)
    }

    func testThatItemsAreVerticallyCenteredForMixedItemSizes() {
        let itemHeightForTallestItemInRow: CGFloat = 30
        let itemHeightForAnItemInRow: CGFloat = 20
        let verticalEdgeSpacing = EtsyCompositionalLayoutBridge.ItemVerticalEdgeSpacing(groupHeight: itemHeightForTallestItemInRow, itemHeight: itemHeightForAnItemInRow)
        XCTAssertEqual(verticalEdgeSpacing.topEdgeSpacing.isFixed, true)
        // In this case, 5 points need to be added to the top of the shorter item for it to be vertically centered to the taller item.
        XCTAssertEqual(verticalEdgeSpacing.topEdgeSpacing.spacing, 5)
        XCTAssertNil(verticalEdgeSpacing.bottomEdgeSpacing)
    }
}

// MARK: mock view controller class
private class MockViewController: NSObject, UICollectionViewDataSource, EtsyCompositionalLayoutBridgeDelegate {
    let numberOfItems: Int

    init(numberOfItems: Int) {
        self.numberOfItems = numberOfItems
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfItems
    }

    func compositionalLayoutBridge(_ bridge: EtsyCompositionalLayoutBridge, shouldUseFlowLayoutFor section: Int) -> Bool {
        return true
    }

    func compositionalLayoutBridge(_ bridge: EtsyCompositionalLayoutBridge, layoutSectionFor section: Int, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        return nil
    }
}

// MARK: mock view controller subclass with configurable flow layout delegate methods.
private class MockViewControllerWithFlowLayoutDelegate: MockViewController, UICollectionViewDelegateFlowLayout {
    let sizeForItemGenerator: (Int) -> CGSize
    let interitemSpacing: CGFloat
    let lineSpacing: CGFloat
    let headerSize: CGSize
    let footerSize: CGSize
    let sectionInset: UIEdgeInsets

    init(numberOfItems: Int,
         sizeForItemGenerator: @escaping (Int) -> CGSize,
         interitemSpacing: CGFloat,
         lineSpacing: CGFloat,
         sectionInset: UIEdgeInsets,
         headerSize: CGSize,
         footerSize: CGSize) {
        self.sizeForItemGenerator = sizeForItemGenerator
        self.interitemSpacing = interitemSpacing
        self.lineSpacing = lineSpacing
        self.sectionInset = sectionInset
        self.headerSize = headerSize
        self.footerSize = footerSize

        super.init(numberOfItems: numberOfItems)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return sizeForItemGenerator(indexPath.item)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return interitemSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return lineSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return headerSize
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return footerSize
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInset
    }
}

// MARK: mock environment and container classes.
private class MockEnvironment: NSObject, NSCollectionLayoutEnvironment {
    private var _container: MockContainer?
    override init() {
        super.init()
    }

    init(contentSize: CGSize, contentInsets: NSDirectionalEdgeInsets) {
        _container = MockContainer(contentSize: contentSize, contentInsets: contentInsets)
    }

    var container: NSCollectionLayoutContainer {
        return _container ?? MockContainer()
    }

    var traitCollection: UITraitCollection {
        return .init()
    }
}

private class MockContainer: NSObject, NSCollectionLayoutContainer {
    private var _contentSize: CGSize?
    private var _contentInsets: NSDirectionalEdgeInsets?

    override init() {
        super.init()
    }

    convenience init(contentSize: CGSize, contentInsets: NSDirectionalEdgeInsets?) {
        self.init()
        _contentSize = contentSize
        _contentInsets = contentInsets
    }

    var contentSize: CGSize {
        return _contentSize ?? .zero
    }

    var effectiveContentSize: CGSize {
        if let contentSize = _contentSize, let contentInsets = _contentInsets {
            return CGSize(width: contentSize.width - contentInsets.leading - contentInsets.trailing,
                          height: contentSize.height - contentInsets.top - contentInsets.bottom)
        } else {
            return .zero
        }
    }

    var contentInsets: NSDirectionalEdgeInsets {
        return .zero
    }

    var effectiveContentInsets: NSDirectionalEdgeInsets {
        return .zero
    }
}

// MARK: convenience methods for tests
extension NSCollectionLayoutGroup {
    // Returns the total number of items that are `NSCollectionLayoutItem`s but NOT `NSCollectionLayoutGroups`
    func totalNumberOfItems() -> Int {
        let numberOfItemsInCurrentGroup = subitems.reduce(0) { currentValue, item in
            if item is NSCollectionLayoutGroup {
                return currentValue
            } else {
                return currentValue + 1
            }
        }

        let nestedGroups = subitems.compactMap { $0 as? NSCollectionLayoutGroup }

        // Find number of subitems recursively!
        return numberOfItemsInCurrentGroup + nestedGroups.reduce(0) { $0 + $1.totalNumberOfItems() }
    }
}

/// `enum` to simulate different position of groups (i.e. rows) in the collection view.
private enum GroupPosition: CaseIterable {
    case firstAndLastGroup, firstButNotLastGroup, groupThatIsNotFirstOrLast, lastGroup

    var isInFirstGroup: Bool {
        switch self {
        case .firstAndLastGroup:
            return true
        case .firstButNotLastGroup:
            return true
        case .groupThatIsNotFirstOrLast:
            return false
        case .lastGroup:
            return false
        }
    }

    var isInLastGroup: Bool {
        switch self {
        case .firstAndLastGroup:
            return true
        case .firstButNotLastGroup:
            return false
        case .groupThatIsNotFirstOrLast:
            return false
        case .lastGroup:
            return true
        }
    }
}
