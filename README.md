# deep-skip-thoughts

**This project is stopped because the model is a little out-of-date in research area about sequence-to-sequence.**

This is a brutal Torch implementation of [Skip-Thought Vectors](http://arxiv.org/abs/1506.06726). The original implementation is at [here](https://github.com/ryankiros/skip-thoughts). You may read the paper for more details.

My implementation is different from Ryan Kiros's at some points such as the optimizer and data processing but the main architecture is similar. Mutil-layer is supported for better result - This is why I add a **deep** before skip-thoughts.
There may be some problems in my code and it's result haven't be tested by now. But you can try this bleeding-edge code if you wish. 

By the way, the code is boring and lengthy because I define five small modules and concate them together. One embedding layer and four RNNs are trained seperately in similar manner.

Most of the code is borrowed from [Andrej Karpathy's Char-Rnn](https://github.com/karpathy/char-rnn). Thanks for Andrej.


## Requirements

This code is written in Lua and requires [Torch](http://torch.ch/).
Additionally, you need to install the `nngraph` and `optim` packages using [LuaRocks](https://luarocks.org/) which you will be able to do after installing Torch:

```bash
$ luarocks install nngraph 
$ luarocks install optim
```

If you'd like to use CUDA GPU computing, you'll first need to install the [CUDA Toolkit](https://developer.nvidia.com/cuda-toolkit), then the `cutorch` and `cunn` packages:

```bash
$ luarocks install cutorch
$ luarocks install cunn
```


## Usage

The following command will tell you everything to do.

```bash
$ th rnn2rnn.lua --help
```
