//
//  CompositionalLayoutBridgeDelegate.swift
//  EtsyKit
//
//  Created by Sharar Rahman on 2/9/21.
//  Copyright © 2021 Etsy. All rights reserved.
//

import Foundation
import UIKit

/**
 Protocol for a `delegate` of `EtsyCompositionalLayoutBridge` to conform to. `EtsyCompositionalLayoutBridge` queries its `delegate` on whether a collection view `section` has flow layout methods implemented for it or not. If yes, `EtsyCompositionalLayoutBridge` will obtain item sizes and spacing for the flow layout section and bridge it into an `NSCollectionLayoutSection`. If not, `EtsyCompositionalLayoutBridge` asks for an `NSCollectionLayoutSection` to use for the section.
 */
@objc
public protocol EtsyCompositionalLayoutBridgeDelegate: NSObjectProtocol {
    /// Returning `false` from this method for a given section will cause `EtsyCompositionalLayoutBridgeDelegate.compositionalLayoutBridge(_:layoutSectionFor:)` to be called for that section. Returning `true` means flow layout will be used for the section.
    func compositionalLayoutBridge(_ bridge: EtsyCompositionalLayoutBridge, shouldUseFlowLayoutFor section: Int) -> Bool

    /// Return a compositional layout section given a section for which `false` was returned in `compositionalLayoutBridge(_:shouldUseFlowLayoutFor:)`
    func compositionalLayoutBridge(_ bridge: EtsyCompositionalLayoutBridge, layoutSectionFor section: Int, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection?
}
