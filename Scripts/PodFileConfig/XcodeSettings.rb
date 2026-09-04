# XcodeSettings.rb
# 每次 pod install/update 结束时由 Podfile 的 post_install 钩子调用，负责给 Pods 工程和用户工程统一设置构建参数，目前做四件事：
# ① 设置最低部署版本(Podfile 里 platform :ios 的值)
# ② 自动探测 arm64 模拟器支持：扫描 Pods 里所有二进制库(xcframework/framework/.a，源码库会按架构现编不用查)用 lipo 查模拟器切片，全部支持就移除(或不写)EXCLUDED_ARCHS 排除、M系列芯片模拟器原生跑 arm64；有不支持的库就自动写入排除(模拟器走 x86_64/Rosetta)并在控制台打印是哪些库不支持
# ③ 纯 OC 工程(一个 .swift 源文件都没有)链接 Swift 静态 pod 时自动补 Swift 兼容库链接参数(按SDK分平台：模拟器/真机各自链各自目录的库，互不串台；清单和路径运行时从当前Xcode工具链动态推导，工具链以后增删兼容库、换目录都能自动跟上)，防止链接报 __swift_FORCE_LOAD_$_swiftCompatibility* 未定义
# ④ 顺带把 Pods 生成的 xcconfig 里过时的 DT_TOOLCHAIN_DIR 替换成 TOOLCHAIN_DIR 消警告

require 'pathname'

# 可配置的默认部署目标
$pods_deployment_target = '13.0'

# 设置Pods项目版本(仅限从Podfile解析部署版本失败时有效)
def set_pods_deployment_target(version)
    $pods_deployment_target = version
end

# 设置用户项目和Pods项目(排除一些警告，修复一些编译问题)
def apply_all_project_settings(installer)
    apply_pod_project_settings(installer)
    apply_user_project_settings(installer)
end

# 设置Pods项目
def apply_pod_project_settings(installer)

    # 获取 Podfile 中设置的部署版本
    deployment_target = podfile_deployment_target(installer)

    # 检测所有三方库是否都支持arm64模拟器，决定要不要排除arm64(库不支持时模拟器只能走x86_64/Rosetta)
    exclude_arm64 = should_exclude_arm64_simulator?(installer)

    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            # 设置最低部署版本(Podfile中设置的部署版本)
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = deployment_target

            # 设置或移除排除架构(所有库都支持arm64模拟器时移除排除，让M系列芯片模拟器原生跑arm64；有不支持的库时设置排除，防止链接报错"building for iOS Simulator, but linking in object file built for iOS")
            if exclude_arm64
                config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
            elsif config.build_settings.key?("EXCLUDED_ARCHS[sdk=iphonesimulator*]")
                config.build_settings.delete("EXCLUDED_ARCHS[sdk=iphonesimulator*]")
            end

            # 修复DT_TOOLCHAIN_DIR警告
            fix_dt_toolchain_warning(config)
        end
    end
end

# 设置用户项目
def apply_user_project_settings(installer)

    user_projects = installer.aggregate_targets.map(&:user_project).compact.uniq

    # 备用检测机制：从workspace中查找项目
    if user_projects.empty? && File.exist?(installer.workspace_path.to_s)
        workspace = Xcodeproj::Workspace.new_from_xcworkspace(installer.workspace_path.to_s)
        user_projects = workspace.file_references
        .map { |ref| File.join(File.dirname(installer.workspace_path.to_s), ref.path) }
        .select { |path| path.end_with?('.xcodeproj') }
        .map { |path| Xcodeproj::Project.open(path) rescue nil }
        .compact
    end

    # 检测所有三方库是否都支持arm64模拟器，决定要不要排除arm64(检测结果整个pod命令期间只算一次)
    exclude_arm64 = should_exclude_arm64_simulator?(installer)

    # 应用设置到所有检测到的用户项目
    user_projects.each do |project|
        modified = false

        # 纯OC工程(一个.swift源文件都没有)链接Swift静态pod时，Xcode不会自动带Swift兼容库，链接会报 __swift_FORCE_LOAD_$_swiftCompatibility* 未定义，给这类工程按SDK分平台补上链接参数(清单和路径运行时从工具链动态推导，不写死)
        needs_swift_compat_flags = project.native_targets.all? { |target| target.source_build_phase.files.none? { |build_file| build_file.file_ref.is_a?(Xcodeproj::Project::Object::PBXFileReference) && build_file.file_ref.path.to_s.end_with?(".swift") } }
        if needs_swift_compat_flags
            swift_compat_flags = resolve_swift_compat_flags
            if swift_compat_flags.empty?
                puts "⚠️ 未能从Xcode工具链解析出Swift兼容库清单(#{`xcrun --toolchain default --show-toolchain-path 2>/dev/null`.strip}下没找到libswiftCompatibility*.a)，跳过补链；纯OC工程若链接报 __swift_FORCE_LOAD_$_swiftCompatibility* 未定义，请检查本提示"
            end
        end

        project.build_configurations.each do |config|
            # 所有库都支持arm64模拟器时移除排除(含历史pod install写入或手动设置的)，否则保持/写入排除
            if exclude_arm64
                if config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] != "arm64"
                    config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
                    modified = true
                end
            elsif config.build_settings.key?("EXCLUDED_ARCHS[sdk=iphonesimulator*]")
                config.build_settings.delete("EXCLUDED_ARCHS[sdk=iphonesimulator*]")
                modified = true
            end

            # 纯OC工程按SDK分平台补Swift兼容库链接参数(必须带[sdk=]限定：不带限定的裸OTHER_LDFLAGS在真机构建时也会去模拟器目录找库，把模拟器平台的兼容库链进真机，报"Building for 'iOS', but linking in object file ... built for 'iOS-simulator'")；先清掉本脚本历史写入的旧片段再按当前配置重写，路径或清单变更后能自我修正
            if needs_swift_compat_flags && !swift_compat_flags.empty?
                swift_compat_flags.each do |platform, flags|
                    setting_key = "OTHER_LDFLAGS[sdk=#{platform}*]"
                    cleaned = Array(config.build_settings[setting_key]).flat_map { |v| v.to_s.split(/\s+/) }.reject { |token| token.match?(/\A-l(lib)?swiftCompatibility/) || (token.start_with?("-L") && token.include?("usr/lib/swift/")) }.uniq
                    rebuilt = ((cleaned.include?("$(inherited)") ? cleaned : ["$(inherited)"] + cleaned) + flags.split(/\s+/)).join(" ")
                    if config.build_settings[setting_key] != rebuilt
                        config.build_settings[setting_key] = rebuilt
                        modified = true
                    end
                end
                # 清理历史版本写过的裸OTHER_LDFLAGS(真机构建会误链模拟器库的元凶)：清完只剩$(inherited)就把整项删掉
                if config.build_settings.key?("OTHER_LDFLAGS")
                    plain_cleaned = Array(config.build_settings["OTHER_LDFLAGS"]).flat_map { |v| v.to_s.split(/\s+/) }.reject { |token| token.match?(/\A-l(lib)?swiftCompatibility/) || (token.start_with?("-L") && token.include?("usr/lib/swift/")) }.uniq
                    if plain_cleaned.empty? || plain_cleaned == ["$(inherited)"]
                        config.build_settings.delete("OTHER_LDFLAGS")
                        modified = true
                    elsif config.build_settings["OTHER_LDFLAGS"] != plain_cleaned.join(" ")
                        config.build_settings["OTHER_LDFLAGS"] = plain_cleaned.join(" ")
                        modified = true
                    end
                end
            end
        end

        project.save if modified
    end
end

private

# 检测结果缓存(同一次pod命令里多个入口调用时只扫描一遍Pods目录；扫完把结论和元凶打印出来，让业务知道为什么排除了arm64)
def arm64_simulator_check_result(installer)
    @arm64_check_result ||= begin
        result = scan_pods_for_arm64_simulator_support(installer)
        if result[:offenders].any?
            puts "⚠️ 检测到不支持arm64模拟器的二进制库，已自动给Pods和用户工程设置EXCLUDED_ARCHS排除arm64(模拟器将走x86_64/Rosetta，M系列芯片性能会打折扣)："
            result[:offenders].each { |item| puts "    ❌ #{item}" }
        else
            puts "✅ 所有二进制库都支持arm64模拟器，已移除(或不再写入)EXCLUDED_ARCHS排除设置，M系列芯片模拟器原生跑arm64"
        end
        result[:warnings].each { |item| puts "    ⚠️ #{item}" }
        result
    end
end

# 是否应该排除arm64模拟器架构：有不支持arm64模拟器的二进制库就排除，全部支持就不排除
def should_exclude_arm64_simulator?(installer)
    result = arm64_simulator_check_result(installer)
    result[:offenders].any?
end

# 从当前Xcode工具链动态解析Swift兼容库链接参数，按SDK分平台返回({"iphonesimulator"=>参数串, "iphoneos"=>参数串}，某平台目录缺失或没库就不出现在结果里，全失败返回空Hash由调用方兜底提示)
def resolve_swift_compat_flags
    toolchain_path = `xcrun --toolchain default --show-toolchain-path 2>/dev/null`.strip
    return {} if toolchain_path.empty?

    developer_dir = `xcode-select -p 2>/dev/null`.strip
    flags_by_platform = {}

    ["iphonesimulator", "iphoneos"].each do |platform|
        swift_lib_dir = File.join(toolchain_path, "usr", "lib", "swift", platform)
        next unless File.directory?(swift_lib_dir)

        # basename去掉.a后还带lib前缀(如libswiftCompatibility50.a→libswiftCompatibility50)，链接的-l参数只要后半段，所以再去掉lib前缀
        lib_names = Dir.glob(File.join(swift_lib_dir, "libswiftCompatibility*.a")).map { |path| File.basename(path, ".a").sub(/\Alib/, "") }.sort
        next if lib_names.empty?

        # 工具链绝对路径换算成$(DEVELOPER_DIR)开头(换机器、换Xcode安装位置、升版本都不失效)；工具链不在xcode-select目录下时退回绝对路径
        if !developer_dir.empty? && swift_lib_dir.start_with?(developer_dir + File::SEPARATOR)
            search_path = "$(DEVELOPER_DIR)#{swift_lib_dir[developer_dir.length..]}"
        else
            search_path = swift_lib_dir
        end

        flags_by_platform[platform] = "-L#{search_path} " + lib_names.map { |name| "-l#{name}" }.join(" ")
    end

    flags_by_platform
end

# 扫描Pods目录里所有带二进制产物的库，逐个lipo查模拟器切片里有没有arm64(源码库会按架构现编不用检查；返回offenders=确定不支持的库、warnings=需要人工留意的库)
def scan_pods_for_arm64_simulator_support(installer)
    pods_root = installer.sandbox.root.to_s
    offenders = []
    warnings = []

    # 收集三类二进制产物：xcframework、framework、静态库(.a)，跳过Pods工程自身、xcconfig生成目录和头文件软链目录
    skip_patterns = ["Target Support Files", "Pods.xcodeproj", "/Headers/"]
    xcframeworks = Dir.glob(File.join(pods_root, "**", "*.xcframework")).reject { |p| skip_patterns.any? { |s| p.include?(s) } }
    binaries = (Dir.glob(File.join(pods_root, "**", "*.framework")) + Dir.glob(File.join(pods_root, "**", "*.a")))
    .reject do |p|
        # xcframework内部的framework/.a由xcframework分支统一判定，这里只处理独立的fat二进制
        skip_patterns.any? { |s| p.include?(s) } || p.include?(".xcframework/")
    end

    xcframeworks.each do |xcframework|
        pod_name = pod_name_of(xcframework, pods_root)
        # xcframework的模拟器切片是名为 ios-arm64_x86_64-simulator 这类带simulator字样的子目录
        sim_slices = Dir.entries(xcframework).select { |e| e.include?("simulator") && File.directory?(File.join(xcframework, e)) }
        if sim_slices.empty?
            warnings << "#{pod_name}：#{File.basename(xcframework)} 完全不含模拟器切片(模拟器本来就用不了，与arm64无关)"
            next
        end
        slice_archs = sim_slices.flat_map { |slice| lipo_archs_in_dir(File.join(xcframework, slice)) }.uniq.compact
        if slice_archs.empty?
            warnings << "#{pod_name}：#{File.basename(xcframework)} 模拟器切片里找不到可识别的二进制，请人工确认"
        elsif slice_archs.include?("arm64")
            puts "✅ #{pod_name}：#{File.basename(xcframework)} 模拟器切片含 arm64(#{slice_archs.join('、')})"
        else
            offenders << "#{pod_name}：#{File.basename(xcframework)} 模拟器切片只有 #{slice_archs.join('、')}，不含 arm64"
        end
    end

    binaries.each do |binary_path|
        pod_name = pod_name_of(binary_path, pods_root)
        archs = lipo_archs_of(binary_path.end_with?(".a") ? binary_path : File.join(binary_path, File.basename(binary_path, ".*")))
        next if archs.empty?
        if archs.include?("arm64") && archs.include?("x86_64")
            # Apple不允许同一个fat文件里同时放arm64真机和arm64模拟器(所以才发明了xcframework)，arm64+x86_64的老式fat包里arm64只能是真机切片
            offenders << "#{pod_name}：#{File.basename(binary_path)} 是arm64+x86_64的老式fat包(arm64只服务真机)，不支持arm64模拟器"
        elsif archs == ["arm64"]
            warnings << "#{pod_name}：#{File.basename(binary_path)} 只含arm64，分不清是真机还是模拟器切片，请人工确认"
        else
            offenders << "#{pod_name}：#{File.basename(binary_path)} 只含 #{archs.join('、')}，不含arm64模拟器"
        end
    end

    { offenders: offenders, warnings: warnings }
end

# 从产物路径反查所属的pod名(Pods目录下第一层目录名就是pod名)
def pod_name_of(artifact_path, pods_root)
    Pathname.new(artifact_path).relative_path_from(Pathname.new(pods_root)).to_s.split(File::SEPARATOR).first
end

# 用lipo查询一个二进制文件包含的架构列表(识别不了Mach-O就返回空数组)
def lipo_archs_of(binary_path)
    return [] unless File.exist?(binary_path)
    info = `lipo -info "#{binary_path}" 2>/dev/null`.strip
    if match = info.match(/are:\s*(.+)$/)
        match[1].split(/\s+/)
    elsif match = info.match(/is architecture:\s*(\S+)/)
        [match[1]]
    else
        []
    end
end

# 扫描一个目录(如xcframework的某个切片)里所有可lipo的二进制，汇总架构列表
def lipo_archs_in_dir(dir_path)
    candidates = Dir.glob(File.join(dir_path, "**", "*.framework")).map { |f| File.join(f, File.basename(f, ".*")) }
    candidates += Dir.glob(File.join(dir_path, "**", "*.a"))
    candidates += Dir.glob(File.join(dir_path, "**", "*.dylib"))
    candidates.flat_map { |c| lipo_archs_of(c) }
end

# 修复DT_TOOLCHAIN_DIR相关警告
def fix_dt_toolchain_warning(config)
    return unless config.base_configuration_reference &&
    config.base_configuration_reference.real_path &&
    File.exist?(config.base_configuration_reference.real_path)

    xcconfig_path = config.base_configuration_reference.real_path
    xcconfig = File.read(xcconfig_path)
    xcconfig_mod = xcconfig.gsub(/DT_TOOLCHAIN_DIR/, "TOOLCHAIN_DIR")

    if xcconfig_mod != xcconfig
        File.write(xcconfig_path, xcconfig_mod)
    end
end

# 从 Podfile 中解析部署版本
def podfile_deployment_target(installer)
    version = nil
    
    # 1. 首先尝试从Podfile platform :ios这里直接获取
    if installer.podfile.target_definition_list.any?
        platform = installer.podfile.target_definition_list.first.platform
        version = platform.to_s if platform
    end
    
    # 2. 如果直接获取失败，尝试解析 Podfile 文件内容
    unless version
        podfile_path = installer.podfile.defined_in_file
        if podfile_path && File.exist?(podfile_path)
            podfile_content = File.read(podfile_path)
            if match = podfile_content.match(/platform\s*:ios\s*,\s*['"]([\d.]+)['"]/)
                version = match[1]
            end
        end
    end
    
    # 3. 如果所有方法都失败，使用配置的默认值
    version ||= $pods_deployment_target
    
    # 移除非数字和点号以外的字符
    cleaned = version.to_s.gsub(/[^\d.]/, '')
    
    # 确保版本号至少有一个点号分隔符
    unless cleaned.include?('.')
        cleaned += '.0'
    end
    
    # 确保版本号格式为 X.X 或 X.X.X
    parts = cleaned.split('.')
    if parts.size < 2
        cleaned = "#{parts[0]}.0"
    end
    
    # 返回处理后的版本
    cleaned
end
