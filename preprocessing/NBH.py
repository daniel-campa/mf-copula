# https://osf.io/a67uf/files/osfstorage
# This file contains functions for preprocessing the raw data from the paper
# Navigational Behavior of Humans and Deep Reinforcement Learning Agents

import os
import pandas as pd
import numpy as np
from tqdm import tqdm

os.chdir(os.path.expanduser('~/git/mf-copula/'))

AGENT = 'raycast'

directory = f'./NBH/{AGENT}/'
out = f'./NBH/preprocessed/{AGENT}/'
try:
    os.mkdir(out)
except FileExistsError:
    print(out)

targets = [
    (16, -12),
    (16, 0),
    (16, 12)
]

starts = [
    (-16, -5),
    (-16, 5)
]

def find_closest_coordinate(coordinates, new_coordinate):
    def euclidean_distance(coord1, coord2):
        return np.sqrt((coord1[0] - coord2[0]) ** 2 + (coord1[1] - coord2[1]) ** 2)

    closest_coordinate = min(coordinates, key=lambda coord: euclidean_distance(coord, new_coordinate))
    return closest_coordinate

df_list = [
    pd.concat([pd.read_csv(
        os.path.join(directory, csv),
        header=1 if AGENT == 'human' else 'infer',
        low_memory=False
    ), pd.DataFrame({'filename': [csv]})], axis=1)
    for csv in os.listdir(directory)
]

obstacles_df = pd.DataFrame([df.iloc[0, df.columns.get_loc('O1xpos'):df.columns.get_loc('Space')] for df in df_list]).drop_duplicates().reset_index(drop=True)
obstacles_df.to_csv(os.path.join(out, 'obstacles.csv'))
obstacles_list = [tuple(row) for row in obstacles_df.values]

for df in tqdm(df_list):

    obstacles_row = tuple(df.iloc[0, df.columns.get_loc('O1xpos'):df.columns.get_loc('Space')].values)

    path = df[['P1xpos','P1zpos']]
    path.columns = ['x','y']
    try:
        path.loc[:, 'x'] = pd.to_numeric(path.x)
        path.loc[:, 'y'] = pd.to_numeric(path.y)
    except ValueError:
        print(df.loc[0,'filename'])
        continue
    
    path = path.dropna()

    start = find_closest_coordinate(starts, (int(path.x.iloc[0]), int(path.y.iloc[0])))
    target = find_closest_coordinate(targets, (int(df.Targetxpos.iloc[0]), int(df.Targetzpos.iloc[0])))
    
    desc_str = f'map{start[0]}_{start[1]}_{target[0]}_{target[1]}_obs{obstacles_list.index(obstacles_row)}'
    
    os.makedirs(os.path.join(out, desc_str), exist_ok=True)

    path.to_csv(os.path.join(out, desc_str, df.loc[0,'filename']), index=False)
