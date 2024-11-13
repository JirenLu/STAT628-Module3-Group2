import pandas as pd
import glob
from collections import Counter

# 使用 Counter 统计每种云层类型的出现次数
condition_counter = Counter()

for year in range(2018, 2019):
    folder_path =rf'D:\文档\UW-Madison\STAT628\Module 3\WebScraper\climatological_data_{str(year)}'
    for file_path in glob.glob(f"{folder_path}/*.csv"):
        df = pd.read_csv(file_path)
        if 'HourlySkyConditions' in df.columns:
            # 遍历 'HourlySkyConditions' 列
            for index, entry in df['HourlySkyConditions'].dropna().items():
                try:
                    if isinstance(entry, (int, float)):
                        condition_counter.update(["NumericOnly"])  # 计入单独类别
                        continue
                    # 按空格分隔不同的云量类型
                    conditions = entry.split()
                    # 按每两项或一项一组解析出云量类型和高度
                    i = 0
                    while i < len(conditions):
                        # 获取云量类型和高度
                        cloud_type = conditions[i]  # 例如 'SCT:04'
                        # 更新计数器（将云量类型+高度视为单一特征）
                        condition_counter.update([cloud_type])
                        # 判断下一个元素是否为能见度数值
                        i += 2 if i + 1 < len(conditions) and conditions[i + 1].replace('.', '', 1).isdigit() else 1
                except AttributeError:
                    print(f"文件 '{file_path}' 的第 {index + 1} 行出现异常值：{entry}")

with open("cloud_conditions_counts.txt", "w") as file:
    for condition, count in condition_counter.items():
        file.write(f"{condition}: {count}\n")
