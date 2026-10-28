//
//  WYStorage+Implementation.swift
//  WYBasisKit
//
//  Created by guanren on 2026/10/27.
//

import Foundation

extension WYStorage {

    /// 遍历沙盒文件夹，返回大小
    static func folderSize(forPath path: String) -> CGFloat {

        let manager = FileManager.default
        guard let files = manager.subpaths(atPath: path) else {
            return 0
        }
        var folderSize :CGFloat = 0
        for file in files {
            let filePath = path +  ("/\(file)")
            folderSize += sandboxFileSize(forPath:filePath)
        }
        return folderSize/(1024*1024)
    }
}
