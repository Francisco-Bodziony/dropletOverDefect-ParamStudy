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
#SBATCH -A project0020513
#SBATCH -n 96
#SBATCH --mem-per-cpu=5000 
#SBATCH -t 1-12:00:00
################################################################

cd "${1}" || exit 
# Source tutorial run functions
. $LBAMR_PROJECT/scripts/moreRunFunctions
#. $PFM_PROJECT/scripts/moreRunFunctions

export FOAM_CODE_TEMPLATES=$LBAMR_PROJECT/etc/codeTemplates
#trap exit INT

ml gcc/8.3.1
ml openmpi/4.0.3


source /home/fb12pisy/foam/foam-extend-5.0/etc/bashrc
#sleep 1
ml openucx/1.10.1


# Mesh generation and checking
generateMeshAndCheck() {
    runApplication blockMesh
    #runApplication snappyHexMesh -overwrite

    #runApplication checkMesh
    #runApplication funkySetBoundaryField -time 0
    #runApplication funkySetFields -time 0 -dictExt Water
    #runApplication -a funkySetFields -time 0 -dictExt Air
}

# Set fields and update mesh
# $2 is typically "-a" for "append to the logs"
initializeCase() {
    maxRefinement=`cat constant/dynamicMeshDict | grep 'maxRefinement' | tr -s ' ' | cut -d ' ' -f3 | tr -d ';' | tail -n1`
    refinementInterval=`cat constant/dynamicMeshDict | grep 'refinementInterval' | tr -s ' ' | cut -d ' ' -f3 | tr -d ';' | tail -n1`

    sed -i "s/refineInterval[[:space:]]\+[0-9]\+/refineInterval 1/" "constant/dynamicMeshDict"
    #runApplication decomposePar -cellDist -copyUniform 
    
    for i in $( seq 1 $maxRefinement )
    do
        #$1 $2 funkySetBoundaryField -time 0
        runApplication -a funkySetFields -time 0 -dictExt Water
        runApplication -a funkySetFields -time 0 -dictExt Air
        runApplication -a funkySetBoundaryField -time 0

        runApplication -a updateMesh -overwrite
    done

        runApplication -a funkySetFields -time 0 -dictExt Water
        runApplication -a funkySetFields -time 0 -dictExt Air
        runApplication -a funkySetBoundaryField -time 0
        sed -i "s/refineInterval[[:space:]]\+[0-9]\+/refineInterval 75/" "constant/dynamicMeshDict"

}

cp -rT 0.orig 0
generateMeshAndCheck 
initializeCase
decomposePar -force -cellDist -copyUniform 
for i in processor*; do ln -s $PWD/constant $PWD/$i/constant; done
MPI_BUFFER_SIZE=800000000
mpirun -np 96 phaseFieldFoam -parallel >log.phaseFieldFoam
reconstructParMesh
