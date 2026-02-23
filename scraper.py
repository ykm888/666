import requests
import re
from datetime import datetime

def solve():
    # 模拟浏览器 Header，防止被拦截
    headers = {
        "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15",
        "Referer": "https://49208.com/"
    }
    
    # 尝试从 API 抓取最新的前三名高手数据
    # 这是该网站的核心数据接口，如果失效，我们会根据日志报错调整
    api_url = "https://49208.com/api/gszj_list" 
    
    try:
        # 这里演示实时逻辑：如果 API 无法直接获取，我们采用精准正则匹配
        # 在实际操作中，如果你能提供该网站 Network 面板里的最新 XHR 链接，我会帮你填入
        
        # 目前先锁定最新一期（54期/55期）你确认的原始号码块
        raw_list = [
            "43-23-15-18-45-37-26-05-49-34-36-22-40-12-33-38-27-47-17-30-42-03-44-07-13-46-16-25-01-11",
            "44-38-45-07-37-11-34-35-31-24-17-49-14-13-18-03-04-30-06-42-16-28-20-47-23-40-19-22-32-01",
            "13-01-11-42-40-19-34-12-15-48-23-20-17-29-14-28-36-31-45-27-25-49-09-46-16-07-39-06-35-08"
        ]
        
        # 核心算法：提取数字 -> 补齐两位 -> 求三方交集
        sets = [set(n.zfill(2) for n in re.findall(r'\d+', raw)) for raw in raw_list]
        common = sorted(list(set.intersection(*sets)))
        
        result_text = " . ".join(common)
        now_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        with open("999.txt", "w", encoding="utf-8") as f:
            f.write(f"三方共同号码 ({len(common)}个):\n{result_text}\n\n更新时间: {now_time}")
            
        print(f"✅ 任务完成！交集号：{result_text}")

    except Exception as e:
        print(f"❌ 抓取失败，错误详情: {e}")

if __name__ == "__main__":
    solve()
