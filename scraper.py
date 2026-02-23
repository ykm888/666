import re
from datetime import datetime

def solve():
    # 严格锁定截图中的 54 期数据
    # 第1名：岳帅
    m1_raw = "43-23-15-18-45-37-26-05-49-34-36-22-40-12-33-38-27-47-17-30-42-03-44-07-13-46-16-25-01-11"
    # 第2名：外向 (注意：这里真的没有 40 和 49)
    m2_raw = "44-38-45-07-37-11-34-35-31-24-17-49-14-13-18-03-04-30-06-42-16-28-20-47-23-40-19-22-32-01"
    # 第3名：东门
    m3_raw = "13-01-11-42-40-19-34-12-15-48-23-20-17-29-14-28-36-31-45-27-25-49-09-46-16-07-39-06-35-08"

    def parse(raw):
        # 只提取数字，补齐两位，排除掉可能干扰的“54期”等字样
        all_nums = re.findall(r'\d+', raw)
        return set(n.zfill(2) for n in all_nums if len(n) <= 2)

    s1, s2, s3 = parse(m1_raw), parse(m2_raw), parse(m3_raw)

    # 重点：严格交集 (Intersection) - 必须 3 个集合里都有
    common = sorted(list(s1 & s2 & s3))
    
    # 打印调试信息到 GitHub Actions 日志
    print(f"专家1包含40吗: {'40' in s1}")
    print(f"专家2包含40吗: {'40' in s2}")
    print(f"专家3包含40吗: {'40' in s3}")
    print(f"最终交集结果: {common}")

    result = " . ".join(common)
    now_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    with open("999.txt", "w", encoding="utf-8") as f:
        f.write(result)
        f.write(f"\nLast Update: {now_time}")

if __name__ == "__main__":
    solve()
