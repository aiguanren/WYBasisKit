//
//  WYTableViewGroupedController.swift
//  WYBasisKit
//
//  Created by 官人 on 2021/7/4.
//  Copyright © 2021 官人. All rights reserved.
//

import UIKit

class WYGroupedHeaderView: UITableViewHeaderFooterView {
    
    let bannerView = WYBannerView()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = .white
        
        bannerView.backgroundColor = .wy_random
        bannerView.automaticCarousel = false
        bannerView.imageContentMode = .scaleAspectFit
        WYLogManager.output("字节描述(KB或MB等)：\(bannerView.cacheSizeString())，\(bannerView.cacheSize())字节")
        contentView.addSubview(bannerView)
        bannerView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 300, height: 600))
            make.edges.equalToSuperview()
        }
    }
    
    func reload(images: [String]) {
        WYLogManager.output("第一张图片信息：\(String(describing: bannerView.cacheImage(images.first ?? "")))")
        bannerView.reload(images: images)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
