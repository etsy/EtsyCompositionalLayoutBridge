//
//  CollectionViewCell.swift
//  EtsyCompositionalLayoutBridgeDemo
//
//  Created by Sharar Rahman on 5/19/21.
//  Copyright © 2021 Etsy. All rights reserved.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.cornerRadius = 10
        backgroundColor = .orange
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
