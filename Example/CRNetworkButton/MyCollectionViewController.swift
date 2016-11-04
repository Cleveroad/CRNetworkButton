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
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 100
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
    cell.backgroundColor = UIColor.white
        return cell
    }

}
