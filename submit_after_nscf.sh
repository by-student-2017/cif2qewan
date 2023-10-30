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
if [ $NCORE == 0 ]; then
  NCORE=`lscpu -b -p=Core,Socket | grep -v '^#' | sort -u | wc -l`
fi
if [ $NTHRE == 0 ]; then
  NTHRE=$(bc <<< "$NCORE/2")
fi
echo "----------------------------------------------------------------"
echo "MPI    for main (except wannier90.x): "$NCORE" cores"
echo "OpenMP for wannier90.x              : "$NTHRE" threads"
#----------------------------------------------------------------------
export OMP_NUM_THREADS=1
WANNIER90_OMP=$NTHRE
#----------------------------------------------------------------------
MPI_PREFIX="mpirun -np $NCORE"
#----------------------------------------------------------------------

echo "----------------------------------------------------------------"
echo "restart after NSCF calculation"
echo "Prepare [work_nscf] as [work]. (mv work_nscf work)"
mv work_nscf work
echo "----------------------------------------------------------------"

echo "----------------------------------------------------------------"
echo "wannier90 settings (To generate a list of the required overlaps (written into the pwscf.nnkp))"
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
echo "pw2wannier90 calculation (To compute the overlaps between Bloch states and"
echo "  the projections for the starting guess (pwscf.amn and pwscf.mmn))"
echo "$MPI_PREFIX $ESPRESSO_DIR/bin/pw2wannier90.x < pw2wan.in > pw2wan.out"
date
export OMP_NUM_THREADS=1
$MPI_PREFIX $ESPRESSO_DIR/bin/pw2wannier90.x < pw2wan.in > pw2wan.out
mv work work_nscf
echo "output files: pwscf.amn, pwscf.mmn and pwscf.eig"
echo "pwscf.amn: Projection A^(k) of the Bloch states onto a set of traial localized orbitals"
echo "pwscf.mmn: The overlap matrices M^(k,b)"
echo "pwscf.eig: The Bloch eigenvalues at each k-point. For interpolation only."
echo "----------------------------------------------------------------"

echo "----------------------------------------------------------------"
echo "set dis_froz_max = EF + ${Expand_E} eV from nscf.out"
echo "set dis_froz_min = EF ${Bottom_E_from_EF} eV from nscf.out"
date
ef=$(grep Fermi nscf.out | cut -c27-35)
efu=$(bc -l <<< "$ef + ${Expand_E} + 20")
ef1=$(bc -l <<< "$ef + ${Expand_E}")
efb=$(bc -l <<< "$ef + ${Bottom_E_from_EF}")
#sed -i "s/dis_win_max .*/dis_win_max = $efu/g" pwscf.win
#sed -i "s/dis_win_min .*/dis_win_min = $efb/g" pwscf.win
sed -i "s/dis_froz_max .*/dis_froz_max = $ef1/g" pwscf.win
sed -i "s/dis_froz_min .*/dis_froz_min = $efb/g" pwscf.win
echo "--------------------------------"
#grep -n "dis_win_max" pwscf.win
grep -n "dis_froz_max" pwscf.win
echo "Fermi energy: "$ef" [eV]"
grep -n "dis_froz_min" pwscf.win
#grep -n "dis_win_min" pwscf.win
echo "--------------------------------"
echo "----------------------------------------------------------------"

echo "----------------------------------------------------------------"
echo "wannier90 calculation (To compute the Maximally-Localised Wannier Functions (MLWFs))"
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
#rm -r work
cd ../
echo "----------------------------------------------------------------"

echo "----------------------------------------------------------------"
echo "wannier_conv calculation"
echo "python3 $CIF2QEWAN_DIR/wannier_conv.py"
date
python3 $CIF2QEWAN_DIR/wannier_conv.py
echo "----------------------------------------------------------------"

#echo "----------------------------------------------------------------"
#echo "Band calculation"
#echo "$MPI_PREFIX $ESPRESSO_DIR/bin/pw.x < nscf.in > nscf.out"
#echo "$MPI_PREFIX $ESPRESSO_DIR/bin/bands.x < band.in > band.out"
#date
#cd band
#$MPI_PREFIX $ESPRESSO_DIR/bin/pw.x < nscf.in > nscf.out
#$MPI_PREFIX $ESPRESSO_DIR/bin/bands.x < band.in > band.out
#rm -r work
#cd ../
#echo "----------------------------------------------------------------"

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