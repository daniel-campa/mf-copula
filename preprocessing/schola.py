# https://github.com/GPUOpen-LibrariesAndSDKs/Schola
# This file contains was used to preprocess data that was collected
# using AMD Schola library

import os
import pandas as pd
import numpy as np
from rdp import rdp

def read_json(path):
    df = pd.read_json(path)

    series = [pd.DataFrame(df[col].dropna().to_list(), columns=['x','y']) for col in df.columns]
        
    return series

os.chdir(os.path.expanduser('~/git/mf-copula/'))

set_num = 2

agent0 = read_json(f'./schola/sets/set{set_num}/trajectories0-{set_num}.json')
agent1 = read_json(f'./schola/sets/set{set_num}/trajectories1-{set_num}.json')
agent2 = read_json(f'./schola/sets/set{set_num}/trajectories2-{set_num}.json')
agent3 = read_json(f'./schola/sets/set{set_num}/trajectories3-{set_num}.json')

set_dir = f'./schola/sets/set{set_num}'

for j, agent in enumerate([agent0,agent1,agent2,agent3]):
    os.mkdir(os.path.join(set_dir, f'agent{j}'))

    for i, path in enumerate(agent):
        path.to_csv(os.path.join(set_dir, f'agent{j}/scen{i}.csv'), index=False)
        with open(os.path.join(set_dir, f'agent{j}/scen{i}-mask.txt'), 'w') as f:
            for corner in np.where(rdp(path, epsilon=75, return_mask=True))[0]:
                f.write(f'{corner}\n')
