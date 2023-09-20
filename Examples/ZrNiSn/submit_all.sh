#!/bin/bash

export OMP_NUM_THREADS=1
WANNIER90_OMP=5
MPI_PREFIX="mpirun -n 10"
ESPRESSO_DIR=/usr
WANNIER90_DIR=/usr/bin
CIF2QEWAN_DIR=./../../cif2qewan
TOML_FILE=./../../cif2qewan.toml

python3 $CIF2QEWAN_DIR/cif2qewan.py *.cif $TOML_FILE

$MPI_PREFIX $ESPRESSO_DIR/bin/pw.x < scf.in > scf.out
cp -r work check_wannier/
cp -r work band/

$MPI_PREFIX $ESPRESSO_DIR/bin/pw.x < nscf.in > nscf.out
export OMP_NUM_THREADS=$WANNIER90_OMP
$WANNIER90_DIR/wannier90.x -pp pwscf
export OMP_NUM_THREADS=1
$MPI_PREFIX $ESPRESSO_DIR/bin/pw2wannier90.x < pw2wan.in > pw2wan.out
rm -r work

# set dis_froz_max = EF+1eV
ef=$(grep Fermi nscf.out | cut -c27-35)
ef1=$(bc -l <<< "$ef + 1.2")
sed -i "s/dis_froz_max .*/dis_froz_max = $ef1/g" pwscf.win

export OMP_NUM_THREADS=$WANNIER90_OMP
$WANNIER90_DIR/wannier90.x pwscf
export OMP_NUM_THREADS=1

cd check_wannier
$MPI_PREFIX $ESPRESSO_DIR/bin/pw.x < nscf.in > nscf.out
rm -r work
cd ../
python3 $CIF2QEWAN_DIR/wannier_conv.py

cd band
$MPI_PREFIX $ESPRESSO_DIR/bin/pw.x < nscf.in > nscf.out
$MPI_PREFIX $ESPRESSO_DIR/bin/bands.x < band.in > band.out
rm -r work
cd ../

python3 $CIF2QEWAN_DIR/band_comp.py
