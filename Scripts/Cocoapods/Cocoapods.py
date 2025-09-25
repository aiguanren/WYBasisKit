import re
import subprocess
import sys
import os
import glob

CONFIG = {
    'kit_path_local': '',  # 本地验证时要把 kit_path 设置为空字符串 ""，验证完毕后再还原成原本的值
    'podspec_relative_path': '../../WYBasisKit/WYBasisKit/WYBasisKit',  # podspec 文件所在目录
    'local_validation_params': ['--verbose', '--allow-warnings', '--skip-import-validation', '--no-clean'],  # 本地验证额外参数
    'remote_validation_params': ['--verbose', '--allow-warnings', '--skip-import-validation', '--no-clean'],  # 远程验证额外参数
    'publish_validation_params': ['--allow-warnings', '--skip-import-validation'],  # 发布时的参数
}

def find_podspec_files(directory_path):
    """
    在指定目录下查找所有的 .podspec 文件
    返回 podspec 文件的绝对路径列表
    """
    if not os.path.exists(directory_path):
        return []
    
    # 使用 glob 查找所有 .podspec 文件
    pattern = os.path.join(directory_path, "*.podspec")
    podspec_files = glob.glob(pattern)
    
    return podspec_files

def select_podspec_file(podspec_files):
    """
    让用户从找到的 podspec 文件列表中选择一个
    返回选择的 podspec 文件路径
    """
    if not podspec_files:
        print_red("未找到任何 .podspec 文件")
        sys.exit(1)
    
    print_green(f"\n找到 {len(podspec_files)} 个 .podspec 文件：")
    
    # 显示文件列表供用户选择
    options = []
    for idx, file_path in enumerate(podspec_files, 1):
        file_name = os.path.basename(file_path)
        options.append(file_name)
        print_orange(f"{idx}: {file_name}")
    
    while True:
        try:
            choice = int(input("\n请选择要操作的 podspec 文件（输入数字）："))
            if 1 <= choice <= len(podspec_files):
                selected_file = podspec_files[choice - 1]
                print_green(f"已选择：{os.path.basename(selected_file)}")
                return selected_file
            else:
                print_red(f"请输入 1 到 {len(podspec_files)} 之间的数字")
        except ValueError:
            print_red("输入无效，请输入数字")

def replace_kit_path(podspec_path, new_value):
    """
    替换 podspec 文件中 kit_path 这一行的值为 new_value
    例如，kit_path = "旧值" 替换为 kit_path = new_value
    保留原行缩进格式。
    """
    with open(podspec_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    with open(podspec_path, 'w', encoding='utf-8') as f:
        for line in lines:
            if line.strip().startswith("kit_path"):
                # 获取当前行缩进
                indent = line[:line.find("kit_path")]
                f.write(f'{indent}kit_path = "{new_value}"\n')  # 注意写入时加上引号
            else:
                f.write(line)

def parse_subspecs(podspec_path):
    """
    解析 podspec 文件中的 subspec 名称，支持多层嵌套，并忽略注释掉的 subspec。
    返回 subspec 名称列表，格式类似 ["Config", "Config/Sub1", ...]
    """
    subspecs = []
    stack = []
    pattern = re.compile(r'\.subspec\s+"([^"]+)"')

    with open(podspec_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    for raw_line in lines:
        line = raw_line.strip()

        # 忽略整行注释或.subspec前有#的情况
        if line.startswith("#") or re.match(r'.*#.*\.subspec', line):
            continue

        m = pattern.search(line)
        if m:
            name = m.group(1)
            stack.append(name)
            subspecs.append("/".join(stack))
            continue

        if line == "end" and stack:
            stack.pop()

    return subspecs

def choose_option(title, options):
    """
    打印选项列表，让用户输入数字选择。
    返回选择的索引 (从1开始)
    """
    print_green(f"\n{title}")
    for idx, opt in enumerate(options, 1):
        print_orange(f"{idx}: {opt}")
    while True:
        try:
            choice = int(input("请输入数字选择："))
            if 1 <= choice <= len(options):
                return choice
            print_green(f"请输入1到{len(options)}之间的数字")
        except ValueError:
            print_red("输入无效，请输入数字")

def ask_yes_no(question, default="n"):
    """
    让用户输入 y/n 回答，默认值为 default。
    返回 True 或 False
    """
    yn = input(f"{question} (y/n): ").strip().lower()
    if not yn:
        yn = default
    return yn == "y"

def print_green(text):
    """绿色字体输出"""
    print(f"\033[32m{text}\033[0m")

def print_red(text):
    """红色字体输出"""
    print(f"\033[31m{text}\033[0m")

def print_orange(text):
    """橙色字体输出"""
    print(f"\033[38;5;208m{text}\033[0m")

def main():
    # 计算 podspec 目录绝对路径
    script_dir = os.path.dirname(os.path.abspath(__file__))
    podspec_dir = os.path.normpath(os.path.join(script_dir, CONFIG['podspec_relative_path']))

    if not os.path.exists(podspec_dir):
        print_red(f"指定的 podspec 目录不存在: {podspec_dir}")
        sys.exit(1)

    print_green(f"搜索 podspec 文件的目录：{podspec_dir}")

    # 查找所有 podspec 文件
    podspec_files = find_podspec_files(podspec_dir)
    
    # 让用户选择要操作的 podspec 文件
    podspec_path = select_podspec_file(podspec_files)
    
    print_green(f"选择的 podspec 文件：{podspec_path}")

    # 选择操作模式
    modes = ["本地验证 (pod lib lint)", "远程验证 (pod spec lint)", "发布到 CocoaPods (pod trunk push)"]
    mode_choice = choose_option("请选择要执行的操作：", modes)
    mode_map = {1: "local", 2: "remote", 3: "publish"}
    mode = mode_map[mode_choice]

    print_green(f"选择的操作模式：{modes[mode_choice - 1]}")

    subspec_arg = ""
    selected_subspec = "全部 subspec (不指定)"

    # 本地和远程需要选择 subspec
    if mode in ("local", "remote"):
        subspecs = parse_subspecs(podspec_path)
        if subspecs:
            options = ["全部 subspec (不指定)"] + subspecs
            subspec_choice = choose_option("请选择验证的 subspec：", options)
            selected_subspec = options[subspec_choice - 1]
            print_green(f"选择的 subspec：{selected_subspec}")
            if subspec_choice != 1:
                podspec_basename = os.path.basename(podspec_path)
                podspec_name_without_ext = os.path.splitext(podspec_basename)[0]  # 如 WYBasisKit
                subspec_arg = f"--subspec={podspec_name_without_ext}/{subspecs[subspec_choice - 2]}"
        else:
            print_red("未检测到任何 subspec，默认验证全部")

    if mode == "local":
        # 备份 podspec 原始内容，防止修改失败
        with open(podspec_path, 'r', encoding='utf-8') as f:
            original_content = f.read()
        try:
            # 本地验证时修改 kit_path
            replace_kit_path(podspec_path, CONFIG['kit_path_local'])

            cmd = ["pod", "lib", "lint", podspec_path] + CONFIG['local_validation_params']
            if subspec_arg:
                cmd.append(subspec_arg)

            print_green("\n即将执行命令：\n" + " ".join(cmd) + "\n")

            result = subprocess.run(cmd)
        finally:
            # 恢复 podspec 文件内容
            with open(podspec_path, 'w', encoding='utf-8') as f:
                f.write(original_content)

    elif mode == "remote":
        cmd = ["pod", "spec", "lint", podspec_path] + CONFIG['remote_validation_params']
        if subspec_arg:
            cmd.append(subspec_arg)

        print_green("\n即将执行命令：\n" + " ".join(cmd) + "\n")

        result = subprocess.run(cmd)

    else:  # publish
        params = CONFIG['publish_validation_params'][:]
        verbose = ask_yes_no("发布模式，是否开启详细日志 (--verbose)?")
        if verbose:
            params.append('--verbose')

        cmd = ["pod", "trunk", "push", podspec_path] + params

        print_green("\n即将执行命令：\n" + " ".join(cmd) + "\n")

        result = subprocess.run(cmd)

    if result.returncode == 0:
        print_green("\n脚本执行完毕\n")
    else:
        print_red(f"\n操作失败，退出码：{result.returncode}")

if __name__ == "__main__":
    main()