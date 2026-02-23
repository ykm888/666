import re
import json
import os
from datetime import datetime

def solve():
    now_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    # 定义数据文件和结果文件
    raw_file = "raw_data.json"
    output_file = "999.txt"
    
    try:
        # 1. 检查数据文件是否存在
        if not os.path.exists(raw_file):
            raise Exception(f"找不到 {raw_file}。请先将 Response 内容粘贴到该文件中。")
            
        with open(raw_file, "r", encoding="utf-8") as f:
            raw_content = f.read()
        
        # 2. 解析 JSON 数据
        data = json.loads(raw_content)
        items = data.get('data', {}).get('list', [])
        
        if not items:
            raise Exception("数据格式不正确，未找到有效的专家列表。")

        # 3. 提取期数和前三个高手号码
        issue = items[0].get('issue', '未知期数')
        num_sets = []
        for i in range(min(3, len(items))):
            content = items[i].get('content', '')
            # 提取数字并统一成两位格式（如 1 变 01）
            nums = set(n.zfill(2) for n in re.findall(r'\d+', content))
            num_sets.append(nums)

        # 4. 计算三方共同号码（交集）
        common = sorted(list(set.intersection(*num_sets)))
        result_text = " . ".join(common)

        # 5. 写入 999.txt
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(f"最新期数: {issue}\n")
            f.write(f"三方共同号码 ({len(common)}个):\n{result_text}\n")
            f.write(f"\n最后解析成功时间: {now_time}")
        
        print(f"✅ 处理完成！期数: {issue}，共同号码: {len(common)}个")

    except Exception as e:
        error_msg = f"解析失败原因: {str(e)}"
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(f"{error_msg}\n检查时间: {now_time}")
        print(f"❌ {error_msg}")

if __name__ == "__main__":
    solve()
