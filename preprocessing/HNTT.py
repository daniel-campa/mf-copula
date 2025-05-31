# https://icml2021.z5.web.core.windows.net/HNTT_data.zip
# This file contains was used to preprocess the raw data from the paper
# Navigation Turing Test (NTT): Learning to Evaluate Human-Like Navigation

import pandas as pd
import numpy as np
import json
import os
from rdp import rdp
import json

os.chdir(os.path.expanduser('~/git/mf-copula/'))

EPSILON = 75
TYPE = 'symbolic'
CHECKPOINT = 'checkpoint11600'

dir = os.path.join('./HNTT/ICML2021-train-data/', TYPE, CHECKPOINT)

with open(os.path.join(dir, 'sets.json')) as f:
    sets = json.load(f)

try:
    os.mkdir(os.path.join('./HNTT/preprocessed/', TYPE))
except FileExistsError:
    pass
os.mkdir(os.path.join('./HNTT/preprocessed/', TYPE, CHECKPOINT))


for i, group in sets.items():

    os.mkdir(os.path.join('./HNTT/preprocessed/', TYPE, CHECKPOINT, f's{i}'))
    
    for file in group:
        
        with open(os.path.join(dir, file)) as f:
            lines = f.readlines()

        df = pd.DataFrame()

        for line in lines:
            json_line = json.loads(line)
            step = list(json_line.keys())[0]
            pos_dict = json_line[step]['Observations']['Players'][0]['Position'][0]
            # print(f'{step}:', pos_dict)
            df = pd.concat([df, pd.DataFrame(pos_dict, index=[int(step[4:])])])
            
        timestamp = file.split('___ReplayDebug-Map_Rooftops_Seeds_Main-')[1].split('Trajectories')[0]
        df.to_csv(os.path.join('./HNTT/preprocessed', TYPE, CHECKPOINT, f's{i}', f'{timestamp}.csv'), index=False)

        mask = rdp(df, epsilon=EPSILON, return_mask=True)
        np.savetxt(os.path.join('./HNTT/preprocessed', TYPE, CHECKPOINT, f's{i}', f'{timestamp}-mask.txt'), np.where(mask), delimiter='\n', fmt='%d')
