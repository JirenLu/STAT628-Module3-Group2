import pandas as pd
import pytz
from datetime import datetime

# 读取CSV文件
df = pd.read_csv('airports_info.csv')

# 创建空列用于存储夏令时和冬令时偏移
df['daylight_saving_offset'] = None
df['standard_offset'] = None

# 当前年份
current_year = datetime.now().year

# 计算夏令时和冬令时偏移
for index, row in df.iterrows():
    timezone_str = row['Tz database timezone']
    try:
        timezone = pytz.timezone(timezone_str)

        # 获取夏令时和冬令时的时间偏移
        dst_time = timezone.localize(datetime(current_year, 7, 1))  # 7月通常在夏令时
        std_time = timezone.localize(datetime(current_year, 1, 1))  # 1月通常在冬令时

        # 将偏移转换为小时
        dst_offset = int(dst_time.utcoffset().total_seconds() / 3600)
        std_offset = int(std_time.utcoffset().total_seconds() / 3600)

        # 存储到DataFrame中
        df.at[index, 'daylight_saving_offset'] = dst_offset
        df.at[index, 'standard_offset'] = std_offset

    except Exception as e:
        print(f"Error processing timezone {timezone_str}: {e}")

# 保存到新的CSV文件
df.to_csv('airports_info_.csv', index=False)
