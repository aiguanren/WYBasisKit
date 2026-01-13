//
//  WYSpeechRecognitionController.m
//  ObjCVerify
//
//  Created by guanren on 2026/1/13.
//

#import "WYSpeechRecognitionController.h"
#import <Speech/Speech.h>
#import <WYBasisKitObjC/WYBasisKitObjC.h>

// 在进行语音识别之前，你必须获得用户的相应授权，因为语音识别并不是在iOS设备本地进行识别，而是在苹果的伺服器上进行识别的。所有的语音数据都需要传给苹果的后台服务器进行处理。因此必须得到用户的授权。

// 创建语音识别器，指定语音识别的语言环境 locale ,将来会转化为什么语言，这里是使用的当前区域，那肯定就是简体中文啦

@interface WYSpeechRecognitionController () <SFSpeechRecognizerDelegate, SFSpeechRecognitionTaskDelegate>

@property (weak, nonatomic) IBOutlet UITextView *textView;

@property (weak, nonatomic) IBOutlet UIButton *voiceView;

@property (nonatomic, strong) SFSpeechRecognizer *speechRecognizer;

// 使用 identifier 这里设置的区域是台湾，将来会转化为繁体汉语
//    @property (nonatomic, strong) SFSpeechRecognizer *speechRecognizer;

// 发起语音识别请求，为语音识别器指定一个音频输入源，这里是在音频缓冲器中提供的识别语音。
// 除 SFSpeechAudioBufferRecognitionRequest 之外还包括：
// SFSpeechRecognitionRequest  从音频源识别语音的请求。
// SFSpeechURLRecognitionRequest 在录制的音频文件中识别语音的请求。
@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *recognitionRequest;

// 语音识别任务，可监控识别进度，通过他可以取消或终止当前的语音识别任务
@property (nonatomic, strong) SFSpeechRecognitionTask *recognitionTask;

// 语音引擎，负责提供录音输入
@property (nonatomic, strong) AVAudioEngine *audioEngine;

// 记录每次识别到的文字
@property (nonatomic, strong) NSMutableArray<NSString *> *audioToTexts;

@end

@implementation WYSpeechRecognitionController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // 网络监听
    [WYNetworkStatus listening:@"SpeechRecognition" queue:dispatch_get_main_queue() handler:^(NSInteger status) {
            
        // ✅ 是否已连接网络
        if (WYNetworkStatus.isReachable) {
            WYLogManager.output(@"✅ 网络连接正常");
        }
        
        // ❌ 是否无法连接
        if (WYNetworkStatus.isNotReachable) {
            WYLogManager.output(@"❌ 当前没有网络连接（可能是飞行模式、断网或信号太差）");
        }
        
        // ⚠️ 是否需要额外步骤（如登录认证）
        if (WYNetworkStatus.requiresConnection) {
            WYLogManager.output(@"⚠️ 网络需要建立连接（可能需要认证登录）");
        }
        
        // 📱 是否蜂窝数据网络
        if (WYNetworkStatus.isReachableOnCellular) {
            WYLogManager.output(@"📱 当前使用蜂窝移动网络（4G/5G 数据流量）");
        }
        
        // 📶 是否 Wi-Fi
        if (WYNetworkStatus.isReachableOnWiFi) {
            WYLogManager.output(@"📶 当前通过 Wi-Fi 连接网络");
        }
        
        // 🖥️ 是否有线网络
        if (WYNetworkStatus.isReachableOnWiredEthernet) {
            WYLogManager.output(@"🖥️ 当前使用有线网络（例如 Lightning 转网线适配器）");
        }
        
        // 🛡️ 是否 VPN 连接
        if (WYNetworkStatus.isReachableOnVPN) {
            WYLogManager.output(@"🛡️ 当前通过 VPN 连接（加密通道，可能改变出口 IP）");
        }
        
        // 🔁 是否本地回环接口
        if (WYNetworkStatus.isLoopback) {
            WYLogManager.output(@"🔁 当前网络是本地回环接口（仅限设备内部通信）");
        }
        
        // 💰 是否昂贵连接（蜂窝或热点）
        if (WYNetworkStatus.isExpensive) {
            WYLogManager.output(@"💰 当前网络连接昂贵（例如蜂窝数据或个人热点）");
        }
        
        // 🌐 是否其他(未知类型)
        if (WYNetworkStatus.isReachableOnOther) {
            WYLogManager.output(@"🌐 当前是其他(未知类型)的网络接口（不在常规分类中）");
        }
        
        // 🌍 是否支持 IPv4
        if (WYNetworkStatus.supportsIPv4) {
            WYLogManager.output(@"🌍 当前网络支持 IPv4 协议");
        }
        
        // 🌏 是否支持 IPv6
        if (WYNetworkStatus.supportsIPv6) {
            WYLogManager.output(@"🌏 当前网络支持 IPv6 协议");
        }
        
        // 🧩 当前网络状态值
        NSArray <NSString *>*statusTips = @[@"🟢 当前网络状态：已连接（satisfied）",
                                @"🔴 当前网络状态：未连接（unsatisfied）",
                                @"🟡 当前网络状态：需要额外连接步骤（requiresConnection）",
                                @"⚪️ 当前网络状态：未知"];
        
        [WYActivity showInfo:statusTips[status]];
    }];
    
    // 输出一下语音识别器支持的区域，就是上边初始化SFSpeechRecognizer 时 locale 所需要的 identifier
    WYLog(@"%@", [SFSpeechRecognizer supportedLocales]);
    
    self.voiceView.enabled = NO;
    
    // 初始化语音识别器
    self.speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:NSLocale.autoupdatingCurrentLocale];
    
    // 使用 identifier 这里设置的区域是台湾，将来会转化为繁体汉语
//    self.speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:[NSLocale localeWithLocaleIdentifier:@"zh-TW"]];
    
    // 设置语音识别器代理
    self.speechRecognizer.delegate = self;
    
    // 初始化音频引擎
    self.audioEngine = [[AVAudioEngine alloc] init];
    
    // 初始化文本数组
    self.audioToTexts = [NSMutableArray array];
    
    // 要求用户授予您的应用许可来执行语音识别。
    [WYSpeechRecognitionAuthorization authorizeSpeechRecognitionWithShowAlert:YES completionHandler:^(BOOL authorized) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.textView.userInteractionEnabled = NO;
            self.voiceView.enabled = authorized;
        }];
    }];
}

- (void)startRecordingPersonSpeech {
    // 检查 recognitionTask 任务是否处于运行状态。如果是，取消任务开始新的任务
    if (self.recognitionTask != nil) {
        // 取消当前语音识别任务。
        [self.recognitionTask cancel];
        self.recognitionTask = nil;
    }
    
    // 建立一个AVAudioSession 用于录音
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error = nil;
    @try {
        // category 设置为 record,录音
        [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
        if (error) {
            WYLog(@"audioSession setCategory error: %@", error);
            error = nil;
        }
        
        // mode 设置为 measurement
        [audioSession setMode:AVAudioSessionModeMeasurement error:&error];
        if (error) {
            WYLog(@"audioSession setMode error: %@", error);
            error = nil;
        }
        
        // 开启 audioSession
        [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
        if (error) {
            WYLog(@"audioSession setActive error: %@", error);
            error = nil;
        }
    } @catch (NSException *exception) {
        WYLog(@"audioSession properties weren't set because of an error.");
    }
    
    // 初始化RecognitionRequest，在后边我们会用它将录音数据转发给苹果服务器
    self.recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    
    // 检查 iPhone 是否有有效的录音设备
    AVAudioInputNode *inputNode = self.audioEngine.inputNode;
    if (!inputNode) {
        WYLog(@"Audio engine has no input node");
        return;
    }
    
    if (!self.recognitionRequest) {
        WYLog(@"Unable to create an SFSpeechAudioBufferRecognitionRequest object");
        return;
    }
    
    // 在用户说话的同时，将识别结果分批次返回
    self.recognitionRequest.shouldReportPartialResults = YES;
    
    // 添加标点符号
    if (@available(iOS 16, *)) {
        self.recognitionRequest.addsPunctuation = YES;
    } else {
        // iOS16以下需要自己处理标点符号，建议可以参考：PaddleSpeech
    }
    
    // 防止通过网络发送音频，识别将不再那么准确
    if ([self.speechRecognizer supportsOnDeviceRecognition]) {
        self.recognitionRequest.requiresOnDeviceRecognition = YES;
    }
    
    // 使用recognitionTask方法开始识别，这里推荐代理实现方式，闭包方式无法将已经识别到的文本和新识别到的文本连接起来
    self.recognitionTask = [self.speechRecognizer recognitionTaskWithRequest:self.recognitionRequest delegate:self];
    
    /*
     self.recognitionTask = [self.speechRecognizer recognitionTaskWithRequest:self.recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
     __weak typeof(self) weakSelf = self;
     // 用于检查识别是否结束
     BOOL isFinal = NO;
     // 如果 result 不是 nil,
     if (result != nil) {
     // 将 textView.text 设置为 result 的最佳音译
     weakSelf.textView.text = result.bestTranscription.formattedString ?: @"";
     
     // 如果 result 是最终，将 isFinal 设置为 true
     isFinal = result.isFinal;
     }
     
     // 如果没有错误发生，或者 result 已经结束，停止audioEngine 录音，终止 recognitionRequest 和 recognitionTask
     if (error != nil || isFinal) {
     [weakSelf.audioEngine stop];
     [inputNode removeTapOnBus:0];
     
     weakSelf.recognitionRequest = nil;
     weakSelf.recognitionTask = nil;
     // 开始录音按钮可用
     weakSelf.voiceView.enabled = YES;
     }
     }];
     */
    
    // 向recognitionRequest加入一个音频输入
    AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
    [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        [self.recognitionRequest appendAudioPCMBuffer:buffer];
    }];
    
    [self.audioEngine prepare];
    
    @try {
        // 开始录音
        [self.audioEngine startAndReturnError:&error];
        if (error) {
            WYLog(@"audioEngine couldn't start because of an error: %@", error);
        }
    } @catch (NSException *exception) {
        WYLog(@"audioEngine couldn't start because of an error.");
    }
    
    self.textView.text = @"请讲话...";
}

- (IBAction)startRecording:(UIButton *)sender {
    
    if (self.audioEngine.isRunning) {
        // 停止录音
        [self.audioEngine stop];
        // 表示音频源已完成，并且不会再将音频附加到识别请求。
        [self.recognitionRequest endAudio];
        self.voiceView.enabled = NO;
        [self.voiceView setTitle:@"语音识别" forState:UIControlStateNormal];
    } else {
        [self startRecordingPersonSpeech];
        [self.voiceView setTitle:@"结束" forState:UIControlStateNormal];
    }
}

#pragma mark - SFSpeechRecognizerDelegate

- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available {
    // Handle availability changes
}

#pragma mark - SFSpeechRecognitionTaskDelegate

// Called when the task first detects speech in the source audio
- (void)speechRecognitionDidDetectSpeech:(SFSpeechRecognitionTask *)task {
    WYLog(@"Called when the task first detects speech in the source audio");
}

// Called for all recognitions, including non-final hypothesis
- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didHypothesizeTranscription:(SFTranscription *)transcription {
    // 在这里实现即时转译效果
    NSString *currentText = [self.audioToTexts componentsJoinedByString:@""];
    self.textView.text = [currentText stringByAppendingString:transcription.formattedString];
}

// Called only for final recognitions of utterances. No more about the utterance will be reported
- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didFinishRecognition:(SFSpeechRecognitionResult *)recognitionResult {
    // 这里是获取最终的识别结果，并且将 textView.text 设置为 result 的最佳音译
    // 添加标点符号
    NSString *symbol = @"";
    if (@available(iOS 16, *)) {
    } else {
        symbol = @",";
    }
    NSString *finalText = [recognitionResult.bestTranscription.formattedString stringByAppendingString:symbol];
    [self.audioToTexts addObject:finalText];
    self.textView.text = [self.audioToTexts componentsJoinedByString:@""];
}

// Called when the task is no longer accepting new audio but may be finishing final processing
- (void)speechRecognitionTaskFinishedReadingAudio:(SFSpeechRecognitionTask *)task {
    WYLog(@"Called when the task is no longer accepting new audio but may be finishing final processing");
}

// Called when the task has been cancelled, either by client app, the user, or the system
- (void)speechRecognitionTaskWasCancelled:(SFSpeechRecognitionTask *)task {
    WYLog(@"Called when the task has been cancelled, either by client app, the user, or the system");
}

// Called when recognition of all requested utterances is finished.
// If successfully is false, the error property of the task will contain error information
- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didFinishSuccessfully:(BOOL)successfully {
    
    [self.audioEngine stop];
    [self.audioEngine.inputNode removeTapOnBus:0];
    self.recognitionRequest = nil;
    self.recognitionTask = nil;
    [self.audioToTexts removeAllObjects];
    self.textView.text = @"语音识别步骤\n1、按下 语音识别 按钮\n2、语音识别(说出想要识别的内容)\n3、按下 结束 按钮结束语音识别";
    self.voiceView.enabled = YES;
}

- (void)dealloc {
    [WYNetworkStatus stopListening:@"SpeechRecognition"];
}


/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
