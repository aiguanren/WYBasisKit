//
//  WYAppleServices.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/30.
//

import Foundation
import UIKit

/// Apple系统相关功能封装
public struct WYAppleServices {

    /// 判断能否唤起系统 eSIM 安装页
    public static var isEsimSupported: Bool {
        if #available(iOS 17.4, *) {
            return true
        }else {
            return false
        }
    }

    /**
     *  唤起系统处理指定链接(系统没有任何应用能处理该链接时回调 false)
     *
     *  @param url 要唤起的链接(支持 https 通用链接与 tel:、mailto:、sms: 等系统 scheme)
     *  
     *  @param completion 唤起结果回调(success 为 true 时系统已接管该链接)
     */
    public static func open(url: URL, completion: ((_ success: Bool) -> Void)?) {

        // 不需要先调 canOpenURL 判断，openURL 处理不了时本来就会回调 false，且自定义 scheme 的 canOpenURL 依赖宿主在 Info.plist 配置 LSApplicationQueriesSchemes，漏配会误判为不支持
        UIApplication.shared.open(url, options: [:]) { success in
            completion?(success)
        }
    }

    /**
     *  跳到系统设置里当前 App 的设置页(权限开关、通知选项都在这页)
     *
     *  @param completion 唤起结果回调(success 为 true 时系统已打开当前 App 的设置页)
     */
    public static func openAppSettings(completion: ((_ success: Bool) -> Void)?) {

        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            completion?(false)
            return
        }
        open(url: url, completion: completion)
    }

    /**
     *  唤起系统 eSIM 安装页安装 eSIM(需要 iOS 17.4 及以上，低版本系统没有该安装页，可先用 isEsimSupported 提前判断)
     *
     *  说明：
     *  1. 唤起成功只代表系统已弹出安装页，eSIM 最终有没有激活成功 App 拿不到结果(系统限制，只能引导用户去系统设置确认或回 App 查询业务状态)
     *  2. 唤起失败(通常是设备不支持 eSIM 或系统无法处理)时会自动弹出提示，传 unsupportedTip 可自定义提示文案
     *
     *  @param lpa 获取到的 LPA 串(兼容带/不带 lpa: 前缀及任意大小写，内部统一归一为大写 LPA: 前缀，形如 LPA:1$SM-DP+地址$激活码，传空串时视为不支持直接弹提示)
     *
     *  @param unsupportedTip 唤起失败时的提示文案(不传时用默认文案"当前设备不支持 eSIM")
     *
     *  @param completion 唤起结果回调(success 为 true 时系统已接管并弹出 eSIM 安装页，全程不经过 Safari)
     */
    @available(iOS 17.4, *)
    public static func install(lpa: String, unsupportedTip: String? = nil, completion: ((_ success: Bool) -> Void)?) {

        /**
         * 链接为 esimsetup.apple.com 通用链接，系统拦截后直接弹出内置 eSIM 安装页，域名必须保持小写
         * carddata 放归一后的完整 LPA 串(含 LPA: 前缀与字面 $)，按 URL 查询串常规编码即可，LPA 串里的 $ 与 : 本就是查询串合法字符，编码后保持字面
         * 不能改成 esim_qrcode_plugin?lpa= 一类写法(路径与参数名不对，iOS 不会拦截，页面会被甩给 Safari 并报无法与服务器建立安全的连接)
         */
        guard let normalized = normalizedLpa(lpa),
              let carddata = normalized.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://esimsetup.apple.com/esim_qrcode_provisioning?carddata=\(carddata)") else {
            showUnsupportedTip(unsupportedTip)
            completion?(false)
            return
        }

        open(url: url) { success in
            if !success {
                showUnsupportedTip(unsupportedTip)
            }
            completion?(success)
        }
    }

    /**
     *  生成 LPA 串的二维码图片(内容为归一后的完整 LPA 串，供无法唤起系统安装页的环境(如低于 iOS 17.4 的系统)引导用户扫码安装兜底)
     *
     *  @param lpa 获取到的 LPA 串(兼容带/不带 lpa: 前缀及任意大小写，内部统一归一为大写 LPA: 前缀)
     *
     *  @param size 二维码图片的尺寸(单位为像素，传显示尺寸乘以屏幕缩放比可以得到清晰图)
     *
     *  @return 二维码图片(lpa 为空串时返回 nil)
     */
    public static func qrCode(lpa: String, size: CGSize) -> UIImage? {

        guard let normalized = normalizedLpa(lpa) else { return nil }
        return UIImage.wy_createQrCode(with: Data(normalized.utf8), size: size)
    }

    /**
     *  唤起系统邮件编辑页发邮件(收件人至少要传一个邮箱地址，主题与正文会预填进编辑页)
     *
     *  @param to 收件人邮箱地址列表(多个时编辑页会全部带上)
     *
     *  @param cc 抄送邮箱地址列表(不需要抄送传空数组)
     *
     *  @param bcc 密送邮箱地址列表(不需要密送传空数组)
     *
     *  @param subject 邮件主题(不需要预填主题传空串)
     *
     *  @param body 邮件正文(不需要预填正文传空串)
     *
     *  @param completion 唤起结果回调(success 为 false 时通常是设备没有可用邮件应用或系统无法处理，需要调用方自行弹提示)
     */
    public static func sendMail(to: [String], cc: [String] = [], bcc: [String] = [], subject: String = "", body: String = "", completion: ((_ success: Bool) -> Void)?) {

        guard let url = mailURL(to: to, cc: cc, bcc: bcc, subject: subject, body: body) else {
            completion?(false)
            return
        }
        open(url: url, completion: completion)
    }

    /**
     *  唤起系统短信编辑页发短信(收件人至少要传一个手机号，内容会预填进编辑页)
     *
     *  @param to 收件人手机号列表(多个时编辑页会全部带上)
     *
     *  @param body 短信内容(不需要预填内容传空串)
     *
     *  @param completion 唤起结果回调(success 为 false 时通常是设备不支持发短信或系统无法处理，需要调用方自行弹提示)
     */
    public static func sendSms(to: [String], body: String = "", completion: ((_ success: Bool) -> Void)?) {

        guard let url = smsURL(to: to, body: body) else {
            completion?(false)
            return
        }
        open(url: url, completion: completion)
    }

    /**
     *  唤起系统拨号页拨打电话(只弹拨号确认页不会自动拨出，无电话功能的设备如部分 iPad 回调 false)
     *
     *  @param number 电话号码(支持 + 区号、数字与连字符，内部会去掉空白字符)
     *
     *  @param completion 唤起结果回调(success 为 false 时通常是设备不支持拨号或系统无法处理，需要调用方自行弹提示)
     */
    public static func call(number: String, completion: ((_ success: Bool) -> Void)?) {

        let trimmed = number.filter { !$0.isWhitespace }
        guard !trimmed.isEmpty, let url = URL(string: "tel:\(trimmed)") else {
            completion?(false)
            return
        }
        open(url: url, completion: completion)
    }

    /**
     *  打开指定 App 的 App Store 详情页
     *
     *  @param appId App 在 App Store 的数字 id(App Store 链接里 id 后面的那串数字)
     *  
     *  @param completion 唤起结果回调(success 为 true 时系统已打开 App Store 详情页)
     */
    public static func openAppPage(appId: String, completion: ((_ success: Bool) -> Void)?) {
        openStore(appId: appId, action: nil, completion: completion)
    }

    /**
     *  打开指定 App 的 App Store 评分页(用户在页里直接打分评论)
     *
     *  @param appId App 在 App Store 的数字 id(App Store 链接里 id 后面的那串数字)
     *  @param completion 唤起结果回调(success 为 true 时系统已打开 App Store 评分页)
     */
    public static func writeReview(appId: String, completion: ((_ success: Bool) -> Void)?) {
        openStore(appId: appId, action: "write-review", completion: completion)
    }
}
