//
//  UIEdgeInsets+Convenience.swift
//  EtsyKit
//
//  Created by Sharar Rahman on 2/5/21.
//  Copyright © 2021 Etsy. All rights reserved.
//

import UIKit

extension UIEdgeInsets {
    public init(repeating value: CGFloat) {
        self = UIEdgeInsets(top: value,
                            left: value,
                            bottom: value,
                            right: value)
    }

    public init(horizontalValue: CGFloat,
                verticalValue: CGFloat) {
        self = UIEdgeInsets(top: verticalValue,
                            left: horizontalValue,
                            bottom: verticalValue,
                            right: horizontalValue)
    }

    public var directionalInsets: NSDirectionalEdgeInsets {
        return NSDirectionalEdgeInsets(top: top,
                                       leading: left,
                                       bottom: bottom,
                                       trailing: right)
    }
}
