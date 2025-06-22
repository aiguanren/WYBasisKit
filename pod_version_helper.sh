# scripts/pod_version_helper.rb

# 获取当前 Xcode 版本数组(返回值包含：主版本、次版本以及补丁版本)
def xcode_versions
  version_str = `xcodebuild -version 2>&1`.lines.first.to_s
  # 提取版本号并分割为数组
  match = version_str.match(/Xcode (\d+\.\d+\.?\d?)/)
  match ? match[1].split('.').map(&:to_i) : [0, 0, 0]
end

# 比较两个版本数组
def compare_versions(v1, v2)
  # 确保两个数组都有3个元素（不足的补0）
  v1 = (v1 + [0, 0, 0]).first(3)
  v2 = (v2 + [0, 0, 0]).first(3)
  
  # 依次比较主版本、次版本、补丁版本
  v1.each_with_index do |part, i|
    return -1 if part < v2[i]
    return 1 if part > v2[i]
  end
  0
end

# 检查 Xcode 版本是等于指定版本(参数依次为：主版本、次版本以及补丁版本)
def xcode_version_equal_to(major, minor = 0, patch = 0)
  current_version = xcode_versions
  target_version = [major, minor, patch]
  compare_versions(current_version, target_version) == 0
end

# 检查 Xcode 版本是否小于等于指定版本(参数依次为：主版本、次版本以及补丁版本)
def xcode_version_less_than_or_equal_to(major, minor = 0, patch = 0)
  current_version = xcode_versions
  target_version = [major, minor, patch]
  compare_versions(current_version, target_version) <= 0
end

# 检查 Xcode 版本是否大于等于指定版本(参数依次为：主版本、次版本以及补丁版本)
def xcode_version_greater_than_or_equal_to(major, minor = 0, patch = 0)
  current_version = xcode_versions
  target_version = [major, minor, patch]
  compare_versions(current_version, target_version) >= 0
end
