ABOUT
=====

This is a synthetic oracle for the Empiric network.


```
# compilation
starknet-compile --cairo_path=../../ aggregator/Aggregator.cairo --output outputs/aggregator_compiled.json --abi abis/aggregator_abi.json

# declaration
starknet declare --contract outputs/aggregator_compiled.json --network=alpha-goerli

# deployment
starknet deploy --contract outputs/aggregator_compiled.json --network=alpha-goerli --inputs 1234
```
