import os
import pandas as pd
import numpy as np
from collections import Counter  # 统计次数

all_airports = Counter()
for year in range(18, 25):
    for month in range(1, 13):
        y = str(year)
        m = str(month)
        filght_data_file = rf'D:\文档\UW-Madison\STAT628\Module 3\Flight-Data\{y}-{m}.csv'
        if not os.path.exists(filght_data_file):
            print("File not found:", filght_data_file)
            continue
        print(f'{y}-{m}.csv')
        filght_data_df = pd.read_csv(filght_data_file, encoding='ISO-8859-1')
        # except UnicodeDecodeError as e:
        # print(f"无法解码文件中的部分内容。错误位置：{e}")
        origin_airport = Counter(filght_data_df['Origin'])
        dest_airport = Counter(filght_data_df['Dest'])
        all_airports = all_airports + origin_airport + dest_airport

df = pd.DataFrame(list(all_airports.items()), columns=['Airport', 'Count'])
df.to_csv('airports_count.csv', index=False)
