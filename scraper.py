import requests
import re

def fetch_real_data():
    # 目标：抓取 49208.com 页面前三个高手的号码
    # 注意：该网站通常有防爬，这里使用真实的 Header 模拟
    url = "https://49208.com/api/gszj_list" # 这是一个预测的API路径，实际可能需根据Network调整
    headers = {
        "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15",
        "Referer": "https://49208.com/"
    }

    try:
        # 如果 API 无法直接访问，我们先用你提供的这三组真实号码作为逻辑基准进行修复
        # 在实际部署中，我会引导你如何获取动态生成的 Token
        raw_list = [
            "43-23-15-18-45-37-26-05-49-34-36-22-40-12-33-38-27-47-17-30-42-03-44-07-13-46-16-25-01-11",
            "44-38-45-07-37-11-34-35-31-24-17-49-14-13-18-03-04-30-06-42-16-28-20-47-23-40-19-22-32-01",
            "13-01-11-42-40-19-34-12-15-48-23-20-17-29-14-28-36-31-45-27-25-49-09-46-16-07-39-06-35-08"
        ]
        
        sets = []
        for raw in raw_list:
            # 统一提取数字，处理 '-' 或 '.' 等分隔符
            nums = set(re.findall(r'\d+', raw))
            sets.append(nums)
            
        # 求三个集合的交集
        common = sorted(list(set.intersection(*sets)), key=int)
        return common
    except Exception as e:
        print(f"抓取失败: {e}")
        return []

def save_to_999(common_nums):
    # 格式化输出为 01 . 07 ...
    result_text = " . ".join(common_nums) if common_nums else "未发现三方重复号码"
    with open("999.txt", "w", encoding="utf-8") as f:
        f.write(result_text)
    print(f"写入成功: {result_text}")

if __name__ == "__main__":
    result = fetch_real_data()
    save_to_999(result)
