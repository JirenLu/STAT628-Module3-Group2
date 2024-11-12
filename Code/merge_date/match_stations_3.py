import pandas as pd
import numpy as np
from geopy.distance import geodesic
from scipy.spatial import KDTree

# 第三轮匹配，要求25km内，总文件大小>=30MB的数据量最大的站点
# 匹配379个（新增23个，还剩10个）

# 读取上次生成的匹配文件
airports_df = pd.read_csv('match_stations_2.csv')
station_df = pd.read_csv('weather_stations_final.csv')

# 将气象站的经纬度转换为数组并建立 KDTree
station_locations = np.array(list(zip(station_df['LATITUDE'], station_df['LONGITUDE'])))
station_tree = KDTree(station_locations)

# 设定第三次匹配的最大距离为 25 公里
max_distance = 25

# 更新未匹配的机场
for idx, airport_row in airports_df[airports_df['Station_ID'].isna()].iterrows():
    airport_location = (airport_row['Latitude'], airport_row['Longitude'])

    # 使用 KDTree 查找距离机场 25 公里以内的所有站点索引
    nearby_indices = station_tree.query_ball_point(airport_location, max_distance / 111)  # 111 approx km per degree

    # 筛选出距离在 25 公里以内且 Total_Size_MB 大于 30 的站点，并找到数据量最大的站点
    max_total_size = 30  # 设置最小 Total_Size_MB 值为 30
    selected_station_id = None
    selected_distance = None
    selected_yearly_data = {year: None for year in
                            ['2018_MB', '2019_MB', '2020_MB', '2021_MB', '2022_MB', '2023_MB', '2024_MB']}

    for idx2 in nearby_indices:
        station_row = station_df.iloc[idx2]
        station_location = (station_row['LATITUDE'], station_row['LONGITUDE'])
        distance = geodesic(airport_location, station_location).kilometers

        # 判断是否符合距离和 Total_Size_MB 条件
        if distance <= max_distance and station_row['Total_Size_MB'] > max_total_size:
            max_total_size = station_row['Total_Size_MB']
            selected_station_id = station_row['ID']
            selected_distance = distance
            selected_yearly_data = {year: station_row[year] for year in selected_yearly_data.keys()}

    # 如果找到符合条件的监测站，更新 DataFrame 中的值
    airports_df.at[idx, 'Station_ID'] = selected_station_id
    airports_df.at[idx, 'Distance_km'] = selected_distance
    for year, value in selected_yearly_data.items():
        airports_df.at[idx, year] = value

# 保存更新后的结果
airports_df.to_csv('match_stations_3.csv', index=False)
