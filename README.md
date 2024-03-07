# parallel implementation of the iterative Jacobi method

### set the env
```bash
julia --project=jenv
```
```julia
]instantiate
```

### run
```julia
include("distr-jacobi.jl")
```

## Results

Tested on HPC VM:
specs:

**CPU: Intel Xeon Gold 6244 @ 3.60GHz**

**nVCPU: 12**

**ОЗУ: 94 Gib**

**OS: openSUSE Leap 15.5 x86_64 GNU/Linux**


|Matrix|SINGLE|2 Core|4 Core|6 Core|8 Core|10 Core|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|$600\times600$|0.0014|0.0021|0.0024|0.0027|0.0033|0.0037|
|$1080\times1080$|0.0048|0.0039|0.0035|0.0036|0.0040|0.0045|
|$2040\times2040$|0.0357|0.0178|0.0105|0.0065|0.0074|0.0074|
|$5040\times5040$|0.1635|0.0761|0.0734|0.0282|0.0384|0.0184|
|$10080\times10080$|1.0791|0.4475|0.1836|0.1517|0.1271|0.0952|
|$25200\times25200$|8.1449|3.2131|1.8372|1.1579|1.1129|0.6414|
|$49680\times49680$|31.0217|15.3617|9.5660|5.4763|5.4366|3.1153|

![](https://raw.githubusercontent.com/raw.githubusercontent.com/shlapique/parallel-linal/master/img/nprcs_to_speedup.png)
