//
//  APLoopingScrollViewHelpers.swift
//  APLoopingScrollView
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
    set { self.frame = CGRectSetWidth(self.frame, width: newValue) }
  }

  var frameHeight: CGFloat {
    get { return self.frame.height }
    set { self.frame = CGRectSetHeight(self.frame, height: newValue) }
  }

  var frameSize: CGSize {
    get { return self.frame.size }
    set { self.frame = CGRectSetSize(self.frame, size: newValue) }
  }
  var boundsWidth: CGFloat {
    get { return self.bounds.width }
    set { self.bounds = CGRectSetWidth(self.bounds, width: newValue) }
  }

  var boundsHeight: CGFloat {
    get { return self.bounds.height }
    set { self.bounds = CGRectSetHeight(self.bounds, height: newValue) }
  }

  var boundsSize: CGSize {
    get { return self.bounds.size }
    set { self.bounds = CGRectSetSize(self.bounds, size: newValue) }
  }
}

func CGRectSetWidth(rect: CGRect, width: CGFloat) -> CGRect {
  return CGRect(origin: rect.origin, size: CGSizeMake(width, rect.size.height))
}

func CGRectSetHeight(rect: CGRect, height: CGFloat) -> CGRect {
  return CGRect(origin: rect.origin, size: CGSizeMake(rect.size.width, height))
}

func CGRectSetSize(rect: CGRect, size: CGSize) -> CGRect {
  return CGRect(origin: rect.origin, size: size)
}

// Grabbed from https://github.com/pNre/ExSwift

internal extension Dictionary {
  /**
   Checks if a key exists in the dictionary.

   - parameter key: Key to check
   - returns: true if the key exists
   */
  func has (key: Key) -> Bool {
    return indexForKey(key) != nil
  }
}
