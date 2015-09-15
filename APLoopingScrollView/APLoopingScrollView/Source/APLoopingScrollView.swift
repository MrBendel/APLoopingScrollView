//
//  APLoopingScrollView.swift
//  APLoopingScrollView
//
//  Created by Andrew Poes on 8/25/15.
//  Copyright (c) 2015 Andrew Poes. All rights reserved.
//

import UIKit

func ==(lhs: APLoopingScrollView.IndexPath, rhs: APLoopingScrollView.IndexPath) -> Bool {
    return lhs.item == rhs.item && lhs.offset == rhs.offset
}

@objc protocol APLoopingScrollViewDataSource: class {
    func infiniteScrollViewTotalItems(scrollView: APLoopingScrollView) -> Int
    func infiniteScrollView(scrollView: APLoopingScrollView, viewForIndex index: Int) -> UIView
}

@objc protocol APLoopingScrollViewDelegate: UIScrollViewDelegate {
    optional func infiniteScrollView(scrollView: APLoopingScrollView, willDisplayView view: UIView)
    optional func infiniteScrollView(scrollView: APLoopingScrollView, didEndDisplayingView view: UIView)
    optional func infiniteScrollView(scrollView: APLoopingScrollView, didScrollToIndex index: Int)
}

class APLoopingScrollView: UIScrollView {
    struct IndexPath: Hashable {
        var item: Int
        var offset: Int
        
        func description() -> String {
            return "\(item):\(offset)"
        }
        
        var hashValue: Int {
            get {
                return 31 * item + offset
            }
        }
    }
    
    enum ScrollDirection {
        case Horizontal
        case Vertical
    }
    
    weak var dataSource: APLoopingScrollViewDataSource?
    weak var privateDelegate: APLoopingScrollViewDelegate? {
        get { return self.delegate as? APLoopingScrollViewDelegate }
        set { self.delegate = newValue }
    }
    override var delegate: UIScrollViewDelegate? {
        set {
            if let supportedDelegate = newValue as? APLoopingScrollViewDelegate {
                super.delegate = supportedDelegate
            }
            else if newValue != nil {
                print("Warning: wrong delegate type set. Should be of type APLoopingScrollViewDelegate")
            }
        }
        get { return super.delegate }
    }
    
    var scrollDirection: ScrollDirection = .Horizontal
    var itemSize: CGSize = CGSize() {
        didSet {
            self.setNeedsUpdateLayoutInfo()
            self.setNeedsLayout()
        }
    }
    var itemSpacing: CGFloat = 0 {
        didSet {
            self.setNeedsUpdateLayoutInfo()
            self.setNeedsLayout()
        }
    }
    var currentIndex: Int = 0
    var visibleItems = [IndexPath]()
    var cachedViews = [String: UIView]()
    var needsUpdateLayoutInfo: Bool = true
    func setNeedsUpdateLayoutInfo() {
        self.needsUpdateLayoutInfo = true
    }
    
    var dragInitialIndex: Int = 0
    var displayLink: CADisplayLink?
    var targetXOffset: CGFloat = 0
    var animXOffset: CGFloat = 0
    var animating: Bool = false
    private var _pagingEnabled: Bool = false
    override var pagingEnabled: Bool {
        get {
            return _pagingEnabled
        }
        set {
            _pagingEnabled = newValue
        }
    }
    
    var blockContentOffsetChanges: Bool = false
    
    override func touchesShouldCancelInContentView(view: UIView) -> Bool {
        return true
    }
    
    convenience init(frame: CGRect, scrollDirection: ScrollDirection) {
        self.init(frame: frame)
        self.scrollDirection = scrollDirection
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.sharedInit()
    }
    
    func sharedInit() {
        self.itemSize = self.frame.size
        self.clipsToBounds = true
        self.indicatorStyle = .White
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        
        // set the scroll speed to be tighter
        self.decelerationRate = UIScrollViewDecelerationRateFast
        
//         listen to pan gesture
        self.panGestureRecognizer.addTarget(self, action: "handlePanGesture:")
    }
    
    override var contentOffset: CGPoint {
        set {
            if self.blockContentOffsetChanges == false { super.contentOffset = newValue }
        }
        get {
            return super.contentOffset
        }
    }
    
    func calculatedCenterX() -> CGFloat {
        //        alternative
        //        0.5 * (-self.boundsWidth + totalItemWidth + self.itemSize.width)
        return 0.5 * (self.contentSize.width - self.boundsWidth - self.itemSpacing)
    }
    
    func updateViewLayoutInfo() {
        if self.needsUpdateLayoutInfo {
            self.needsUpdateLayoutInfo = false
            
            let totalItemWidth = itemSize.width + itemSpacing
            let contentSize = CGSize(width: totalItemWidth * 2, height: self.itemSize.height)
            let edgeInset = (self.boundsWidth - totalItemWidth) * 0.5
            let contentInset = UIEdgeInsets(top: 0, left: edgeInset, bottom: 0, right: edgeInset)
            
            self.contentSize = contentSize
            self.contentInset = contentInset
            
            let centerXOffset = self.calculatedCenterX()
            self.contentOffset = CGPoint(x: centerXOffset, y: 0)
        }
    }
    
    func recenterIfNeccesary() {
        let currentOffset = self.contentOffset
        let contentWidth = self.contentSize.width
        let centerXOffset = (contentWidth - self.boundsWidth) * 0.5
        let distanceFromCenter = fabs(currentOffset.x - centerXOffset)
        let totalItemWidth = itemSize.width + itemSpacing
        
        if distanceFromCenter > totalItemWidth * 0.5 {
            let centerX = self.calculatedCenterX()
            
            let offset = currentOffset.x > centerX ? 1 : -1
            let newIndex = self.currentIndex + offset
            self.currentIndex = safemod(newIndex, b: self.totalItems())
            
            
            let minLeft = -self.contentInset.left
            let maxRight = (self.contentSize.width - self.contentInset.right) - totalItemWidth
            let xOffset = offset > 0 ? minLeft : maxRight
            self.contentOffset = CGPointMake(xOffset, currentOffset.y)
            
            // update anim values
            if self.animating {
                self.targetXOffset = centerX
                self.animXOffset = self.contentOffset.x
            }
        }
    }
    
    func updateViews() {
        let visibleItems = self.visibleItems(forContentOffset: self.contentOffset)
        let hasChanges = self.hasChanges(visibleItems, self.visibleItems)
        let newItems = visibleItems.filter { return self.visibleItems.indexOf($0) == nil }
        let removedItems = self.visibleItems.filter { return visibleItems.indexOf($0) == nil }
        // save the values
        self.visibleItems = visibleItems
        
        for indexPath in visibleItems {
            // add any indexes not previously in visibleIndexes
            if newItems.indexOf(indexPath) != nil {
                if let view = self.view(forIndexPath: indexPath) {
                    self.privateDelegate?.infiniteScrollView?(self, willDisplayView: view)
                    self.insertSubview(view, atIndex: 0)
                }
            }
            // if there are changes, update the frames
            if hasChanges {
                if let view = self.view(forIndexPath: indexPath) {
                    view.frame = self.frameForView(indexPath.offset)
                }
            }
        }
        // remove any indexes not in visible indexes
        for indexPath in removedItems {
            if let view = self.view(forIndexPath: indexPath) {
                view.removeFromSuperview()
                self.privateDelegate?.infiniteScrollView?(self, didEndDisplayingView: view)
            }
        }
    }
    
    // given as offsets from the current index, i.e. [-2, -1, 0, 1, 2]
    func visibleItems(forContentOffset contentOffset: CGPoint) -> [IndexPath] {
        var visibleItems = [IndexPath]()
        let totalItemWidth = itemSize.width + itemSpacing
        let visibleRect = CGRect(x: contentOffset.x, y: 0, width: totalItemWidth + self.contentInset.left + self.contentInset.right, height: self.boundsHeight)
        let totalItems = self.totalItems()
        let minItems = Int(ceil(self.contentSize.width / totalItemWidth))
        let searchLength = max(totalItems, minItems)
        // go left
        for index in 0 ..< searchLength {
            // go left
            let frame = self.frameForView(-index)
            if CGRectIntersectsRect(frame, visibleRect) {
                let item = safemod(self.currentIndex - index, b: totalItems)
                let indexPath = IndexPath(item: item, offset: -index)
                visibleItems.append(indexPath)
            }
            // go right, skipping 0
            if index > 0 {
                let frame = self.frameForView(index)
                if CGRectIntersectsRect(frame, visibleRect) {
                    let item = safemod(self.currentIndex + index, b: totalItems)
                    let indexPath = IndexPath(item: item, offset: index)
                    visibleItems.append(indexPath)
                }
            }
        }
        // sort the offsets so they're in order
        visibleItems.sortInPlace { (a, b) -> Bool in
            return a.offset < b.offset
        }
        return visibleItems
    }
    
    func frameForView(distToCenterIndex: Int) -> CGRect {
        let totalItemWidth = itemSize.width + itemSpacing
        let xCenter = (self.contentSize.width - totalItemWidth) * 0.5
        let xOffset = xCenter + CGFloat(distToCenterIndex) * totalItemWidth
        let frame = CGRect(x: xOffset, y: (self.frameHeight - self.itemSize.height) * 0.5, width: self.itemSize.width, height: self.itemSize.height)
        return frame
    }
    
    func hasChanges(a: [IndexPath], _ b: [IndexPath]) -> Bool {
        if a.count != b.count {
            return true
        }
        else {
            for (i, ai) in a.enumerate() {
                let bi = b[i]
                if ai != bi {
                    return true
                }
            }
        }
        return false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // debug logs
//        println("x: \(self.contentOffset.x), left: \(self.contentInset.left), right: \(self.contentInset.right)")
        
        // updates the layout info if neccesary, that is
        // contentSize and edge insets to match view width
        self.updateViewLayoutInfo()
        // check contentOffset and recenter scroll offset
        self.recenterIfNeccesary()
        // update on screen views
        self.updateViews()
    }
    
    // MARK: Datasource protocol
    
    func totalItems() -> Int {
        if let totalItems = self.dataSource?.infiniteScrollViewTotalItems(self) {
            return totalItems
        }
        return 0
    }
    
    func view(forIndexPath indexPath: IndexPath) -> UIView? {
        let key = indexPath.description()
        if self.cachedViews.has(key) {
            return self.cachedViews[key]
        }
        else {
            if let view = self.dataSource?.infiniteScrollView(self, viewForIndex: indexPath.item) {
                self.cachedViews.updateValue(view, forKey: key)
                return view
            }
        }
        
        return nil
    }
    
    // MARK: UIPanGestureRecognizer
    
    func handlePanGesture(gestureRecognizer: UIPanGestureRecognizer) {
        if self.pagingEnabled {
            if gestureRecognizer.state == .Began {
                if self.animating {
                    self.stopTargetOffsetAnimation()
                }
                self.dragInitialIndex = self.currentIndex
            }
            else if gestureRecognizer.state == .Ended || gestureRecognizer.state == .Cancelled {
                var targetIndex = 0
                
                let totalItemWidth = self.itemSize.width + self.itemSpacing
                let panVelocity = gestureRecognizer.velocityInView(self)
                
                if self.currentIndex == self.dragInitialIndex && fabs(panVelocity.x) > 10 {
                    targetIndex = panVelocity.x < 0 ?  1 : -1
                }
                
                var xOffset = 0.5 * (-self.boundsWidth + totalItemWidth + self.itemSize.width)
                xOffset += self.boundsWidth * CGFloat(targetIndex)
                self.targetXOffset = xOffset
                self.animXOffset = self.contentOffset.x
                
                // start the animation
                self.startTargetOffsetAnimation()
            }
        }
    }
    
    // MARK: Force-Reload of views
    
    func reloadData() {
        for (_, view) in self.cachedViews {
            view.removeFromSuperview()
        }
        self.visibleItems.removeAll(keepCapacity: true)
        self.cachedViews.removeAll(keepCapacity: true)
    }
    
    // MARK: Programatic Animation
    
    func startTargetOffsetAnimation() {
        self.animating = true
        
        self.displayLink = CADisplayLink(target: self, selector: "animateToTargetOffset:")
        self.displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
    }
    
    func animateToTargetOffset(sender: CADisplayLink) {
        let delta = self.targetXOffset - self.animXOffset
        if fabs(delta) > 0.1 {
            let dx = delta * 0.3
            self.animXOffset += dx
            
            self.setContentOffset(CGPoint(x: self.animXOffset, y: self.contentOffset.y), animated: false)
        }
        else {
            self.setContentOffset(CGPoint(x: self.targetXOffset, y: self.contentOffset.y), animated: false)
            self.stopTargetOffsetAnimation()
            // inform the delegate
            self.privateDelegate?.infiniteScrollView?(self, didScrollToIndex: self.currentIndex)
        }
    }
    
    func stopTargetOffsetAnimation() {
        self.animating = false
        
        self.displayLink?.invalidate()
        self.displayLink = nil
        
        self.targetXOffset = 0
        self.animXOffset = 0
    }
}
