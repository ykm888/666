import re
from datetime import datetime

def solve():
    # 数据源完全基于你提供的文本
    m1 = "43-23-15-18-45-37-26-05-49-34-36-22-40-12-33-38-27-47-17-30-42-03-44-07-13-46-16-25-01-11"
    m2 = "44-38-45-07-37-11-34-35-31-24-17-49-14-13-18-03-04-30-06-42-16-28-20-47-23-40-19-22-32-01"
    m3 = "13-01-11-42-40-19-34-12-15-48-23-20-17-29-14-28-36-31-45-27-25-49-09-46-16-07-39-06-35-08"

    def parse(raw):
        return set(n.zfill(2) for n in re.findall(r'\d+', raw))

    s1, s2, s3 = parse(m1), parse(m2), parse(m3)

    # 计算共同拥有的号码（交集）
    common = sorted(list(s1 & s2 & s3))
    
    # 结果字符串
    result_nums = " . ".join(common)
    count = len(common)
    now_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    # 写入文件：增加总数统计，方便你核对
    with open("999.txt", "w", encoding="utf-8") as f:
        f.write(f"三方共同号码 ({count}个):\n")
        f.write(f"{result_nums}\n")
        f.write(f"\n最后更新时间: {now_time}")

    print(f"成功！共有 {count} 个号码入选。")

if __name__ == "__main__":
    solve()
