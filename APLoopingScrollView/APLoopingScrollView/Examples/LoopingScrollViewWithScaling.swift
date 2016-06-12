//
//  LoopingScrollViewWithScaling.swift
//  APLoopingScrollView
//
//  Created by Andrew Poes on 9/14/15.
//  Copyright © 2015 Andrew Poes. All rights reserved.
//

import UIKit

class LoopingScrollViewWithScaling: APLoopingScrollView {
    var edgeScale: CGFloat = 0.9
    override func updateViews() {
        // reset the transforms
        for indexPath in self.visibleItems {
            if let view = self.view(forIndexPath: indexPath) {
                view.transform = CGAffineTransformIdentity
            }
        }
        // update the frames
        super.updateViews()
        // set the transforms
        let centerX = CGRectGetWidth(self.frame) * 0.5
        for indexPath in self.visibleItems {
            if let view = self.view(forIndexPath: indexPath) {
                let progX = (view.center.x - self.contentOffset.x - centerX) / centerX
                let scale = 1 - fabs(progX * (1 - edgeScale))
                let transform = CGAffineTransformMakeScale(scale, scale)
                view.transform = transform
            }
        }
    }
}