%lang starknet

from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.pow import pow
from starkware.starknet.common.syscalls import get_contract_address

from contracts.oracle_controller.IEmpiricOracle import IEmpiricOracle
from contracts.oracle_controller.IOracleController import IOracleController
from contracts.oracle_controller.library import SubmittedEntry
from contracts.entry.structs import Entry

const EMPIRIC_ORACLE_ADDRESS = 0x012fadd18ec1a23a160cc46981400160fbf4a7a5eed156c4669e39807265bcd4

const KEY = 28556963469423460  # str_to_felt("eth/usd")
const AGGREGATION_MODE = 0  # default

@external
func poll() -> ():
    let (entry) = get_entry()
    
    SubmittedEntry.emit(entry)

    return ()
end


@external
func get_decimals(key : felt) -> (decimals : felt):
     return (0)
end


@external
func get_entries(key : felt, sources_len : felt, sources : felt*) -> (
    entries_len : felt, entries : Entry*
):
    return (0, )
end


@external
func get_entry(key : felt, source : felt) -> (entry : Entry):
    let (price, decimals, timestamp, num_sources_aggregated) = IEmpiricOracle.get_entry(
        EMPIRIC_ORACLE_ADDRESS, KEY, AGGREGATION_MODE
    )

    let

    # let (multiplier) = pow(10, decimals)
    # let shifted_threshold = threshold * multiplier
    # let (is_above_threshold) = is_le(shifted_threshold, eth_price)

    let (contract_address) = get_contract_address()

    let new_entry = Entry(
        2053732472,  # key = str_to_felt("zixx")
        10,  # value
        timestamp,  # timestamp
        KEY,  # source
        contract_address,  # publisher = this contract
    )

    return (new_entry)
end


func get_value(key : felt, aggregation_mode : felt) -> (
    value : felt, decimals : felt, last_updated_timestamp : felt, num_sources_aggregated : felt
):
end


func get_value_for_sources(
    key : felt, aggregation_mode : felt, sources_len : felt, sources : felt*
) -> (
    value : felt, decimals : felt, last_updated_timestamp : felt, num_sources_aggregated : felt
):
end


func get_sources(
    key : felt, aggregation_mode : felt, sources_len : felt, sources : felt*
) -> (
    value : felt, decimals : felt, last_updated_timestamp : felt, num_sources_aggregated : felt
):
end
