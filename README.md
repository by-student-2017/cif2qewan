# cif2qewan
cif2qewan.py is a simple python script to create quantum-ESPRESSO (QE) and wannier90 inputs from cif files.


## Information ######################################
- Tests: QE 7.2 + Python 3.10 on Ubuntu 22.04.1 LTS (WLS2, windows11)
- Need: cif2cell-informal_py3
- Other tools (Now not recommend !!!): Seek-path (AttributeError: module 'pymatgen' has no attribute 'Element' )
- There are times when "primitive cells" work well and times when they don't.
- Adding "r" to "orbitals" in "csv" file changed it to "random". However, the Wannier function does not fit well. "GaAs" didn't work either."Random" doesn't go so well that I think it's a miracle that "Si" goes well.


## Installation ######################################
  1. Install python3, etc, e.g.
  
     % sudo apt update
     
     % sudo apt -y install python3 python3-dev python3-numpy python3-docopt
  
  
  2. Prepare cif2cell-informal_py3. (See for details, https://github.com/by-student-2017/cif2cell-informal_py3.git)
  
  3. Download or clone the github repository, e.g.
  
     % git clone https://github.com/by-student-2017/cif2qewan.git


## Bash script: submit_all.sh (Examples: FeS2) ######################################
A series of calculations can be performed using "submit_all.sh". "submit_all.sh" and "cif2qewan.toml" are currently working in the directory created in Examples.
The two lines immediately after "calculation command:" are from cif2cell, so don't worry about it.

	% cd Examples

	% cd FeS2

	% cp ./../../submit_all.sh ./

	% chmod +x submit_all.sh

	% ./submit_all.sh

	% cd band

	% evince band_compare_narrow.eps


Tips 1: It is recommended to adjust the value of "nexc" in the 3rd column and the trajectory of "orbitals" in the 4th column in "pp_kjpaw_psl100_PBE_user.csv". Adjusting the "number of Kohn-Sham states" of "SCF" and "NSCF" to be close values will shorten the calculation time, and in addition, it will be easier to fit the Wannier function.


Tips 2: If the pseudopotential file name is "spn", the value of "nexc" in the third column of "pp_kjpaw_psl100_PBE_user.csv" starts from 4 (=(s+p)/2=(2+6)/2), and then , increase or decrease to find the best fit. Think of "dn" in the same way (e.g., 5=d/2=10/2 (for projections:s,p), 6=(d+s)/2=(10+2)/2 (for projections:p), 0 (for projections:d)).


## Usage (Step by Step) ######################################
  1. Enter the "cif2qewan" directory.
  
     % cd cif2qewan
  
  
  2. Edit pseudo_dir in cif2qewan.py.
  
  3. Edit path settings in cif2qewan.toml.
  
  4. Run.

     % python3 cif2qewan.py *.cif cif2qewan.toml
  
     % pw.x < scf.in > scf.out
      
     % pw.x < nscf.in > nscf.out
      
     % wannier90.x -pp pwscf
      
     % pw2wannier90.x < pw2wan.in

  5. Edit dis_froz_max in pwscf.win. Recommended value is around EF+1eV ~ EF+3eV.

  6. Wannierize.
  
     % wannier90.x pwscf


## Compare band structures of DFT and wannier90 #####
cif2qewan.py prepares band calculation input files in directory "band".

     % cd band

     % pw.x < ../scf.in > scf.out

	 % pw.x < nscf.in > nscf.out

	 % bands.x < band.in > band.out

	 % cd ..

	 % python3 band_comp.py

Then, you can get the band structure plot of DFT and wannier90.

## Compare band energy of DFT and wannier90 #####
cif2qewan.py prepares nscf input file for energy diffierence.
Wannier90 Hamiltonian should reproduce the band energy on the kmesh for wannierzation. (For example, 8x8x8 mesh including gamma point (8 8 8 0 0 0 in QE expression).)
Here, the code checks the energy difference of DFT and wannier90 on the shifted kmesh. (c.f., 8 8 8 1 1 1 in QE expression))

	% cd check_wannier

	% pw.x < ../scf.in > scf.out

	% pw.x < nscf.in > nscf.out

	% cd ..

	% python3 wannier_conv.py

	% cat check_wannier/CONV

wannier_conv.py calculates the energy differences and outputs the result in check_wannier/CONV.
 "average diff" means $\delta$ defined by

$$ \delta^2 = \frac{1}{N} \sum_{n,k} (e_{n,k}^{DFT} - e_{n,k}^{Wannier})^2 $$


## Reference ######################################

- [Iron-based binary ferromagnets for transverse thermoelectric conversion,  A. Sakai, S. Minami, T. Koretsune et al. Nature 581 53-57 (2020)](https://doi.org/10.1038/s41586-020-2230-z)

  The database of anomalous Hall conductivity and anomalous Nernst conductivity is generated using cif2qewan.py.

- [Systematic first-principles study of the on-site spin-orbit coupling in crystals Phys. Rev. B 102 045109 (2020)](https://doi.org/10.1103/PhysRevB.102.045109)
 
  The spin-orbit couplings are extracted from the tight-binding models generated by cif2qewan.py.
