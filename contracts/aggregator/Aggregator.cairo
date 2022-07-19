%lang starknet

from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.pow import pow
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_contract_address

from contracts.oracle_controller.IEmpiricOracle import IEmpiricOracle
from contracts.entry.structs import Entry
from contracts.oracle_controller.library import SubmittedEntry

const EMPIRIC_ORACLE_ADDRESS = 0x012fadd18ec1a23a160cc46981400160fbf4a7a5eed156c4669e39807265bcd4


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

    let new_entry = Entry(
        key,
        value,  # value
        0,  # timestamp
        key,  # source
        contract_address,  # publisher = this contract
    )

    return (new_entry)
end
