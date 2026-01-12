//
//  WYTestDownloadController.swift
//  WYBasisKit
//
//  Created by 官人 on 2021/10/3.
//  Copyright © 2021 官人. All rights reserved.
//

import UIKit
import Kingfisher

class WYTestDownloadController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        let memoryData = WYStorage.takeOut(forKey: "AAAAA")
        var localImage: UIImage? = nil
        if memoryData.userData != nil {
            localImage = UIImage(data: memoryData.userData!)
        }else {
            WYLogManager.output("\(memoryData.error!)")
        }
        
        let localImageView = UIImageView()
        localImageView.backgroundColor = .orange
        localImageView.image = localImage
        self.view.addSubview(localImageView)
        localImageView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(UIDevice.wy_screenHeight / 2)
        }
        
        let downloadImageView = UIImageView()
        downloadImageView.backgroundColor = .orange
        self.view.addSubview(downloadImageView)
        downloadImageView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(UIDevice.wy_screenHeight / 2)
        }
        
        WYActivity.showLoading(in: self.view)
        downloadImage(false, downloadImageView: downloadImageView, localImageView: localImageView)
    }
    
    func downloadImage(_ kingfisher: Bool, downloadImageView: UIImageView, localImageView: UIImageView) {
        
        let imageUrl: String = "https://pic1.zhimg.com/v2-fc20b20ea15bfd6190ddeabf5ed2b5ba_1440w.jpg"
        
        if kingfisher == true {
            
            let cache = try! ImageCache(name: "hahaxiazai", cacheDirectoryURL: WYStorage.createDirectory(directory: .cachesDirectory, subDirectory: "WYBasisKit/Download"))
            
            localImageView.kf.setImage(with: URL(string: imageUrl), placeholder: UIImage.wy_createImage(from: .wy_random), options: [.targetCache(cache)]) { [weak self] result in
                
                guard let self = self else { return }
                
                WYActivity.dismissLoading(in: self.view)
                
                switch result {
                case .success(let source):
                    downloadImageView.image = source.image.wy_blur(20)
                    WYLogManager.output("cacheKey = \(source.originalSource.cacheKey), \nmd5 = \(imageUrl.wy_sha256()), \n缓存路径 = \(cache.diskStorage.cacheFileURL(forKey: source.source.cacheKey))")
                    break
                case .failure(let error):
                    WYLogManager.output("\(error)")
                    WYActivity.dismissLoading(in: self.view)
                    break
                }
            }
            
        }else {
            
            WYNetworkManager.download(path: imageUrl, assetName: "AAAAA") { result in
                
                switch result {
                    
                case .progress(let progress):
                    
                    WYLogManager.output("\(progress.progress)")
                    
                    break
                case .success(let success):
                    
                    WYActivity.dismissLoading(in: self.view)
                    
                    let assetObj: WYDownloadModel? = try! WYCodable().decode(WYDownloadModel.self, from: success.origin.data(using: .utf8)!)
                    
                    WYLogManager.output("assetObj = \(String(describing: assetObj))")
                    
                    let imagePath: String = assetObj?.assetPath ?? ""
                    let image = UIImage(contentsOfFile: imagePath)
                    downloadImageView.image = image?.wy_blur(20)
                    
                    let diskCachePath = assetObj?.diskPath ?? ""
                    
                    let asset: String = (assetObj?.assetName ?? "") + "." + (assetObj?.mimeType ?? "")
                    
                    let memoryData: WYStorageData = WYStorage.storage(forKey: "AAAAA", data: image!.jpegData(compressionQuality: 1.0)!, durable: .minute(2))
                    if memoryData.error == nil {
                        WYLogManager.output("缓存成功 = \(memoryData)")
                        localImageView.image = UIImage(data: memoryData.userData!)
                    }else {
                        WYLogManager.output("缓存失败 = \(memoryData.error ?? "")")
                    }
                    
                    WYNetworkManager.clearDiskCache(path: diskCachePath, asset: asset) { error in
                        
                        if error != nil {
                            WYLogManager.output("error = \(error!)")
                        }else {
                            WYLogManager.output("移除成功")
                        }
                    }
                    
//                    WYNetworkManager.clearDiskCache(path: WYNetworkConfig.default.downloadSavePath.path, asset: asset) { error in
//
//                        if error != nil {
//                            WYLogManager.output("error = \(error!)")
//                        }else {
//                            WYLogManager.output("下载缓存全部移除成功")
//                        }
//                    }
                    
                    break
                case .error(let error):
                    WYLogManager.output("\(error)")
                    WYActivity.dismissLoading(in: self.view)
                    break
                }
            }
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
