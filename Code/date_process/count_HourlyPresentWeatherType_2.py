import pandas as pd
from collections import Counter

# 读取包含所有天气现象的文件
file_path = 'weather_type_counts_3.csv'
weather_counts_df = pd.read_csv(file_path)

# 初始化一个计数器
weather_counter = Counter()

# 遍历原始数据，将有空格的天气现象分开，并重新统计
for _, row in weather_counts_df.iterrows():
    try:
        # 确保 WeatherCondition 是字符串类型，然后分割天气现象（按空格）
        conditions = row['WeatherCondition'].split()
        count = row['Count']
        for condition in conditions:
            weather_counter[condition] += count  # 将计数加到每个独立的天气现象
    except AttributeError:
        # 如果 WeatherCondition 是 float（可能是 NaN），跳过此行
        continue

# 将计数结果转换为 DataFrame
expanded_weather_counts_df = pd.DataFrame(weather_counter.items(), columns=['WeatherCondition', 'Count'])

# 保存结果到新的 CSV 文件
output_file = 'weather_type_counts_4.csv'
expanded_weather_counts_df.to_csv(output_file, index=False)
