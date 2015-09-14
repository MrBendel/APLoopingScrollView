//
//  InfiniteScrollViewHelpers.swift
//  InfiniteScrollView
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
    var frameWidth: CGFloat {
        get { return self.frame.width }
        set { self.frame = CGRectSetWidth(self.frame, newValue) }
    }
    
    var frameHeight: CGFloat {
        get { return self.frame.height }
        set { self.frame = CGRectSetHeight(self.frame, newValue) }
    }
    
    var frameSize: CGSize {
        get { return self.frame.size }
        set { self.frame = CGRectSetSize(self.frame, newValue) }
    }
    var boundsWidth: CGFloat {
        get { return self.bounds.width }
        set { self.bounds = CGRectSetWidth(self.bounds, newValue) }
    }
    
    var boundsHeight: CGFloat {
        get { return self.bounds.height }
        set { self.bounds = CGRectSetHeight(self.bounds, newValue) }
    }
    
    var boundsSize: CGSize {
        get { return self.bounds.size }
        set { self.bounds = CGRectSetSize(self.bounds, newValue) }
    }
}

func CGRectSetWidth(rect: CGRect, width: CGFloat) -> CGRect {
    return CGRect(x: CGRectGetMinX(rect), y: CGRectGetMinY(rect), width: width, height: CGRectGetHeight(rect))
}

func CGRectSetHeight(rect: CGRect, height: CGFloat) -> CGRect {
    return CGRect(x: CGRectGetMinX(rect), y: CGRectGetMinY(rect), width: CGRectGetWidth(rect), height: height)
}

func CGRectSetSize(rect: CGRect, size: CGSize) -> CGRect {
    return CGRect(origin: CGPoint(x: CGRectGetMinX(rect), y: CGRectGetMinY(rect)), size: size)
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