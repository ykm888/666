import requests
import re
import json
from datetime import datetime

def get_numbers_from_api():
    # 核心 API 地址：这是从你提供的详情页推导出的列表接口
    # 它会自动返回最新的预测列表
    api_url = "https://n7bnnz.ksxmy.com/api/forums/prediction/prediction/page?pageNum=1&pageSize=15&predictionTypeId=61&lotteryType=2"
    
    headers = {
        "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15",
        "Referer": "https://n7bnnz.ksxmy.com/"
    }

    try:
        response = requests.get(api_url, headers=headers, timeout=15)
        res_data = response.json()
        
        # 自动获取最新列表
        items = res_data.get('data', {}).get('list', [])
        if not items:
            return None, "未抓取到数据"

        # 获取当前最新的期数（从第一个数据条目获取）
        current_issue = items[0].get('issue', '未知期数')
        
        # 提取前三个高手的号码（自动过滤掉非号码字符）
        num_sets = []
        for i in range(min(3, len(items))):
            content = items[i].get('content', '')
            # 使用正则提取所有数字，并补齐两位（如 1 变成 01）
            nums = set(n.zfill(2) for n in re.findall(r'\d+', content))
            num_sets.append(nums)
            
        if len(num_sets) < 3:
            return None, f"高手人数不足3人(当前{len(num_sets)}人)"

        # 计算三方交集
        common = sorted(list(set.intersection(*num_sets)))
        return (current_issue, common), None

    except Exception as e:
        return None, str(e)

def solve():
    result, error = get_numbers_from_api()
    
    now_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    with open("999.txt", "w", encoding="utf-8") as f:
        if error:
            f.write(f"抓取失败: {error}\n更新时间: {now_time}")
            print(f"❌ 错误: {error}")
        else:
            issue, common_nums = result
            result_text = " . ".join(common_nums)
            f.write(f"最新期数: {issue}\n")
            f.write(f"三方共同号码 ({len(common_nums)}个):\n{result_text}\n")
            f.write(f"\n最后自动抓取时间: {now_time}")
            print(f"✅ 成功抓取第 {issue} 期，共同号码: {result_text}")

if __name__ == "__main__":
    solve()
