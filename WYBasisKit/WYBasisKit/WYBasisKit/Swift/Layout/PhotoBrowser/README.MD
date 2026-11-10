# PhotoBrowser

`WYPhotoBrowser`支持整页、多页同屏与叠卡三种布局，使用同一份数据源、当前页和翻页事件。视频项显示封面与播放入口，播放操作通过`wy_photoBrowser(_:didTapPlayVideoItemAt:)`交给接入方。

## 嵌入叠卡

```swift
var configuration = WYPhotoBrowserConfiguration()
configuration.layoutStyle = .stackedCards
configuration.isEmbedded = true
configuration.pageIndicatorStyle = .none
configuration.appearance.backgroundColor = .clear
configuration.stackedCardCount = 3
configuration.stackedCardRotationAngle = .pi / 90

let browser = WYPhotoBrowser(configuration: configuration)
browser.dataSource = source
browser.browserDelegate = delegate
parent.addChild(browser)
container.addSubview(browser.view)
browser.view.frame = container.bounds
browser.didMove(toParent: parent)
```

父控制器持有浏览器，并随容器尺寸更新`browser.view.frame`。移除时依次调用`willMove(toParent: nil)`、移除浏览器视图、`removeFromParent()`。数据源和代理为弱引用，接入方须持有它们。

`stackedCardCount`控制显示层数，`stackedCardOffset`控制层间偏移，`stackedCardRotationAngle`和`stackedCardDragRotationAngle`分别控制静止与滑动的旋转角度，`stackedCardCornerRadius`和`stackedCardContentMode`控制图片外观。`scrollDirection`支持横向或纵向翻页。

嵌入模式单击通过`wy_photoBrowser(_:didTapItemAt:)`回调，不关闭父页面，关闭缩放和长按菜单。展开、收起按钮及事件由容器界面管理。

```objc
WYPhotoBrowserConfiguration *configuration = [[WYPhotoBrowserConfiguration alloc] init];
configuration.layoutStyle = WYPhotoBrowserLayoutStyleStackedCards;
configuration.isEmbedded = true;
WYPhotoBrowser *browser = WYPhotoBrowserController.create(configuration);
browser.dataSource = source;
browser.browserDelegate = delegate;
```

## 全屏浏览与页码

调用`WYPhotoBrowser.show(from:index:dataSource:configuration:delegate:)`打开全屏浏览器，全屏配置保持`isEmbedded = false`。`sourceView(at:)`返回指定可见页的图片视图，可供外层转场使用；不可见页返回nil。Objective-C对应`browser.sourceViewAtIndex(index)`。

写入`currentIndex`立即切页，`scrollToItem(at:animated:)`可选择动画。越界页码被忽略，实际切换后通知`wy_photoBrowser(_:didShowItemAt:)`。数据变化后调用`reloadData()`，尽量保留当前页。
