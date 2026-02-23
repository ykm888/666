import requests
import re
import os

def solve():
    # 模拟抓取逻辑 - 这里建议未来替换为真实的 API 请求
    # 根据你提供的截图，这里模拟前三名高手的 30 码方案
    masters_data = [
        {"name": "高手1", "raw": "11.36.26.45.01.02.03.04.05.06.07.08.09.10.12.13.14.15.16.17.18.19.20.21.22.23.24.25.27.28"},
        {"name": "高手2", "raw": "11.26.45.37.01.02.03.04.05.33.34.35.36.38.39.40.41.42.43.44.46.47.48.49.07.08.09.10.12.13"},
        {"name": "高手3", "raw": "11.49.25.45.01.02.03.04.05.11.22.33.44.06.07.08.09.10.12.13.14.15.16.17.18.19.20.21.23.24"}
    ]

    sets = []
    for m in masters_data:
        # 提取数字并补零（如 1 变成 01），确保匹配准确
        nums = set(n.zfill(2) for n in re.findall(r'\d+', m['raw']))
        sets.append(nums)

    # 计算三者的交集（共同重复号码）
    common = sorted(list(set.intersection(*sets)))
    
    # 结果写入 999.txt
    result_text = " . ".join(common) if common else "今日无共有号码"
    
    with open("999.txt", "w", encoding="utf-8") as f:
        f.write(result_text)
    
    print(f"✅ 成功！共有号码已写入 999.txt: {result_text}")

if __name__ == "__main__":
    solve()
