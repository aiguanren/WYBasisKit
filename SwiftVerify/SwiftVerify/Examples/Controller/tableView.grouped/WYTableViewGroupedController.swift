//
//  WYTableViewGroupedController.swift
//  WYBasisKit
//
//  Created by 官人 on 2021/7/4.
//  Copyright © 2021 官人. All rights reserved.
//

import UIKit
import Kingfisher

class WYGroupedHeaderView: UITableViewHeaderFooterView {
    
    let contentScrollView = WYContentScrollView()
    
    /// 水平方向的两页View(当前+预备，banner由图片构成)
    let horizontalViews: [UIImageView] = [UIImageView(), UIImageView()]
    
    /// 垂直方向的两页View(当前+预备，banner由图片构成)
    let verticalViews: [UIImageView] = [UIImageView(), UIImageView()]
    
    /// 水平方向各下标对应的图片地址
    var horizontalImages: [String] = []
    
    /// 垂直方向各下标对应的图片地址
    var verticalImages: [UIImage] = [UIImage(named: "banner_0")!,
                                     UIImage(named: "banner_1")!,
                                     UIImage(named: "banner_2")!,
                                     UIImage(named: "banner_3")!,
                                     UIImage(named: "banner_4")!,
                                     UIImage(named: "banner_5")!,
                                     UIImage(named: "banner_6")!,
                                     UIImage(named: "banner_7")!,
                                     UIImage(named: "banner_8")!,
                                     UIImage(named: "banner_9")!]
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = .white
        
        for (_, imageView) in horizontalViews.enumerated() {
            imageView.contentMode = .scaleAspectFit
        }
        
        for (_, imageView) in verticalViews.enumerated() {
            imageView.contentMode = .scaleAspectFit
        }
        
        contentScrollView.backgroundColor = .wy_random
        contentScrollView.contentDelegate = self
        contentScrollView.contentSlidingDirection = .omnidirectional
        contentView.addSubview(contentScrollView)
        contentScrollView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 300, height: 600))
            make.edges.equalToSuperview()
        }
    }
    
    func reload(images: [String]) {
        self.horizontalImages = images
        
        contentScrollView.numberOfHorizontalContent = images.count
        contentScrollView.numberOfVerticalContent = images.count
        
        contentScrollView.omnidirectionalDisplay(currentHorizontalView: horizontalViews[0], reserveHorizontalView: horizontalViews[1], currentVerticalView: verticalViews[0], reserveVerticalView: verticalViews[1])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension WYGroupedHeaderView: WYContentScrollViewDelegate {
    
    func wy_contentScrollViewWillSwitch(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentHorizontalView: UIView?, reserveHorizontalView: UIView?, currentVerticalView: UIView?, reserveVerticalView: UIView?) {
        // 由于kf在有placeholder时，默认行为是用占位图先顶掉View上已有的图然后真图异步回来，此时占位图和真图在切换的瞬间会有跳变行为(视觉上就是图片闪烁)，为此加上options: [.keepCurrentImageWhileLoading]来优化处理
        if ((direction == .left) || (direction == .right)), let imageView = reserveHorizontalView as? UIImageView, horizontalImages.isEmpty == false {
            imageView.kf.setImage(with: URL(string: horizontalImages[contentScrollView.reserveHorizontalIndex % horizontalImages.count]), placeholder: UIImage.wy_appIcon(), options: [.keepCurrentImageWhileLoading])
        }
        
        // 预备页按reserveIndex预载图片(取模防环绕越界)
        if ((direction == .up) || (direction == .down)), let imageView = reserveVerticalView as? UIImageView, verticalImages.isEmpty == false {
            imageView.image = verticalImages[contentScrollView.reserveVerticalIndex % verticalImages.count]
        }
    }
    
    func wy_contentScrollViewDidSwitch(_ contentScrollView: WYContentScrollView, direction: WYSlidingDirection, currentHorizontalView: UIView?, reserveHorizontalView: UIView?, currentVerticalView: UIView?, reserveVerticalView: UIView?) {
        // 当前页按currentIndex装图(取模防环绕越界)；同样keepCurrentImageWhileLoading——willSwitch已装过同URL时重设不再被占位图顶掉，补发场景(未预载)也能保留旧图到真图就位
        if ((direction == .left) || (direction == .right)), let imageView = currentHorizontalView as? UIImageView, horizontalImages.isEmpty == false {
            imageView.kf.setImage(with: URL(string: horizontalImages[contentScrollView.currentHorizontalIndex % horizontalImages.count]), placeholder: UIImage.wy_appIcon(), options: [.keepCurrentImageWhileLoading])
        }
        
        // 当前页按currentIndex装图(补发didSwitch时reserveIndex还是残留值，用它会串台；取模防环绕越界)
        if ((direction == .up) || (direction == .down)), let imageView = currentVerticalView as? UIImageView, verticalImages.isEmpty == false {
            imageView.image = verticalImages[contentScrollView.currentVerticalIndex % verticalImages.count]
        }
    }
}

class WYTableViewGroupedController: UIViewController {
    
    lazy var tableView: UITableView = {

        let tableview = UITableView.wy_shared(style: .grouped, separatorStyle: .singleLine, delegate: self, dataSource: self, superView: view)
        tableview.wy_register(UITableViewCell.self, .cell)
        tableview.wy_register(WYGroupedHeaderView.self, .headerFooterView)
        tableview.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(UIDevice.wy_navViewHeight)
            make.left.right.bottom.equalToSuperview()
        }
        return tableview
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationItem.title = "测试tableview Grouped模式"
        tableView.backgroundColor = UIColor.wy_dynamic(.white, .black)
    }
    
    deinit {
        WYLogManager.output("deinit")
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

extension WYTableViewGroupedController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 50
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        let headerView: WYGroupedHeaderView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "WYGroupedHeaderView") as! WYGroupedHeaderView
        headerView.reload(images: ["https://pic4.zhimg.com/v2-f4fa00c730322fb24143e4a33dbec223_1440w.jpg",
                                   "https://pic4.zhimg.com/v2-d2d0eda42a507e4e5215352a5454b117_1440w.jpg",
                                   "https://picx.zhimg.com/v2-4d913fbfef97730e8a6f65fc69f87cd1_1440w.jpg",
                                   "https://pic2.zhimg.com/v2-007cfca521fce9b8c3db588c484d87b1_1440w.jpg",
                                   "https://pic3.zhimg.com/v2-08d43a5cdddcbf948e9240d08bbc3068_1440w.jpg",
                                   "https://pic4.zhimg.com/v2-b40b07cdbe0229e4011df2545f9336e7_1440w.jpg",
                                   "https://pic4.zhimg.com/v2-25ae3f2b5912e43b988d623f4b32afff_1440w.jpg",
                                   "https://pic4.zhimg.com/v2-f012f54144d0364c33a9ccdc42e789b7_1440w.jpg",
                                   "https://picx.zhimg.com/v2-399017a28614691ebe64df664701fb2f_1440w.jpg"])

        return headerView
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        cell.textLabel?.text = "\(indexPath.row)"
        cell.textLabel?.textColor = UIColor.wy_dynamic(.black, .white)
        cell.textLabel?.font = .systemFont(ofSize: UIFont.wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels))

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
