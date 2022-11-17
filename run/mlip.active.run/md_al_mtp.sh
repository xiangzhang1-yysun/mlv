#!/bin/bash

rm -f train.cfg
rm -f curr.mtp
rm -f preselected.cfg
rm -f diff.cfg
rm -f selected.cfg
rm -f out.cfg

cp init.mtp curr.mtp
cp train_init.cfg train.cfg

#A. Active set construction
mlp calc-grade curr.mtp train.cfg train.cfg out.cfg --als-filename=state.als

rm out.cfg

while [ 1 -gt 0 ]
do

#B. MD simulations and extrapolative (preselected) configurations
touch preselected.cfg
lmp -in in.nb_md

n_preselected=$(grep "BEGIN" preselected.cfg | wc -l)

if [ $n_preselected -gt 0 ]; then

#C. Selection
    mlp select-add curr.mtp train.cfg preselected.cfg diff.cfg --als-filename=state.als
    cp diff.cfg calculate_ab_initio_ef/

    rm -f preselected.cfg
    rm -f selected.cfg

#D and E. Ab initio calculations and merging (updating the training set)
    cd calculate_ab_initio_ef/
    ./ab_initio_calculations.sh
    cd ../

#F. Training
    mpirun -n $(nproc --all) --allow-run-as-root --mca btl_vader_single_copy_mechanism none mlp train curr.mtp train.cfg --trained-pot-name=curr.mtp --update-mindist
    
#A. Active set construction
    mlp calc-grade curr.mtp train.cfg diff.cfg out.cfg --als-filename=state.als
    
    rm -f diff.cfg
    rm -f out.cfg
    
    exit    # Customize here?
    
elif  [ $n_preselected -eq 0 ]; then
    exit
fi

done
