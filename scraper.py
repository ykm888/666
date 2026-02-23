import re

def solve():
    # 严格锁定截图中的前三名数据
    m1_raw = "43-23-15-18-45-37-26-05-49-34-36-22-40-12-33-38-27-47-17-30-42-03-44-07-13-46-16-25-01-11"
    m2_raw = "44-38-45-07-37-11-34-35-31-24-17-49-14-13-18-03-04-30-06-42-16-28-20-47-23-40-19-22-32-01"
    m3_raw = "13-01-11-42-40-19-34-12-15-48-23-20-17-29-14-28-36-31-45-27-25-49-09-46-16-07-39-06-35-08"

    def get_clean_set(raw):
        # 提取数字并确保是两位字符串格式
        return set(n.zfill(2) for n in re.findall(r'\d+', raw))

    s1 = get_clean_set(m1_raw)
    s2 = get_clean_set(m2_raw)
    s3 = get_clean_set(m3_raw)

    # 逻辑检查打印（会在 GitHub Actions 日志中显示）
    print(f"检查号码 40: 专家1:{'40' in s1}, 专家2:{'40' in s2}, 专家3:{'40' in s3}")
    print(f"检查号码 49: 专家1:{'49' in s1}, 专家2:{'49' in s2}, 专家3:{'49' in s3}")

    # 严格求交集：必须三个集合都有
    common = sorted(list(s1 & s2 & s3))

    # 最终输出结果
    result = " . ".join(common)
    
    with open("999.txt", "w", encoding="utf-8") as f:
        f.write(result)
    
    print(f"--- 最终三方共有号码 ({len(common)}个) ---")
    print(result)

if __name__ == "__main__":
    solve()
