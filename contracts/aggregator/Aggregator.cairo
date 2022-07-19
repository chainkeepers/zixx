%lang starknet

from starkware.cairo.common.math import unsigned_div_rem
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
const TIMESTAMP_BUFFER = 100

const e = 2
const HALF_LIFE = 3600

@storage_var
func Config_key() -> (value : felt):
end

# mapping source to map (last_state, timestamp)
@storage_var
func state(source : felt) -> (res : (felt, felt)):
end

@storage_var
func state2(source : felt) -> (res : (felt, felt)):
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

    let (key : felt) = Config_key.read()  # 28556963469423460 # eth/usd

    let (price, decimals, timestamp, num_sources_aggregated) = IEmpiricOracle.get_value(
        EMPIRIC_ORACLE_ADDRESS, key, source
    )

    let (res1) = state.read(source)
    let s1 = res1[0]
    let last_ts = res1[1]
    let (res2) = state2.read(source)
    let s2 = res2[0]
    let last_ts2 = res2[1]

    # update source
    let (price2) = pow(price, 2)
    let (a) = pow(e, -(timestamp - last_ts) / HALF_LIFE)
    let (a2) = pow(e, -(timestamp - last_ts2) / HALF_LIFE)
    state.write(source, (a * s1 + (1 - a) * price, timestamp))
    state2.write(source, (a * s2 + (1 - a) * price2, timestamp))

    # emit on update

    let (new_entry) = get_entry(source)

    SubmittedEntry.emit(new_entry)

    return ()
end


#
# Getters
#

@view
func get_entry{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(source : felt) -> (entry : Entry):
    alloc_locals

    # compute value

    let (key) = Config_key.read()
    let (res1) = state.read(source)
    let s1 = res1[0]
    let last_ts = res1[1]
    let (res2) = state2.read(source)
    let s2 = res2[0]
    let last_ts2 = res2[1]

    let (s22) = pow(s2, 2)
    let value = s1 - s22

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


@view
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
        let (all_sources_len, all_sources) = IOracleImplementation.get_all_sources(EMPIRIC_ORACLE_ADDRESS, key)
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


func get_value{
syscall_ptr : felt*,
pedersen_ptr : HashBuiltin*,
range_check_ptr
}(aggregation_mode : felt) -> (
      value : felt,
      decimals : felt,
      last_updated_timestamp : felt,
      num_sources_aggregated : felt
):
    alloc_locals

    assert aggregation_mode = 0  # the default and the only one implemented

    let (entries_len, entries) = get_entries(0, syscall_ptr)

      if entries_len == 0:
          return (0, 0, 0, 0)
      end

      let (value, _) = Entry_entries_mean(entries_len, entries, 0, 0)
      let (last_updated_timestamp) = Entry_aggregate_timestamps_max(entries_len, entries)
      return (value, 0, last_updated_timestamp, entries_len)

end

#
# Library
#

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


func Entry_aggregate_timestamps_max{range_check_ptr}(num_entries : felt, entries_ptr : Entry*) -> (
    last_updated_timestamp : felt
):
    alloc_locals

    let entry_timestamp = [entries_ptr].timestamp
    if num_entries == 1:
        return (entry_timestamp)
    end

    let (rec_last_updated_timestamp) = Entry_aggregate_timestamps_max(
        num_entries - 1, entries_ptr + Entry.SIZE
    )
    let (is_current_entry_last) = is_le(rec_last_updated_timestamp, entry_timestamp)
    if is_current_entry_last == TRUE:
        return (entry_timestamp)
    end
    return (rec_last_updated_timestamp)
end


func Entry_entries_mean{range_check_ptr}(
    num_entries : felt, entries_ptr : Entry*, idx : felt, remainder : felt
) -> (value : felt, remainder : felt):
    alloc_locals
    let running_value = [entries_ptr + idx * Entry.SIZE].value
    let (local summand, new_remainder) = unsigned_div_rem(running_value + remainder, num_entries)
    if idx + 1 == num_entries:
        return (summand, new_remainder)
    end
    let (recursive_summand, recursive_remainder) = Entry_entries_mean(
        num_entries, entries_ptr, idx + 1, new_remainder
    )
    let value = summand + recursive_summand
    return (value, recursive_remainder)
end
