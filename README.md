Given any material, calculate its kappa using Green-Kubo, MLIP potential (auto-trained on VASP data) and LAMMPS.

## Requirements

[Docker](http://docker.com)

- OUTCAR: VASP OUTCAR of >100-ish configurations, e.g. from MD.
- INCAR, KPOINTS, POTCAR: VASP input files that calculates energy.

## Usage 1
In a folder containing OUTCAR, INCAR, KPOINTS, POTCAR, run `docker run -v ${PWD}:/upstream xzhang0/mlv`.

## Usage 2
Replace the sample upstream/OUTCAR|INCAR|KPOINTS|POTCAR with your own, and run `docker build --progress=plain .`.

## Output
Kappa will be printed to stdout. Eventually.

## Implementation
This is just a wrapper containing i) MLIP passive training, ii) MLIP active training, and iii) LAMMPS Green-Kubo. Adapt the files to your liking.

1. Train preliminary MLIP potential using OUTCAR data.
2. Retrain MLIP potential: generates structures using MLIP potential, calculate energy using VASP, retrain.
3. Calculate kappa using LAMMPS.Green-Kubo.

## Notes
Proprietary source files have been removed from `src/`
