//
//  Examples.swift
//  APLoopingScrollView
//
//  Created by Andrew Poes on 9/14/15.
//  Copyright © 2015 Andrew Poes. All rights reserved.
//

import UIKit

class ExampleHorz: UIViewController, APLoopingScrollViewDataSource, APLoopingScrollViewDelegate {
    
    @IBOutlet var backButton: UIButton?
    @IBOutlet var loopingScrollView: LoopingScrollViewWithScaling?
    
    var cacheCount = 0
    var cellColors = [UIColor.cyanColor().colorWithAlphaComponent(0.5), UIColor.yellowColor().colorWithAlphaComponent(0.5),UIColor.greenColor().colorWithAlphaComponent(0.5),UIColor.grayColor().colorWithAlphaComponent(0.5)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let loopingScrollView = self.loopingScrollView {
            let frame = loopingScrollView.frame
            loopingScrollView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.3)
            loopingScrollView.delegate = self
            loopingScrollView.dataSource = self
            loopingScrollView.scrollDirection = .Horizontal
            loopingScrollView.itemSize = CGSize(width: CGRectGetHeight(frame) * 0.5, height: CGRectGetHeight(frame) * 0.5)
            loopingScrollView.itemSpacing = 6
            loopingScrollView.edgeScale = 0.9
            loopingScrollView.pagingEnabled = true
        }
    }
    
    @IBAction func handleClearData(sender: UIButton) {
        ++self.cacheCount
        self.loopingScrollView?.reloadData()
    }
    
    func loopingScrollViewTotalItems(scrollView: APLoopingScrollView) -> Int {
        return 10
    }
    
    func loopingScrollView(scrollView: APLoopingScrollView, viewForIndex index: Int) -> UIView {
        let itemSize = scrollView.itemSize
        let cell = ExampleCell(frame: CGRect(origin: CGPointZero, size: itemSize))
        cell.text = "\(index)"
        let colorIndex = self.cacheCount%self.cellColors.count
        cell.backgroundColor = self.cellColors[colorIndex]
        return cell
    }
    
    @IBAction func backButtonTouchUpInside(sender: UIButton?) {
        self.navigationController?.popViewControllerAnimated(true)
    }
}

class ExampleVert: UIViewController, APLoopingScrollViewDataSource, APLoopingScrollViewDelegate {
    
    @IBOutlet var backButton: UIButton?
    @IBOutlet var loopingScrollView: APLoopingScrollView?
    
    var cacheCount = 0
    var cellColors = [UIColor.cyanColor().colorWithAlphaComponent(0.5), UIColor.yellowColor().colorWithAlphaComponent(0.5),UIColor.greenColor().colorWithAlphaComponent(0.5),UIColor.grayColor().colorWithAlphaComponent(0.5)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let loopingScrollView = self.loopingScrollView {
            let frame = loopingScrollView.frame
            loopingScrollView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.3)
            loopingScrollView.delegate = self
            loopingScrollView.dataSource = self
            loopingScrollView.scrollDirection = .Vertical
            loopingScrollView.itemSize = CGSize(width: CGRectGetWidth(frame) * 0.5, height: CGRectGetWidth(frame) * 0.5)
            loopingScrollView.itemSpacing = 6
            loopingScrollView.pagingEnabled = false
        }
    }
    
    @IBAction func handleClearData(sender: UIButton) {
        ++self.cacheCount
        self.loopingScrollView?.reloadData()
    }
    
    func loopingScrollViewTotalItems(scrollView: APLoopingScrollView) -> Int {
        return 10
    }
    
    func loopingScrollView(scrollView: APLoopingScrollView, viewForIndex index: Int) -> UIView {
        let itemSize = scrollView.itemSize
        let cell = ExampleCell(frame: CGRect(origin: CGPointZero, size: itemSize))
        cell.text = "\(index)"
        let colorIndex = self.cacheCount%self.cellColors.count
        cell.backgroundColor = self.cellColors[colorIndex]
        return cell
    }
    
    @IBAction func backButtonTouchUpInside(sender: UIButton?) {
        self.navigationController?.popViewControllerAnimated(true)
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

