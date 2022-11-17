#!/bin/bash

rm -rf vasp/
rm -f POSCAR*

n_selected=$(grep "BEGIN" diff.cfg | wc -l)
mlp convert-cfg diff.cfg POSCAR --output-format=vasp-poscar

for ((i=0; i<n_selected; i++))
do
    mkdir vasp
    cp INCAR KPOINTS POTCAR vasp
    if [ $n_selected -eq 1 ]; then 
        cp POSCAR vasp
    elif [ $n_selected -gt 1 ]; then
        cp POSCAR$i vasp/POSCAR
    fi
    cd vasp
    OMP_NUM_THREADS=1 mpirun -n $(nproc --all) --allow-run-as-root --mca btl_vader_single_copy_mechanism none vasp
    mlp convert-cfg OUTCAR output_ef.cfg --input-format=vasp-outcar
    cat output_ef.cfg >> ../../train.cfg
    cd ..
    rm -r vasp
done

rm diff.cfg
rm POSCAR*