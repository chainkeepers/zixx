sudo apt install -y libgmp3-dev

cairo-compile contracts/test.cairo --output build/test.json


cairo-run --program=build/test.json --print_output --print_info --relocate_prints

STARKNET

Do the setup.

export STARKNET_WALLET=starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount
export STARKNET_NETWORK=alpha-goerli

Deploy an account.

starknet deploy_account --network=alpha-goerli

ondra@leto zixx $ starknet deploy_account --network=alpha-goerli
Sent deploy account contract transaction.

NOTE: This is a modified version of the OpenZeppelin account contract. The signature is computed
differently.

Contract address: 0x0473f62622d6bb64fe8d8576add7d13d9ff41509eb7dea108268cf0c6a10bdda
Public key: 0x06d008bb5a90377fd9f5df41fc08e98b120cb3b332a9ee481ad9dd42532de3c1
Transaction hash: 0x246d40f087f3682e218e5dc18e7d42204bf9e71c2a9aed9f56d69e87a66eef7



starknet-compile --cairo_path=../empiric/ contracts/read.cairo --output build/read.json --abi=artefacts/read.json

Declare a contract.  This is no necessary as deploy does that automatically if needed.

starknet declare --network=alpha-goerli --contract build/read.json

ondra@leto zixx $ starknet declare --network=alpha-goerli --contract build/read.json
Declare transaction was sent.
Contract class hash: 0x529bbf81739c3b3de578d962da9d86fd41d3a8a0815ebc07ce802797d3ace7d
Transaction hash: 0x357e6de06e13137d47d93c927c23a0d8d8f0f1d88cee9cf8a6e468e99c689e2

Deploy the contract.

starknet deploy --network=alpha-goerli --contract build/read.json

ondra@leto zixx $ starknet deploy --network=alpha-goerli --contract build/read.json
Deploy transaction was sent.
Contract address: 0x04f5150dd172543c88cebae0082f2619d33c254ddcd6b8cd63cc12134dae12a0
Transaction hash: 0x7813fd2d63bb74eef05666973a63108a8be5f527d0530f8c1182c63e5ef1b59

# you need to have your wallet account deployed first

ondra@leto zixx $ starknet deploy --network=alpha-goerli --contract build/read.json
Deploy transaction was sent.
Contract address: 0x054b1bd5fed26345e813fffa6dba5fcba94aa4809d80ec9aaf50eb830d2caf07
Transaction hash: 0x1aaecac87a9f13cff4e506a57172746f17e1ba7a76e14157752be5e00a43f5

The example "read.cairo" works...

ondra@leto zixx $ starknet call --address 0x04f5150dd172543c88cebae0082f2619d33c254ddcd6b8cd63cc12134dae12a0 --abi artefacts/read.json --function check_eth_usd_threshold --network=alpha-goerli --inputs 10000 --max_fee 1 
0
ondra@leto zixx $ starknet call --address 0x04f5150dd172543c88cebae0082f2619d33c254ddcd6b8cd63cc12134dae12a0 --abi artefacts/read.json --function check_eth_usd_threshold --network=alpha-goerli --inputs 10 --max_fee 1 
1

# Publishing

Serializations are apparantly done in startnet.py from named tuples representing structs.

It "publish_entry" sent to the oracle controller address.  This is done by
cross-contract invocation.

ondra@leto zixx $ starknet deploy --contract build/provide.json
Deploy transaction was sent.
Contract address: 0x029cadc9b0b737f591abac16bad18e74d62c2ade00f7d832af637dfc06252ba2
Transaction hash: 0x4eaf405bfcce7c06ce7625e4c0c7913af468539f368dafd18d45e57abe136c1

---

List all sources for a key

IOracleImplementation.get_all_sources(key)
