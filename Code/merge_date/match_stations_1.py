import pandas as pd
import numpy as np
from geopy.distance import geodesic
from scipy.spatial import KDTree

# 第一轮匹配，要求5km内，总文件大小>=50MB的数据量最大的站点
# 匹配224个

airports_df = pd.read_csv('airports_info_.csv')
station_df = pd.read_csv('weather_stations_final_.csv')

# 将气象站的经纬度转换为数组并建立 KDTree
station_locations = np.array(list(zip(station_df['LATITUDE'], station_df['LONGITUDE'])))
station_tree = KDTree(station_locations)

# 设定最大距离
max_distance = 5

# 创建空列表用于存储匹配结果
station_ids = []
distances = []

# 遍历每个机场，找到距离最近且数据量最大的站点
for _, airport_row in airports_df.iterrows():
    airport_location = (airport_row['Latitude'], airport_row['Longitude'])

    # 使用 KDTree 查找距离机场 30 公里以内的所有站点索引
    nearby_indices = station_tree.query_ball_point(airport_location, max_distance / 111)  # 111 approx km per degree

    max_total_size = 50
    selected_station_id = None
    selected_distance = None

    for idx in nearby_indices:
        station_row = station_df.iloc[idx]
        station_location = (station_row['LATITUDE'], station_row['LONGITUDE'])
        distance = geodesic(airport_location, station_location).kilometers
        # 判断是否为当前最大数据量的站点
        if distance <= max_distance and station_row['Total_Size_MB'] > max_total_size:
            max_total_size = station_row['Total_Size_MB']
            selected_station_id = station_row['ID']
            selected_distance = distance

    # 保存结果
    station_ids.append(selected_station_id)
    distances.append(selected_distance)


# 将结果写入 airports_df
airports_df['Station_ID'] = station_ids
airports_df['Distance_km'] = distances

# 从 station_df 中提取需要的列：ID 和各年度数据
station_data = station_df[['ID', '2018_MB', '2019_MB', '2020_MB', '2021_MB', '2022_MB', '2023_MB', '2024_MB']]
# 合并数据，根据 airports_df 的 'Station_ID' 和 station_data 的 'ID' 进行合并
airports_with_station_data = airports_df.merge(
    station_data,
    left_on='Station_ID',
    right_on='ID',
    how='left'
)
# 删除多余的 ID 列
airports_with_station_data.drop(columns=['ID'], inplace=True)

airports_with_station_data.to_csv('match_stations_1.csv', index=False)
