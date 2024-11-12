import pandas as pd
import pytz
from datetime import datetime
import os


def convert_to_datetime(row, time_col, timezone_col):
    # 处理空值情况
    if pd.isnull(row[time_col]):
        return pd.NaT
    # 读取FlightDate
    date = pd.to_datetime(row['FlightDate'])
    # 提取小时和分钟
    time_value = int(row[time_col])
    if time_value == 2400:  # 时间为次日00:00
        date = date + pd.Timedelta(days=1)  # 日期加1天
        hours, minutes = 0, 0
    else:  # 正常处理时间
        hours = time_value // 100  # 获取小时
        minutes = time_value % 100  # 获取分钟
    # 检查小时和分钟的范围
    if not (0 <= hours < 24 and 0 <= minutes < 60):
        raise ValueError(f"Invalid time value in row: {row.name}, {time_col}={time_value}")
    # 创建datetime对象
    dt = datetime(date.year, date.month, date.day, hours, minutes)
    # 添加时区信息
    timezone = row[timezone_col]
    dt_with_timezone = pd.Timestamp(dt, tz=pytz.timezone(timezone))
    return dt_with_timezone


'''
def delay_datetime(row, crs_time_col, delay_col):
    # 检查 CRSDepTime_timezone 或 DepDelay 是否为空
    if pd.isnull(row[delay_col]):
        return pd.NaT  # 返回空值
    # 从 CRSDepTime_timezone 获取时间，并根据 DepDelay 偏移分钟数
    delay_datetime = row[crs_time_col] + pd.Timedelta(minutes=row[delay_col])
    return delay_datetime
'''


def delay_datetime_vectorized(df, crs_time_col, delay_col, result_col):
    mask = df[delay_col].isnull()  # 如果 delay_col 中有空值，则结果应为空
    # 使用矢量化操作计算延迟后的时间
    df[result_col] = df[crs_time_col] + pd.to_timedelta(df[delay_col].fillna(0), unit='m')
    df.loc[mask, result_col] = pd.NaT  # 将原本延迟为空的行设为 NaT
    return df


airports_info_df = pd.read_csv(r'D:\文档\UW-Madison\STAT628\Module 3\WebScraper\data_processing\airports_info_.csv')
timezone_dict = airports_info_df.set_index('Airport')['Tz database timezone'].to_dict()
for year in range(18, 21):
    for month in [1, 11, 12]:
        flight_raw_file = rf'D:\文档\UW-Madison\STAT628\Module 3\Flight-Data\{str(year)}-{str(month)}.csv'
        if not os.path.exists(flight_raw_file):
            continue
        flight_raw_data_df = pd.read_csv(flight_raw_file)
        # 保留有用列
        flight_raw_data_filtered_df = flight_raw_data_df[[
            'DayOfWeek', 'FlightDate', 'Marketing_Airline_Network', 'Flight_Number_Marketing_Airline',
            'IATA_Code_Operating_Airline', 'Flight_Number_Operating_Airline', 'Origin', 'Dest',
            'CRSDepTime', 'DepTime', 'DepDelay', 'CRSArrTime', 'ArrTime', 'ArrDelay', 'CancellationCode', 'Diverted',
            'CarrierDelay', 'WeatherDelay', 'NASDelay', 'SecurityDelay', 'LateAircraftDelay']]
        # 添加时区列
        flight_raw_data_filtered_df['OriginTimezone'] = flight_raw_data_filtered_df['Origin'].map(timezone_dict)
        flight_raw_data_filtered_df['DestTimezone'] = flight_raw_data_filtered_df['Dest'].map(timezone_dict)
        # 时间转换
        flight_raw_data_filtered_df['CRSDepTime_timezone'] = flight_raw_data_filtered_df.apply(convert_to_datetime,
                                                                                               axis=1,
                                                                                               time_col='CRSDepTime',
                                                                                               timezone_col='OriginTimezone')
        flight_raw_data_filtered_df = delay_datetime_vectorized(flight_raw_data_filtered_df, 'CRSDepTime_timezone',
                                                                'DepDelay', 'DepTime_timezone')
        '''
        flight_raw_data_filtered_df['DepTime_timezone'] = flight_raw_data_filtered_df.apply(delay_datetime, axis=1,
                                                                                            crs_time_col='CRSDepTime_timezone',
                                                                                            delay_col='DepDelay')
        '''
        flight_raw_data_filtered_df['CRSArrTime_timezone'] = flight_raw_data_filtered_df.apply(convert_to_datetime,
                                                                                               axis=1,
                                                                                               time_col='CRSArrTime',
                                                                                               timezone_col='DestTimezone')
        # 找到所有 CRSDepTime_timezone 晚于 CRSArrTime_timezone 的行，将CRSArrTime_timezone 加一天
        overnight_flights = flight_raw_data_filtered_df['CRSDepTime_timezone'] > flight_raw_data_filtered_df[
            'CRSArrTime_timezone']
        flight_raw_data_filtered_df.loc[overnight_flights, 'CRSArrTime_timezone'] += pd.Timedelta(days=1)
        # 时间转换
        flight_raw_data_filtered_df = delay_datetime_vectorized(flight_raw_data_filtered_df, 'CRSArrTime_timezone',
                                                                'ArrDelay', 'ArrTime_timezone')
        '''
        flight_raw_data_filtered_df['ArrTime_timezone'] = flight_raw_data_filtered_df.apply(delay_datetime, axis=1,
                                                                                            crs_time_col='CRSArrTime_timezone',
                                                                                            delay_col='ArrDelay')
        '''
        # 保存csv
        flight_data_filtered_df = flight_raw_data_filtered_df[[
            'DayOfWeek', 'FlightDate', 'Marketing_Airline_Network', 'Flight_Number_Marketing_Airline',
            'IATA_Code_Operating_Airline', 'Flight_Number_Operating_Airline',
            'Origin', 'OriginTimezone', 'Dest', 'DestTimezone',
            'CRSDepTime_timezone', 'DepTime_timezone', 'DepDelay',
            'CRSArrTime_timezone', 'ArrTime_timezone', 'ArrDelay',
            'CancellationCode', 'Diverted',
            'CarrierDelay', 'WeatherDelay', 'NASDelay', 'SecurityDelay', 'LateAircraftDelay'
        ]]
        flight_data_filtered_df.to_csv(
            rf'D:\文档\UW-Madison\STAT628\Module 3\Flight-Data-Filtered\{str(year)}-{str(month)}.csv', index=True)
