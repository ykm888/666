import re
from datetime import datetime

def solve():
    # 锁定你提供的最新三组 54 期数据
    m1 = "43-23-15-18-45-37-26-05-49-34-36-22-40-12-33-38-27-47-17-30-42-03-44-07-13-46-16-25-01-11"
    m2 = "44-38-45-07-37-11-34-35-31-24-17-49-14-13-18-03-04-30-06-42-16-28-20-47-23-40-19-22-32-01"
    m3 = "13-01-11-42-40-19-34-12-15-48-23-20-17-29-14-28-36-31-45-27-25-49-09-46-16-07-39-06-35-08"

    def parse(raw):
        return set(n.zfill(2) for n in re.findall(r'\d+', raw))

    s1, s2, s3 = parse(m1), parse(m2), parse(m3)

    # 计算交集
    common = sorted(list(s1 & s2 & s3))
    result = " . ".join(common)

    # --- 关键：日志打印 ---
    # 运行后请去 GitHub Actions 日志里看这里输出的是什么
    print(f"--- 核心计算结果输出: {result} ---")

    # 获取当前时间（确保文件内容每次都不一样）
    now_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    # 写入 999.txt
    with open("999.txt", "w", encoding="utf-8") as f:
        f.write(result)
        # 在文件末尾加一行时间，强迫 Git 认为文件已更改
        f.write(f"\nLast Update: {now_time}")

if __name__ == "__main__":
    solve()
