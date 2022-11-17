import numpy as np

v = {}

with open("cfg","r") as cfg:
    _ = v["[structure:cfg]"] = cfg.read().split("\n\n")
_.pop(-1)
length = len(_)

v["[structure:cfg].train"] = np.random.choice(_[:length*3//4:], size=50, replace=False) # Customize here?
v["[structure:cfg].test"] = np.random.choice(_[length*3//4:], size=10, replace=False)   # Customize here?

_ = v["[structure:cfg].train"]
with open("train.cfg","w") as file:
    file.write("\n\n".join(_))
_ = v["[structure:cfg].test"]
with open("test.cfg","w") as file:
    file.write("\n\n".join(_))

import ase.io
structure = ase.io.read('OUTCAR', index='-1')
ase.io.write('input.pos', structure, format='lammps-data')