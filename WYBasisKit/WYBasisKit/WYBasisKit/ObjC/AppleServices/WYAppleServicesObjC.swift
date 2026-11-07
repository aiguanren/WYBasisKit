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

    /// 二维码允许的最大边长(单位为像素)
    @objc public static var maximumQRCodeDimension: CGFloat { WYAppleServices.maximumQRCodeDimension }

    /// eSIM 硬件与运营商地区能力(不包含当前安装资格或数量限制，无法确认时返回 unknown)
    @objc public static var esimCapability: WYEsimRegionSupport { WYAppleServices.esimCapability }

    /// 系统是否提供 eSIM 通用链接入口(不代表设备支持或安装界面已出现)
    @objc public static var isEsimInstallationLinkAvailable: Bool { WYAppleServices.isEsimInstallationLinkAvailable }

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
    @objc public static var open: @convention(block) (_ url: URL, _ completion: @escaping (_ success: Bool) -> Void) -> Void {
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
    @objc public static var openAppSettings: @convention(block) (_ completion: @escaping (_ success: Bool) -> Void) -> Void {
        return { completion in
            WYAppleServices.openAppSettings(completion: completion)
        }
    }

    /**
     *  创建 eSIM 安装链接(不检查设备能力或打开链接)
     *
     *  @param lpa 完整 LPA 串或省略 LPA: 前缀的激活资料
     *  @return 安装链接(格式不合法时返回 nil)
     */
    @objc public static func esimInstallationURL(lpa: String) -> URL? {
        return WYAppleServices.esimInstallationURL(lpa: lpa)
    }

    /**
     *  创建 eSIM 安装链接(不检查设备能力或打开链接)
     *
     *  @param lpa 完整 LPA 串或省略 LPA: 前缀的激活资料
     *  @return 安装链接(格式不合法时返回 nil)
     */
    @objc public static var esimInstallationURL: @convention(block) (_ lpa: String) -> URL? {
        return { lpa in WYAppleServices.esimInstallationURL(lpa: lpa) }
    }

    /**
     *  请求系统处理 eSIM 安装链接(不会回退到浏览器)
     *
     *  @param lpa 完整 LPA 串或省略 LPA: 前缀的激活资料
     *  @param completion 请求结果回调(result 仅表示链接请求结果，安装界面是否出现及最终安装或激活结果无法从此回调获取)
     */
    @objc public static func requestEsimInstallation(lpa: String, completion: ((_ result: WYEsimRequestResult) -> Void)?) {
        WYAppleServices.requestEsimInstallation(lpa: lpa, completion: completion)
    }

    /**
     *  请求系统处理 eSIM 安装链接(不会回退到浏览器)
     *
     *  @param lpa 完整 LPA 串或省略 LPA: 前缀的激活资料
     *  @param completion 请求结果回调(result 仅表示链接请求结果，安装界面是否出现及最终安装或激活结果无法从此回调获取)
     */
    @objc public static var requestEsimInstallation: @convention(block) (_ lpa: String, _ completion: @escaping (_ result: WYEsimRequestResult) -> Void) -> Void {
        return { lpa, completion in WYAppleServices.requestEsimInstallation(lpa: lpa, completion: completion) }
    }

    /**
     *  请求系统处理 eSIM 安装链接(失败时显示提示，不会回退到浏览器)
     *
     *  @param lpa 完整 LPA 串或省略 LPA: 前缀的激活资料
     *  @param unsupportedTip 请求失败时的提示文案(不传时显示无法打开 eSIM 安装入口)
     *  @param completion 请求结果回调(success 为 true 仅表示系统接受链接，安装界面是否出现及最终安装或激活结果无法从此回调获取)
     */
    @available(iOS 17.4, *)
    @objc public static func install(lpa: String, unsupportedTip: String? = nil, completion: ((_ success: Bool) -> Void)?) {
        WYAppleServices.install(lpa: lpa, unsupportedTip: unsupportedTip, completion: completion)
    }

    /**
     *  请求系统处理 eSIM 安装链接(失败时显示提示，不会回退到浏览器)
     *
     *  @param lpa 完整 LPA 串或省略 LPA: 前缀的激活资料
     *  @param unsupportedTip 请求失败时的提示文案(不传时显示无法打开 eSIM 安装入口)
     *  @param completion 请求结果回调(success 为 true 仅表示系统接受链接，安装界面是否出现及最终安装或激活结果无法从此回调获取)
     */
    @available(iOS 17.4, *)
    @objc public static var install: @convention(block) (_ lpa: String, _ unsupportedTip: String?, _ completion: @escaping (_ success: Bool) -> Void) -> Void {
        return { lpa, unsupportedTip, completion in WYAppleServices.install(lpa: lpa, unsupportedTip: unsupportedTip, completion: completion) }
    }

    /**
     *  生成 LPA 串的二维码图片(内容为归一后的完整 LPA 串，供无法唤起系统安装页的环境(如低于 iOS 17.4 的系统)引导用户扫码安装兜底)
     *
     *  @param lpa 获取到的 LPA 串(兼容带/不带 lpa: 前缀及任意大小写，内部统一归一为大写 LPA: 前缀)
     *
     *  @param size 二维码图片的尺寸(单位为像素，传显示尺寸乘以屏幕缩放比可以得到清晰图)
     *
     *  @return 二维码图片(LPA 不合法、尺寸非有限正数、边长超过 maximumQRCodeDimension 或无法生成时返回 nil)
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
     *  @return 二维码图片(LPA 不合法、尺寸非有限正数、边长超过 maximumQRCodeDimension 或无法生成时返回 nil)
     */
    @objc public static var qrCode: @convention(block) (_ lpa: String, _ size: CGSize) -> UIImage? {
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
    @objc public static var sendMail: @convention(block) (_ to: [String], _ cc: [String], _ bcc: [String], _ subject: String, _ body: String, _ completion: @escaping (_ success: Bool) -> Void) -> Void {
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
    @objc public static var sendSms: @convention(block) (_ to: [String], _ body: String, _ completion: @escaping (_ success: Bool) -> Void) -> Void {
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
    @objc public static var call: @convention(block) (_ number: String, _ completion: @escaping (_ success: Bool) -> Void) -> Void {
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
    @objc public static var openAppPage: @convention(block) (_ appId: String, _ completion: @escaping (_ success: Bool) -> Void) -> Void {
        return { appId, completion in
            WYAppleServices.openAppPage(appId: appId, completion: completion)
        }
    }

    /**
     *  打开指定 App 的 App Store 评分页(用户在页里直接打分评论)
     *
     *  @param appId App 在 App Store 的数字 id(App Store 链接里 id 后面的那串数字)
     *  @param completion 唤起结果回调(success 为 true 时系统已打开 App Store 评分页)
     */
    @objc public static func writeReview(appId: String, completion: ((_ success: Bool) -> Void)?) {
        WYAppleServices.writeReview(appId: appId, completion: completion)
    }

    /**
     *  打开指定 App 的 App Store 评分页(用户在页里直接打分评论)
     *
     *  @param appId App 在 App Store 的数字 id(App Store 链接里 id 后面的那串数字)
     *  @param completion 唤起结果回调(success 为 true 时系统已打开 App Store 评分页)
     */
    @objc public static var writeReview: @convention(block) (_ appId: String, _ completion: @escaping (_ success: Bool) -> Void) -> Void {
        return { appId, completion in
            WYAppleServices.writeReview(appId: appId, completion: completion)
        }
    }
}
#endif
