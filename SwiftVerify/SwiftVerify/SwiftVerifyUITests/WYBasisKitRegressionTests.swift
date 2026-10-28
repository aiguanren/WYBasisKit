import XCTest
import UIKit
import AppIntents

/// 通过正常测试页面执行图片浏览和播放器交互回归
final class WYBasisKitRegressionTests: XCTestCase {

    @MainActor
    func testNavigationTabsRestoreAfterPushAndBack() throws {
        continueAfterFailure = false
        let app = launchApp()
        capture(app, name: "navigation-main-top-background")
        for title in ["图片浏览", "TableViewCell侧滑"] {
            open(title, in: app)
            let bar = app.navigationBars.firstMatch
            XCTAssertTrue(bar.waitForExistence(timeout: 5))
            if title == "图片浏览" {
                let configuration = app.navigationBars.buttons["配置"]
                XCTAssertTrue(configuration.waitForExistence(timeout: 5))
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.005, dy: 0.4)).press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.18, dy: 0.4)), withVelocity: .slow, thenHoldForDuration: 0.5)
                let cancelled = NSPredicate { _, _ in configuration.isHittable }
                XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: cancelled, object: nil)], timeout: 5), .completed)
                capture(app, name: "navigation-cancelled-pop")
            }
            capture(app, name: "navigation-open-" + title)
            let systemBack = app.buttons["BackButton"]
            let back = systemBack.exists ? systemBack : bar.buttons.firstMatch
            XCTAssertTrue(back.isHittable)
            back.tap()
            let tab = app.buttons["左"].firstMatch
            let restored = NSPredicate { _, _ in tab.isHittable }
            XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: restored, object: nil)], timeout: 5), .completed)
            XCTAssertTrue(app.tables.firstMatch.waitForExistence(timeout: 5))
            capture(app, name: "navigation-restored-" + title)
        }
    }

    @MainActor
    func testRichTextSafeAreaAndScrolling() throws {
        continueAfterFailure = false
        let app = launchApp()
        open("富文本", in: app)
        let scroll = app.scrollViews["WYRichText.scroll"]
        let primary = app.staticTexts["WYRichText.primary"]
        XCTAssertTrue(scroll.waitForExistence(timeout: 5))
        XCTAssertTrue(primary.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(primary.frame.minX, scroll.frame.minX)
        XCTAssertLessThanOrEqual(primary.frame.maxX, scroll.frame.maxX)
        capture(app, name: "rich-text-safe-area")
        let measured = app.staticTexts["WYRichText.height"]
        for _ in 0..<12 {
            if measured.isHittable { break }
            scroll.swipeUp()
        }
        XCTAssertTrue(measured.isHittable)
        XCTAssertGreaterThanOrEqual(measured.frame.minX, scroll.frame.minX)
        XCTAssertLessThanOrEqual(measured.frame.maxX, scroll.frame.maxX)
        capture(app, name: "rich-text-height-measurement")
    }

    @MainActor
    func testSideslipControlsAndReuse() throws {
        continueAfterFailure = false
        let app = launchApp()
        open("TableViewCell侧滑", in: app)
        if app.buttons["长拉:开"].exists { app.buttons["长拉:开"].tap() }
        let table = app.tables.firstMatch
        let first = table.cells.element(boundBy: 0)
        for priority in ["手势:自动", "手势:侧滑优先", "手势:返回优先"] {
            XCTAssertTrue(app.buttons[priority].exists)
            for position in [0.15, 0.35, 0.55] {
                let origin = first.coordinate(withNormalizedOffset: CGVector(dx: position, dy: 0.5))
                origin.press(forDuration: 0.05, thenDragTo: first.coordinate(withNormalizedOffset: CGVector(dx: position + 0.3, dy: 0.5)))
                let left = first.buttons["(左)删除"].firstMatch
                XCTAssertTrue(left.waitForExistence(timeout: 5), "内容区域右滑应打开侧滑")
                XCTAssertTrue(left.isHittable, "侧滑操作不应触发页面返回")
                XCTAssertTrue(app.navigationBars["侧滑功能验证"].exists)
                table.cells.element(boundBy: 1).tap()
            }
            app.buttons[priority].tap()
        }
        let start = first.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: first.coordinate(withNormalizedOffset: CGVector(dx: 0.65, dy: 0.5)))
        let leftDelete = first.buttons["(左)删除"].firstMatch
        XCTAssertTrue(leftDelete.waitForExistence(timeout: 5))
        XCTAssertTrue(leftDelete.isHittable)
        capture(app, name: "sideslip-left")
        table.cells.element(boundBy: 1).tap()
        let closed = NSPredicate { _, _ in !leftDelete.isHittable }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: closed, object: nil)], timeout: 5), .completed)
        start.press(forDuration: 0.05, thenDragTo: first.coordinate(withNormalizedOffset: CGVector(dx: 0.65, dy: 0.5)))
        leftDelete.tap()
        XCTAssertTrue(table.cells.element(boundBy: 0).staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "测试单元格 2")).firstMatch.waitForExistence(timeout: 5))
        let second = table.cells.element(boundBy: 1)
        second.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5)).press(forDuration: 0.05, thenDragTo: second.coordinate(withNormalizedOffset: CGVector(dx: 0.35, dy: 0.5)))
        let rightDelete = second.buttons["(右)删除"].firstMatch
        let opened = NSPredicate { _, _ in rightDelete.isHittable }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: opened, object: nil)], timeout: 5), .completed)
        rightDelete.tap()
        XCTAssertTrue(table.cells.element(boundBy: 1).staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "测试单元格 4")).firstMatch.waitForExistence(timeout: 5))
        capture(app, name: "sideslip-after-deletion")
        let edge = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: 1, dy: table.cells.element(boundBy: 0).frame.midY))
        edge.press(forDuration: 0.05, thenDragTo: edge.withOffset(CGVector(dx: app.frame.width * 0.7, dy: 0)))
        XCTAssertTrue(app.tables.cells.containing(.staticText, identifier: "TableViewCell侧滑").firstMatch.waitForExistence(timeout: 5), "自动模式边缘右滑仍应允许返回")
    }

    @MainActor
    func testRenamedAnimatedResources() throws {
        continueAfterFailure = false
        let app = launchApp()
        open("Gif加载", in: app)
        for identifier in ["oneGifView", "oneApngView", "customGifView", "customApngView"] {
            let image = app.descendants(matching: .any)["WYAnimation." + identifier]
            XCTAssertTrue(image.waitForExistence(timeout: 5))
            let first = image.screenshot().pngRepresentation
            var changes = false
            for interval in [0.17, 0.31, 0.47, 0.23, 0.41] {
                Thread.sleep(forTimeInterval: interval)
                if image.screenshot().pngRepresentation != first { changes = true; break }
            }
            XCTAssertTrue(changes, "循环动图应持续显示不同帧")
        }
        capture(app, name: "renamed-animated-resources")
    }

    @MainActor
    func testPhotoTouchGestures() throws {
        continueAfterFailure = false
        let app = launchApp()
        open("图片浏览", in: app)
        let grid = app.collectionViews.firstMatch
        XCTAssertTrue(grid.waitForExistence(timeout: 10))
        grid.cells.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["1/17"].waitForExistence(timeout: 10))
        let photo = app.scrollViews.firstMatch
        XCTAssertTrue(photo.waitForExistence(timeout: 5))
        photo.swipeLeft()
        XCTAssertTrue(app.staticTexts["2/17"].waitForExistence(timeout: 5), "应能滑到相邻图片")
        photo.swipeLeft()
        XCTAssertTrue(app.staticTexts["3/17"].waitForExistence(timeout: 5))
        photo.swipeRight()
        photo.swipeRight()
        XCTAssertTrue(app.staticTexts["1/17"].waitForExistence(timeout: 5))
        capture(app, name: "photo-paged-back")
        let original = app.screenshot().pngRepresentation
        capture(app, name: "photo-original")
        photo.doubleTap()
        capture(app, name: "photo-double-zoom")
        XCTAssertTrue(app.screenshot().pngRepresentation != original, "双击后图片应放大")
        photo.doubleTap()
        capture(app, name: "photo-double-reset")
        photo.pinch(withScale: 4, velocity: 1)
        capture(app, name: "photo-pinch")
        XCTAssertTrue(app.screenshot().pngRepresentation != original, "捏合后图片应放大")
        photo.doubleTap()
        photo.swipeLeft()
        XCTAssertTrue(app.staticTexts["2/17"].waitForExistence(timeout: 5), "缩放还原后应能继续翻页")
        photo.swipeRight()
        XCTAssertTrue(app.staticTexts["1/17"].waitForExistence(timeout: 5))
        photo.press(forDuration: 1)
        XCTAssertTrue(app.buttons["保存图片"].waitForExistence(timeout: 5))
        capture(app, name: "photo-longpress-menu")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.1)).tap()
        XCTAssertFalse(app.buttons["保存图片"].isHittable)
        let start = photo.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: 0, dy: 30)), withVelocity: .slow, thenHoldForDuration: 0.3)
        XCTAssertTrue(app.staticTexts["1/17"].exists, "短拖后应留在浏览器")
        start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: 0, dy: photo.frame.height * 0.4)), withVelocity: .slow, thenHoldForDuration: 0.3)
        XCTAssertTrue(app.staticTexts["浏览器已关闭"].waitForExistence(timeout: 5), "长拖后应关闭浏览器")
    }

    @MainActor
    func testPhotoMultiPageHorizontal() throws {
        continueAfterFailure = false
        let app = launchApp()
        open("图片浏览", in: app)
        capture(app, name: "photo-config-entry")
        app.buttons["配置"].tap()
        app.staticTexts["同屏布局"].tap()
        app.buttons["多页同屏(一次多张)"].tap()
        app.buttons["保存"].tap()
        app.collectionViews.firstMatch.cells.element(boundBy: 1).tap()
        XCTAssertTrue(app.staticTexts["2/17"].waitForExistence(timeout: 5))
        capture(app, name: "photo-multi-centered")
        let page = app.windows.firstMatch
        let right = page.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.5))
        let left = page.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.5))
        right.press(forDuration: 0.1, thenDragTo: left, withVelocity: .slow, thenHoldForDuration: 0.3)
        XCTAssertTrue(app.staticTexts["3/17"].waitForExistence(timeout: 5))
        left.press(forDuration: 0.1, thenDragTo: right, withVelocity: .slow, thenHoldForDuration: 0.3)
        XCTAssertTrue(app.staticTexts["2/17"].waitForExistence(timeout: 5))
        page.doubleTap()
        page.doubleTap()
        left.press(forDuration: 0.1, thenDragTo: right, withVelocity: .slow, thenHoldForDuration: 0.3)
        XCTAssertTrue(app.staticTexts["1/17"].waitForExistence(timeout: 5))
        capture(app, name: "photo-multi-first")
    }

    @MainActor
    func testPhotoAnimatedImageAndFailureRetry() throws {
        continueAfterFailure = false
        let app = launchApp()
        open("图片浏览", in: app)
        app.collectionViews.firstMatch.cells.element(boundBy: 7).tap()
        XCTAssertTrue(app.staticTexts["8/17"].waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 1)
        let first = XCUIScreen.main.screenshot().pngRepresentation
        Thread.sleep(forTimeInterval: 1.2)
        XCTAssertNotEqual(first, XCUIScreen.main.screenshot().pngRepresentation, "本地动图应持续更新画面")
        capture(app, name: "photo-gif-playing")
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
        XCTAssertTrue(app.staticTexts["浏览器已关闭"].waitForExistence(timeout: 5))
        let grid = app.collectionViews.firstMatch
        let failure = grid.cells["WYPhotoGrid.15"]
        for _ in 0..<5 {
            if failure.isHittable { break }
            grid.swipeUp()
        }
        XCTAssertTrue(failure.isHittable)
        failure.tap()
        XCTAssertTrue(app.staticTexts["16/17"].waitForExistence(timeout: 5))
        let retry = app.buttons["加载失败，点击重试"]
        XCTAssertTrue(retry.waitForExistence(timeout: 30))
        retry.tap()
        XCTAssertTrue(retry.waitForExistence(timeout: 30))
        capture(app, name: "photo-failure-retry")
        app.scrollViews.firstMatch.swipeRight()
        XCTAssertTrue(app.staticTexts["15/17"].waitForExistence(timeout: 5), "失败页仍应允许翻页")
    }

    @MainActor
    func testPhotoLocalLivePhoto() throws {
        continueAfterFailure = false
        let app = launchApp()
        open("图片浏览", in: app)
        let grid = app.collectionViews.firstMatch
        let thumbnail = grid.cells["WYPhotoGrid.10"]
        for _ in 0..<5 {
            if thumbnail.isHittable { break }
            grid.swipeUp()
        }
        XCTAssertTrue(thumbnail.isHittable)
        thumbnail.tap()
        XCTAssertTrue(app.staticTexts["11/17"].waitForExistence(timeout: 10))
        let badge = app.staticTexts["WYPhotoBrowser.liveBadge"]
        XCTAssertTrue(badge.waitForExistence(timeout: 20), "有效配对素材应加载为可播放的 Live Photo")
        capture(app, name: "photo-live-local-result")
        app.scrollViews.firstMatch.press(forDuration: 1)
        capture(app, name: "photo-live-playback")
        app.scrollViews.firstMatch.swipeRight()
        XCTAssertTrue(app.staticTexts["10/17"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testPhotoSecondLocalLivePhoto() throws {
        continueAfterFailure = false
        let app = launchApp()
        open("图片浏览", in: app)
        let grid = app.collectionViews.firstMatch
        let thumbnail = grid.cells["WYPhotoGrid.16"]
        for _ in 0..<5 {
            if thumbnail.isHittable { break }
            grid.swipeUp()
        }
        XCTAssertTrue(thumbnail.isHittable)
        thumbnail.tap()
        XCTAssertTrue(app.staticTexts["17/17"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["WYPhotoBrowser.liveBadge"].waitForExistence(timeout: 20))
        app.scrollViews.firstMatch.press(forDuration: 1)
        capture(app, name: "photo-live-second-playback")
        app.scrollViews.firstMatch.swipeRight()
        XCTAssertTrue(app.staticTexts["16/17"].waitForExistence(timeout: 5))
        app.scrollViews.firstMatch.swipeLeft()
        XCTAssertTrue(app.staticTexts["17/17"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["WYPhotoBrowser.liveBadge"].exists, "翻页返回后仍应保留已加载的 Live Photo")
    }

    @MainActor
    func testPhotoVerticalPaging() throws {
        continueAfterFailure = false
        let app = launchApp()
        open("图片浏览", in: app)
        app.buttons["配置"].tap()
        app.staticTexts["翻页方向"].tap()
        app.buttons["纵向上下翻页"].tap()
        app.buttons["保存"].tap()
        app.collectionViews.firstMatch.cells.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["1/17"].waitForExistence(timeout: 5))
        let page = app.scrollViews.firstMatch
        page.swipeUp()
        XCTAssertTrue(app.staticTexts["2/17"].waitForExistence(timeout: 5), "竖滑应翻页，不能误触关闭")
        page.swipeDown()
        XCTAssertTrue(app.staticTexts["1/17"].waitForExistence(timeout: 5))
        capture(app, name: "photo-vertical-returned")
    }

    @MainActor
    func testPhotoLoopPagingAndReload() throws {
        continueAfterFailure = false
        let app = launchApp()
        open("图片浏览", in: app)
        app.buttons["配置"].tap()
        let row = app.tables.cells.containing(.staticText, identifier: "循环翻页(末页无缝回首页)").firstMatch
        for _ in 0..<12 {
            if row.switches.firstMatch.isHittable { break }
            app.tables.firstMatch.swipeUp()
        }
        row.switches.firstMatch.tap()
        app.buttons["保存"].tap()
        app.collectionViews.firstMatch.cells.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["1/17"].waitForExistence(timeout: 5))
        let page = app.scrollViews.firstMatch
        page.swipeRight()
        XCTAssertTrue(app.staticTexts["17/17"].waitForExistence(timeout: 5))
        page.swipeLeft()
        XCTAssertTrue(app.staticTexts["1/17"].waitForExistence(timeout: 5))
        page.press(forDuration: 1)
        app.buttons["数据+1并刷新"].tap()
        XCTAssertTrue(app.staticTexts["1/18"].waitForExistence(timeout: 5))
        capture(app, name: "photo-loop-reloaded")
    }

    @MainActor
    func testImageEditorCropAndMark() throws {
        continueAfterFailure = false
        let app = launchApp()
        open("相片裁剪与标记", in: app)
        app.buttons["Block方式 打开编辑器"].tap()
        XCTAssertTrue(app.buttons["完成"].waitForExistence(timeout: 5))
        app.windows.firstMatch.pinch(withScale: 2, velocity: 1)
        let pendingCrop = NSPredicate { _, _ in
            app.buttons.matching(identifier: "裁剪").allElementsBoundByIndex.contains { $0.frame.maxY <= app.buttons["还原"].frame.maxY + 1 }
        }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: pendingCrop, object: nil)], timeout: 5), .completed)
        let cropTitle = app.buttons.matching(identifier: "裁剪").allElementsBoundByIndex.min { $0.frame.minY < $1.frame.minY }!
        XCTAssertGreaterThanOrEqual(cropTitle.frame.minX, app.buttons["取消"].frame.maxX)
        XCTAssertLessThanOrEqual(cropTitle.frame.maxX, app.buttons["还原"].frame.minX)
        XCTAssertLessThanOrEqual(app.buttons["还原"].frame.maxX, app.buttons["完成"].frame.minX)
        let cropMode = app.buttons.matching(identifier: "裁剪").allElementsBoundByIndex.max { $0.frame.minY < $1.frame.minY }!
        XCTAssertGreaterThanOrEqual(cropMode.frame.height, cropMode.staticTexts["裁剪"].frame.height)
        XCTAssertGreaterThanOrEqual(app.buttons["标记"].frame.height, app.buttons["标记"].staticTexts["标记"].frame.height)
        capture(app, name: "editor-header-and-mode")
        app.buttons["裁剪"].firstMatch.tap()
        app.buttons["标记"].tap()
        for title in ["文本", "划线", "马赛克", "水印"] {
            app.buttons[title].tap()
            let tool = app.buttons["文本"].frame
            let hintPrefix = title == "文本" ? "文本" : (title == "水印" ? "水印" : "画笔")
            let hintSuffix = title == "文本" || title == "水印" ? "字号" : "粗细"
            let hint = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", hintPrefix, hintSuffix)).firstMatch
            XCTAssertTrue(hint.waitForExistence(timeout: 5))
            let colors = app.buttons.allElementsBoundByIndex.filter {
                $0.label.isEmpty && $0.frame.width > 0 && $0.frame.midY > tool.midY && $0.frame.midY < hint.frame.midY
            }
            XCTAssertFalse(colors.isEmpty, "标记页应显示颜色选项")
            for color in colors {
                XCTAssertGreaterThanOrEqual(color.frame.minY, tool.maxY, "颜色选项不能与工具行重叠")
                XCTAssertLessThanOrEqual(color.frame.maxY, hint.frame.minY, "颜色选项不能与样式行重叠")
            }
            XCTAssertLessThanOrEqual(hint.frame.maxY, app.frame.maxY)
            let styleControls = app.buttons.allElementsBoundByIndex.filter {
                $0.frame.width > 0 && $0.frame.midY >= hint.frame.minY && $0.frame.midY <= hint.frame.maxY
            }
            for index in styleControls.indices {
                for next in styleControls.indices where next > index {
                    let overlap = styleControls[index].frame.intersection(styleControls[next].frame)
                    XCTAssertTrue(overlap.isNull || overlap.width < 0.5 || overlap.height < 0.5, "样式控件之间不能重叠")
                }
            }
            capture(app, name: "editor-toolbar-" + title)
            if title == "划线" {
                let toolbar = app.scrollViews.containing(.button, identifier: "文本").firstMatch
                let styleRow = app.scrollViews.containing(.button, identifier: "自由").firstMatch
                let colorRow = app.scrollViews.allElementsBoundByIndex.first {
                    $0.frame.minY >= toolbar.frame.maxY - 1 && $0.frame.maxY <= styleRow.frame.minY + 1 && $0.buttons.count > 0
                }
                XCTAssertNotNil(colorRow, "颜色行应有独立滚动容器")
                guard let colorRow = colorRow, let color = colors.first else { return }
                let text = app.buttons["文本"]
                let textX = text.frame.minX
                let colorX = color.frame.minX
                let hintX = hint.frame.minX
                styleRow.swipeLeft()
                XCTAssertEqual(text.frame.minX, textX, accuracy: 1, "滚动样式行不能带动工具行")
                XCTAssertEqual(color.frame.minX, colorX, accuracy: 1, "滚动样式行不能带动颜色行")
                let free = app.buttons["自由"]
                XCTAssertTrue(free.isHittable, "横向滚动后应能操作后面的样式按钮")
                free.tap()
                XCTAssertTrue(free.isSelected)
                capture(app, name: "editor-toolbar-line-scrolled")
                styleRow.swipeRight()
                let toolOverflows = toolbar.buttons.allElementsBoundByIndex.contains { $0.frame.maxX > toolbar.frame.maxX + 1 }
                toolbar.swipeLeft()
                if toolOverflows { XCTAssertLessThan(text.frame.minX, textX - 1) }
                XCTAssertEqual(color.frame.minX, colorX, accuracy: 1, "滚动工具行不能带动颜色行")
                XCTAssertEqual(hint.frame.minX, hintX, accuracy: 1, "滚动工具行不能带动样式行")
                toolbar.swipeRight()
                let restoredTextX = text.frame.minX
                let colorOverflows = colorRow.buttons.allElementsBoundByIndex.contains { $0.frame.maxX > colorRow.frame.maxX + 1 }
                colorRow.swipeLeft()
                if colorOverflows { XCTAssertLessThan(color.frame.minX, colorX - 1) }
                XCTAssertEqual(text.frame.minX, restoredTextX, accuracy: 1, "滚动颜色行不能带动工具行")
                XCTAssertEqual(hint.frame.minX, hintX, accuracy: 1, "滚动颜色行不能带动样式行")
                capture(app, name: "editor-three-independent-rows")
                colorRow.swipeRight()
            }
        }
        app.buttons["箭头"].tap()
        let canvas = app.windows.firstMatch
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.35, dy: 0.4)).press(forDuration: 0.1, thenDragTo: canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.65, dy: 0.5)))
        capture(app, name: "editor-arrow")
        app.buttons["完成"].tap()
        XCTAssertTrue(app.staticTexts["Block方式"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tables.cells.element(boundBy: 2).images.firstMatch.exists, "编辑结果应返回并显示图片")
        capture(app, name: "editor-result")
    }

    @MainActor
    func testVideoFullscreenAndRateMenu() throws {
        continueAfterFailure = false
        let app = launchApp()
        open("点播播放器", in: app)
        let player = app.otherElements["WYVideoPlayerDemo.player"]
        let originalFrame = player.frame
        let fullscreen = app.buttons["WYVideoPlayer.fullscreen"]
        XCTAssertTrue(fullscreen.waitForExistence(timeout: 10))
        if !fullscreen.isHittable { fullscreen.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap() }
        fullscreen.tap()
        if UIDevice.current.userInterfaceIdiom == .pad {
            let expanded = NSPredicate { _, _ in
                let frame = player.frame
                let window = app.frame
                return abs(frame.width - window.width) < 1 && abs(frame.height - window.height) < 1
            }
            XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: expanded, object: nil)], timeout: 10), .completed, "player=\(player.frame) window=\(app.frame)")
        } else {
            let landscape = NSPredicate { _, _ in app.frame.width > app.frame.height }
            XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: landscape, object: nil)], timeout: 10), .completed)
        }
        capture(app, name: "video-fullscreen")
        let rate = app.buttons["WYVideoPlayer.rate"]
        if !rate.isHittable { rate.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap() }
        rate.tap()
        XCTAssertTrue(app.staticTexts["1.5x"].waitForExistence(timeout: 5))
        capture(app, name: "video-rate-menu")
        app.staticTexts["1.5x"].tap()
        XCTAssertEqual(rate.label, "1.5x")
        let back = app.buttons["WYVideoPlayer.back"]
        if !back.isHittable { back.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap() }
        back.tap()
        let portrait = NSPredicate { _, _ in app.frame.height > app.frame.width }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: portrait, object: nil)], timeout: 10), .completed)
        let restored = NSPredicate { _, _ in
            let frame = player.frame
            return abs(frame.width - originalFrame.width) < 1 && abs(frame.height - originalFrame.height) < 1
        }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: restored, object: nil)], timeout: 8), .completed)
        capture(app, name: "video-restored")
    }

    @MainActor
    func testVideoLocalControlsAndCache() throws {
        continueAfterFailure = false
        let app = launchApp()
        open("点播播放器", in: app)
        action("播放本地素材", in: app)
        let status = app.staticTexts["WYVideoPlayerDemo.status"]
        let ready = NSPredicate { _, _ in status.exists && status.label.contains("s / ") }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: ready, object: nil)], timeout: 15), .completed)
        action("定位到中间", in: app)
        action("播放 / 暂停", in: app)
        let player = app.otherElements["WYVideoPlayerDemo.player"]
        let play = app.buttons["WYVideoPlayer.playPause"]
        if !play.isHittable { player.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap() }
        let duration = app.staticTexts["WYVideoPlayer.duration"]
        XCTAssertGreaterThan(play.frame.width, 0)
        XCTAssertTrue(player.frame.contains(play.frame), "播放按钮应完整位于播放器内")
        XCTAssertGreaterThan(duration.frame.width, 30, "总时长应有完整文字宽度")
        capture(app, name: "video-local-inline")
        let time = app.staticTexts["WYVideoPlayer.currentTime"]
        if !time.exists { player.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap() }
        let before = seconds(time.label)
        XCTAssertGreaterThan(before, 0)
        action("边下边播 开/关", in: app)
        let unchanged = NSPredicate { _, _ in time.exists && abs(self.seconds(time.label) - before) <= 1 }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: unchanged, object: nil)], timeout: 10), .completed)
        capture(app, name: "video-cache-paused")
        let seekStart = player.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.35))
        let seekEnd = player.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.35))
        let seekSpan = min(90, max(3, seconds(duration.label) * 0.05))
        let expectedDelta = Double((seekEnd.screenPoint.x - seekStart.screenPoint.x) / player.frame.width) * seekSpan
        seekStart.press(forDuration: 0.1, thenDragTo: seekEnd)
        let sought = NSPredicate { _, _ in time.exists && self.seconds(time.label) > before + 0.5 }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: sought, object: nil)], timeout: 5), .completed)
        XCTAssertEqual(seconds(time.label) - before, expectedDelta, accuracy: 1, "滑动幅度应按视频时长和拖动距离收敛")
        capture(app, name: "video-smart-seek")
        let fullscreen = app.buttons["WYVideoPlayer.fullscreen"]
        if !fullscreen.isHittable { player.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap() }
        fullscreen.tap()
        XCTAssertTrue(app.buttons["WYVideoPlayer.back"].waitForExistence(timeout: 5))
        capture(app, name: "video-local-fullscreen")
        app.buttons["WYVideoPlayer.back"].tap()
        XCTAssertTrue(player.waitForExistence(timeout: 5))
        capture(app, name: "video-local-restored")
    }

    @MainActor
    func testVideoMorePlaybackOptions() throws {
        continueAfterFailure = false
        let app = launchApp()
        open("点播播放器", in: app)
        action("播放本地素材", in: app)
        action("定位到中间", in: app)
        action("播放 / 暂停", in: app)
        let more = app.buttons["WYVideoPlayer.more"]
        XCTAssertTrue(more.waitForExistence(timeout: 5))
        if !more.isHittable { app.otherElements["WYVideoPlayerDemo.player"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap() }
        more.tap()
        capture(app, name: "video-more-inline")
        for title in ["音频播放", "后台播放", "循环播放"] {
            let button = app.buttons[title]
            XCTAssertTrue(button.waitForExistence(timeout: 5))
            button.tap()
            XCTAssertEqual(button.value as? String, "开启")
            button.tap()
            XCTAssertEqual(button.value as? String, "关闭")
        }
        app.buttons["倍速"].tap()
        app.staticTexts["1.5x"].tap()
        XCTAssertTrue(app.buttons["定时关闭"].waitForExistence(timeout: 5))
        app.buttons["定时关闭"].tap()
        app.staticTexts["00:03"].tap()
        XCTAssertEqual(app.buttons["定时关闭"].value as? String, "开启")
        app.buttons["关闭"].tap()
        XCTAssertFalse(app.activityIndicators["WYVideoPlayer.loading"].exists)
        let fullscreen = app.buttons["WYVideoPlayer.fullscreen"]
        fullscreen.tap()
        XCTAssertTrue(app.buttons["WYVideoPlayer.back"].waitForExistence(timeout: 5))
        more.tap()
        capture(app, name: "video-more-fullscreen")
        app.buttons["关闭"].tap()
        app.buttons["WYVideoPlayer.back"].tap()
    }

    @MainActor
    func testVideoControlConfiguration() throws {
        continueAfterFailure = false
        let app = launchApp()
        open("点播播放器", in: app)
        action("播放本地素材", in: app)
        action("定位到中间", in: app)
        action("播放 / 暂停", in: app)
        action("控件显隐 开/关", in: app)
        XCTAssertFalse(app.staticTexts["WYVideoPlayer.duration"].exists)
        action("控件显隐 开/关", in: app)
        XCTAssertTrue(app.staticTexts["WYVideoPlayer.duration"].exists)
        let play = app.buttons["WYVideoPlayer.playPause"]
        let fullscreen = app.buttons["WYVideoPlayer.fullscreen"]
        XCTAssertLessThan(play.frame.minX, fullscreen.frame.minX)
        action("控件顺序 正序/反序", in: app)
        XCTAssertGreaterThan(play.frame.minX, fullscreen.frame.minX)
        action("自定义按钮位置 开/关", in: app)
        let more = app.buttons["WYVideoPlayer.more"]
        let player = app.otherElements["WYVideoPlayerDemo.player"]
        XCTAssertLessThan(more.frame.midX, player.frame.midX)
        capture(app, name: "video-controls-customized")
        more.tap()
        XCTAssertTrue(app.buttons["音频播放"].waitForExistence(timeout: 5))
        app.buttons["关闭"].tap()
        action("自定义按钮位置 开/关", in: app)
        XCTAssertGreaterThan(more.frame.midX, player.frame.midX)
    }

    @MainActor
    func testVideoFailureAndRetry() throws {
        continueAfterFailure = false
        let app = launchApp()
        open("点播播放器", in: app)
        loadAddress("http://127.0.0.1:1/unavailable.mp4", in: app)
        let retry = app.buttons["WYVideoPlayer.retry"]
        XCTAssertTrue(retry.waitForExistence(timeout: 22))
        XCTAssertTrue(retry.isHittable)
        capture(app, name: "video-failure")
        retry.tap()
        XCTAssertTrue(retry.waitForExistence(timeout: 22))
        action("播放本地素材", in: app)
        let recovered = NSPredicate { _, _ in app.staticTexts["WYVideoPlayerDemo.status"].label.contains("s / ") && !retry.exists }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: recovered, object: nil)], timeout: 15), .completed)
        capture(app, name: "video-recovered")
    }

    @MainActor
    private func loadAddress(_ address: String, in app: XCUIApplication) {
        action("播放指定地址", in: app)
        let field = app.textFields["WYVideoPlayerDemo.url"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(address)
        app.alerts.buttons["播放"].tap()
    }

    @MainActor
    private func action(_ title: String, in app: XCUIApplication) {
        let row = app.staticTexts[title]
        let table = app.tables.firstMatch
        for _ in 0..<12 {
            if row.isHittable { row.tap(); return }
            if row.exists && row.frame.minY < table.frame.minY { table.swipeDown() }
            else { table.swipeUp() }
        }
        XCTFail("找不到操作 " + title)
    }

    private func seconds(_ text: String) -> Double {
        text.split(separator: ":").reduce(0) { total, part in total * 60 + (Double(part) ?? 0) }
    }

    @MainActor
    func testPhotoSaveWithSystemPermission() throws {
        continueAfterFailure = false
        let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        settings.launch()
        let apps = settings.buttons["com.apple.settings.apps"]
        for _ in 0..<5 {
            if apps.exists { break }
            let back = settings.navigationBars.buttons.firstMatch
            if back.exists == false { break }
            back.tap()
        }
        for _ in 0..<10 {
            if apps.isHittable { break }
            settings.swipeUp()
        }
        XCTAssertTrue(apps.isHittable, settings.debugDescription)
        apps.tap()
        let settingsApp = settings.buttons.matching(NSPredicate(format: "identifier == %@ OR label == %@", "com.guanren.SwiftVerify", "WYBasisKit(Swift)")).firstMatch
        if settingsApp.isHittable == false {
            let search = settings.searchFields.matching(NSPredicate(format: "label == %@ OR label == %@", "搜索App", "Search Apps")).firstMatch
            XCTAssertTrue(search.waitForExistence(timeout: 5), settings.debugDescription)
            search.tap()
            search.typeText("WYBasisKit")
        }
        XCTAssertTrue(settingsApp.waitForExistence(timeout: 5), settings.debugDescription)
        settingsApp.tap()
        let settingsPhotos = settings.staticTexts.matching(NSPredicate(format: "label == %@ OR label == %@", "照片", "Photos")).firstMatch
        XCTAssertTrue(settingsPhotos.waitForExistence(timeout: 5), settings.debugDescription)
        settingsPhotos.tap()
        let none = settings.staticTexts.matching(NSPredicate(format: "label == %@ OR label == %@", "无", "None")).firstMatch
        XCTAssertTrue(none.waitForExistence(timeout: 5), settings.debugDescription)
        none.tap()
        let app = launchApp()
        open("图片浏览", in: app)
        app.collectionViews.firstMatch.cells.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["1/17"].waitForExistence(timeout: 10))
        app.scrollViews.firstMatch.press(forDuration: 1)
        app.buttons["保存图片"].tap()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let success = app.staticTexts["已保存到相册"]
        for _ in 0..<12 {
            if success.exists { break }
            let alert = app.alerts.firstMatch.exists ? app.alerts.firstMatch : springboard.alerts.firstMatch
            if alert.exists {
                if alert.buttons["去授权"].exists {
                    alert.buttons["去授权"].tap()
                    XCTAssertTrue(settings.wait(for: .runningForeground, timeout: 10))
                    let photos = settings.staticTexts.matching(NSPredicate(format: "label == %@ OR label == %@", "照片", "Photos")).firstMatch
                    if photos.waitForExistence(timeout: 5) == false {
                        let appRow = settings.buttons.matching(NSPredicate(format: "identifier == %@ OR label == %@", "com.guanren.SwiftVerify", "WYBasisKit(Swift)")).firstMatch
                        if appRow.isHittable == false {
                            let search = settings.searchFields.matching(NSPredicate(format: "label == %@ OR label == %@", "搜索App", "Search Apps")).firstMatch
                            XCTAssertTrue(search.waitForExistence(timeout: 5), settings.debugDescription)
                            search.tap()
                            search.typeText("WYBasisKit")
                        }
                        XCTAssertTrue(appRow.waitForExistence(timeout: 5), settings.debugDescription)
                        appRow.tap()
                    }
                    XCTAssertTrue(photos.waitForExistence(timeout: 5), settings.debugDescription)
                    photos.tap()
                    let full = settings.staticTexts.matching(NSPredicate(format: "label == %@ OR label == %@ OR label == %@ OR label == %@", "完全访问", "所有照片", "Full Access", "All Photos")).firstMatch
                    XCTAssertTrue(full.waitForExistence(timeout: 5), settings.debugDescription)
                    full.tap()
                    let confirmation = settings.alerts.firstMatch.exists ? settings.alerts.firstMatch : springboard.alerts.firstMatch
                    let confirm = confirmation.buttons.matching(NSPredicate(format: "label CONTAINS %@ OR label CONTAINS %@", "允许完全访问", "Allow Full Access")).firstMatch
                    if confirm.waitForExistence(timeout: 3) { confirm.tap() }
                    app.activate()
                    if app.staticTexts["1/17"].waitForExistence(timeout: 3) == false {
                        open("图片浏览", in: app)
                        app.collectionViews.firstMatch.cells.element(boundBy: 0).tap()
                        XCTAssertTrue(app.staticTexts["1/17"].waitForExistence(timeout: 10))
                    }
                    app.scrollViews.firstMatch.press(forDuration: 1)
                    XCTAssertTrue(app.buttons["保存图片"].waitForExistence(timeout: 5))
                    app.buttons["保存图片"].tap()
                    continue
                }
                let allow = alert.buttons.matching(NSPredicate(format: "label CONTAINS %@ OR label CONTAINS %@ OR label CONTAINS %@ OR label CONTAINS %@", "允许完全访问", "允许访问所有照片", "Allow Full Access", "Allow Access to All Photos")).firstMatch
                if allow.exists { allow.tap() }
            }
            Thread.sleep(forTimeInterval: 0.3)
        }
        capture(app, name: "photo-save-result")
        XCTAssertTrue(success.exists, "保存动作应显示已保存到相册")
    }

    @MainActor
    func testLogPreviewAndSearch() throws {
        continueAfterFailure = false
        let app = launchApp()
        open("日志输出与保存", in: app)
        let floating = app.buttons["日志"]
        XCTAssertTrue(floating.waitForExistence(timeout: 10), "示例页应显示日志悬浮按钮")
        floating.tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 5), "应打开日志预览")
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5), "预览应显示搜索框")
        let matchKeyword = "均不输出到控制台"
        let known = app.cells.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", matchKeyword)).firstMatch
        let other = app.cells.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "仅在 DEBUG 模式下")).firstMatch
        XCTAssertTrue(known.waitForExistence(timeout: 10), "预览应包含已知示例日志")
        XCTAssertTrue(other.waitForExistence(timeout: 5), "预览应包含第二条已知示例日志")
        search.tap()
        search.typeText(matchKeyword)
        XCTAssertTrue(known.waitForExistence(timeout: 5), "可匹配关键词应保留对应日志")
        XCTAssertFalse(other.exists, "搜索结果不应包含不匹配日志")
        XCTAssertFalse(app.staticTexts["未找到匹配的日志内容"].exists)
        search.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: matchKeyword.count))
        let cleared = NSPredicate { _, _ in let value = search.value as? String ?? ""; return value.isEmpty || value == "搜索日志关键字" }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: cleared, object: nil)], timeout: 3), .completed, "清除后搜索框应为空")
        XCTAssertTrue(known.waitForExistence(timeout: 5), "清除搜索应恢复完整列表")
        XCTAssertTrue(other.waitForExistence(timeout: 5), "清除搜索应恢复不匹配日志")
        XCTAssertFalse(app.staticTexts["未找到匹配的日志内容"].exists)
        let missKeyword = "ZP07不存在的关键词Q9Z"
        search.typeText(missKeyword)
        XCTAssertTrue(app.staticTexts["未找到匹配的日志内容"].waitForExistence(timeout: 5), "无匹配时应显示未找到提示")
        XCTAssertFalse(known.exists, "无匹配关键词时原日志不应出现在列表")
        search.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: missKeyword.count))
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: cleared, object: nil)], timeout: 3), .completed, "再次清除后搜索框应为空")
        XCTAssertTrue(known.waitForExistence(timeout: 5), "再次清除搜索应恢复完整列表")
        XCTAssertTrue(other.waitForExistence(timeout: 5), "再次清除应恢复不匹配日志")
        XCTAssertFalse(app.staticTexts["未找到匹配的日志内容"].exists)
        let close = app.navigationBars.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "关闭", "Close")).firstMatch
        if close.exists { close.tap() } else { app.navigationBars.buttons.element(boundBy: 0).tap() }
        XCTAssertTrue(floating.waitForExistence(timeout: 5), "关闭预览应回到示例页且悬浮按钮仍在")
        capture(app, name: "log-preview-closed")
    }

    @MainActor
    private func launchApp() -> XCUIApplication {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launch()
        return app
    }

    @MainActor
    private func open(_ title: String, in app: XCUIApplication) {
        let row = app.tables.cells.containing(.staticText, identifier: title).firstMatch
        for _ in 0..<15 {
            if row.isHittable { row.tap(); return }
            app.tables.firstMatch.swipeUp()
        }
        XCTFail("找不到测试入口 " + title)
    }

    @MainActor
    private func capture(_ app: XCUIApplication, name: String) {
        let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        image.name = name
        image.lifetime = .keepAlways
        add(image)
    }
}
