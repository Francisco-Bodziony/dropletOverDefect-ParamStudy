#!/bin/sh
#################################################################
## Example for a parallel job array, specified by -a option
## e.g. -a 1-5%1 starts an array of 5 batch jobs of which
## only 1 is allowed to run at the same time.
## Further options:
## -J Job_Name
## -p Name_Queue, e.g. short (30min max.), deflt (24h max.)
## -o Name_Output file
## -e Name_Error file
## -n Number of tasks (CPU) (parallelization)
## --mem-per-cpu=xy Memory per cpu in MB (mandatory option!)
##(note: if you specify not enough memory the job will be killed)
## -t Walltime, e.g 24h for deflt queue
#################################################################
#SBATCH -J droplet
#SBATCH --mail-type=ALL
#SBATCH -o out.%A_%a
#SBATCH -e err.%A_%a
#SBATCH -A project02078
#SBATCH -n 192
#SBATCH --mem-per-cpu=5000 
#SBATCH -t 00:10:00
################################################################

ml gcc/8.3.1
ml openmpi/4.0.3

cd ./
source /home/fb12pisy/foam/foam-extend-5.0/etc/bashrc
sleep 1
ml openucx/1.10.1

MPI_BUFFER_SIZE=800000000
./Allrun -p
mpirun -np 192 phaseFieldFoam -parallel >log.phaseFieldFoam
return 0
