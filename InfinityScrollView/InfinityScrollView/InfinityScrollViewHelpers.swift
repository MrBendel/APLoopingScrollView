//
//  InfinityScrollViewHelpers.swift
//  InfinityScrollView
//
//  Created by Andrew Poes on 8/25/15.
//  Copyright (c) 2015 Andrew Poes. All rights reserved.
//

import UIKit

// safe mode function fixes bugs with negative values
func safemod(a: Int, b: Int) -> Int {
    return (((a % b) + b) % b)
}

extension UIView {
    var boundsWidth: CGFloat {
        get {
            return self.bounds.width
        }
    }
    
    var boundsHeight: CGFloat {
        get {
            return self.bounds.height
        }
    }
    
    var boundsSize: CGSize {
        get {
            return self.bounds.size
        }
    }
}

// Grabbed from https://github.com/pNre/ExSwift

internal extension Array {
    /**
    Index of the first occurrence of item, if found.

    :param: item The item to search for
    :returns: Index of the matched item or nil
    */
    func indexOf <U: Equatable> (item: U) -> Int? {
        if item is Element {
            return Swift.find(unsafeBitCast(self, [U].self), item)
        }
        
        return nil
    }
}

internal extension Dictionary {
    /**
    Checks if a key exists in the dictionary.
    
    :param: key Key to check
    :returns: true if the key exists
    */
    func has (key: Key) -> Bool {
        return indexForKey(key) != nil
    }
}