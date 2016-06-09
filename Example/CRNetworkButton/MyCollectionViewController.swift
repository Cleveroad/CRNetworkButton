//
//  MyCollectionViewController.swift
//  CRNetworkButton
//
//  Created by Dmitry Pashinskiy on 5/19/16.
//  Copyright © 2016 Cleveroad Inc. All rights reserved.
//

import UIKit

private let reuseIdentifier = "cellIdentifier"

class MyCollectionViewController: UICollectionViewController {
    // MARK: UICollectionViewDataSource
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 100
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath)
    cell.backgroundColor = UIColor.whiteColor()
        return cell
    }

}
