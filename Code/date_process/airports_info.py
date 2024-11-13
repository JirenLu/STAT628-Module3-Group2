import pandas as pd
import numpy as np

airports_search_file = 'airports_search.csv'
airports_search_df = pd.read_csv(airports_search_file, encoding='ISO-8859-1')
airports_count_file = 'airports_count.csv'
airports_count_df = pd.read_csv(airports_count_file, encoding='ISO-8859-1')

# airports_search_df_us = airports_search_df[airports_search_df['Country'] == 'United States']
merged = pd.merge(airports_count_df,
                  airports_search_df[
                      ['IATA', 'Latitude', 'Longitude', 'Altitude', 'Timezone', 'Tz database timezone', 'Country',
                       'City']],
                  left_on='Airport', right_on='IATA', how='left')
merged = merged.drop(columns=['IATA'])
merged.to_csv('airports_info.csv', index=False)
