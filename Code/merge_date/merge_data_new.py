import pandas as pd
import numpy as np

year = '23'  # TODO 只需要写最后两位，写在引号里

station_dict = pd.read_csv(r'match_stations_4_.csv').set_index('Airport')['Station_ID'].to_dict()
weather_columns = ['DATE', 'HourlyAltimeterSetting', 'HourlyDewPointTemperature', 'HourlyDryBulbTemperature',
                   'HourlyPrecipitation', 'HourlyPresentWeatherType', 'HourlyPresentWeatherType_Minimal',
                   'HourlyPresentWeatherType_Moderate', 'HourlyPresentWeatherType_Severe',
                   'HourlyPresentWeatherType_Extreme', 'HourlyPressureChange', 'HourlyPressureTendency',
                   'HourlyRelativeHumidity', 'HourlySkyConditions', 'HourlySkyConditions_CLR00',
                   'HourlySkyConditions_BKN07', 'HourlySkyConditions_OVC08', 'HourlySkyConditions_SCT04',
                   'HourlySkyConditions_FEW02', 'HourlySkyConditions_FEW01', 'HourlySkyConditions_SCT03',
                   'HourlySkyConditions_BKN05', 'HourlySkyConditions_BKN06', 'HourlySkyConditions_VV09',
                   'HourlySeaLevelPressure', 'HourlyStationPressure', 'HourlyVisibility', 'HourlyWetBulbTemperature',
                   'HourlyWindDirection', 'HourlyWindGustSpeed', 'HourlyWindSpeed', 'DailyAverageDewPointTemperature',
                   'DailyAverageDryBulbTemperature', 'DailyAverageRelativeHumidity', 'DailyAverageSeaLevelPressure',
                   'DailyAverageStationPressure', 'DailyAverageWetBulbTemperature', 'DailyAverageWindSpeed',
                   'DailyCoolingDegreeDays', 'DailyDepartureFromNormalAverageTemperature', 'DailyHeatingDegreeDays',
                   'DailyMaximumDryBulbTemperature', 'DailyMinimumDryBulbTemperature', 'DailyPeakWindDirection',
                   'DailyPeakWindSpeed', 'DailyPrecipitation', 'DailySnowDepth', 'DailySnowfall',
                   'DailySustainedWindDirection', 'DailySustainedWindSpeed', 'DailyWeather', 'DailyWeather_Minimal',
                   'DailyWeather_Moderate', 'DailyWeather_Severe', 'DailyWeather_Extreme']
# Define column groups for each case
weather_column_groups = {
    'CRSDepTime_Origin': ['CRSDepTime_timezone', 'Origin'],
    'CRSDepTime_Dest': ['CRSDepTime_timezone', 'Dest'],
    'DepTime_Origin': ['DepTime_timezone', 'Origin'],
    'DepTime_Dest': ['DepTime_timezone', 'Dest'],
    'CRSArrTime_Dest': ['CRSArrTime_timezone', 'Dest'],
    'ArrTime_Dest': ['ArrTime_timezone', 'Dest'],
}
weather_dfs = {}


# 1. 按需加载天气数据的函数
def load_weather_data(station_id):
    if station_id in weather_dfs:
        return weather_dfs[station_id]
    station_file = rf"climatological_data_20{year}_filtered\{station_id}_20{year}_filtered.csv"
    weather_df = pd.read_csv(station_file, parse_dates=['DATE'])
    weather_df = weather_df.sort_values('DATE').reset_index(drop=True)  # 按日期排序
    weather_dfs[station_id] = weather_df
    return weather_df


# 2. 查找最近的天气记录的函数
def find_nearest_weather_data(row, time_col, airport_col, prefix):
    global progress_counter
    progress_counter += 1
    if progress_counter % 10000 == 0:
        print(f"Processed {progress_counter} flight records")

    station_id = station_dict.get(row[airport_col])
    if station_id is None or pd.isna(station_id):
        return pd.Series([np.nan] * len(weather_columns), index=[f"{prefix}_{col}" for col in weather_columns])

    weather_df = load_weather_data(station_id)
    target_time = row[time_col]
    # 检查 target_time 是否为空值
    if pd.isna(target_time):
        return pd.Series([np.nan] * len(weather_columns), index=[f"{prefix}_{col}" for col in weather_columns])

    # Locate the closest time
    pos = np.searchsorted(weather_df['DATE'], target_time)
    idxs = [pos - 1, pos] if 0 < pos < len(weather_df) else [0] if pos == 0 else [len(weather_df) - 1]
    nearest_idx = min(idxs, key=lambda i: abs(weather_df['DATE'].iloc[i] - target_time))
    nearest_row = weather_df.iloc[nearest_idx]

    # Populate data with fallback to previous row if missing
    filled_data = {}
    for col in weather_columns:
        value = nearest_row[col]
        # 如果当前值为空且最近索引有效，则向前查找最多四行的最近有效值
        if pd.isna(value) and nearest_idx > 0:
            for offset in range(1, 5):
                if nearest_idx - offset >= 0:
                    previous_value = weather_df[col].iloc[nearest_idx - offset]
                    if pd.notna(previous_value):
                        value = previous_value
                        break  # 找到最近的非空值后停止查找
        # 如果向前四行都没有找到有效值，则向后查找一行
        if pd.isna(value) and nearest_idx < len(weather_df) - 1:
            next_value = weather_df[col].iloc[nearest_idx + 1]
            if pd.notna(next_value):
                value = next_value
        filled_data[f"{prefix}_{col}"] = value

    return pd.Series(filled_data)


for month in ['1', '11', '12']:
    # 3. 加载航班数据
    # TODO 改路径
    flight_df = pd.read_csv(
        rf'D:\文档\UW-Madison\STAT628\Module 3\Flight-Data-Filtered-Indexed\indexed_modified_{year}-{month}.csv',
        parse_dates=['CRSDepTime_timezone', 'DepTime_timezone', 'CRSArrTime_timezone', 'ArrTime_timezone'])
    # Add station ID columns for Origin and Dest in flight_df
    flight_df['Origin_Station_ID'] = flight_df['Origin'].map(station_dict)
    flight_df['Dest_Station_ID'] = flight_df['Dest'].map(station_dict)

    # 4. 应用函数和保存结果
    for prefix, (time_col, airport_col) in weather_column_groups.items():
        print(prefix)
        progress_counter = 0
        weather_matched_data = flight_df.apply(find_nearest_weather_data, axis=1, args=(time_col, airport_col, prefix))
        flight_df = pd.concat([flight_df, weather_matched_data], axis=1)
    # TODO 改路径
    flight_df.to_csv(rf'D:\文档\UW-Madison\STAT628\Module 3\Flight-Data-Merged\{year}-{month}.csv', index=False)
