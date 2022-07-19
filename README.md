ABOUT
=====

ZIXX is a volatility index oracle based on price feeds of the Empiric network.

For every Empiric price feed there is a ZIXX contract deployed which provides
the oracle with the volatility index.

Keepers have to call update() on every ZIXX oracle regularly so that it updates.

Users subscribe to the SubmittedEntry event to consume the output or act upon
index changes.  This makes integration strightforward with no need of
understanding the internals of how is the index calculated or when it might
change.  It is simply enough to rely on the events emitted by the oracle.

There is a contract deployed for the ETH/USD feed at

0x068708a64989f68275bacc2a7870417559bff88f348616476d9e2e07637bc019


USAGE
=====

Update the ETH/USD oracle using on-chain prices from the Empiric price feed

  starknet invoke --address 0x068708a64989f68275bacc2a7870417559bff88f348616476d9e2e07637bc019 --abi artefacts/Aggregator.json --function get_entry --input 6714488

Query the squared volatility index from ZIXX using command line

  starknet call --address 0x068708a64989f68275bacc2a7870417559bff88f348616476d9e2e07637bc019 --abi artefacts/Aggregator.json --function get_value

Query the squared volatility index from ZIXX using command line based on data
from a single Empiric source

  starknet call --address 0x068708a64989f68275bacc2a7870417559bff88f348616476d9e2e07637bc019 --abi artefacts/Aggregator.json --function get_entry --input 6714488

Note that

  6714488 = str_to_felt("ftx")


DEVELOPMENT
===========

```
# compilation
starknet-compile --cairo_path=../../ aggregator/Aggregator.cairo --output outputs/aggregator_compiled.json --abi abis/aggregator_abi.json

# declaration
starknet declare --contract outputs/aggregator_compiled.json --network=alpha-goerli

# deployment
starknet deploy --contract outputs/aggregator_compiled.json --network=alpha-goerli --inputs 1234
```
