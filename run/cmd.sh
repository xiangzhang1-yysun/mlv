#!/bin/bash
# bind-mount to /upstream

cd /data/mlip.passive
cp /upstream/OUTCAR .
mlp convert-cfg OUTCAR cfg --input-format=vasp-outcar
python3 setup.py
mindist="$(mlp mindist train.cfg | awk '{print $3}')" && sed -i "s/min_dist = 1.9/min_dist = ${mindist}/g" 18.mtp
nelement="$(head -1000 OUTCAR | grep POTCAR | wc -l)" && sed -i "s/species_count = 1/species_count = $((nelement/2))/g" 18.mtp
mpirun -n $(nproc --all) --allow-run-as-root --mca btl_vader_single_copy_mechanism none mlp train 18.mtp train.cfg --trained-pot-name=mtp --valid-cfgs=test.cfg

cd /data/mlip.active
cp /data/mlip.passive/mtp init.mtp
cp /data/mlip.passive/train.cfg train_init.cfg
cp /data/mlip.passive/input.pos input.pos
cp /upstream/INCAR /upstream/POTCAR /upstream/KPOINTS calculate_ab_initio_ef/
./md_al_mtp.sh 

cd /data/kappa
cp /data/mlip.passive/input.pos structure.lmp
cp /data/mlip.active/curr.mtp mtp
mpirun -n $(nproc --all) --allow-run-as-root --mca btl_vader_single_copy_mechanism none lmp -in in