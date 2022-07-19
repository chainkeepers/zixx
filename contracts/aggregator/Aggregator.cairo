%lang starknet

from starkware.cairo.common.math_cmp import is_le, is_not_zero
from starkware.cairo.common.pow import pow
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import get_contract_address, get_block_timestamp

from contracts.oracle_controller.IEmpiricOracle import IEmpiricOracle
from contracts.oracle_controller.library import SubmittedEntry
from contracts.oracle_implementation.IOracleImplementation import IOracleImplementation
from contracts.entry.structs import Entry

const EMPIRIC_ORACLE_ADDRESS = 0x012fadd18ec1a23a160cc46981400160fbf4a7a5eed156c4669e39807265bcd4
const EMPIRIC_ORACLE_IMPLEMENTATION_ADDRESS = 0x05a88457f9292d0596090300713e80724631024e7a92989302d458271c98cad4
const TIMESTAMP_BUFFER = 100


@storage_var
func Config_key() -> (value : felt):
end

@storage_var
func state(source : felt) -> (value : felt):
end

@storage_var
func state2(source : felt) -> (value : felt):
end



#
# Constructor
#

@constructor
func constructor{
     syscall_ptr : felt*,
     pedersen_ptr : HashBuiltin*,
     range_check_ptr
}(key : felt):

    Config_key.write(key)

    return ()
end

#
# Updaters
#

@external
func update{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(source: felt):
    alloc_locals

    let (key) = Config_key.read()  # 28556963469423460 # eth/usd

    let (price, decimals, timestamp, num_sources_aggregated) = IEmpiricOracle.get_value(
        EMPIRIC_ORACLE_ADDRESS, key, source
    )

    let (s1) = state.read(source)
    let (s2) = state2.read(source)

    # update source
    let (price2) = pow(price, 2)
    state.write(source, s1 + price)
    state2.write(source, s2 + price2)

    # emit on update

    let (new_entry) = get_entry(source)

    SubmittedEntry.emit(new_entry)

    return ()
end


#
# Getters
# 

@external
func get_entry{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(source : felt) -> (entry : Entry):
    alloc_locals

    # compute value

    let (key) = Config_key.read()
    let (s1) = state.read(source)
    let (s2) = state2.read(source)

    let (s22) = pow(s2, 2)
    let (value) = pow(s1 - s22, 1/2)

    # construct response

    let (contract_address) = get_contract_address()
    let (current_timestamp) = get_block_timestamp()

    let new_entry = Entry(
        key,
        value,  # value
        current_timestamp,  # timestamp
        key,  # source
        contract_address,  # publisher = this contract
    )

    return (new_entry)
end


func get_entries{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(sources_len : felt, sources : felt*) -> (entries_len : felt, entries : Entry*):
    alloc_locals

    # compute value

    let (key) = Config_key.read()
    let (entries : Entry*) = alloc()

    if sources_len == 0:
        let (all_sources_len, all_sources) = IOracleImplementation.get_all_sources(EMPIRIC_ORACLE_IMPLEMENTATION_ADDRESS, key)
        let (entries_len, entries) = Oracle_build_entries_array(
            key, all_sources_len, all_sources, 0, 0, entries
        )
    else:
        let (entries_len, entries) = Oracle_build_entries_array(
            key, sources_len, sources, 0, 0, entries
        )
    end

    return (entries_len, entries)
end


func Oracle_build_entries_array{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    key : felt,
    sources_len : felt,
    sources : felt*,
    sources_idx : felt,
    entries_idx : felt,
    entries : Entry*,
) -> (entries_len : felt, entries : Entry*):
    alloc_locals

    if sources_idx == sources_len:
        let entries_len = entries_idx  # 0-indexed
        return (entries_len, entries)
    end

    let source = [sources + sources_idx]
    let (entry) = get_entry(source)
    let (is_entry_initialized) = is_not_zero(entry.timestamp)
    let not_is_entry_initialized = 1 - is_entry_initialized
    let (current_timestamp) = get_block_timestamp()
    let (is_entry_stale) = is_le(entry.timestamp, current_timestamp - TIMESTAMP_BUFFER)
    let (should_skip_entry) = is_not_zero(is_entry_stale + not_is_entry_initialized)

    if should_skip_entry == TRUE:
        let (entries_len, entries) = Oracle_build_entries_array(
            key, sources_len, sources, sources_idx + 1, entries_idx, entries
        )
        return (entries_len, entries)
    end

    assert [entries + entries_idx * Entry.SIZE] = entry

    let (entries_len, entries) = Oracle_build_entries_array(
        key, sources_len, sources, sources_idx + 1, entries_idx + 1, entries
    )
    return (entries_len, entries)
end
