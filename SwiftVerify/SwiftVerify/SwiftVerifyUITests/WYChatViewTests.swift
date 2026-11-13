import XCTest

@MainActor
final class WYChatViewTests: XCTestCase {
    private func openChat(_ application: XCUIApplication? = nil) -> XCUIApplication {
        continueAfterFailure = false
        let app = application ?? XCUIApplication()
        app.launch()
        let row = app.tables.cells.containing(.staticText, identifier: "聊天界面").firstMatch
        for _ in 0..<20 {
            if row.isHittable { row.tap(); break }
            app.tables.firstMatch.swipeUp()
        }
        XCTAssertTrue(app.navigationBars["聊天界面"].waitForExistence(timeout: 15))
        let input = app.textViews["WYChatInput.text"]
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        let stable = NSPredicate { _, _ in input.isHittable && input.frame.maxX <= app.frame.width }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: stable, object: nil)], timeout: 10), .completed)
        return app
    }

    func testReenterAfterScrollingTop() {
        let app = openChat()
        for turn in 0..<3 {
            if turn > 0 {
                let row = app.tables.cells.containing(.staticText, identifier: "聊天界面").firstMatch
                XCTAssertTrue(row.waitForExistence(timeout: 5))
                row.tap()
                XCTAssertTrue(app.navigationBars["聊天界面"].waitForExistence(timeout: 10))
            }
            let initialScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            initialScreenshot.name = "chat-reentry-\(turn)-initial"
            initialScreenshot.lifetime = .keepAlways
            add(initialScreenshot)
            app.navigationBars.buttons["测试"].tap()
            let initial = app.tables.cells.containing(.staticText, identifier: "首次进入的实际列表").firstMatch
            XCTAssertTrue(initial.waitForExistence(timeout: 5))
            initial.tap()
            app.alerts.buttons["运行"].tap()
            let passed = initial.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
            XCTAssertTrue(passed.waitForExistence(timeout: 10), "第\(turn + 1)次进入的实际列表出现裁切")
            app.navigationBars.buttons["关闭"].tap()
            for _ in 0..<15 { app.tables.firstMatch.swipeDown() }
            let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            image.name = "chat-reentry-\(turn)-top"
            image.lifetime = .keepAlways
            add(image)
            if app.buttons["BackButton"].exists { app.buttons["BackButton"].tap() }
            else { app.navigationBars["聊天界面"].buttons.element(boundBy: 0).tap() }
        }
    }

    func testInitialLayoutAndKeyboard() {
        let app = openChat()
        let input = app.textViews["WYChatInput.text"]
        input.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        XCTAssertLessThanOrEqual(input.frame.maxY, app.keyboards.firstMatch.frame.minY)
        XCTAssertFalse(app.buttons["Done"].exists)
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "chat-keyboard-without-toolbar"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testGestureScrollingFromFreshEntry() {
        let app = openChat()
        let table = app.tables.firstMatch
        for _ in 0..<4 {
            let start = table.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
            let end = table.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
            start.press(forDuration: 0.02, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0)
        }
        app.navigationBars.buttons["测试"].tap()
        let row = app.tables.cells.containing(.staticText, identifier: "实际手势滚动").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 10), "实际拖动中的消息位置出现跳动，详情见测试报告")
    }

    func testAppleLiveSpeechRecognition() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Apple")
        let row = app.tables.cells.containing(.staticText, identifier: "Apple原生实时识别").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let permission = XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.firstMatch
        let liveText = app.descendants(matching: .any)["WYChatRecording.liveText"].firstMatch
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        let screenshotDeadline = Date().addingTimeInterval(15)
        while Date() < screenshotDeadline {
            if permission.exists {
                let allow = permission.buttons.matching(NSPredicate(format: "label IN %@", ["Allow", "允许", "好", "OK"])).firstMatch
                if allow.exists { allow.tap() }
            }
            if liveText.exists {
                let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                attachment.name = "chat-apple-live-recording"
                attachment.lifetime = .keepAlways
                add(attachment)
                break
            }
            if passed.exists { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        let failed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "失败")).firstMatch
        let completed = NSPredicate { _, _ in passed.exists || failed.exists }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: completed, object: nil)], timeout: 60), .completed)
        XCTAssertTrue(passed.exists, "Apple实时识别结果未通过，系统直接调用对照及错误详情见测试报告")
    }

    func testObjCFunctionalSuite() {
        let app = openChat(XCUIApplication(bundleIdentifier: "com.guanren.ObjCVerify"))
        app.navigationBars.buttons["测试"].tap()
        let run = app.buttons["全部运行"]
        XCTAssertTrue(run.waitForExistence(timeout: 5))
        run.tap()
        let status = app.staticTexts["WYChatTests.status"]
        let completed = NSPredicate(format: "label BEGINSWITH %@", "执行完成")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: completed, object: status)], timeout: 30), .completed)
        XCTAssertTrue(status.label.contains("失败0"), status.label)
    }

    func testQuoteReeditActualWorkflow() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("引用与重编辑真实操作")
        let row = app.tables.cells.containing(.staticText, identifier: "引用与重编辑真实操作").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let reference = app.tables.cells.buttons["↪ 引用联系人"].firstMatch
        XCTAssertTrue(reference.waitForExistence(timeout: 5))
        let initial = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        initial.name = "chat-message-reference-below-bubble"
        initial.lifetime = .keepAlways
        add(initial)
        reference.tap()
        let reply = app.textViews.matching(NSPredicate(format: "value == %@", "重新编辑的回复")).firstMatch
        XCTAssertTrue(reply.waitForExistence(timeout: 5))
        reply.press(forDuration: 0.8)
        let withdraw = app.buttons["撤回"].firstMatch
        XCTAssertTrue(withdraw.waitForExistence(timeout: 5))
        withdraw.tap()
        let reedit = app.buttons["WYChatNotice.reedit"].firstMatch
        XCTAssertTrue(reedit.waitForExistence(timeout: 5))
        reedit.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["WYChatView.quote"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["↪ 引用联系人"].firstMatch.exists)
        let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        image.name = "chat-reedit-quote-above-native-keyboard"
        image.lifetime = .keepAlways
        add(image)
        XCTAssertFalse(app.buttons["Done"].exists)
        app.buttons["WYChatView.quote"].firstMatch.tap()
        app.buttons["WYChatInput.send"].firstMatch.tap()
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 15))
    }

    func testVoicePlaybackRateActualMenu() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("语音倍速真实菜单")
        let row = app.tables.cells.containing(.staticText, identifier: "语音倍速真实菜单").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let rate = app.buttons["WYChatVoice.rate.rate-touch"].firstMatch
        XCTAssertTrue(rate.waitForExistence(timeout: 5))
        let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        image.name = "chat-voice-playback-rate"
        image.lifetime = .keepAlways
        add(image)
        rate.tap()
        let choice = app.buttons["2×"].firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 5))
        choice.tap()
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 15))
    }

    func testRecordsDetailActualWorkflow() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("合并记录明细真实操作")
        let row = app.tables.cells.containing(.staticText, identifier: "合并记录明细真实操作").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let card = app.tables.cells.staticTexts["测试合并记录"].firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.tap()
        let close = app.buttons["WYChatRecords.close"].firstMatch
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        XCTAssertTrue(app.textViews.matching(NSPredicate(format: "value == %@", "记录中的消息1")).firstMatch.exists)
        XCTAssertTrue(app.buttons["记录发送者"].firstMatch.exists)
        XCTAssertFalse(app.textViews["WYChatInput.text"].firstMatch.isHittable)
        let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        image.name = "chat-merged-records-detail"
        image.lifetime = .keepAlways
        add(image)
        close.tap()
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 15))
    }

    func testSelectionForwardActualWorkflow() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("区间选择与合并转发真实操作")
        let row = app.tables.cells.containing(.staticText, identifier: "区间选择与合并转发真实操作").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let first = app.textViews.matching(NSPredicate(format: "value == %@", "区间消息1")).firstMatch
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        first.press(forDuration: 0.8)
        let select = app.buttons["多选"].firstMatch
        XCTAssertTrue(select.waitForExistence(timeout: 5))
        select.tap()
        let last = app.textViews.matching(NSPredicate(format: "value == %@", "区间消息4")).firstMatch
        last.press(forDuration: 0.8)
        let range = app.buttons["选择到这里"].firstMatch
        XCTAssertTrue(range.waitForExistence(timeout: 5))
        range.tap()
        let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        image.name = "chat-range-selection-toolbar"
        image.lifetime = .keepAlways
        add(image)
        app.buttons["WYChatView.selectionForward"].firstMatch.tap()
        let merged = app.buttons["合并转发"].firstMatch
        XCTAssertTrue(merged.waitForExistence(timeout: 5))
        merged.tap()
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 15))
    }

    func testExternalMessageActionsActualMenu() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("宿主消息菜单真实操作")
        let row = app.tables.cells.containing(.staticText, identifier: "宿主消息菜单真实操作").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let message = app.textViews.matching(NSPredicate(format: "value == %@", "宿主操作测试消息")).firstMatch
        XCTAssertTrue(message.waitForExistence(timeout: 5))
        for title in ["收藏", "安排提醒", "搜索", "标记已读", "标记未读"] {
            message.press(forDuration: 0.8)
            let action = app.buttons[title].firstMatch
            XCTAssertTrue(action.waitForExistence(timeout: 5), title)
            action.tap()
        }
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 15))
    }

    func testEmojiCrossRowPreviewActualGesture() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("表情跨行预览真实操作")
        let row = app.tables.cells.containing(.staticText, identifier: "表情跨行预览真实操作").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let first = app.cells["WYChatEmoji.previewStart"].firstMatch
        let second = app.cells["WYChatEmoji.previewEnd"].firstMatch
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        XCTAssertTrue(second.waitForExistence(timeout: 5))
        first.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 1, thenDragTo: second.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)), withVelocity: .slow, thenHoldForDuration: 1)
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 15))
    }

    func testExternalMessageActions() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("宿主消息操作入口")
        let row = app.tables.cells.containing(.staticText, identifier: "宿主消息操作入口").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 25))
    }

    func testConfigurationEditorActualWorkflow() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        app.navigationBars.buttons["配置"].tap()
        XCTAssertTrue(app.staticTexts["WYChatConfiguration.summary"].waitForExistence(timeout: 5))
        let search = app.searchFields.firstMatch
        func find(_ path: String) -> XCUIElement {
            search.tap()
            if search.buttons.firstMatch.exists { search.buttons.firstMatch.tap() }
            search.typeText(path)
            let row = app.tables.cells["WYChatConfiguration.field." + path]
            XCTAssertTrue(row.waitForExistence(timeout: 5), path)
            return row
        }
        func edit(_ row: XCUIElement, _ text: String) {
            row.tap()
            let value = app.textViews["WYChatConfiguration.value"]
            XCTAssertTrue(value.waitForExistence(timeout: 5))
            let count = (value.value as? String ?? "").count
            value.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.95)).tap()
            value.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: count) + text)
            app.buttons["WYChatConfiguration.apply"].tap()
        }
        let font = find("input.textFont")
        let initial = font.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        edit(font, "invalid-font")
        XCTAssertTrue(app.staticTexts["WYChatConfiguration.error"].exists)
        let value = app.textViews["WYChatConfiguration.value"]
        value.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.95)).tap()
        value.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "invalid-font".count) + "26")
        app.buttons["WYChatConfiguration.apply"].tap()
        XCTAssertTrue(font.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "26.0")).firstMatch.waitForExistence(timeout: 5))
        _ = find("input.rendersIconsAsTemplate")
        let toggle = app.switches["WYChatConfiguration.switch.input.rendersIconsAsTemplate"]
        XCTAssertEqual(toggle.value as? String, "1")
        toggle.tap()
        XCTAssertEqual(toggle.value as? String, "0")
        edit(find("basic.avatarSize"), "38, 38")
        app.navigationBars.buttons["预览"].tap()
        XCTAssertTrue(app.navigationBars["配置预览"].waitForExistence(timeout: 5))
        let avatars = app.tables["WYChatConfiguration.previewMessages"].images.matching(NSPredicate(format: "identifier BEGINSWITH %@", "WYChatAvatar.")).allElementsBoundByIndex
        let avatar = avatars.first { $0.isHittable }
        XCTAssertNotNil(avatar)
        if let avatar { XCTAssertEqual(avatar.frame.width, 38, accuracy: 1); XCTAssertEqual(avatar.frame.height, 38, accuracy: 1) }
        let input = app.textViews["WYChatInput.text"].firstMatch
        input.tap()
        input.typeText("配置字体预览")
        XCTAssertFalse(app.buttons["Done"].exists)
        let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        image.name = "chat-configuration-live-preview"
        image.lifetime = .keepAlways
        add(image)
        app.navigationBars.buttons["全部配置"].tap()
        app.navigationBars.buttons["复原"].tap()
        let restored = find("input.textFont")
        XCTAssertEqual(restored.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines), initial)
    }

    func testConfigurationContentOverrideActualWorkflow() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        app.navigationBars.buttons["配置"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("contentOverrides")
        app.tables.cells["WYChatConfiguration.field.contentOverrides"].tap()
        let file = app.tables.cells["WYChatConfiguration.messageType.file"]
        XCTAssertTrue(file.waitForExistence(timeout: 5))
        for _ in 0..<5 {
            if file.isHittable { break }
            app.tables["WYChatConfiguration.messageTypes"].swipeUp()
        }
        file.tap()
        XCTAssertTrue(app.navigationBars["覆盖·文件"].waitForExistence(timeout: 5))
        let row = app.tables.cells["WYChatConfiguration.field.contentOverrides.file.titleFont"]
        for _ in 0..<5 {
            if row.isHittable { break }
            app.tables.firstMatch.swipeUp()
        }
        let initial = row.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        row.tap()
        let editor = app.textViews["WYChatConfiguration.value"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        let count = (editor.value as? String ?? "").count
        editor.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.95)).tap()
        editor.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: count) + "24")
        app.buttons["WYChatConfiguration.apply"].tap()
        XCTAssertTrue(row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "24.0")).firstMatch.waitForExistence(timeout: 5))
        app.navigationBars.buttons["预览"].tap()
        XCTAssertTrue(app.navigationBars["配置预览"].waitForExistence(timeout: 5))
        XCTAssertGreaterThan(app.tables["WYChatConfiguration.previewMessages"].cells.count, 0)
        let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        image.name = "chat-per-message-configuration-preview"
        image.lifetime = .keepAlways
        add(image)
        app.navigationBars.buttons["覆盖·文件"].tap()
        row.swipeLeft()
        let clear = app.buttons["取消覆盖"].firstMatch
        XCTAssertTrue(clear.waitForExistence(timeout: 5))
        clear.tap()
        XCTAssertEqual(row.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines), initial)
    }

    func testInputEmojiAndMoreActualWorkflow() {
        let app = openChat()
        let input = app.textViews["WYChatInput.text"]
        app.buttons["WYChatInput.emoji"].tap()
        let emoji = app.collectionViews["WYChatEmoji.items"]
        XCTAssertTrue(emoji.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(emoji.cells.count, 0)
        emoji.cells.firstMatch.tap()
        let send = app.buttons["WYChatInput.send"]
        XCTAssertTrue(send.waitForExistence(timeout: 5))
        send.tap()
        XCTAssertTrue(emoji.staticTexts["最近使用"].waitForExistence(timeout: 5))
        XCTAssertTrue((input.value as? String ?? "").isEmpty || input.value as? String == "请输入消息")
        let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        image.name = "chat-emoji-send-and-history"
        image.lifetime = .keepAlways
        add(image)
        app.buttons["WYChatInput.more"].tap()
        let more = app.collectionViews["WYChatMore.items"]
        XCTAssertTrue(more.waitForExistence(timeout: 5))
        more.cells.containing(.staticText, identifier: "照片").firstMatch.tap()
        XCTAssertTrue(app.alerts["相册由宿主接入"].waitForExistence(timeout: 5))
        app.alerts.buttons["关闭"].tap()
    }

    func testConfigurationToastActualWorkflow() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        app.navigationBars.buttons["配置"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("media.browser.appearance.toastConfig")
        app.tables.cells["WYChatConfiguration.field.media.browser.appearance.toastConfig"].tap()
        XCTAssertTrue(app.navigationBars["保存结果提示"].waitForExistence(timeout: 5))
        let row = app.tables.cells["WYChatConfiguration.field.media.browser.appearance.toastConfig.textFont"]
        row.tap()
        let editor = app.textViews["WYChatConfiguration.value"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        let count = (editor.value as? String ?? "").count
        editor.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.95)).tap()
        editor.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: count) + "22")
        app.buttons["WYChatConfiguration.apply"].tap()
        app.navigationBars.buttons["预览"].tap()
        XCTAssertTrue(app.staticTexts["保存结果提示预览"].waitForExistence(timeout: 5))
        let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        image.name = "chat-save-result-style-preview"
        image.lifetime = .keepAlways
        add(image)
        let preview = app.staticTexts["保存结果提示预览"]
        XCTAssertTrue(preview.waitForNonExistence(timeout: 10))
        row.swipeLeft()
        app.buttons["使用默认提示"].tap()
        XCTAssertFalse(row.staticTexts.allElementsBoundByIndex.contains { $0.label.contains("22.0") })
    }

    func testAdvancedConfiguration() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("消息事件与输入面板：高级配置")
        let row = app.tables.cells.containing(.staticText, identifier: "消息事件与输入面板：高级配置").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 25))
    }

    func testConfigurationDirectoryValidation() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("配置目录与输入校验")
        let row = app.tables.cells.containing(.staticText, identifier: "配置目录与输入校验").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 45))
    }

    func testConfigurationColorPicker() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("配置选色器回调")
        let row = app.tables.cells.containing(.staticText, identifier: "配置选色器回调").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 25))
    }

    func testLightDarkAppearance() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("浅色深色与输入外观")
        let row = app.tables.cells.containing(.staticText, identifier: "浅色深色与输入外观").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 25))
    }

    func testVoicePlaybackRates() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("语音倍速与播放接管")
        let row = app.tables.cells.containing(.staticText, identifier: "语音倍速与播放接管").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 25))
    }

    func testSelectionForwarding() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("区间多选与转发快照")
        let row = app.tables.cells.containing(.staticText, identifier: "区间多选与转发快照").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 25))
    }

    func testQuotesWithdrawalAndReedit() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("引用快照与撤回重编辑")
        let row = app.tables.cells.containing(.staticText, identifier: "引用快照与撤回重编辑").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 25))
    }

    func testAvatarMentions() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("用户提及与头像配置")
        let row = app.tables.cells.containing(.staticText, identifier: "用户提及与头像配置").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 20))
    }

    func testAvatarActualGestures() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("头像真实手势")
        let row = app.tables.cells.containing(.staticText, identifier: "头像真实手势").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let avatar = app.tables.cells.descendants(matching: .any)["WYChatAvatar.avatar-gesture"].firstMatch
        XCTAssertTrue(avatar.waitForExistence(timeout: 5))
        avatar.press(forDuration: 0.7)
        XCTAssertFalse(app.buttons["复制"].exists)
        avatar.doubleTap()
        avatar.tap()
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 15))
    }

    func testRecordingActionStyles() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("录音操作双样式")
        let row = app.tables.cells.containing(.staticText, identifier: "录音操作双样式").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 15))
    }

    func testHistoryReadingPosition() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("历史消息与阅读位置")
        let row = app.tables.cells.containing(.staticText, identifier: "历史消息与阅读位置").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 30))
    }

    func testDictationAndOriginalVoice() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("直接转写与原语音")
        let row = app.tables.cells.containing(.staticText, identifier: "直接转写与原语音").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 25))
    }

    func testTranscriptEditorAndTranslation() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("转写编辑与外部翻译")
        let row = app.tables.cells.containing(.staticText, identifier: "转写编辑与外部翻译").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 25))
    }

    func testMediaSelectionAndGroups() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("相册结果与媒体合并")
        let row = app.tables.cells.containing(.staticText, identifier: "相册结果与媒体合并").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 25))
    }

    func testChatMediaPreviewGestures() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("聊天媒体真实预览手势")
        let row = app.tables.cells.containing(.staticText, identifier: "聊天媒体真实预览手势").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let host = app.otherElements["WYChatTests.mediaGestureHost"]
        XCTAssertTrue(host.waitForExistence(timeout: 10))
        let toggle = host.buttons["WYChatMedia.toggle"].firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        let cards = host.collectionViews["WYPhotoBrowser.stackedCards"].firstMatch
        XCTAssertTrue(cards.waitForExistence(timeout: 5))
        let before = cards.frame
        let initial = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        initial.name = "chat-media-before-first-swipe"
        initial.lifetime = .keepAlways
        add(initial)
        cards.swipeLeft()
        let after = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        after.name = "chat-media-after-first-swipe"
        after.lifetime = .keepAlways
        add(after)
        let secondPage = NSPredicate { _, _ in cards.value as? String == "2/3" && !app.collectionViews["WYPhotoBrowser.pages"].exists }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: secondPage, object: nil)], timeout: 5), .completed, "value=\(String(describing: cards.value)), preview=\(app.collectionViews["WYPhotoBrowser.pages"].exists), before=\(before), collection=\(cards.frame)")
        cards.swipeRight()
        let thirdPage = NSPredicate { _, _ in cards.value as? String == "3/3" && !app.collectionViews["WYPhotoBrowser.pages"].exists }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: thirdPage, object: nil)], timeout: 5), .completed)
        cards.swipeLeft()
        let firstPage = NSPredicate { _, _ in cards.value as? String == "1/3" && !app.collectionViews["WYPhotoBrowser.pages"].exists }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: firstPage, object: nil)], timeout: 5), .completed)
        let cardImage = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        cardImage.name = "chat-media-stack-before-preview"
        cardImage.lifetime = .keepAlways
        add(cardImage)
        cards.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let pages = app.collectionViews["WYPhotoBrowser.pages"]
        let opened = pages.waitForExistence(timeout: 5)
        if !opened {
            let failed = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            failed.name = "chat-media-preview-not-opened"
            failed.lifetime = .keepAlways
            add(failed)
        }
        XCTAssertTrue(opened)
        pages.swipeLeft()
        let play = pages.buttons["WYPhotoBrowser.videoPlay"].firstMatch
        XCTAssertTrue(play.waitForExistence(timeout: 5))
        play.tap()
        let player = app.otherElements["WYChatMedia.videoPlayer"].firstMatch
        XCTAssertTrue(player.waitForExistence(timeout: 5))
        let fullFrame = NSPredicate { _, _ in player.frame == app.frame }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: fullFrame, object: nil)], timeout: 5), .completed)
        let playing = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        playing.name = "chat-media-native-video-player"
        playing.lifetime = .keepAlways
        add(playing)
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in play.isHittable }, object: nil)], timeout: 10), .completed)
        pages.swipeLeft()
        let center = pages.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        center.doubleTap()
        let zoomed = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        zoomed.name = "chat-media-photo-zoomed"
        zoomed.lifetime = .keepAlways
        add(zoomed)
        center.doubleTap()
        let from = pages.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45))
        let to = pages.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
        from.press(forDuration: 0.05, thenDragTo: to)
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 15))
    }

    func testMixedMediaVideoPlayback() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("混合媒体全屏与视频播放")
        let row = app.tables.cells.containing(.staticText, identifier: "混合媒体全屏与视频播放").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 30))
    }

    func testPhotoBrowserStackMode() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("PhotoBrowser叠卡模式")
        let row = app.tables.cells.containing(.staticText, identifier: "PhotoBrowser叠卡模式").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 20))
    }

    func testPhotoBrowserStackGestures() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("PhotoBrowser叠卡真实滑动")
        let row = app.tables.cells.containing(.staticText, identifier: "PhotoBrowser叠卡真实滑动").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let host = app.otherElements["WYChatTests.browserStackHost"]
        XCTAssertTrue(host.waitForExistence(timeout: 5))
        let collection = host.collectionViews["WYPhotoBrowser.stackedCards"]
        XCTAssertTrue(collection.waitForExistence(timeout: 5))
        collection.swipeLeft()
        collection.swipeRight()
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "photo-browser-stacked-cards-real-swipes"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        collection.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 10))
    }

    func testStackContinuousBidirectionalCycles() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("叠卡连续双向循环")
        let row = app.tables.cells.containing(.staticText, identifier: "叠卡连续双向循环").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let cards = app.otherElements["WYChatTests.browserStackHost"].collectionViews.firstMatch
        XCTAssertTrue(cards.waitForExistence(timeout: 5))
        cards.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 0.15, thenDragTo: cards.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.5)), withVelocity: .slow, thenHoldForDuration: 0.2)
        let returned = NSPredicate { _, _ in cards.value as? String == "1/6" }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: returned, object: nil)], timeout: 5), .completed, "after small drag=\(String(describing: cards.value))")
        for turn in 0..<12 {
            if turn < 6 { cards.swipeLeft() } else { cards.swipeRight() }
            let expected = "\((turn + 1) % 6 + 1)/6"
            let settled = NSPredicate { _, _ in cards.value as? String == expected }
            XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: settled, object: nil)], timeout: 5), .completed, "turn=\(turn), value=\(String(describing: cards.value))")
            let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            image.name = "stack-cycle-\(turn)"
            image.lifetime = .keepAlways
            add(image)
        }
        cards.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 10))
    }

    func testRepairAPICases() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        for title in ["回弹、气泡与录音入列", "输入框实时识别与占位配置"] {
            search.tap()
            if !(search.value as? String ?? "").isEmpty, search.buttons.firstMatch.exists { search.buttons.firstMatch.tap() }
            search.typeText(title)
            let row = app.tables.cells.containing(.staticText, identifier: title).firstMatch
            XCTAssertTrue(row.waitForExistence(timeout: 5))
            row.tap()
            app.alerts.buttons["运行"].tap()
            let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
            XCTAssertTrue(passed.waitForExistence(timeout: 15), title)
        }
    }

    func testCenteredPlaceholderLongPress() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("居中占位长按真实手势")
        let row = app.tables.cells.containing(.staticText, identifier: "居中占位长按真实手势").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let placeholder = app.buttons["WYChatInput.placeholder"].firstMatch
        XCTAssertTrue(placeholder.waitForExistence(timeout: 5))
        placeholder.press(forDuration: 1.2)
        XCTAssertTrue(app.textViews["WYChatRecording.editor"].waitForExistence(timeout: 5))
        app.buttons["WYChatRecording.sendText"].tap()
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 10))
    }

    func testRecordingSendAndRegionGestures() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("录音发送真实手势")
        let row = app.tables.cells.containing(.staticText, identifier: "录音发送真实手势").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let record = app.buttons["WYChatInput.record"].firstMatch
        XCTAssertTrue(record.waitForExistence(timeout: 5))
        record.press(forDuration: 1.2)
        record.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 0.7, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25)), withVelocity: .slow, thenHoldForDuration: 0.3)
        record.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 0.7, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.80)), withVelocity: .slow, thenHoldForDuration: 0.3)
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 15))
    }

    func testTopElasticBounce() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("顶部回弹真实手势")
        let row = app.tables.cells.containing(.staticText, identifier: "顶部回弹真实手势").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.alerts.buttons["运行"].tap()
        let table = app.tables["WYChatTests.bounceTable"]
        XCTAssertTrue(table.waitForExistence(timeout: 5))
        table.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25)).press(forDuration: 0.2, thenDragTo: table.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.65)), withVelocity: .slow, thenHoldForDuration: 0.3)
        let passed = row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "通过")).firstMatch
        XCTAssertTrue(passed.waitForExistence(timeout: 15))
    }

    func testFunctionalSuite() {
        let app = openChat()
        app.navigationBars.buttons["测试"].tap()
        let run = app.buttons["全部运行"]
        XCTAssertTrue(run.waitForExistence(timeout: 5))
        run.tap()
        let status = app.staticTexts["WYChatTests.status"]
        let completed = NSPredicate(format: "label BEGINSWITH %@", "执行完成")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: completed, object: status)], timeout: 240), .completed)
        XCTAssertTrue(status.label.contains("失败0"), status.label)
    }
}
