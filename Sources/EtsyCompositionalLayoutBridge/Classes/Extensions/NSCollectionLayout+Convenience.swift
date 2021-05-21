//
//  NSCollectionLayout+Convenience.swift
//  EtsyKit
//
//  Created by Sharar Rahman on 2/5/21.
//  Copyright © 2021 Etsy. All rights reserved.
//

import UIKit

extension NSCollectionLayoutSize {
    public static var fullContainerSize: NSCollectionLayoutSize {
        return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .fractionalHeight(1.0))
    }

    public static var equalDimensions: NSCollectionLayoutSize {
        return NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .fractionalWidth(1.0))
    }

    public static func absoluteSize(_ size: CGSize) -> NSCollectionLayoutSize {
        return NSCollectionLayoutSize(from: size)
    }

    public convenience init(from size: CGSize) {
        self.init(widthDimension: .absolute(size.width), heightDimension: .absolute(size.height))
    }
}
