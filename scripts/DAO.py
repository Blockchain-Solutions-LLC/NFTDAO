#!/usr/bin/python3

from brownie import Token, HOANFT, SimpleToken, accounts, network, config
import time


def main():
    dev = accounts.add(config["wallets"]["from_key"])
    print(network.show_active())

    # constructor(uint256 _units, address _royaltiesCollector, string memory _baseURI)

    # deploy simple token
    st = SimpleToken.deploy("Simple Token", "SIMP", 10**22, {'from': accounts[0]})
    name = st.name()
    symbol = st.symbol()
    ts = st.totalSupply()

    print(f'name, symbol, ts:')
    print(name, symbol, ts)

    hoa = HOANFT.deploy(100, accounts[0], "", st.address, {'from': accounts[0]})
    # tx = hoa.setERC20Address(st.address)
    # tx.wait(1)

    # todo -- make functionality in RelativeTokenHolding, as it is not able to access it directly
    # todo -- fix issue with tree structure; Linearization of inheritance graph impossible
    print(f'ERC20 Addy: {hoa.token()}')

    for i in range(3):
        seconds = hoa.getTimestampEstimate(i, 2023)
        print(f'timestamp for month {i} of 2023: {seconds}')

        # seconds = hoa.getSecondsInGivenMonth(i, 2023)
        # print(f'seconds in month {i} of 2023: {seconds}')
        # seconds.wait(1)

    # create Lease terms
    start_month = 0
    end_month = 12
    start_year = 2022
    end_year = 2022
    unit = 0
    payment_per_period = 1
    period_type = 3 #     enum PeriodType { SECOND, MINUTE, HOUR, DAY, WEEK, MONTH, YEAR, CUSTOM}



    # create terms for lease
    tx = hoa.createLeaseTerms(unit,  start_month,  start_year,  end_month,
         end_year,  payment_per_period, period_type)

    # print(f'events: {tx.events}')

    # accept lease
    tx = hoa.commitToLease(unit) #, start_month, start_year, end_month, end_year)

    # get amount owed
    # use for loop to accellerate one month for 14 months

    rent_due = hoa.getRentDue(unit)
    print(f'rent_due: {rent_due}\n')

    unit_data = hoa.getUnitData(0)
    lease_info = hoa.getLeaseInfo(0)

    print(f'unit_data: {unit_data}')
    print(f'lease_info: {lease_info}')


    # tx = hoa.getRentDue(unit)
    # print(f'events: {tx.events}\n')

    # hoa.getMyRentDue
    my_leases = hoa.getMyLeases()
    print(f'my_leases: {my_leases}')

    my_rent_everywhere = hoa.getMyRentDueEverywhere()
    print(f'my_rent_everywhere: {my_rent_everywhere}')

    for i in range(5):
        print('.', end='')
        time.sleep(1)
    print(' Finished \n')
    return hoa
