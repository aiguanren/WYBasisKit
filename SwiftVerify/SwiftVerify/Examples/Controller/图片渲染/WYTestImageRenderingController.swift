//
//  WYTestImageRenderingController.swift
//  SwiftVerify
//
//  Created by guanren on 2026/3/24.
//

import UIKit
import Kingfisher

class WYTestImageRenderingController: UIViewController {
    
    @IBOutlet weak var imageView1: UIImageView!
    
    @IBOutlet weak var imageView2: UIImageView!
    
    @IBOutlet weak var imageView3: UIImageView!
    
    @IBOutlet weak var imageView4: UIImageView!
    
    @IBOutlet weak var imageView5: UIImageView!
    
    @IBOutlet weak var imageView6: UIImageView!
    
    @IBOutlet weak var imageView7: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        let webpUrl: URL = URL(fileURLWithPath: Bundle.main.path(forResource: "彩色花", ofType: "webp").wy_safe)
        imageView3.kf.setImage(with: LocalFileImageDataProvider(fileURL: webpUrl))
        
        imageView4.image = imageView4.image?.wy_rendering(color: .wy_hex("969696"))
        imageView5.image = imageView5.image?.wy_rendering(color: .wy_hex("969696"))
        
        let renderingColor: UIColor = .red
        
        let cache = KingfisherManager.shared.cache
        
        let urlString = "https://img2.baidu.com/it/u=1992834630,4261363621&fm=253&fmt=auto&app=138&f=JPEG.webp"
        let url = URL(string: urlString)!
        let urlCacheKey = "\(urlString)_\(renderingColor.hashValue)"
        let urlTaskId = UUID().uuidString
        imageView6.accessibilityIdentifier = urlTaskId
        imageView6.kf.setImage(with: url) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let value):
                
                let sourceImage = value.image
                
                // 查询缓存
                cache.retrieveImage(forKey: urlCacheKey) { result in
                    
                    // 渲染
                    func render() {
                        sourceImage.wy_rendering(color: renderingColor) { [weak self] tintedImage in
                            guard let self = self else { return }
                            
                            // 校验任务
                            guard self.imageView6.accessibilityIdentifier == urlTaskId else { return }
                            
                            // 写入缓存 + 设置图片
                            cache.store(tintedImage, forKey: urlCacheKey)
                            self.imageView6.image = tintedImage
                        }
                    }
                    
                    switch result {
                    case .success(let value):
                        Task { @MainActor in
                            if let image = value.image,
                               self.imageView6.accessibilityIdentifier == urlTaskId {
                                self.imageView6.image = image
                            } else {
                                render()
                            }
                        }
                    case .failure:
                        render()
                    }
                }
                
            case .failure(let error):
                WYLogManager.output("加载失败：\(error.localizedDescription)")
            }
        }
        
        let pathCacheKey = "\(webpUrl.path)_\(renderingColor.hashValue)"
        let pathTaskId = UUID().uuidString
        imageView7.accessibilityIdentifier = pathTaskId
        let sourceImage = UIImage(contentsOfFile: webpUrl.path)
        cache.retrieveImage(forKey: pathCacheKey) { [weak self] result in
            guard let self = self else { return }
            
            func render() {
                guard let sourceImage = sourceImage else { return }
                
                let renderingImage = sourceImage.wy_rendering(color: renderingColor)
                
                Task { @MainActor in
                    // 校验任务
                    guard self.imageView7.accessibilityIdentifier == pathTaskId else { return }
                    
                    cache.store(renderingImage, forKey: pathCacheKey)
                    self.imageView7.image = renderingImage
                }
            }
            
            switch result {
            case .success(let value):
                Task { @MainActor in
                    
                    if let image = value.image,
                       self.imageView7.accessibilityIdentifier == pathTaskId {
                        self.imageView7.image = image
                    } else {
                        render()
                    }
                }
                
            case .failure:
                render()
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
