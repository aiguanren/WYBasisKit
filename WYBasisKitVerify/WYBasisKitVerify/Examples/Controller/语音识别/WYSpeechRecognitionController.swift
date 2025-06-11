//
//  WYSpeechRecognitionController.swift
//  WYBasisKitTest
//
//  Created by 官人 on 2023/6/8.
//  参考：https://blog.51cto.com/u_11643026/6273204

import UIKit
import Speech

class WYSpeechRecognitionController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var voiceView: UIButton!
    
    // 在进行语音识别之前，你必须获得用户的相应授权，因为语音识别并不是在iOS设备本地进行识别，而是在苹果的伺服器上进行识别的。所有的语音数据都需要传给苹果的后台服务器进行处理。因此必须得到用户的授权。
    
    // 创建语音识别器，指定语音识别的语言环境 locale ,将来会转化为什么语言，这里是使用的当前区域，那肯定就是简体中文啦
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.autoupdatingCurrent)
    
    // 使用 identifier 这里设置的区域是台湾，将来会转化为繁体汉语
    //    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-TW"))
    
    // 发起语音识别请求，为语音识别器指定一个音频输入源，这里是在音频缓冲器中提供的识别语音。
    // 除 SFSpeechAudioBufferRecognitionRequest 之外还包括：
    // SFSpeechRecognitionRequest  从音频源识别语音的请求。
    // SFSpeechURLRecognitionRequest 在录制的音频文件中识别语音的请求。
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    // 语音识别任务，可监控识别进度，通过他可以取消或终止当前的语音识别任务
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // 语音引擎，负责提供录音输入
    private let audioEngine: AVAudioEngine? = AVAudioEngine()
    
    // 记录每次识别到的文字
    private var audioToTexts: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // 网络监听
        WYNetworkStatus.listening("SpeechRecognition") { status in
            switch status {
            case .notReachable:
                wy_print("无网络连接")
            case .unknown :
                wy_print("未知网络连接状态")
            case .reachable(.ethernetOrWiFi):
                wy_print("连接到WiFi网络")
            case .reachable(.cellular):
                wy_print("连接到移动网络")
            }
        }
        
        // 输出一下语音识别器支持的区域，就是上边初始化SFSpeechRecognizer 时 locale 所需要的 identifier
        wy_print(SFSpeechRecognizer.supportedLocales())
        
        voiceView.isEnabled = false
        // 设置语音识别器代理
        speechRecognizer?.delegate = self
        
        // 要求用户授予您的应用许可来执行语音识别。
        wy_authorizeSpeechRecognition { authorized in
            OperationQueue.main.addOperation() {
                self.textView.isUserInteractionEnabled = false
                self.voiceView.isEnabled = authorized
            }
        }
    }
    
    func startRecordingPersonSpeech() {
        // 检查 recognitionTask 任务是否处于运行状态。如果是，取消任务开始新的任务
        if recognitionTask != nil {
            // 取消当前语音识别任务。
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // 建立一个AVAudioSession 用于录音
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // category 设置为 record,录音
            try audioSession.setCategory(AVAudioSession.Category.record)
            // mode 设置为 measurement
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            // 开启 audioSession
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            wy_print("audioSession properties weren't set because of an error.")
        }
        
        // 初始化RecognitionRequest，在后边我们会用它将录音数据转发给苹果服务器
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        // 检查 iPhone 是否有有效的录音设备
        guard let inputNode = audioEngine?.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        //
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        // 在用户说话的同时，将识别结果分批次返回
        recognitionRequest.shouldReportPartialResults = true
        
        // 添加标点符号
        if #available(iOS 16, *) {
            recognitionRequest.addsPunctuation = true
        } else {
            // iOS16以下需要自己处理标点符号，建议可以参考：PaddleSpeech
        }
        
        if #available(iOS 13, *) {
            // 防止通过网络发送音频，识别将不再那么准确
            if speechRecognizer?.supportsOnDeviceRecognition ?? false {
                recognitionRequest.requiresOnDeviceRecognition = true
            }
        } else {
            // Fallback on earlier versions
        }
        
        // 使用recognitionTask方法开始识别，这里推荐代理实现方式，闭包方式无法将已经识别到的文本和新识别到的文本连接起来
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, delegate: self)
        
        /*
         recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { [weak self] (result, error) in
 
             guard let self = self else { return }
             // 用于检查识别是否结束
             var isFinal = false
             // 如果 result 不是 nil,
             if result != nil {
                 // 将 textView.text 设置为 result 的最佳音译
                 textView.text = result?.bestTranscription.formattedString ?? ""
                 
                 // 如果 result 是最终，将 isFinal 设置为 true
                 isFinal = (result?.isFinal)!
             }
 
             // 如果没有错误发生，或者 result 已经结束，停止audioEngine 录音，终止 recognitionRequest 和 recognitionTask
             if error != nil || isFinal {
                 audioEngine?.stop()
                 inputNode.removeTap(onBus: 0)
 
                 self.recognitionRequest = nil
                 recognitionTask = nil
                 // 开始录音按钮可用
                 voiceView.isEnabled = true
             }
         })
         */
        
        // 向recognitionRequest加入一个音频输入
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer, when) in
            self?.recognitionRequest?.append(buffer)
        }
        
        audioEngine?.prepare()
        
        do {
            // 开始录音
            try audioEngine?.start()
        } catch {
            wy_print("audioEngine couldn't start because of an error.")
        }
        textView.text = "请讲话..."
    }
    
    @IBAction func startRecording(_ sender: UIButton) {
        
        if audioEngine?.isRunning ?? false {
            // 停止录音
            audioEngine?.stop()
            // 表示音频源已完成，并且不会再将音频附加到识别请求。
            recognitionRequest?.endAudio()
            voiceView.isEnabled = false
            voiceView.setTitle("语音识别", for: .normal)
        } else {
            startRecordingPersonSpeech()
            voiceView.setTitle("结束", for: .normal)
        }
    }
    
    deinit {
        WYNetworkStatus.stopListening("SpeechRecognition")
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

extension WYSpeechRecognitionController: SFSpeechRecognizerDelegate, SFSpeechRecognitionTaskDelegate {
    
    // Called when the task first detects speech in the source audio
    func speechRecognitionDidDetectSpeech(_ task: SFSpeechRecognitionTask) {
        wy_print("Called when the task first detects speech in the source audio")
    }
    
    
    // Called for all recognitions, including non-final hypothesis
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {
        // 在这里实现即时转译效果
        textView.text = audioToTexts.joined().appending(transcription.formattedString)
    }
    
    
    // Called only for final recognitions of utterances. No more about the utterance will be reported
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult) {
        // 这里是获取最终的识别结果，并且将 textView.text 设置为 result 的最佳音译
        // 添加标点符号
        var symbol: String = ""
        if #available(iOS 16, *) {
        } else {
            symbol = ","
        }
        audioToTexts.append(recognitionResult.bestTranscription.formattedString.appending(symbol))
        textView.text = audioToTexts.joined()
    }
    
    
    // Called when the task is no longer accepting new audio but may be finishing final processing
    func speechRecognitionTaskFinishedReadingAudio(_ task: SFSpeechRecognitionTask) {
        wy_print("Called when the task is no longer accepting new audio but may be finishing final processing")
    }
    
    
    // Called when the task has been cancelled, either by client app, the user, or the system
    func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask) {
        wy_print("Called when the task has been cancelled, either by client app, the user, or the system")
    }
    
    
    // Called when recognition of all requested utterances is finished.
    // If successfully is false, the error property of the task will contain error information
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest = nil
        recognitionTask = nil
        audioToTexts.removeAll()
        textView.text = "语音识别步骤\n1、按下 语音识别 按钮\n2、语音识别(说出想要识别的内容)\n3、按下 结束 按钮结束语音识别"
        voiceView.isEnabled = true
    }
}
