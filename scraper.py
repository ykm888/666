import requests
import re
from datetime import datetime

def solve():
    # 1. 你抓到的那个 API 地址
    api_url = "https://n7bnnz.ksxmy.com/api/forums/prediction/prediction/page?pageNum=1&pageSize=15&predictionTypeId=61&lotteryType=2"
    
    # 2. 增强型伪装头（让服务器觉得你是在用手机浏览器访问）
    headers = {
        "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1",
        "Accept": "application/json, text/plain, */*",
        "Accept-Language": "zh-CN,zh;q=0.9",
        "Origin": "https://n7bnnz.ksxmy.com",
        "Referer": "https://n7bnnz.ksxmy.com/",
        "Sec-Fetch-Dest": "empty",
        "Sec-Fetch-Mode": "cors",
        "Sec-Fetch-Site": "same-origin"
    }

    now_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    try:
        # 发送请求
        response = requests.get(api_url, headers=headers, timeout=20)
        
        # 检查状态码
        if response.status_code != 200:
            raise Exception(f"服务器返回错误状态码: {response.status_code}")

        # 打印部分返回内容用于调试（在 GitHub Actions 日志里看）
        print(f"返回内容片段: {response.text[:100]}")
        
        data = response.json()
        items = data.get('data', {}).get('list', [])
        
        if not items:
            raise Exception("API 返回成功但没有数据内容")

        # 自动提取期数和前三个高手号码
        issue = items[0].get('issue', '未知期数')
        num_sets = []
        for i in range(min(3, len(items))):
            content = items[i].get('content', '')
            nums = set(n.zfill(2) for n in re.findall(r'\d+', content))
            num_sets.append(nums)

        # 对碰逻辑
        common = sorted(list(set.intersection(*num_sets)))
        result_text = " . ".join(common)

        # 写入文件
        with open("999.txt", "w", encoding="utf-8") as f:
            f.write(f"最新期数: {issue}\n")
            f.write(f"三方共同号码 ({len(common)}个):\n{result_text}\n")
            f.write(f"\n最后自动抓取时间: {now_time}")
            
        print(f"✅ 抓取成功！期数: {issue}")

    except Exception as e:
        # 如果报错，把具体的错误原因写入 999.txt 方便我们排查
        error_msg = f"抓取失败详情: {str(e)}"
        with open("999.txt", "w", encoding="utf-8") as f:
            f.write(f"{error_msg}\n更新时间: {now_time}")
        print(f"❌ {error_msg}")

if __name__ == "__main__":
    solve()
