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
    func loopingScrollViewTotalItems(scrollView: APLoopingScrollView) -> Int
    func loopingScrollView(scrollView: APLoopingScrollView, viewForIndex index: Int) -> UIView
}

@objc protocol APLoopingScrollViewDelegate: UIScrollViewDelegate {
    optional func loopingScrollView(scrollView: APLoopingScrollView, willDisplayView view: UIView)
    optional func loopingScrollView(scrollView: APLoopingScrollView, didEndDisplayingView view: UIView)
    optional func loopingScrollView(scrollView: APLoopingScrollView, didScrollToIndex index: Int)
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
    var targetOffset: CGFloat = 0
    var animOffset: CGFloat = 0
    var animating: Bool = false
    private var _pagingEnabled: Bool = false {
        didSet {
            if _pagingEnabled {
                // set the scroll speed to be tighter
                self.decelerationRate = UIScrollViewDecelerationRateFast
            }
            else {
                // set the scroll speed to be looser
                self.decelerationRate = UIScrollViewDecelerationRateNormal
            }
        }
    }
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
        // Uncomment if you want to see whats happening
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        
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
    
    func calculatedCenter() -> CGFloat {
        var center: CGFloat = 0
        if self.scrollDirection == .Vertical {
            center = 0.5 * (self.contentSize.height - self.boundsHeight - self.itemSpacing)
        }
        else /*if self.scrollDirection == .Horizontal*/ {
            center = 0.5 * (self.contentSize.width - self.boundsWidth - self.itemSpacing)
        }
        return center
    }
    
    func updateViewLayoutInfo() {
        if self.needsUpdateLayoutInfo {
            self.needsUpdateLayoutInfo = false
            
            let totalItemSpace: CGFloat
            let contentSize: CGSize
            let edgeInset: CGFloat
            let contentInset: UIEdgeInsets
            
            if self.scrollDirection == .Vertical {
                totalItemSpace = itemSize.height + itemSpacing
                contentSize = CGSize(width: self.itemSize.width, height: totalItemSpace * 2)
                edgeInset = (self.boundsHeight - totalItemSpace) * 0.5
                contentInset = UIEdgeInsets(top: edgeInset, left: 0, bottom: edgeInset, right: 0)
            }
            else /*if self.scrollDirection == .Horizontal*/ {
                totalItemSpace = itemSize.width + itemSpacing
                contentSize = CGSize(width: totalItemSpace * 2, height: self.itemSize.height)
                edgeInset = (self.boundsWidth - totalItemSpace) * 0.5
                contentInset = UIEdgeInsets(top: 0, left: edgeInset, bottom: 0, right: edgeInset)
            }
            
            self.contentSize = contentSize
            self.contentInset = contentInset
            
            let centerOffset = self.calculatedCenter()
            let contentOffset: CGPoint
            if self.scrollDirection == .Vertical {
                contentOffset = CGPoint(x: 0, y: centerOffset)
            }
            else /*if self.scrollDirection == .Horizontal*/ {
                contentOffset = CGPoint(x: centerOffset, y: 0)
            }
            self.contentOffset = contentOffset
        }
    }
    
    func recenterIfNeccesary() {
        let currentOffset: CGFloat
        let contentSize: CGFloat
        let centerOffset: CGFloat
        let distanceFromCenter: CGFloat
        let totalItemSpace: CGFloat
        let minOffset: CGFloat
        let maxOffset: CGFloat
        
        if self.scrollDirection == .Vertical {
            currentOffset = self.contentOffset.y
            contentSize = self.contentSize.height
            centerOffset = (contentSize - self.boundsHeight) * 0.5
            distanceFromCenter = fabs(currentOffset - centerOffset)
            totalItemSpace = self.itemSize.height + self.itemSpacing
        }
        else /*if self.scrollDirection == .Horizontal*/ {
            currentOffset = self.contentOffset.x
            contentSize = self.contentSize.width
            centerOffset = (contentSize - self.boundsWidth) * 0.5
            distanceFromCenter = fabs(currentOffset - centerOffset)
            totalItemSpace = self.itemSize.width + self.itemSpacing
        }
        
        if distanceFromCenter > totalItemSpace * 0.5 {
            if self.scrollDirection == .Vertical {
                minOffset = -self.contentInset.top
                maxOffset = self.contentSize.height - self.contentInset.bottom - totalItemSpace
            }
            else /*if self.scrollDirection == .Horizontal*/ {
                minOffset = -self.contentInset.left
                maxOffset = self.contentSize.width - self.contentInset.right - totalItemSpace
            }

            let center = self.calculatedCenter()
            let indexOffset = currentOffset > center ? 1 : -1
            let newIndex = self.currentIndex + indexOffset
            self.currentIndex = safemod(newIndex, b: self.totalItems())

            let newOffset = indexOffset > 0 ? minOffset : maxOffset
            if self.scrollDirection == .Vertical {
                self.contentOffset = CGPointMake(self.contentOffset.x, newOffset)
            }
            else /*if self.scrollDirection == .Horizontal*/ {
                self.contentOffset = CGPointMake(newOffset, self.contentOffset.y)
            }
            
            // update anim values
            if self.animating {
                self.targetOffset = center
                if self.scrollDirection == .Vertical {
                    self.animOffset = self.contentOffset.y
                }
                else /*if self.scrollDirection == .Horizontal*/ {
                    self.animOffset = self.contentOffset.x
                }
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
                    self.privateDelegate?.loopingScrollView?(self, willDisplayView: view)
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
                self.privateDelegate?.loopingScrollView?(self, didEndDisplayingView: view)
            }
        }
    }
    
    // given as offsets from the current index, i.e. [-2, -1, 0, 1, 2]
    func visibleItems(forContentOffset contentOffset: CGPoint) -> [IndexPath] {
        var visibleItems = [IndexPath]()
        
        let totalItemSpace: CGFloat
        let visibleRect: CGRect
        
        if self.scrollDirection == .Vertical {
            totalItemSpace = self.itemSize.height + self.itemSpacing
            visibleRect = CGRect(x: 0, y: self.contentOffset.y, width: self.boundsWidth, height: totalItemSpace + self.contentInset.top + self.contentInset.bottom)
        }
        else /*if self.scrollDirection == .Horizontal*/ {
            totalItemSpace = self.itemSize.width + self.itemSpacing
            visibleRect = CGRect(x: self.contentOffset.x, y: 0, width: totalItemSpace + self.contentInset.left + self.contentInset.right, height: self.boundsHeight)
        }
        
        let totalItems = self.totalItems()
        let minItems = Int(ceil(self.contentSize.width / totalItemSpace))
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
        let totalItemSpace: CGFloat
        let screenCenter: CGFloat
        
        if self.scrollDirection == .Vertical {
            totalItemSpace = self.itemSize.height + self.itemSpacing
            screenCenter = (self.contentSize.height - totalItemSpace) * 0.5
        }
        else /*if self.scrollDirection == .Horizontal*/ {
            totalItemSpace = self.itemSize.width + self.itemSpacing
            screenCenter = (self.contentSize.width - totalItemSpace) * 0.5
        }

        let offset = screenCenter + CGFloat(distToCenterIndex) * totalItemSpace
        let frame: CGRect
        
        if self.scrollDirection == .Vertical {
            frame = CGRect(x: (self.frameWidth - self.itemSize.width) * 0.5, y: offset, width: self.itemSize.width, height: self.itemSize.height)
        }
        else /*if self.scrollDirection == .Horizontal*/ {
            frame = CGRect(x: offset, y: (self.frameHeight - self.itemSize.height) * 0.5, width: self.itemSize.width, height: self.itemSize.height)
        }
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
        if let totalItems = self.dataSource?.loopingScrollViewTotalItems(self) {
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
            if let view = self.dataSource?.loopingScrollView(self, viewForIndex: indexPath.item) {
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
                
                let panVelocity = gestureRecognizer.velocityInView(self)
                let activeVelocity: CGFloat
                let totalItemSpace: CGFloat
                var offset: CGFloat
                var boundsSize: CGFloat
                var currentOffset: CGFloat
                
                if self.scrollDirection == .Vertical {
                    activeVelocity = panVelocity.y
                    boundsSize = self.boundsHeight
                    totalItemSpace = self.itemSize.height + self.itemSpacing
                    offset = 0.5 * (-boundsSize + totalItemSpace + self.itemSize.height)
                    currentOffset = self.contentOffset.y
                }
                else /*if self.scrollDirection == .Horizontal*/ {
                    activeVelocity = panVelocity.x
                    boundsSize = self.boundsWidth
                    totalItemSpace = self.itemSize.width + self.itemSpacing
                    offset = 0.5 * (-boundsSize + totalItemSpace + self.itemSize.width)
                    currentOffset = self.contentOffset.x
                }
                
                if self.currentIndex == self.dragInitialIndex && fabs(activeVelocity) > 10 {
                    targetIndex = activeVelocity < 0 ?  1 : -1
                }
                
                offset += boundsSize * CGFloat(targetIndex)
                self.targetOffset = offset
                self.animOffset = currentOffset
                
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
        let delta = self.targetOffset - self.animOffset
        if fabs(delta) > 0.1 {
            let dx = delta * 0.3
            self.animOffset += dx
            self._setContentOffset(self.animOffset)
        }
        else {
            self._setContentOffset(self.animOffset)
            self.stopTargetOffsetAnimation()
            // inform the delegate
            self.privateDelegate?.loopingScrollView?(self, didScrollToIndex: self.currentIndex)
        }
    }
    
    private func _setContentOffset(offset: CGFloat) {
        if self.scrollDirection == .Vertical {
            self.setContentOffset(CGPoint(x: self.contentOffset.x, y: offset), animated: false)
        }
        else /*if self.scrollDirection == .Horizontal*/ {
           self.setContentOffset(CGPoint(x: offset, y: self.contentOffset.y), animated: false)
        }
    }
    
    func stopTargetOffsetAnimation() {
        self.animating = false
        
        self.displayLink?.invalidate()
        self.displayLink = nil
        
        self.targetOffset = 0
        self.animOffset = 0
    }
}
