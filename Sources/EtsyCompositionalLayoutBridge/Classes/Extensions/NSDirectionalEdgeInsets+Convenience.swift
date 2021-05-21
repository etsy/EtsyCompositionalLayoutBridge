//
//  NSDirectionalEdgeInsets.swift
//  EtsyKit
//
//  Created by Sharar Rahman on 2/5/21.
//  Copyright © 2021 Etsy. All rights reserved.
//

import UIKit

extension NSDirectionalEdgeInsets {
    public init(repeating value: CGFloat) {
        self = NSDirectionalEdgeInsets(top: value,
                                       leading: value,
                                       bottom: value,
                                       trailing: value)
    }
}
