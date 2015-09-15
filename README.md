# APLoopingScrollView

![alt tag](https://raw.githubusercontent.com/MrBendel/APLoopingScrollView/master/APLoopingScrollView/APLoopingScrollView/gifs/horz.gif)    ![alt tag](https://raw.githubusercontent.com/MrBendel/APLoopingScrollView/master/APLoopingScrollView/APLoopingScrollView/gifs/vert.gif)

After failing to find a decent looping scroll view impelementation I set out to build my own. APLoopingScrollView is a direct subclass of `UIScrollView` that displays collections of "cards" in either horizontal or vertical orientation. 

You have control over:
* Item Size
* Item Spacing
* Scroll Direction
* Paging

APLoopingScrollView supports as few as 1 item and can repeat a single item as needed to fill the screen. The implementation is very simliar to `UICollectionView` in that there is a delegate and datasource. The delegate provides the functionality of UIScrollView mixed with added functionality for the looping ScrollView. The datasource provides the view with the neccesary information it needs to draw such as number of items, and the actual view to draw inside the ScrollView.

##How To Use:

    func loopingScrollViewTotalItems(scrollView: APLoopingScrollView) -> Int

Return the total number of items to display. This controls how many 'cards' appear on screen.

    func loopingScrollView(scrollView: APLoopingScrollView, viewForIndex index: Int) -> UIView

Return a view for the corrosponding index. *Note, this may be called multiple times for a single index!* If you have less items than needed to display on screen, you'll need to return a view for each instance of a single index, ie. if there's only 1 item to display, return a unique view for each index 0.

View's are not reused like in a table or collection view, but they are internaly cached. If you need to free the internal cache, call `reloadData` to force reload all visible views.

##TODO

* Logic for handling animation changes for orientation
* Logic for handling insertions or deletions from the view

Any questions or comments feel free to reach out!
