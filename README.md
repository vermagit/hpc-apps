# Recipes for HPC Apps
Here are some scripts to automate installation of some popular HPC applications. These have been built and tested on Azure.

[OPM](./build-opm.sh): Install the Open Porous Media reservoir simulator ([OPM](https://opm-project.org/)) for upstream oil & gas E&P.
This builds upon the ([CentOS-HPC VM image](https://techcommunity.microsoft.com/t5/Azure-Compute/CentOS-HPC-VM-Image-for-SR-IOV-enabled-Azure-HPC-VMs/ba-p/665557)) for the SR-IOV enabled ([H-series](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/sizes-hpc)) in Azure. Benchmarks results from running on the ([HB-series](https://docs.microsoft.com/en-us/azure/virtual-machines/workloads/hpc/hb-series-overview)) coming soon.

[GROMACS](./build-gromacs.sh): Install the versatile molecular dynamics package ([GROMACS](http://www.gromacs.org/Downloads)).
This has been tested on the ([Azure NC-series](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/sizes-gpu)) VMs with Ubuntu 18.04.
