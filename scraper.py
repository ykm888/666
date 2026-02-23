import re
import json
from datetime import datetime

def solve():
    now_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    try:
        # 尝试读取你手动存入的 raw_data.json 文件（如果自动抓取失败，你可以手动更新这个文件）
        # 这样可以规避 GitHub 被封 IP 的问题
        with open("raw_data.json", "r", encoding="utf-8") as f:
            raw_content = f.read()
        
        data = json.loads(raw_content)
        items = data.get('data', {}).get('list', [])
        
        if not items:
            raise Exception("数据格式不正确，未找到 list 列表")

        # 提取期数和前三个高手
        issue = items[0].get('issue', '未知期数')
        num_sets = []
        for i in range(min(3, len(items))):
            content = items[i].get('content', '')
            nums = set(n.zfill(2) for n in re.findall(r'\d+', content))
            num_sets.append(nums)

        # 核心对碰
        common = sorted(list(set.intersection(*num_sets)))
        result_text = " . ".join(common)

        # 写入 999.txt
        with open("999.txt", "w", encoding="utf-8") as f:
            f.write(f"最新期数: {issue}\n")
            f.write(f"三方共同号码 ({len(common)}个):\n{result_text}\n")
            f.write(f"\n计算时间: {now_time}")
        
        print(f"✅ 解析成功！期数: {issue}")

    except Exception as e:
        error_msg = f"解析失败: {str(e)}"
        with open("999.txt", "w", encoding="utf-8") as f:
            f.write(f"{error_msg}\n检查时间: {now_time}")
        print(f"❌ {error_msg}")

if __name__ == "__main__":
    solve()
