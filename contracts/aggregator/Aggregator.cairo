%lang starknet

from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.pow import pow
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin

from empiric.contracts.oracle_controller.IEmpiricOracle import IEmpiricOracle

const EMPIRIC_ORACLE_ADDRESS = 0x012fadd18ec1a23a160cc46981400160fbf4a7a5eed156c4669e39807265bcd4
const KEY = 28556963469423460  # str_to_felt("eth/usd")

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
}(source: felt) -> (s1 : felt, s2 : felt):
    alloc_locals

    let key = Config_key.read()  # 28556963469423460 # eth/usd

    let (price, decimals, timestamp, num_sources_aggregated) = IEmpiricOracle.get_value(
        EMPIRIC_ORACLE_ADDRESS, key, source
    )

    let s1 = state.read(source)
    let s2 = state2.read(source)

    # update source
    state.write(source, s1.value + price)
    state2.write(source, s2.value + price)

    return (s1.value + price, s2.value + price)
end
