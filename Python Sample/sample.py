# -*- coding: utf-8 -*-
"""
Python Sample using Pandas
Josefina Rodríguez Orellana
"""

import pandas as pd

from pathlib import Path
path = Path.cwd()
df1 = 'employment.csv'
df2 = 'labor force.csv'
file1 = path.joinpath(df1)
file2 = path.joinpath(df2)

employment  = pd.read_csv(file1)
labor_force = pd.read_csv(file2)

employment = employment[employment['Employment'].notnull()]
labor_force = labor_force[labor_force['Labor Force'].notnull()]

"""
We use inner join to merge the dfs because only the countries that have employment and labor force data,
are useful to calculate unemployment rates (avoiding NAs).
"""
empl_lf = employment.merge(labor_force, how = 'inner',
                           on = ['msa', 'country', 'month', 'year'])


empl_lf['month'] = empl_lf['month'].astype(int)
empl_lf['date']  = empl_lf['year'] + '-' + empl_lf['month'].astype(str) + '-31'
empl_lf['date'] = pd.to_datetime(empl_lf['date'])

#We fix some data error on Houston.
empl_lf.loc[empl_lf['msa'] == 'Houston-The Woodlands-Sugar Land, TX', 'Labor Force'] = 2733348


empl_lf['unemployment_rate'] = 1 - empl_lf['Employment'] / empl_lf['Labor Force']

empl_lf['unemployment_rate_n'] = empl_lf['unemployment_rate'].map('{:.2%}'.format)

avg_unemp_rate = empl_lf['unemployment_rate'].mean()
high_than_avg = empl_lf.loc[empl_lf['unemployment_rate'] > avg_unemp_rate, :]
high_than_avg[['msa', 'unemployment_rate_n']]

#Only run the following line if you wish to save the resulting table in your computer
#empl_lf.to_csv(path.joinpath('data.csv'), index = False)
