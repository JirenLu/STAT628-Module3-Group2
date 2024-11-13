import pandas as pd

# Process both files
file_path1 = 'weather_type_counts_2.csv'
file_path2 = 'weather_type_counts_4.csv'

weather_counts_df1 = pd.read_csv(file_path1)
weather_counts_df2 = pd.read_csv(file_path2)

# Concatenate the two DataFrames
combined_weather_counts_df = pd.concat([weather_counts_df1, weather_counts_df2], ignore_index=True)

# Filter out rows where 'WeatherCondition' is purely integer
combined_weather_counts_df = combined_weather_counts_df[~combined_weather_counts_df['WeatherCondition'].astype(str).str.isdigit()]

# Group by 'WeatherCondition' and sum the 'Count'
final_weather_counts_df = combined_weather_counts_df.groupby('WeatherCondition', as_index=False)['Count'].sum()

# Save the result to a new CSV file
output_file = 'weather_type_counts_x.csv'
final_weather_counts_df.to_csv(output_file, index=False)