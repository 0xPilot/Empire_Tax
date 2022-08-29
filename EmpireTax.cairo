%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_nn, unsigned_div_rem

# PI
const PI = 3141592 / 1000000

# Pending tax amount for the empire
@storage_var
func pending_tax_for_empire() -> (res : felt):
end

# Pending tax amount for the kingdom
@storage_var
func pending_tax_for_kingdom() -> (res : felt):
end

# Tax balance of the empire
@storage_var
func tax_balance_for_empire() -> (res : felt):
end

# Tax balance of the kingdom
@storage_var
func tax_balance_for_kingdom() -> (res : felt):
end

# A map from the day to the corresponding the collected tax amount
@storage_var
func taxes(day : felt) -> (res : felt):
end

# Collect the tax
# Update the tax balance for the empire and the kingdom
@external
func collect_tax{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    day : felt, taxAmount : felt
):
    alloc_locals

    # make sure taxAmount is positive
    assert_nn(taxAmount)

    # update the tax amount collected
    let (the_taxes) = taxes.read(day)
    taxes.write(day, the_taxes + taxAmount)

    # update the tax amount for empire and kingdom
    # taxAmount = 1: 1 felt for empire
    # taxAmount = 10: 10 / PI = 3.183 -> 4 felts for empire
    # taxAmount = 1314159: 314159 / PI = 99999.9 -> 100000 felts for empire
    # assume the indivisible curremncy unit is 1 felt
    let (local for_empire, local r) = unsigned_div_rem(taxAmount, PI)
    if r != 0:
        for_empire = for_empire + 1
    end

    # get the tax amount for the empire and the kingdom
    local for_kingdom = taxAmount - for_empire

    # update the tax amount for the empire and the kingdom
    let (the_pending_tax_for_empire) = pending_tax_for_empire.read()
    let (the_pending_tax_for_kingdom) = pending_tax_for_kingdom.read()
    pending_tax_for_empire.write(the_pending_tax_for_empire + for_empire)
    pending_tax_for_kingdom.write(the_pending_tax_for_kingdom + for_kingdom)

    return ()
end

# Withdraw the tax for the empire
@external
func withdrawTaxByEmpire{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    balance : felt
):
    # transfer pending tax amount to the empire
    let (the_pending_tax_for_empire) = pending_tax_for_empire.read()

    pending_tax_for_empire.write(0)
    let (the_tax_balance_for_empire) = tax_balance_for_empire.read()
    let balance = the_tax_balance_for_empire + the_pending_tax_for_empire
    tax_balance_for_empire.write(balance)

    return (balance=balance)
end

# Withdraw the tax for the kingdom
@external
func withdrawTaxByKingdom{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    balance : felt
):
    # transfer pending tax amount to the kingdom
    let (the_pending_tax_for_kingdom) = pending_tax_for_kingdom.read()

    pending_tax_for_kingdom.write(0)
    let (the_tax_balance_for_kingdom) = tax_balance_for_kingdom.read()
    let balance = the_tax_balance_for_kingdom + the_pending_tax_for_kingdom
    tax_balance_for_kingdom.write(balance)

    return (balance=balance)
end
