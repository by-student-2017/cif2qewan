#!/bin/bash

#----------------------------------------------------------------------
ESPRESSO_DIR=/usr
WANNIER90_DIR=/usr/bin
CIF2QEWAN_DIR=./../../
TOML_FILE=./../../cif2qewan.toml
#----------------------------------------------------------------------
# For dis_froz_max = EF + ${Expand_E} eV from nscf.out, Expand_E is about 1.0 to 3.0 [eV].
Expand_E=1.0
# For dis_froz_min = EF ${Bottom_E_from_EF} eV from nscf.out, Bottom_E_from_EF is about -12.0 [eV]
Bottom_E_from_EF=-12.0
#----------------------------------------------------------------------
# 0 is auto setting
NCORE=0
NTHRE=0
#----------------------------------------------------------------------

#----------------------------------------------------------------------
if [ $NCORE = 0 ]; then
  NCORE=`lscpu -b -p=Core,Socket | grep -v '^#' | sort -u | wc -l`
fi
if [ $NTHRE = 0 ]; then
  NTHRE=$(bc <<< "$NCORE/2")
fi
echo "----------------------------------------------------------------"
echo "MPI    for main (except wannier90.x): "$NCORE" cores"
echo "OpenMP for wannier90.x              : "$NTHRE" threads"
#----------------------------------------------------------------------
export OMP_NUM_THREADS=1
WANNIER90_OMP=$NTHRE
#----------------------------------------------------------------------
MPI_PREFIX="mpirun -n $NCORE"
#----------------------------------------------------------------------

echo "----------------------------------------------------------------"
echo "cif2qewan calculation"
echo "python3 $CIF2QEWAN_DIR/cif2qewan.py *.cif $TOML_FILE"
date
echo "----Note-------------------------------------"
echo "The two lines immediately below [calculation command:] are "
echo "the output of [cif2cell-informal_py3], so ignore them."
echo "---------------------------------------------"
python3 $CIF2QEWAN_DIR/cif2qewan.py *.cif $TOML_FILE
echo "----------------------------------------------------------------"

echo "----------------------------------------------------------------"
echo "SCF calculation"
echo "$MPI_PREFIX $ESPRESSO_DIR/bin/pw.x < scf.in > scf.out"
date
$MPI_PREFIX $ESPRESSO_DIR/bin/pw.x < scf.in > scf.out
grep -n "number of Kohn-Sham states" scf.out
cp -r work check_wannier/
cp -r work band/
echo "----------------------------------------------------------------"

echo "----------------------------------------------------------------"
echo "NSCF calculation"
echo "$MPI_PREFIX $ESPRESSO_DIR/bin/pw.x < nscf.in > nscf.out"
date
$MPI_PREFIX $ESPRESSO_DIR/bin/pw.x < nscf.in > nscf.out
grep -n "number of Kohn-Sham states" nscf.out
echo "----------------------------------------------------------------"

echo "----------------------------------------------------------------"
echo "wannier90 settings"
echo "$WANNIER90_DIR/wannier90.x -pp pwscf"
grep -n "num_bands" pwscf.win
grep -n "num_wann" pwscf.win
grep -n "exclude_bands" pwscf.win
echo "num_bands = nbnd (nscf) - exclude_bands"
date
export OMP_NUM_THREADS=$WANNIER90_OMP
$WANNIER90_DIR/wannier90.x -pp pwscf
echo "Note: nscf results + pwscf.win -> pwscf.nnkp"
echo "----------------------------------------------------------------"

echo "----------------------------------------------------------------"
echo "pw2wannier90 calculation"
echo "$MPI_PREFIX $ESPRESSO_DIR/bin/pw2wannier90.x < pw2wan.in > pw2wan.out"
date
export OMP_NUM_THREADS=1
$MPI_PREFIX $ESPRESSO_DIR/bin/pw2wannier90.x < pw2wan.in > pw2wan.out
rm -r work
echo "output files: pwscf.amn, pwscf.mmn and pwscf.eig"
echo "----------------------------------------------------------------"

echo "----------------------------------------------------------------"
echo "set dis_froz_max = EF + ${Expand_E} eV from nscf.out"
echo "set dis_froz_min = EF ${Bottom_E_from_EF} eV from nscf.out"
date
ef=$(grep Fermi nscf.out | cut -c27-35)
ef1=$(bc -l <<< "$ef + ${Expand_E}")
efb=$(bc -l <<< "$ef + ${Bottom_E_from_EF}")
sed -i "s/dis_froz_max .*/dis_froz_max = $ef1/g" pwscf.win
sed -i "s/dis_froz_min .*/dis_froz_min = $efb/g" pwscf.win
echo "--------------------------------"
grep -n "dis_froz_max" pwscf.win
echo "Fermi energy: "$ef" [eV]"
grep -n "dis_froz_min" pwscf.win
echo "--------------------------------"
echo "----------------------------------------------------------------"

echo "----------------------------------------------------------------"
echo "wannier90 calculation"
echo "$WANNIER90_DIR/wannier90.x pwscf"
date
export OMP_NUM_THREADS=$WANNIER90_OMP
$WANNIER90_DIR/wannier90.x pwscf
export OMP_NUM_THREADS=1
echo "Note: pwscf.amn + pwscf.mmn + pwscf.eig + pwscf.win -> output files"
echo "----------------------------------------------------------------"

echo "----------------------------------------------------------------"
echo "NSCF calculation (check_wannier)"
echo "$MPI_PREFIX $ESPRESSO_DIR/bin/pw.x < nscf.in > nscf.out"
date
cd check_wannier
$MPI_PREFIX $ESPRESSO_DIR/bin/pw.x < nscf.in > nscf.out
rm -r work
cd ../
echo "----------------------------------------------------------------"

echo "----------------------------------------------------------------"
echo "wannier_conv calculation"
echo "python3 $CIF2QEWAN_DIR/wannier_conv.py"
date
python3 $CIF2QEWAN_DIR/wannier_conv.py
echo "----------------------------------------------------------------"

echo "----------------------------------------------------------------"
echo "Band calculation"
echo "$MPI_PREFIX $ESPRESSO_DIR/bin/pw.x < nscf.in > nscf.out"
echo "$MPI_PREFIX $ESPRESSO_DIR/bin/bands.x < band.in > band.out"
date
cd band
$MPI_PREFIX $ESPRESSO_DIR/bin/pw.x < nscf.in > nscf.out
$MPI_PREFIX $ESPRESSO_DIR/bin/bands.x < band.in > band.out
rm -r work
cd ../
echo "----------------------------------------------------------------"

echo "----------------------------------------------------------------"
echo "band_comp calculation"
echo "python3 $CIF2QEWAN_DIR/band_comp.py"
date
python3 $CIF2QEWAN_DIR/band_comp.py
echo "----------------------------------------------------------------"

echo "----------------------------------------------------------------"
echo "End"
date
echo $'\a' # If you want to play the ending sound, delete the "#" at the beginning of this sentence.
echo "----------------------------------------------------------------"