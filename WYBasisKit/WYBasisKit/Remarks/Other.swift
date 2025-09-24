//
//  Other.swift
//  WYBasisKit
//
//  Created by guanren on 2025/9/23.
//

/**
 * Xcode Build Setting: Install Generated Headers
 *
 * 控制编译生成的头文件是否复制到 Public Headers 安装目录
 *
 * - YES: 将头文件安装到Public目录，外部工程可正常 #import
 *         （开发 Framework/Library 时必须开启，否则外部#import时可能会缺少头文件）
 *
 * - NO : 头文件仅存在于编译临时目录
 *         外部工程无法#import，会报错缺少头文件(自己工程能编译，别人引入 framework 时可能会缺少头文件)
 */
