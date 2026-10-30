//
//  WYAppleServices.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/30.
//

#if canImport(WYBasisKitSwift)
import UIKit
import Foundation
import WYBasisKitSwift

/// Apple系统相关功能封装
@objc(WYAppleServices)
@objcMembers public class WYAppleServicesObjC: NSObject {

    /// 提前判断能否唤起系统 eSIM 安装页(系统需 iOS 17.4 及以上，设备是否带 eSIM 硬件没有公开 API 可查，install 唤起失败即设备不支持)
    @objc public static var isEsimSupported: Bool {
        return WYAppleServices.isEsimSupported
    }

    /**
     *  唤起系统处理指定链接(系统没有任何应用能处理该链接时回调 false)
     *
     *  @param url 要唤起的链接(支持 https 通用链接与 tel:、mailto:、sms: 等系统 scheme)
     *
     *  @param completion 唤起结果回调(success 为 true 时系统已接管该链接)
     */
    @objc public static func open(url: URL, completion: ((_ success: Bool) -> Void)?) {
        WYAppleServices.open(url: url, completion: completion)
    }

    /**
     *  唤起系统处理指定链接(系统没有任何应用能处理该链接时回调 false)
     *
     *  @param url 要唤起的链接(支持 https 通用链接与 tel:、mailto:、sms: 等系统 scheme)
     *
     *  @param completion 唤起结果回调(success 为 true 时系统已接管该链接)
     */
    @objc public static var open: @convention(block) (URL, @escaping (Bool) -> Void) -> Void {
        return { url, completion in
            WYAppleServices.open(url: url, completion: completion)
        }
    }

    /**
     *  跳到系统设置里当前 App 的设置页(权限开关、通知选项都在这页)
     *
     *  @param completion 唤起结果回调(success 为 true 时系统已打开当前 App 的设置页)
     */
    @objc public static func openAppSettings(completion: ((_ success: Bool) -> Void)?) {
        WYAppleServices.openAppSettings(completion: completion)
    }

    /**
     *  跳到系统设置里当前 App 的设置页(权限开关、通知选项都在这页)
     *
     *  @param completion 唤起结果回调(success 为 true 时系统已打开当前 App 的设置页)
     */
    @objc public static var openAppSettings: @convention(block) (@escaping (Bool) -> Void) -> Void {
        return { completion in
            WYAppleServices.openAppSettings(completion: completion)
        }
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
    @objc public static func install(lpa: String, unsupportedTip: String? = nil, completion: ((_ success: Bool) -> Void)?) {
        WYAppleServices.install(lpa: lpa, unsupportedTip: unsupportedTip, completion: completion)
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
    @objc public static var install: @convention(block) (String, String?, @escaping (Bool) -> Void) -> Void {
        return { lpa, unsupportedTip, completion in
            WYAppleServices.install(lpa: lpa, unsupportedTip: unsupportedTip, completion: completion)
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
    @objc public static func qrCode(lpa: String, size: CGSize) -> UIImage? {
        return WYAppleServices.qrCode(lpa: lpa, size: size)
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
    @objc public static var qrCode: @convention(block) (String, CGSize) -> UIImage? {
        return { lpa, size in
            WYAppleServices.qrCode(lpa: lpa, size: size)
        }
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
    @objc public static func sendMail(to: [String], cc: [String] = [], bcc: [String] = [], subject: String = "", body: String = "", completion: ((_ success: Bool) -> Void)?) {
        WYAppleServices.sendMail(to: to, cc: cc, bcc: bcc, subject: subject, body: body, completion: completion)
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
    @objc public static var sendMail: @convention(block) ([String], [String], [String], String, String, @escaping (Bool) -> Void) -> Void {
        return { to, cc, bcc, subject, body, completion in
            WYAppleServices.sendMail(to: to, cc: cc, bcc: bcc, subject: subject, body: body, completion: completion)
        }
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
    @objc public static func sendSms(to: [String], body: String = "", completion: ((_ success: Bool) -> Void)?) {
        WYAppleServices.sendSms(to: to, body: body, completion: completion)
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
    @objc public static var sendSms: @convention(block) ([String], String, @escaping (Bool) -> Void) -> Void {
        return { to, body, completion in
            WYAppleServices.sendSms(to: to, body: body, completion: completion)
        }
    }

    /**
     *  唤起系统拨号页拨打电话(只弹拨号确认页不会自动拨出，无电话功能的设备如部分 iPad 回调 false)
     *
     *  @param number 电话号码(支持 + 区号、数字与连字符，内部会去掉空白字符)
     *
     *  @param completion 唤起结果回调(success 为 false 时通常是设备不支持拨号或系统无法处理，需要调用方自行弹提示)
     */
    @objc public static func call(number: String, completion: ((_ success: Bool) -> Void)?) {
        WYAppleServices.call(number: number, completion: completion)
    }

    /**
     *  唤起系统拨号页拨打电话(只弹拨号确认页不会自动拨出，无电话功能的设备如部分 iPad 回调 false)
     *
     *  @param number 电话号码(支持 + 区号、数字与连字符，内部会去掉空白字符)
     *
     *  @param completion 唤起结果回调(success 为 false 时通常是设备不支持拨号或系统无法处理，需要调用方自行弹提示)
     */
    @objc public static var call: @convention(block) (String, @escaping (Bool) -> Void) -> Void {
        return { number, completion in
            WYAppleServices.call(number: number, completion: completion)
        }
    }

    /**
     *  打开指定 App 的 App Store 详情页
     *
     *  @param appId App 在 App Store 的数字 id(App Store 链接里 id 后面的那串数字)
     *
     *  @param completion 唤起结果回调(success 为 true 时系统已打开 App Store 详情页)
     */
    @objc public static func openAppPage(appId: String, completion: ((_ success: Bool) -> Void)?) {
        WYAppleServices.openAppPage(appId: appId, completion: completion)
    }

    /**
     *  打开指定 App 的 App Store 详情页
     *
     *  @param appId App 在 App Store 的数字 id(App Store 链接里 id 后面的那串数字)
     *
     *  @param completion 唤起结果回调(success 为 true 时系统已打开 App Store 详情页)
     */
    @objc public static var openAppPage: @convention(block) (String, @escaping (Bool) -> Void) -> Void {
        return { appId, completion in
            WYAppleServices.openAppPage(appId: appId, completion: completion)
        }
    }

    /**
     *  打开指定 App 的 App Store 评分页(用户在页里直接打分评论)
     *
     *  @param appId App 在 App Store 的数字 id(App Store 链接里 id 后面的那串数字)
     *
     *  @param completion 唤起结果回调(success 为 true 时系统已打开 App Store 评分页)
     */
    @objc public static func writeReview(appId: String, completion: ((_ success: Bool) -> Void)?) {
        WYAppleServices.writeReview(appId: appId, completion: completion)
    }

    /**
     *  打开指定 App 的 App Store 评分页(用户在页里直接打分评论)
     *
     *  @param appId App 在 App Store 的数字 id(App Store 链接里 id 后面的那串数字)
     *
     *  @param completion 唤起结果回调(success 为 true 时系统已打开 App Store 评分页)
     */
    @objc public static var writeReview: @convention(block) (String, @escaping (Bool) -> Void) -> Void {
        return { appId, completion in
            WYAppleServices.writeReview(appId: appId, completion: completion)
        }
    }
}
#endif
