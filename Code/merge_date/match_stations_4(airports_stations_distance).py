import pandas as pd
from geopy.distance import geodesic
from scipy.spatial import KDTree
import numpy as np
import os

# 本轮为手动处理
# 缺失机场['LYH', 'EGE', 'BQN', 'FCA', 'PPG', 'JHM', 'ISN', 'PSE', 'ROP', 'XWA']
# 数据少机场['SGU', 'YUM']
# 距离远机场第一批['DHN', 'RNO', 'SMF', 'PSC', 'CLL']
# 距离远机场第二批['MTJ', 'PSM', 'SWF', 'HOU', 'FLL', 'RSW', 'OAK', 'SGU', 'TPA', 'PIE', 'ONT', 'OGD', 'LAW', 'ITO','MHK', 'JAC']


# 读取机场和监测站数据
airports_df = pd.read_csv('airports_info_.csv')
station_df = pd.read_csv('weather_stations_final_.csv')
output_dir = 'airports_nearby_stations'
os.makedirs(output_dir, exist_ok=True)

# 提取监测站的经纬度并建立 KDTree
station_locations = np.array(list(zip(station_df['LATITUDE'], station_df['LONGITUDE'])))
station_tree = KDTree(station_locations)

# 设置最大距离为 50 公里
max_distance_km = 1000
max_distance_deg = max_distance_km / 111  # 粗略换算，1 度约等于 111 公里

# 指定要搜索的机场代码
specified_airports = ['XWA']

# 过滤出指定机场的行
filtered_airports_df = airports_df[airports_df['Airport'].isin(specified_airports)]

# 遍历指定的机场并查找附近的监测站
for _, airport_row in filtered_airports_df.iterrows():
    airport_name = airport_row['Airport']
    airport_location = (airport_row['Latitude'], airport_row['Longitude'])
    airport_location_deg = [airport_row['Latitude'], airport_row['Longitude']]

    # 使用 KDTree 查找在 30 公里内的监测站索引
    nearby_indices = station_tree.query_ball_point(airport_location_deg, max_distance_deg)

    # 存储符合条件的监测站信息
    nearby_stations = []

    # 遍历附近监测站并精确计算距离
    for idx in nearby_indices:
        station_row = station_df.iloc[idx]
        station_location = (station_row['LATITUDE'], station_row['LONGITUDE'])
        distance = geodesic(airport_location, station_location).kilometers

        # 检查精确距离是否小于 30 公里
        if distance <= max_distance_km:
            nearby_stations.append({
                'Station_ID': station_row['ID'],
                'Latitude': station_row['LATITUDE'],
                'Longitude': station_row['LONGITUDE'],
                'Distance_km': distance,
                '2018_MB': station_row['2018_MB'],
                '2019_MB': station_row['2019_MB'],
                '2020_MB': station_row['2020_MB'],
                '2021_MB': station_row['2021_MB'],
                '2022_MB': station_row['2022_MB'],
                '2023_MB': station_row['2023_MB'],
                '2024_MB': station_row['2024_MB']
            })

    # 如果有符合条件的监测站，将数据写入CSV文件
    if nearby_stations:
        # 创建 DataFrame 并按距离升序排序
        nearby_stations_df = pd.DataFrame(nearby_stations)
        nearby_stations_df = nearby_stations_df.sort_values(by='Distance_km').reset_index(drop=True)

        # 保存到CSV文件，以机场代码命名
        output_file = os.path.join(output_dir, f"{airport_name}.csv")
        nearby_stations_df.to_csv(output_file, index=False)
