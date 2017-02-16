# Virtual Machine Sizes

The doAzureParallel package lets you choose the VMs that your code runs on giving you full control over your infrastructure. By default, we start you on an economical, general-purpose VM size called **"Standard_A1_v2"**. 

Each doAzureParallel pool can only comprise of of a collection of one VM size that is selected upon pool creation. Once the pool is created, users cannot change the VM size unless they plan on reprovisioning another pool.

## Setting your VM size 

The VM size is set in the configuration JSON file that is passed into the `registerPool()` method. To set your desired VM size, simply edit the `vmSize` key in the JSON:

```javascript
{
  ...
  "vmSize": <Your Desired VM Size>,
  ...
}
```

## Choosing your VM Size

Azure has a wide variety of VMs that you can choose from. 

### VM Categories

The three recommended VM categories for the doAzureParallel package are:
- Av2-Series VMs
- F-Series VMs
- Dv2-Series VMs

Each VM category also has a variety of VM sizes (see table below).

Generally speaking, the F-Series VM is ideal for compute intensive workloads, the Dv2-Series VMs are ideal for memory intensive workloads, and finally the Av2-Series VMs are economical, general-purpose VMs.

The Dv2-Series VMs and F-Series VMs use the 2.4 GHz Intel Xeon® E5-2673 v3 (Haswell) processor.

### VM Size Table

Please see the below table for a curated list of VM types:

| VM Category | VM Size | Cores | Memory (GB) |
| ----------- | ------- | ----- | ----------- |
| Av2-Series | Standard_A1_v2 | 1 | 2 |
| Av2-Series | Standard_A2_v2 | 2 | 4 |
| Av2-Series | Standard_A4_v2 | 4 | 8 |
| Av2-Series | Standard_A8_v2 | 8 | 16 |
| Av2-Series | Standard_A2m_v2 | 2 | 16 |
| Av2-Series | Standard_A4m_v2 | 4 | 32 |
| Av2-Series | Standard_A8m_v2 | 8 | 64 |
| F-Series | Standard_F1 | 1 | 2 |
| F-Series | Standard_F2 | 2 | 4 |
| F-Series | Standard_F4 | 4 | 8 |
| F-Series | Standard_F8 | 8 | 16 |
| F-Series | Standard_F16 | 16 | 32 |
| Dv2-Series | Standard_D1_v2 | 1 | 3.5 |
| Dv2-Series | Standard_D2_v2 | 2 | 7 |
| Dv2-Series | Standard_D3_v2 | 4 | 14 |
| Dv2-Series | Standard_D4_v2 | 8 | 28 |
| Dv2-Series | Standard_D5_v2 | 16 | 56 |
| Dv2-Series | Standard_D11_v2 | 2 | 14 |
| Dv2-Series | Standard_D12_v2 | 4 | 28 |
| Dv2-Series | Standard_D13_v2 | 8 | 56 |
| Dv2-Series | Standard_D14_v2 | 16 | 112 |

The list above covers most scenarios that run R jobs. For special scenarios (such as GPU accelerated R code) please see the full list of available VM sizes by visiting the Azure VM Linux Sizes page [here](https://docs.microsoft.com/en-us/azure/virtual-machines/virtual-machines-linux-sizes?toc=%2fazure%2fvirtual-machines%2flinux%2ftoc.json#a-series).

To get a sense of what each VM costs, please visit the Azure Virtual Machine pricing page [here](https://azure.microsoft.com/en-us/pricing/details/virtual-machines/linux/).


