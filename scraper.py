import requests
import re
import json
from datetime import datetime

def solve():
    # 目标 API 地址
    url = "https://n7bnnz.ksxmy.com/api/forums/prediction/prediction/page?pageNum=1&pageSize=15&predictionTypeId=61&lotteryType=2"
    
    # 模拟真实手机浏览器的请求头
    headers = {
        "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1",
        "Referer": "https://n7bnnz.ksxmy.com/",
        "Accept": "application/json, text/plain, */*"
    }

    now_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    try:
        # 发送网络请求
        response = requests.get(url, headers=headers, timeout=15)
        
        # 验证是否返回了有效内容
        if response.status_code != 200:
            raise Exception(f"服务器返回状态码 {response.status_code}")
        
        data = response.json()
        items = data.get('data', {}).get('list', [])
        
        if not items:
            raise Exception("API 未返回有效列表数据")

        # 1. 自动提取最新期数
        issue = items[0].get('issue', '未知期数')
        
        # 2. 提取前三个高手的 30 个号码
        num_sets = []
        for i in range(min(3, len(items))):
            content = items[i].get('content', '')
            # 使用正则抓取所有数字并统一补齐两位（如 1 变 01）
            nums = set(n.zfill(2) for n in re.findall(r'\d+', content))
            num_sets.append(nums)
            
        if len(num_sets) < 3:
            raise Exception(f"高手人数不足3人（当前只有 {len(num_sets)} 人）")

        # 3. 三方对碰（计算交集）
        common_nums = sorted(list(set.intersection(*num_sets)))
        result_text = " . ".join(common_nums)

        # 4. 写入结果文件
        with open("999.txt", "w", encoding="utf-8") as f:
            f.write(f"最新期数: {issue}\n")
            f.write(f"三方共同号码 ({len(common_nums)}个):\n{result_text}\n")
            f.write(f"\n最后自动更新: {now_time}")
            
        print(f"✅ 成功！抓取第 {issue} 期，找到 {len(common_nums)} 个重复号。")

    except Exception as e:
        # 如果报错，记录错误信息到文件，方便排查
        error_info = f"抓取失败: {str(e)}"
        with open("999.txt", "w", encoding="utf-8") as f:
            f.write(f"{error_info}\n更新时间: {now_time}")
        print(f"❌ {error_info}")

if __name__ == "__main__":
    solve()
