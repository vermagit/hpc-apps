# Recipes for HPC Apps
Here are some scripts to automate installation of some popular HPC applications. These have been built and tested on Azure.

## [OPM](./build-opm.sh)
Install the Open Porous Media reservoir simulator [OPM](https://opm-project.org/) for upstream oil & gas E&P.
This builds upon the [CentOS-HPC VM image](https://techcommunity.microsoft.com/t5/Azure-Compute/CentOS-HPC-VM-Image-for-SR-IOV-enabled-Azure-HPC-VMs/ba-p/665557) for the SR-IOV enabled [H-series](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/sizes-hpc) in Azure. Benchmarks results from running on the [HB-series](https://docs.microsoft.com/en-us/azure/virtual-machines/workloads/hpc/hb-series-overview) coming soon.

Build and run with
```
bash build-opm.sh 2>&1 | tee build-opm.log
```
```
mpirun --allow-run-as-root -np 15 --map-by numa --bind-to core --report-bindings -mca pml ucx --mca btl self,vader,openib -x UCX_NET_DEVICES=mlx5_0:1 -x UCX_IB_PKEY=<pkey> <path-to-opm>/opm-simulators/build/bin/flow --parameter-file=./param
```
where the parameter file `param` can be constructed as follows. More details on running OPM [here](https://opm-project.org/wp-content/uploads/2019/06/OPM_Flow_Documentation_2019-04_Rev-0.pdf).
```
ecl-deck-file-name=NORNE_ATW2013.DATA
output-dir=out_parallel
output-mode=none
output-interval=10000
threads-per-process=4
```

## [GROMACS](./build-gromacs.sh)
Install the versatile molecular dynamics package [GROMACS](http://www.gromacs.org/Downloads).
This has been tested on the [Azure NC-series](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/sizes-gpu) VMs with Ubuntu 18.04.

Build and run with
```
bash build-gromacs.sh 2>&1 | tee build-gromacs.log
```
```
<path-to-gromacs>/gmx mdrun -ntmpi 4 -ntomp 6 -resethway -noconfout -nsteps 5000 -v -pin on -nb gpu
```
