# IJKOptions 播放器配置选项说明

> 本文件是 `WYMediaPlayer.options` 的配套阅读文档，仅作查阅用。
>
> 适用版本：**IJKPlayerKit 1.1.0**。
> 下文的选项名单、默认值、取值范围均逐条提取自该版本内核二进制内的选项表；个别键在新版本中可能有微调，超出范围的值会被内核自动钳制。

**更多细节可参考内核源码：**
<https://github.com/Bilibili/ijkplayer/blob/master/ijkmedia/ijkplayer/ff_ffplay_options.h>
（本内核以 1.1.0 实际支持的选项为准）

## 目录

1. [IJKOptions 是什么、怎么设置](#一ijkoptions-是什么怎么设置)
2. [在 WYMediaPlayer 中的使用规则（重要）](#二在-wymediaplayer-中的使用规则重要)
3. [IJKOptions 自身的四个属性](#三ijkoptions-自身的四个属性)
4. [Player 分类选项详解（播放器行为）](#四player-分类选项详解播放器行为)
5. [Format 分类常用选项（封装/协议层）](#五format-分类常用选项封装协议层)
6. [Codec 分类常用选项（解码层）](#六codec-分类常用选项解码层)
7. [Sws / Swr 分类（极少使用）](#七sws--swr-分类极少使用)
8. [典型场景推荐配置](#八典型场景推荐配置)

---

## 一、IJKOptions 是什么、怎么设置

IJKOptions 是 ijkplayer 的启动参数集合，在下发 play/prepare 创建播放器内核实例时**一次性读取生效**，播放过程中修改不会影响当前实例（想运行中调整请用 `WYMediaPlayer` 暴露的对应属性/方法，如 `playbackRate`、`switchVideoDecoder`、`enableAccurateSeek` 等）。

设置入口分 5 个分类，每个分类都有「整型」和「字符串」两种写法：

```swift
setPlayerOptionIntValue(Int64, forKey: String)   // 播放器行为选项（第四节）
setFormatOptionIntValue(Int64, forKey: String)   // 封装/协议层选项（第五节）
setCodecOptionIntValue(Int64, forKey: String)    // 解码层选项（第六节）
setSwsOptionIntValue(Int64, forKey: String)      // 软件缩放（第七节）
setPlayerOptionValue(String?, forKey: String)    // 同上的字符串版
setFormatOptionValue(String?, forKey: String)
setCodecOptionValue(String?, forKey: String)
setSwsOptionValue(String?, forKey: String)
setOptionValue/IntValue(..., ofCategory:)        // 通用版，分类取
                                                 // kIJKFFOptionCategoryFormat / Codec / Sws / Player / Swr
```

> 写错键名不会报错，只会被内核当作未知选项打一条日志后忽略，务必对照本文档核对拼写。

最小示例：

```swift
let opt = IJKOptions.byDefault()
opt.setPlayerOptionIntValue(0, forKey: "infbuf")                  // 关闭无限读包
opt.setFormatOptionValue("Mozilla/5.0 ...", forKey: "user_agent") // 自定义 UA
opt.setFormatOptionIntValue(10 * 1024 * 1024, forKey: "probesize") // 调小探测上限
player.options = opt
player.play(with: "https://example.com/video.mp4")
```

---

## 二、在 WYMediaPlayer 中的使用规则（重要）

1. **时机**：必须在 `play(with:)` / `prepare(with:)` 之前把 options 赋给 `WYMediaPlayer.options`，加载发起后才创建内核实例，之后再改无效。
2. **默认预设**：options 为 nil 时，组件每次加载会自动生成一套默认预设（见下表）；`stop()` 会把 options 置回 nil，下次加载重新走默认预设。
3. **完全接管**：一旦赋了自定义 options，组件的默认预设**一行都不会叠加**，播放行为完全由你写的键决定。建议以 `IJKOptions.byDefault()` 为底、按需抄下面需要的键，避免漏掉硬解、丢帧这类基础项。
4. **每次加载强制覆写的三个键**（写在 options==nil 块之外，自定义 options 也会被覆盖）：
   - `"loop"` ← `looping` 属性
   - `"start-on-prepared"` ← 本次加载意图（play 起播 / prepare 不起播）
   - `"max-buffer-size"` ← 起播 15MB / 预加载 4MB

     这三个键自己设置了也会被组件按上述规则重写，想改循环请用 `looping` / `playbackLoop` 属性。
5. **options 对象会被跨加载复用**（直到 `stop()`），叠加修改时注意旧键残留。

### 组件默认预设一览（options == nil 时自动写入）

★ = 组件预设值。对照 `WYMediaPlayer+LoadCore.swift`。

| 键名 | 分类 | 组件预设 | 内核默认 | 作用 |
|---|---|---|---|---|
| infbuf | Player | 1 ★ | 0 | 无限读包（直播防饿死；点播长视频会持续吃内存） |
| packet-buffering | Player | 1 ★ | 1 | 卡顿时先缓冲再播（流畅优先） |
| framedrop | Player | 1 ★ | 0 | 解码跟不上时丢帧保同步 |
| video-pictq-size | Player | 6 ★ | 3 | 解码后图像帧队列容量 |
| min-frames | Player | 25 ★ | 50000 | 停止预读的最小包数 |
| seek_flag_keyframe | Format | 1 ★ | — | mpeg-ts 拖动按关键帧过滤防花屏 |
| probesize | Player | 5120 ★ | 5MB | 探测上限（字节）；⚠️ 此键按惯例属 Format 分类，见下方备注 |
| enable-cvpixelbufferpool | Player | 0 ★ | 1 | 软解帧转换池（内核默认开，组件主动关闭） |
| videotoolbox_hwaccel | Player | 1 ★ | 1 | FFmpeg 硬解加速通道（1.1.0 的硬解总开关） |
| enable-accurate-seek | Player | 1 ★ | 0 | 精准 seek |
| accurate-seek-timeout | Player | 1500 ★ | 5000 | 精准 seek 超时 ms |
| skip_loop_filter | Player | 48 ★ | 0(Codec) | 跳过全部去块滤波；⚠️ 此键按惯例属 Codec 分类，见下方备注 |
| reconnect | Player | 1 ★ | 0(Format) | 断网自动重连；⚠️ 此键按惯例属 Format 分类，见下方备注 |
| max-fps | Player | 30 ★ | 31 | 帧率上限 |
| skip_frame | Player | 8 ★ | 0(Codec) | 跳过非参考帧解码；⚠️ 此键按惯例属 Codec 分类，见下方备注 |
| dns_cache_clear | Format | 1 ★ | — | 播放前清 DNS 缓存 |
| loop / start-on-prepared / max-buffer-size | Player | 动态 | — | 每次加载按规则动态写入（见上文第 4 条） |

> **备注（分类路由）**：`probesize`、`reconnect` 属 avformat 选项、`skip_loop_filter`、`skip_frame` 属 avcodec 选项，内核惯例分别走 Format / Codec 分类设置；组件当前统一写在 Player 分类，是否生效取决于内核对 Player 分类的路由。自定义 options 时建议按第四~六节的分类示例用正确分类补设，确保生效。
>
> **备注（infbuf 与 max-buffer-size 的关系）**：`infbuf=1` 时读线程不再因"队列满"暂停，`max-buffer-size` 的上限控制不生效、内存随播放持续增长；点播长视频想控内存请自定义 options 把 infbuf 设回 0。

---

## 三、IJKOptions 自身的四个属性

| 属性 | 说明 |
|---|---|
| `showHudView: Bool` | 创建实例时是否直接打开性能调试 HUD（帧率/丢帧/缓冲等叠加面板）。播放中随时可用 `WYMediaPlayer.shouldShowHudView` 开关，一般不必在这设。 |
| `protocolWhitelist: String` | 追加允许的协议白名单（逗号分隔）。内核默认已含 `concat,http,tcp,https,crypto,tls,file,bluray,smb2,dvd,rtmp,rtsp,rtp,srtp,udp`，播放非常规协议被拒时才需要追加。 |
| `automaticallySetupAudioSession: Bool` | 是否由播放器接管 AVAudioSession（设成 Playback 分类并处理中断事件）。App 自己统一管理音频会话时置 false，避免互相覆盖。 |
| `currentPlaybackTimeNotificationInterval: TimeInterval` | 播放进度通知间隔（秒），0=关闭周期通知。1.0.8 起底层默认 0（不通知），WYMediaPlayer 已用 `progressCallbackInterval` 属性自动对接，无需手设。 |

---

## 四、Player 分类选项详解（播放器行为）

> 格式：类型与范围、内核默认值均提取自 1.1.0 内核选项表；★ = WYMediaPlayer 默认预设的取值。

### 4.1 起播与缓冲

| 键名 | 类型·范围 | 内核默认 | 作用 | 建议 |
|---|---|---|---|---|
| start-on-prepared | Int 0~1 | 1 | prepare 完成后是否自动起播；0=停在首帧等手动 play | 组件每次加载按播放意图自动写入，无需手设 |
| max-buffer-size | Int 字节 0~500MB | 0(自动) | 预读包队列（音频+视频+字幕）总大小上限，读满即暂停下载；0=内核按码率自动决策 | 点播 15MB ★、预加载 4MB（组件 prepare 自动用此值）、直播可调小或 0；infbuf=1 时本键不生效 |
| min-frames | Int 2~50000 | 50000 | 判定"缓冲够了"的每条流最小包数，达到后停止预读 | 默认 50000 相当于关闭按包数判定（改由水位线判定）；调小起播更快但初始缓冲更薄；组件 25 ★ |
| first-high-water-mark-ms | Int ms 100~5000 | 100 | 一级缓冲水位线：起播先按此毫秒数要求缓冲 | 一般不动；弱网直播可整体调大换稳定 |
| next-high-water-mark-ms | Int ms 100~5000 | 1000 | 二级水位线：一级不足时升级 | 同上 |
| last-high-water-mark-ms | Int ms 100~5000 | 5000 | 三级水位线：兜底上限，卡顿重缓冲时逐级翻倍封顶于此 | 同上；三个值保持 first ≤ next ≤ last |
| packet-buffering | Int 0~1 | 1 | 缓冲不足时是否暂停输出、先攒数据到水位线再继续 | 1=流畅优先（主动停顿攒缓冲）★；0=低延迟优先（反复小卡顿），低延迟直播配 infbuf=1 |
| infbuf | Int 0~1 | 0 | 无限读包：读线程不再因队列满而暂停 | 1=实时流（RTMP/监控）防饿死专用，此时 max-buffer-size 失效；0=点播常态。组件默认 1 ★，点播长视频想控内存请改回 0 |
| video-pictq-size | Int 3~16 | 3 | 解码后视频帧（图像）队列容量，越大越抗解码抖动、seek 出画越顺，内存越高 | 3~6，组件 6 ★ |
| find_stream_info | Int 0~1 | 1 | 打开流时是否探测解码补全缺失的流信息 | 默认 1；自家转码的规范 MP4 想极致提速可试 0，非标封装可能识别不到分辨率/时长 |
| ijkmeta-delay-init | Int 0~1 | 0 | 延迟初始化媒体元数据，加速起播 | 不需要打开即拿 meta 的场景可开 1 |
| async-init-decoder | Int 0~1 | 0 | 异步创建解码器，prepare 提前返回、起播提速（首帧稍晚到） | 弱机起播优化可开 1 |
| skip-calc-frame-rate | Int 0~1 | 0 | 跳过实测帧率计算，加速起播；副作用是 fpsAtOutput 统计可能不准 | 起播优化可开 1 |

### 4.2 解码与硬解

| 键名 | 类型·范围 | 内核默认 | 作用 | 建议 |
|---|---|---|---|---|
| videotoolbox_hwaccel | Int 0~1 | 1 | **1.1.0 的硬解总开关**：FFmpeg 原生 VideoToolbox 硬解通道 | 保持 1 ★（不支持的编码自动回退软解）；纯软解场景才设 0。运行中可用 `switchVideoDecoder(_:)` 热切换 |
| enable-cvpixelbufferpool | Int 0~1 | 1 | 软解帧 avframe → CVPixelBuffer 的转换对象池，减少频繁分配，软解渲染性能优化 | 软解为主保持 1；内存极度敏感才关。组件预设 0 ★ |
| copy_hw_frame | Int 0~1 | 0 | 是否把硬解帧数据从 GPU 拷回 CPU | 默认 0 不拷（省带宽）；仅当自定义渲染/滤镜必须 CPU 读像素时才开 1 |
| deinterlace | Int 0~3 | 0 | 反交错（仅软解生效，硬解在解码器内部处理） | 隔行扫描源（电视 TS、部分 DVD rip）画面有梳状锯齿时开启。运行中也可用 `WYMediaPlayer.deinterlace` 属性热设 |
| framedrop | Int -1~120 | 0 | 解码跟不上时丢弃迟到帧保播放进度（音画同步） | 常规 1 ★；弱机/高帧率源可适当加大 |
| max-fps | Int -1~121 | 31 | 源标称帧率超过该值时丢帧限制，防高帧率源拖垮渲染 | 30=常见影视源够用 ★；60=高刷内容；-1=不限制。与 framedrop 独立：max-fps 按"源标称帧率"预判丢弃，framedrop 按"实际迟到"丢 |
| an / vn / sn | Int 0~1 | 0 | 分别禁用音频流 / 视频流 / 字幕流（不读不解码） | 纯音频播放设 vn=1 省下整条视频解码；排查音频问题临时 an=1 |
| subtitle_mix | Int 0~1 | 1 | 字幕图像用 GPU 混合渲染 | 保持默认 1；GPU 负载异常时试 0 |
| fast | Int 0~1 | 0 | 允许不严格遵循规范的加速优化（跳过部分校验） | 速度略升但个别非标源可能异常，默认关闭，一般不动 |

**framedrop 值区别**：`0`=从不丢帧（落后就慢放/卡）；`1`=温和丢帧，丢一帧就渲染一帧 ★；数值越大=允许连续丢越多帧，追帧越狠、画面跳跃感越强（如 48 接近"追上为止"）；`-1` 在本内核实现下约等于关闭，不建议使用。

**deinterlace 值区别**：`0`=关闭；`1`=bwdif（质量优先）；`2`=yadif（速度优先）；`3`=field（场显示，最快）。

### 4.3 seek 与循环

| 键名 | 类型·范围 | 内核默认 | 作用 | 建议 |
|---|---|---|---|---|
| loop | Int（32位范围） | 1 | 循环播放次数：1=播一次不循环；0=无限循环；N>1=播 N 次 | 组件每次加载用 `looping` 属性覆写；运行中改循环用 `playbackLoop` 属性 |
| seek-at-start | Float 秒 ≥0 | 0 | 起播偏移：从第 N 秒开始播（跳片头），相当于打开后自动 seek 一次 | 按需 |
| enable-accurate-seek | Int 0~1 | 0 | 精准 seek：先定位到目标点之前的关键帧，再逐帧解码到目标点 | 0=关键帧 seek，快但落点回退到最近关键帧；1=落点准、耗时略长 ★。运行中用 `enableAccurateSeek(_:)` 热切换 |
| accurate-seek-timeout | Int ms 0~5000 | 5000 | 精准 seek 的解码超时，超时就地起播（防长时间黑屏） | 拖动频繁的 UI 可调小换手感，组件 1500 ★ |

### 4.4 音量 / 声道 / 时钟

| 键名 | 类型·范围 | 内核默认 | 作用 | 建议 |
|---|---|---|---|---|
| volume | Int 0~100 | 100 | 内核起播音量（百分比） | WYMediaPlayer 有 `playbackVolume(_:)` / `muted` 体系，请勿再用此键，避免两套音量打架 |
| sync-av-start | Int 0~1 | 1 | 起播时音视频时间基对齐 | 关闭后个别流可能起播即音画有固定偏差，一般不动 |
| no-time-adjust | Int 0~1 | 0 | 1=进度上报媒体流原始时间戳、不做时间轴调整 | 直播时间戳跳变/进度异常时用来对照排查 |
| preset-5-1-center-mix-level | Float -32~32 | 0.707 | 5.1 声道源降混成立体声时的中置声道电平，影响人声占比 | 一般不动 |

### 4.5 渲染 / 滤镜 / 杂项

| 键名 | 类型·范围 | 内核默认 | 作用 | 建议 |
|---|---|---|---|---|
| overlay-format | FourCC | RV32 系 | 渲染层像素格式，可用常量：`fcc-i420` / `fcc-j420` / `fcc-yv12` / `fcc-nv12` / `fcc-bgra` / `fcc-bgr0` / `fcc-argb` / `fcc-0rgb` / `fcc-uyvy` / `fcc-yuv2` / `fcc-rv16` / `fcc-rv24` / `fcc-rv32`（`fcc-_es2` 已废弃） | 1.1.0 Metal 渲染内置格式自适应与转换，一般无需设置 |
| vf0 | String | — | FFmpeg 视频滤镜链（如 `"transpose=1"` 旋转），渲染前对解码帧生效 | 与 `renderDisplayDelegate` 的 CPU 滤镜二选一即可 |
| rdftspeed | Int ms ≥0 | 0 | 音频频谱（rdft）刷新周期，0=关闭 | 波形/频谱 UI 请优先用 `WYMediaPlayer.audioSamplesCallback` 回调 |
| video-mime-type | String | — | 为个别信息不全的流（HLS 内嵌 mp4 等）指定视频 mime 类型 | 按需 |
| render-wait-start | Int 0~1 | 0 | 渲染线程等待 start 指令再渲染画面 | 预加载"先备好不显示"的场景用 |
| icy-update-period | Float ms ≥0 | 2000 | ICY 电台元数据（歌名/主持人等）的轮询刷新周期 | 配合 `wy_mediaPlayerICYMetaDidChanged` 回调使用 |
| nodisp | Int 0~1 | 0 | 禁用画面输出（桌面 ffplay 遗留） | 移动端勿动 |
| iformat | String | — | 强制指定解复用器名（如 `"mpegts"`、`"flv"`、`"hls"`） | 仅在自动识别格式失败时使用，设错会直接打不开 |

### 4.6 Android 专属（iOS 上设置无效）

`mediacodec` / `mediacodec-avc` / `mediacodec-hevc` / `mediacodec-mpeg2` / `mediacodec-mpeg4` / `mediacodec-all-videos` / `mediacodec-auto-rotate` / `mediacodec-handle-resolution-change` / `mediacodec-sync` / `mediacodec-default-name` / `opensles` / `soundtouch`

### 4.7 历史遗留键（1.1.0 选项表中已不存在，设置会被忽略）

照搬网上旧示例代码时容易踩到的键；组件默认预设已不再设置它们。

| 键名 | 说明 |
|---|---|
| videotoolbox | 旧版硬解开关，已被 `videotoolbox_hwaccel` 取代 |
| r | 旧版帧率声明键，已移除 |
| vol | 旧版音量键，已移除；音量请用 `playbackVolume(_:)` |
| http-detect-range-support | 旧版 HTTP range 检测开关，本内核未检出 |
| subtitle | 旧版"解码内嵌字幕流"开关，已被 `subtitle_mix` 取代 |
| af | 音频滤镜链，本版本仅保留 `vf0` |
| get-frame-mode | 旧版截帧模式，已移除 |

---

## 五、Format 分类常用选项（封装/协议层）

该分类实际支持 FFmpeg avformat 的全部封装/协议选项（键名与 ffmpeg 一致），下面只列播放器业务里常用的：

| 键名 | 类型·范围 | 默认 | 作用 | 建议 |
|---|---|---|---|---|
| probesize | Int 字节 | 5MB | 探测流信息最多读多少数据 | 流信息识别不全/打开失败时调大；想加速打开可调小（组件预设 5120 字节 ★，极端省流但个别源可能识别失败） |
| analyzeduration | Int 微秒 | 5s | 探测流信息最多分析多长时间 | 用途同上：调小加速、调大更准；注意单位是微秒（1s = 1000000） |
| timeout | Int 微秒 | — | 网络 IO 超时：多久收不到数据算失败（触发错误/重连） | 注意单位是微秒，如 5 秒应写 5000000 |
| reconnect | Int 0~1 | 0 | HTTP 断线自动重连 | 直播断流自愈基本靠它；组件预设 1 ★ |
| dns_cache_clear | Int 0~1 | — | 每次播放前清除内核 DNS 缓存 | CDN 调度切换/IP 漂移导致"换源后连的还是旧 IP"时开；组件预设 1 ★ |
| seek_flag_keyframe | Int 0~1 | — | mpeg-ts 等流 seek 时按关键帧过滤目标数据，解决拖动后花屏 | 组件预设 1 ★ |
| user_agent | String | — | HTTP 请求头 UA | 鉴权/风控服务器需要时设置 |
| headers | String | — | 自定义 HTTP 请求头，多个头用 `\r\n` 分隔 | 如 `"Authorization: Bearer xxx\r\nReferer: https://example.com"` |
| http_proxy | String | — | HTTP 代理地址 | 如 `"http://127.0.0.1:8888"`，抓包调试常用 |

常用补充（标准 ffmpeg 键）：`multiple_requests`（分块请求）、`icy`（开关 ICY 元数据）、`seekable`（声明流是否可 seek）、`rw_timeout`（读写超时）等。

---

## 六、Codec 分类常用选项（解码层）

| 键名 | 类型·范围 | 默认 | 作用 | 建议 |
|---|---|---|---|---|
| skip_loop_filter | Int 0~48 | 0 | 跳过去块滤波（deblocking），解码省 CPU、画质略降（块效应） | CPU 富余或画质敏感建议 8 或 0；组件预设 48 ★（最激进） |
| skip_frame | Int 0~48 | 0 | 直接跳过某些帧不解码，比 skip_loop_filter 更激进的省 CPU 手段 | 设备性能正常建议 0；组件预设 8 ★，画质差异肉眼可见 |
| threads | String "auto" / Int | — | 解码线程数 | 软解时有用；字符串 `"auto"` 自动按核数分配 |

**skip_loop_filter / skip_frame 取值**（FFmpeg AVDISCARD 级别）：

| 值 | 级别 | 含义 |
|---|---|---|
| 0 | DEFAULT | 不跳过（画质最好，CPU 最耗） |
| 8 | NONREF | 跳过非参考帧（B 帧）：滤波层面性价比最高；帧层面有明显压缩感 |
| 16 | BIDIR | 跳过 B 帧 |
| 24 | NONINTRA | 跳过非帧内帧 |
| 32 | NONKEY | 跳过/只解关键帧（近乎幻灯片，极端省 CPU、快速粗略拖动） |
| 48 | ALL | 全部跳过（skip_frame 设此值等于不解码，基本无使用场景；skip_loop_filter 设此值最省 CPU 但块效应最明显） |

---

## 七、Sws / Swr 分类（极少使用）

- **Sws（软件图像缩放）**：`sws_flags` 等键，控制缩放算法（双线性/双三次等）。1.1.0 Metal 渲染自带 GPU 缩放，基本用不到。可用 `setSwsOptionIntValue` 设置。
- **Swr（音频重采样）**：`dither_method`、`output_sample_rate` 等键，有自定义音频渲染组件（`audioRendering`）且对采样有要求时才可能用到。⚠️ IJKOptions 没有 Swr 的便捷设置方法，只能走通用版 `setOptionValue/IntValue(..., ofCategory: kIJKFFOptionCategorySwr)`。

---

## 八、典型场景推荐配置

以下示例都以 `IJKOptions.byDefault()` 为底（承接组件默认预设的思路，按需增删）：

### 1) 常规点播（组件默认预设即可，无需自定义）

```swift
player.play(with: url)
```

### 2) 长视频点播 · 控内存（关无限读包，限制缓冲上限）

```swift
opt.setPlayerOptionIntValue(0, forKey: "infbuf")
opt.setPlayerOptionIntValue(30 * 1024 * 1024, forKey: "max-buffer-size")
```

### 3) 直播 · 低延迟

```swift
opt.setPlayerOptionIntValue(1, forKey: "infbuf")
opt.setPlayerOptionIntValue(0, forKey: "packet-buffering")
opt.setPlayerOptionIntValue(1, forKey: "framedrop")
opt.setPlayerOptionIntValue(0, forKey: "enable-accurate-seek")
```

### 4) 直播 · 稳定优先（允许缓冲、放大水位线）

```swift
opt.setPlayerOptionIntValue(1, forKey: "infbuf")
opt.setPlayerOptionIntValue(1, forKey: "packet-buffering")
opt.setPlayerOptionIntValue(2000, forKey: "first-high-water-mark-ms")
opt.setPlayerOptionIntValue(5000, forKey: "next-high-water-mark-ms")
```

### 5) 纯音频（跳过视频解码，加速打开）

```swift
opt.setPlayerOptionIntValue(1, forKey: "vn")
opt.setFormatOptionIntValue(512 * 1024, forKey: "probesize")
opt.setFormatOptionIntValue(2 * 1000000, forKey: "analyzeduration")
```

### 6) 弱 CPU 设备（硬解 + 激进丢帧 + 画质换流畅）

```swift
opt.setPlayerOptionIntValue(1, forKey: "videotoolbox_hwaccel")
opt.setCodecOptionIntValue(48, forKey: "skip_loop_filter")
opt.setCodecOptionIntValue(8,  forKey: "skip_frame")
opt.setPlayerOptionIntValue(1, forKey: "framedrop")
```

### 7) 起播提速（源可控时用，开放源慎用）

```swift
opt.setPlayerOptionIntValue(1, forKey: "async-init-decoder")
opt.setPlayerOptionIntValue(1, forKey: "skip-calc-frame-rate")
opt.setFormatOptionIntValue(256 * 1024, forKey: "probesize")
opt.setFormatOptionIntValue(2 * 1000000, forKey: "analyzeduration")
// 源是自家规范 MP4 时才考虑：find_stream_info = 0
```

### 8) 需要鉴权的 CDN 源

```swift
opt.setFormatOptionValue("Mozilla/5.0 (iPhone; ...)", forKey: "user_agent")
opt.setFormatOptionValue("Referer: https://example.com\r\nCookie: token=xxx", forKey: "headers")
```
