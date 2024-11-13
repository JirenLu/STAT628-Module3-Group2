import pandas as pd
import glob
from collections import Counter

# 使用 Counter 统计每种云层类型的出现次数
weather_type_counter = Counter()

for year in range(2018, 2019):
    folder_path =rf'D:\文档\UW-Madison\STAT628\Module 3\WebScraper\climatological_data_{str(year)}'
    for file_path in glob.glob(f"{folder_path}/*.csv"):
        df = pd.read_csv(file_path)
        if 'HourlySkyConditions' in df.columns:
            # 遍历 'HourlySkyConditions' 列
            for index, entry in df['HourlyPresentWeatherType'].dropna().items():
                try:
                    # 如果是数值类型，跳过
                    if isinstance(entry, (int, float)):
                        weather_type_counter.update(["NumericOnly"])  # 单独计入数值类型类别
                        continue

                    # 按 '|' 分隔多个天气现象
                    weather_conditions = entry.split('|')

                    # 遍历分隔后的天气现象
                    for condition in weather_conditions:
                        condition = condition.strip()  # 去除首尾空格
                        # 更新计数器（每个天气现象作为独立特征）
                        weather_type_counter.update([condition])

                except AttributeError:
                    print(f"文件 '{file_path}' 的第 {index + 1} 行出现异常值：{entry}")

weather_type_df = pd.DataFrame(weather_type_counter.items(), columns=['WeatherCondition', 'Count'])
weather_type_df.to_csv('weather_type_counts.csv', index=False)
