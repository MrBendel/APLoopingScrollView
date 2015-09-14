//
//  ViewController.swift
//  InfiniteScrollView
//
//  Created by Andrew Poes on 8/25/15.
//  Copyright (c) 2015 Andrew Poes. All rights reserved.
//

import UIKit

class ViewController: UIViewController, InfiniteScrollViewDataSource, InfiniteScrollViewDelegate {

    var infiniteScrollView: InfiniteScrollView?
    var cacheCount = 0
    var cellColors = [UIColor.cyanColor().colorWithAlphaComponent(0.5), UIColor.yellowColor().colorWithAlphaComponent(0.5),UIColor.greenColor().colorWithAlphaComponent(0.5),UIColor.grayColor().colorWithAlphaComponent(0.5)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.magentaColor().colorWithAlphaComponent(0.2)
        
        let frameSize = self.view.frameSize
        let frame = CGRectMake(0, frameSize.height * 0.25, frameSize.width, frameSize.height * 0.5)
        let iScrollView = InfiniteScrollViewWithScaling(frame: frame)
        iScrollView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3)
        iScrollView.delegate = self
        iScrollView.dataSource = self
        iScrollView.itemSize = CGSize(width: CGRectGetHeight(frame) * 0.5, height: CGRectGetHeight(frame) * 0.5)
        iScrollView.itemSpacing = 6
        iScrollView.edgeScale = 0.9
        iScrollView.pagingEnabled = true
        self.view.addSubview(iScrollView)
        self.infiniteScrollView = iScrollView
        
        let clearDataButton = UIButton(type: UIButtonType.RoundedRect)
        clearDataButton.setTitle("Reload Data", forState: .Normal)
        clearDataButton.sizeToFit()
        clearDataButton.frame = CGRectInset(clearDataButton.frame, -24, -16)
                clearDataButton.center = CGPoint(x: self.view.frameWidth * 0.5, y: CGRectGetMaxY(frame) + clearDataButton.frameHeight * 0.5 + 24)
        clearDataButton.addTarget(self, action: "handleClearData:", forControlEvents: .TouchUpInside)
        self.view.addSubview(clearDataButton)
        
    }
    
    func handleClearData(sender: UIButton) {
        ++self.cacheCount
        self.infiniteScrollView?.reloadData()
    }
    
    func infiniteScrollViewTotalItems(scrollView: InfiniteScrollView) -> Int {
        return 10
    }
    
    func infiniteScrollView(scrollView: InfiniteScrollView, viewForIndex index: Int) -> UIView {
        let itemSize = scrollView.itemSize
        let cell = ExampleCell(frame: CGRect(origin: CGPointZero, size: itemSize))
        cell.text = "\(index)"
        let colorIndex = self.cacheCount%self.cellColors.count
        cell.backgroundColor = self.cellColors[colorIndex]
        return cell
    }
}

class ExampleCell: UIView {
    var label: UILabel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let label = UILabel(frame: self.bounds)
        label.backgroundColor = UIColor.purpleColor().colorWithAlphaComponent(0.5)
        label.textColor = UIColor.whiteColor()
        label.font = UIFont.systemFontOfSize(48, weight: UIFontWeightBlack)
        self.addSubview(label)
        self.label = label
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var text: String? {
        set {
            self.label?.text = newValue
            self.label?.sizeToFit()
            self.label?.center = CGPoint(x: self.frameWidth * 0.5, y: self.frameHeight * 0.5)
        }
        get {
            return self.label?.text
        }
    }
}

