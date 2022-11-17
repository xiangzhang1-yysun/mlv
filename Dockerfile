FROM ubuntu:22.04 AS build
RUN apt-get update
RUN apt-get install -y make build-essential gfortran libopenmpi-dev libopenblas-dev libscalapack-openmpi-dev libfftw3-dev libhdf5-openmpi-dev rsync

FROM build AS mlip
ADD src/mlip-2-master.tar.gz /src/
WORKDIR /src/mlip-2-master
RUN ./configure && make mlp

FROM mlip AS lammps-mlip
ADD src/lammps-29Sep2021.tar.gz /src/
WORKDIR /src/lammps-29Sep2021/src
# nproc distinguishes between the number of CPUs available to the current process, and overall number of CPUs
RUN make -j $(nproc --all) mpi
WORKDIR /src/mlip-2-master
RUN make libinterface
ADD src/interface-lammps-mlip-2.tar.gz /src/
RUN cp /src/mlip-2-master/lib/lib_mlip_interface.a /src/interface-lammps-mlip-2/
WORKDIR /src/interface-lammps-mlip-2/
RUN ./install.sh ../lammps-29Sep2021/ mpi

FROM build AS vasp
ADD src/vasp.6.3.0.tgz /src/
ADD src/makefile.include /src/vasp.6.3.0/
WORKDIR /src/vasp.6.3.0
RUN make DEPS=1 -j $(nproc --all)

FROM ubuntu:22.04 AS production
RUN apt-get update \
    && apt-get install -y gfortran openmpi-bin libopenblas-base libscalapack-openmpi2.1 libfftw3-3 libhdf5-openmpi-103 python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*
RUN yes | pip install ase numpy
COPY --from=lammps-mlip /src/interface-lammps-mlip-2/lmp_mpi /usr/local/bin/lmp
COPY --from=lammps-mlip /src/mlip-2-master/bin/mlp /usr/local/bin/mlp
COPY --from=vasp /src/vasp.6.3.0/bin/vasp_std /usr/local/bin/vasp
ENV OMP_NUM_THREADS 1
WORKDIR /data

FROM production AS mlip.passive
WORKDIR /data
COPY run/mlip.passive.run/18.mtp run/mlip.passive.run/setup.py upstream/OUTCAR .
RUN mlp convert-cfg OUTCAR cfg --input-format=vasp-outcar
RUN python3 setup.py
RUN mindist="$(mlp mindist train.cfg | awk '{print $3}')" && sed -i "s/min_dist = 1.9/min_dist = ${mindist}/g" 18.mtp
RUN nelement="$(head -1000 OUTCAR | grep POTCAR | wc -l)" && sed -i "s/species_count = 1/species_count = $((nelement/2))/g" 18.mtp
RUN mpirun -n $(nproc --all) --allow-run-as-root --mca btl_vader_single_copy_mechanism none mlp train 18.mtp train.cfg --trained-pot-name=mtp --valid-cfgs=test.cfg

FROM production AS mlip.active
WORKDIR /data
COPY run/mlip.active.run/ /data 
COPY --from=mlip.passive /data/mtp init.mtp
COPY --from=mlip.passive /data/train.cfg train_init.cfg
COPY --from=mlip.passive /data/input.pos input.pos
COPY upstream/INCAR upstream/POTCAR upstream/KPOINTS calculate_ab_initio_ef/
RUN ./md_al_mtp.sh 

FROM production AS kappa
WORKDIR /data
COPY run/kappa.run/ .
COPY --from=mlip.passive /data/input.pos structure.lmp
COPY --from=mlip.active /data/curr.mtp mtp
RUN mpirun -n $(nproc --all) --allow-run-as-root --mca btl_vader_single_copy_mechanism none lmp -in in

