#!/usr/bin/python3

from brownie import Token, HOANFT, accounts, network, config


def main():
    dev = accounts.add(config["wallets"]["from_key"])
    print(network.show_active())

    # constructor(uint256 _units, address _royaltiesCollector, string memory _baseURI)
    return HOANFT.deploy(100, accounts[0], "", {'from': accounts[0]})
