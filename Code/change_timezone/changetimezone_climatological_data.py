import pandas as pd
import numpy as np
import os
import re

import warnings
warnings.filterwarnings("ignore")

year = 2023

file_columns_data = {}
column_data_count = {}

station_df = pd.read_csv(r'match_stations_4_.csv')
timezone_dict = station_df.set_index('Station_ID')['Tz database timezone'].to_dict()
os.makedirs(f'climatological_data_{str(year)}_filtered', exist_ok=True)
hourly_columns = [
    'DATE', 'HourlyAltimeterSetting', 'HourlyDewPointTemperature', 'HourlyDryBulbTemperature', 'HourlyPrecipitation',
    'HourlyPresentWeatherType', 'HourlyPressureChange', 'HourlyPressureTendency', 'HourlyRelativeHumidity',
    'HourlySkyConditions', 'HourlySeaLevelPressure', 'HourlyStationPressure', 'HourlyVisibility',
    'HourlyWetBulbTemperature', 'HourlyWindDirection', 'HourlyWindGustSpeed', 'HourlyWindSpeed'
]
daily_columns = [
    'DailyAverageDewPointTemperature', 'DailyAverageDryBulbTemperature', 'DailyAverageRelativeHumidity',
    'DailyAverageSeaLevelPressure', 'DailyAverageStationPressure', 'DailyAverageWetBulbTemperature',
    'DailyAverageWindSpeed', 'DailyCoolingDegreeDays', 'DailyDepartureFromNormalAverageTemperature',
    'DailyHeatingDegreeDays', 'DailyMaximumDryBulbTemperature', 'DailyMinimumDryBulbTemperature',
    'DailyPeakWindDirection', 'DailyPeakWindSpeed', 'DailyPrecipitation', 'DailySnowDepth', 'DailySnowfall',
    'DailySustainedWindDirection', 'DailySustainedWindSpeed', 'DailyWeather'
]
HourlySkyConditions_types = ['CLR:00', 'BKN:07', 'OVC:08', 'SCT:04', 'FEW:02', 'FEW:01', 'SCT:03', 'BKN:05', 'BKN:06',
                             'VV:09']
# 为云量类型生成正则表达式字典，用于快速匹配
cloud_patterns = {cloud_type: re.compile(rf'\b{cloud_type}(?!s)\b') for cloud_type in HourlySkyConditions_types}

# 定义天气影响等级
minimal_impact = {'-DZ:01', '-RA:02', '-SG', '-SHRA:02', '-SHSN:03', '-SN:03', 'BC', 'BCFG:2', 'BR', 'BR:1',
                  'DR', 'DRDU', 'DRSA', 'DU', 'FG', 'FU', 'FU:1', 'HZ', 'HZ:1', 'MI', 'MIBR:1', 'MIFG:2', 'PRFG:2',
                  'RA:1', 'SN:1', 'TSRA:1', 'VCFG', 'VCFG:2', 'VCSH', 'VCSN'}
moderate_impact = {'-GS:08', '-PL:06', '-SG:04', '-SHPL:06', 'BL', 'BLDU', 'BLDU:5', 'BLSA', 'BLSN', 'BLSN:1', 'DRSN',
                   'DRSN:03', 'DU:5', 'DZ', 'DZ:01', 'FZFG', 'GS', 'PL', 'RA', 'RA:02', 'SG', 'SG:04', 'SG:5', 'SH',
                   'SHPL', 'SHRA', 'SHRA:02', 'SHRASN', 'SHSN', 'SHSN:03', 'SN', 'SN:03', 'SS', 'TSRA', 'VCSHRA:02',
                   'VCTS'}
severe_impact = {'+DZ', '+DZ:01', '+FZRA:02', '+PL:06', '+RA', '+RA:02', '+SHPL', '+SHRA:02', '+SHSN', '+SHSN:03',
                 '+SN:03', '+TSRA', '-FZDZ:01', '-FZFG:2', '-FZRA:02', '-GR:07', 'BLSA:6', 'BLSN:03',
                 'DS:5', 'DS:6', 'FC', 'FC:3', 'FC:5', 'FG:2', 'FZDZ', 'FZDZ', 'FZDZ:01', 'FZRA', 'FZRA:02', 'GR',
                 'GR:7', 'HAIL', 'PL:06', 'PO:1', 'SA:6', 'SQ', 'SS:5', 'TS', 'TS+HAIL', 'TS-HAIL', 'TSGR', 'UP',
                 'VA:4', 'VCBLDU:5', 'VCFC', 'VCPO:1', 'VCSHSN:03'}
extreme_impact = {'+BLDU', '+BLSA', '+DS', '+FC', '+FC:3', '+FC:5', '+FZDZ:01', '+GR', '+GR:07', '+GS:08', '+IC', '+SS',
                  '+TS', '+UP', '+UP:09', '-TSRA:02', 'DS:8', 'FU:3', 'FZ', 'FZFG:2', 'GR:07', 'GS:08', 'HZ:7', 'IC',
                  'IC:05', 'SNGR', 'SQ:2', 'SQ:5', 'UP:09', 'VA', 'VA:8'}

output_column_order = ['DATE', 'HourlyAltimeterSetting', 'HourlyDewPointTemperature', 'HourlyDryBulbTemperature',
                       'HourlyPrecipitation', 'HourlyPresentWeatherType', 'HourlyPresentWeatherType_Minimal',
                       'HourlyPresentWeatherType_Moderate', 'HourlyPresentWeatherType_Severe',
                       'HourlyPresentWeatherType_Extreme', 'HourlyPressureChange', 'HourlyPressureTendency',
                       'HourlyRelativeHumidity', 'HourlySkyConditions', 'HourlySkyConditions_CLR00',
                       'HourlySkyConditions_BKN07', 'HourlySkyConditions_OVC08', 'HourlySkyConditions_SCT04',
                       'HourlySkyConditions_FEW02', 'HourlySkyConditions_FEW01', 'HourlySkyConditions_SCT03',
                       'HourlySkyConditions_BKN05', 'HourlySkyConditions_BKN06', 'HourlySkyConditions_VV09',
                       'HourlySeaLevelPressure', 'HourlyStationPressure', 'HourlyVisibility',
                       'HourlyWetBulbTemperature', 'HourlyWindDirection', 'HourlyWindGustSpeed', 'HourlyWindSpeed',
                       'DailyAverageDewPointTemperature', 'DailyAverageDryBulbTemperature',
                       'DailyAverageRelativeHumidity', 'DailyAverageSeaLevelPressure', 'DailyAverageStationPressure',
                       'DailyAverageWetBulbTemperature', 'DailyAverageWindSpeed', 'DailyCoolingDegreeDays',
                       'DailyDepartureFromNormalAverageTemperature', 'DailyHeatingDegreeDays',
                       'DailyMaximumDryBulbTemperature', 'DailyMinimumDryBulbTemperature', 'DailyPeakWindDirection',
                       'DailyPeakWindSpeed', 'DailyPrecipitation', 'DailySnowDepth', 'DailySnowfall',
                       'DailySustainedWindDirection', 'DailySustainedWindSpeed', 'DailyWeather', 'DailyWeather_Minimal',
                       'DailyWeather_Moderate', 'DailyWeather_Severe', 'DailyWeather_Extreme']

for station_id, timezone in timezone_dict.items():
    # 1. 读文件
    climatological_raw_file = rf'climatological_data_{str(year)}\LCD_{station_id}_{str(year)}.csv'
    if not os.path.exists(climatological_raw_file):
        print("File not exists:", station_id)
        continue
    df = pd.read_csv(climatological_raw_file, header=0)

    # 2. 只保留指定的列和指定时间
    df = df[hourly_columns + daily_columns + ['REPORT_TYPE']]
    df['DATE'] = pd.to_datetime(df['DATE']).dt.tz_localize(timezone, ambiguous='NaT', nonexistent='NaT')
    df = df[((df['DATE'] >= f'{year}-01-01') & (df['DATE'] < f'{year}-02-02')) |
            ((df['DATE'] >= f'{year}-11-01') & (df['DATE'] < f'{year + 1}-01-01'))]


    # 3.1 填充daily_columns
    def fill_forward_data(df, columns):
        for column in columns:
            # Replace 'T' with 0.001 in the specified daily columns
            df[column] = df[column].replace('T', 0.001)
            # Forward fill each column individually
            df[column] = df[column].ffill()
        return df


    sod_rows = df['REPORT_TYPE'] == 'SOD'
    df.loc[sod_rows, daily_columns] = df.loc[sod_rows, daily_columns].fillna('@_@')
    df = fill_forward_data(df, daily_columns)
    df[daily_columns] = df[daily_columns].replace('@_@', np.nan)

    # 3.2 填充daily_columns的DailyWeather
    daily_impact_levels = ['Minimal', 'Moderate', 'Severe', 'Extreme']
    for level in daily_impact_levels:
        df[f'DailyWeather_{level}'] = np.nan


    # Define a function to update daily weather impact columns
    def update_daily_weather_impact(row):
        weather = row['DailyWeather']
        # 如果 DailyWeather 列为空，则直接返回 row，不修改影响等级列
        if pd.isna(weather):
            return row
        # 如果有记录，初始化天气影响等级列为 0
        for level in daily_impact_levels:
            row[f'DailyWeather_{level}'] = 0
        # 分割和统计天气影响
        conditions = set(re.split(r'[| ]', weather))  # 按 | 和空格分割，并去重
        for condition in conditions:
            if condition in minimal_impact:
                row['DailyWeather_Minimal'] += 1
            elif condition in moderate_impact:
                row['DailyWeather_Moderate'] += 1
            elif condition in severe_impact:
                row['DailyWeather_Severe'] += 1
            elif condition in extreme_impact:
                row['DailyWeather_Extreme'] += 1
        return row


    # Apply the function to each row in the dataframe
    df = df.apply(update_daily_weather_impact, axis=1)

    # 3.3 删除只记录daily和monthly数据的行
    df = df[~df['REPORT_TYPE'].isin(['SOD', 'SOM'])]  # 删除 REPORT_TYPE 列中值为 SOD 或 SOM 的行
    del df['REPORT_TYPE']

    # 4. 处理hourly_columns
    # 将 HourlyPrecipitation 列中的 'T' 替换为 0.001
    df['HourlyPrecipitation'] = df['HourlyPrecipitation'].replace('T', 0.001)

    # 为每个云量类型创建新列并初始化为 NaN
    for cloud_type in HourlySkyConditions_types:
        new_col_name = f'HourlySkyConditions_{cloud_type.replace(":", "")}'
        df[new_col_name] = np.nan

    # 如果有记录，匹配并设置云量类型列
    valid_conditions = df['HourlySkyConditions'].notna()
    for cloud_type, pattern in cloud_patterns.items():
        new_col_name = f'HourlySkyConditions_{cloud_type.replace(":", "")}'
        try:
            df.loc[valid_conditions, new_col_name] = df.loc[valid_conditions, 'HourlySkyConditions'].str.contains(
                pattern
            ).astype(float)
        except Exception as e:
            print(f"Error processing {cloud_type}: {e}")
            df[new_col_name] = np.nan  # 遇到异常时将该格子置为空

    '''
    # 定义更新云层列的函数
    def update_cloud_conditions(row):
        condition = row['HourlySkyConditions']
        if pd.isna(condition):
            return row  # 如果没有值，保持所有列为 0
            # 遍历每个云量类型，使用预编译的正则表达式检查匹配
        for cloud_type, pattern in cloud_patterns.items():
            new_col_name = f'HourlySkyConditions_{cloud_type.replace(":", "")}'
            if pattern.search(condition):
                row[new_col_name] = 1  # 如果匹配且没有尾随 's'，写 1
            else:
                # 如果不匹配，确保是 0（无匹配的列保持 NaN）
                if pd.isna(row[new_col_name]):
                    row[new_col_name] = 0
        return row


    df = df.apply(update_cloud_conditions, axis=1)
    '''

    # 初始化天气影响等级列为 NaN
    impact_levels = ['Minimal', 'Moderate', 'Severe', 'Extreme']
    for level in impact_levels:
        df[f'HourlyPresentWeatherType_{level}'] = np.nan

    # 如果 'HourlyPresentWeatherType' 列有数据，将相应影响等级列初始化为 0
    valid_weather = df['HourlyPresentWeatherType'].notna()
    for level in impact_levels:
        df.loc[valid_weather, f'HourlyPresentWeatherType_{level}'] = 0


    # 分割和统计天气影响
    def update_weather_impact(row):
        weather = row['HourlyPresentWeatherType']
        if pd.isna(weather):
            return row
        conditions = set(re.split(r'[| ]', weather))  # 按 | 和空格分割，并去重
        for condition in conditions:
            if condition in minimal_impact:
                row['HourlyPresentWeatherType_Minimal'] += 1
            elif condition in moderate_impact:
                row['HourlyPresentWeatherType_Moderate'] += 1
            elif condition in severe_impact:
                row['HourlyPresentWeatherType_Severe'] += 1
            elif condition in extreme_impact:
                row['HourlyPresentWeatherType_Extreme'] += 1
        return row


    df = df.apply(update_weather_impact, axis=1)

    # 5. 整理和保存
    df = df[output_column_order]
    df.to_csv(rf'climatological_data_{str(year)}_filtered\{station_id}_{str(year)}_filtered.csv', index=False)
