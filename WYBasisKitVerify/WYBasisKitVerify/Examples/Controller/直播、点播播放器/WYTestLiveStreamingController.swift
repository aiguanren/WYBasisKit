//
//  WYTestLiveStreamingController.swift
//  WYBasisKit
//
//  Created by 官人 on 2022/4/21.
//  Copyright © 2022 官人. All rights reserved.
//

import UIKit

class WYTestLiveStreamingController: UIViewController {
    
    let player: WYLivePlayer = WYLivePlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        
        let shouldAutoplay = UIButton(type: .custom)
        shouldAutoplay.setTitle("shouldAutoplay", for: .normal)
        shouldAutoplay.backgroundColor = .wy_random
        shouldAutoplay.addTarget(self, action: #selector(shouldAutoplay(sender:)), for: .touchUpInside)
        view.addSubview(shouldAutoplay)
        shouldAutoplay.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview().offset(wy_navViewHeight)
        }
        
        let mute = UIButton(type: .custom)
        mute.backgroundColor = .wy_random
        mute.setTitle("mute", for: .normal)
        mute.addTarget(self, action: #selector(mute(sender:)), for: .touchUpInside)
        view.addSubview(mute)
        mute.snp.makeConstraints { make in
            make.left.equalTo(shouldAutoplay.snp.right)
            make.top.equalTo(shouldAutoplay)
        }
        
        let play = UIButton(type: .custom)
        play.backgroundColor = .wy_random
        play.setTitle("play", for: .normal)
        play.addTarget(self, action: #selector(play(sender:)), for: .touchUpInside)
        view.addSubview(play)
        play.snp.makeConstraints { make in
            make.left.equalTo(mute.snp.right)
            make.top.equalTo(mute)
        }
        
        let pause = UIButton(type: .custom)
        pause.backgroundColor = .wy_random
        pause.setTitle("pause", for: .normal)
        pause.addTarget(self, action: #selector(pause(sender:)), for: .touchUpInside)
        view.addSubview(pause)
        pause.snp.makeConstraints { make in
            make.left.equalTo(shouldAutoplay)
            make.top.equalTo(mute.snp.bottom)
        }
        
        let stop = UIButton(type: .custom)
        stop.backgroundColor = .wy_random
        stop.setTitle("stop", for: .normal)
        stop.addTarget(self, action: #selector(stop(sender:)), for: .touchUpInside)
        view.addSubview(stop)
        stop.snp.makeConstraints { make in
            make.left.equalTo(pause.snp.right)
            make.top.equalTo(mute.snp.bottom)
        }
        
        let url = UIButton(type: .custom)
        url.backgroundColor = .wy_random
        url.setTitle("url", for: .normal)
        url.addTarget(self, action: #selector(url(sender:)), for: .touchUpInside)
        view.addSubview(url)
        url.snp.makeConstraints { make in
            make.left.equalTo(stop.snp.right)
            make.top.equalTo(mute.snp.bottom)
        }
        
        // http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/gear2/prog_index.m3u8
        
        // http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8
        
        player.delegate = self
        player.looping = 1
        player.backgroundColor = .white
        view.addSubview(player)
        player.snp.makeConstraints { make in
            make.left.right.centerY.equalToSuperview()
            make.height.equalTo(300)
        }
        player.layoutIfNeeded()
        
        //        let videoPath: String = Bundle.main.path(forResource: "mpeg4_local", ofType: "mp4") ?? ""
        //        let videoUrl = URL(fileURLWithPath: videoPath)
        //        player.play(with: videoUrl.absoluteString)
        
        //        let videoPath: String = Bundle.main.path(forResource: "1650855755919", ofType: "mp4") ?? ""
        //        let videoUrl = URL(fileURLWithPath: videoPath)
        //        player.play(with: videoUrl.absoluteString)
        
        //        player.play(with: "rtsp://wowzaec2demo.streamlock.net/vod/mp4:BigBuckBunny_115k.mp4")
        
        //        player.play(with: "http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8")
        
        player.play(with: "http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8")
        
        WYActivity.showLoading(in: player, animation: .gifOrApng, config: WYActivityConfig.concise)
        
        /**
         let options: IJKFFOptions = IJKFFOptions.byDefault()
         
         // 1为开启硬件解码，用特定方法把数字编码还原成它所代表的内容或将电脉冲信号转换成它所代表的信息、数据等; 硬件解码其实就是用GPU的专门模块编码来解（建议使用硬解码）。0为软件解码，更稳定，是cpu进行解码(如果使用软解码可能导致cpu占用率高)
         options.setPlayerOptionIntValue(1, forKey: "videotoolbox")
         // 帧速率(fps) （可以改，确认非标准桢率会导致音画不同步，所以只能设定为15或者29.97）帧速率越大,画质越好,但太大了,有些机器版本不支持,反而有些卡。
         options.setPlayerOptionIntValue(Int64(29.97), forKey: "r")
         // -vol——设置音量大小，256为标准音量。（要设置成两倍音量时则输入512，依此类推
         options.setPlayerOptionIntValue(512, forKey: "vol")
         // 是否开启环路过滤，0开启，画面质量高，解码开销大，48关闭，画面质量略差，解码开销小
         options.setPlayerOptionIntValue(48, forKey: "skip_loop_filter")
         // 播放前预加载大小,默认1兆，数字越小，出画面的越快
         options.setPlayerOptionIntValue(1024 * 8, forKey: "probesize")
         // 播放前的探测时间
         options.setPlayerOptionIntValue(50000, forKey: "analyzeduration")
         // 是否开启预缓冲 0关闭，1开启，直播项目一般开启，以达到秒开效果，不过可能会出现丢帧卡顿现象
         options.setPlayerOptionIntValue(1, forKey: "packet-buffering")
         // 设置播放重连次数
         options.setPlayerOptionIntValue(1, forKey: "reconnect")
         // 跳帧处理，当CPU处理较慢时就跳帧，保证声音和画面同步
         options.setPlayerOptionIntValue(1, forKey: "framedrop")
         // 最大fps
         options.setPlayerOptionIntValue(30, forKey: "max-fps")
         // 自动转屏开关
         //options.setPlayerOptionIntValue(0, forKey: "auto_convert")
         
         // 清空DNS,有时因为在APP里面要播放多种类型的视频(如:MP4,直播,直播平台保存的视频,和其他http视频), 有时会造成因为DNS的问题而报10000问题
         //options.setPlayerOptionIntValue(1, forKey: "dns_cache_clear")
         
         // 静音 1开启静音， 0关闭静音
         //options.setPlayerOptionIntValue(0, forKey: "an")
         // 是否有视频
         //options.setPlayerOptionIntValue(0, forKey: "vn")
         
         // 最大缓冲比
         //options.setPlayerOptionIntValue(1024 * 10, forKey: "max-buffer-size")
         // 超时时间，timeout参数只对http设置有效，若果你用rtmp设置timeout，ijkplayer内部会忽略timeout参数。rtmp的timeout参数含义和http的不一样。
         //options.setPlayerOptionIntValue(30 * 1000 * 1000, forKey: "timeout")
         
         options.setPlayerOptionIntValue(0, forKey: "http-detect-range-support")
         options.setPlayerOptionIntValue(25, forKey: "min-frames")
         options.setPlayerOptionIntValue(1, forKey: "start-on-prepared")
         options.setPlayerOptionIntValue(8, forKey: "skip_frame")
         */
    }
    
    @objc func shouldAutoplay(sender: UIButton) {
        player.shouldAutoplay = !player.shouldAutoplay
    }
    
    @objc func mute(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        player.muted(sender.isSelected)
    }
    
    @objc func play(sender: UIButton) {
        player.play()
    }
    
    @objc func pause(sender: UIButton) {
        player.pause()
    }
    
    @objc func stop(sender: UIButton) {
        player.stop()
    }
    
    @objc func url(sender: UIButton) {
        player.play(with: "https://files.cochat.lenovo.com/download/dbb26a06-4604-3d2b-bb2c-6293989e63a7/55deb281e01b27194daf6da391fdfe83.mp4")
        WYActivity.showLoading(in: player, animation: .gifOrApng, config: WYActivityConfig.concise)
    }
    
    deinit {
        wy_print("WYTestLiveStreamingController release")
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

extension WYTestLiveStreamingController: WYLivePlayerDelegate {
    
    func livePlayerDidChangeState(_ player: WYLivePlayer, _ state: WYLivePlayerState) {
        switch state {
        case .unknown:
            wy_print("未知状态")
        case .rendered:
            wy_print("第一帧渲染完成")
            WYActivity.dismissLoading(in: player)
        case .ready:
            wy_print("可以播放了")
        case .playing:
            wy_print("正在播放")
            WYActivity.dismissLoading(in: player)
        case .buffering:
            wy_print("缓冲中")
            WYActivity.showLoading(in: player, animation: .gifOrApng, config: WYActivityConfig.concise)
        case .playable:
            wy_print("缓冲结束")
            WYActivity.dismissLoading(in: player)
        case .paused:
            wy_print("播放暂停")
            WYActivity.dismissLoading(in: player)
        case .interrupted:
            wy_print("播放被中断")
            WYActivity.dismissLoading(in: player)
        case .seekingForward:
            wy_print("快进")
            WYActivity.dismissLoading(in: player)
        case .seekingBackward:
            wy_print("快退")
            WYActivity.dismissLoading(in: player)
        case .ended:
            wy_print("播放完毕")
            WYActivity.dismissLoading(in: player)
        case .userExited:
            wy_print("用户中断播放")
            WYActivity.dismissLoading(in: player)
        case .error:
            wy_print("播放出现异常")
            WYActivity.dismissLoading(in: player)
        }
    }
}

