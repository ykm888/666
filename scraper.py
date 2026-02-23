import re

def solve():
    # 填入你提供的最新三组号码
    data1 = "43-23-15-18-45-37-26-05-49-34-36-22-40-12-33-38-27-47-17-30-42-03-44-07-13-46-16-25-01-11"
    data2 = "44-38-45-07-37-11-34-35-31-24-17-49-14-13-18-03-04-30-06-42-16-28-20-47-23-40-19-22-32-01"
    data3 = "13-01-11-42-40-19-34-12-15-48-23-20-17-29-14-28-36-31-45-27-25-49-09-46-16-07-39-06-35-08"

    def get_set(raw):
        # 提取所有数字并统一补零
        return set(n.zfill(2) for n in re.findall(r'\d+', raw))

    s1, s2, s3 = get_set(data1), get_set(data2), get_set(data3)

    # 严格交集：只有三个集合都存在的号码
    common = sorted(list(s1 & s2 & s3))

    # 格式化输出
    result = " . ".join(common)
    
    with open("999.txt", "w", encoding="utf-8") as f:
        f.write(result)
    
    print(f"精准计算完成！共有号码: {result}")

if __name__ == "__main__":
    solve()
