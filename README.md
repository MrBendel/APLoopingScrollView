# APLoopingScrollView
After failing to find a descent looping scroll view impelementation I set out to build my own. APLoopingScrollView is a direct subclass of `UIScrollView` that displays collections of "cards" in either horizontal or vertical orientation. 

You have control over:
* Item Size
* Item Spacing
* Scroll Direction
* Paging

APLoopingScrollView supports as few as 1 item and can repeat a single item as needed to fill the screen. The implementation is very simliar to `UICollectionView` in that there is a delegate and datasource. The delegate provides the functionality of UIScrollView mixed with added functionality for the looping ScrollView. The datasource provides the view with the neccesary information it needs to draw such as number of items, and the actual view to draw inside the ScrollView.

Any questions or comments feel free to reach out!
