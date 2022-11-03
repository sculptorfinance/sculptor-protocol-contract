// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../interfaces/IPriceFeed.sol";
import "../dependencies/openzeppelin/contracts/Ownable.sol";
import "../dependencies/openzeppelin/contracts/SafeMath.sol";

/*
* PriceFeed for mainnet deployment, to be connected to Chainlink's live ETH:USD aggregator reference
* contract, and a wrapper contract bandOracle, which connects to BandMaster contract.
*
* The PriceFeed uses Chainlink as primary oracle, and Band as fallback. It contains logic for
* switching oracles based on oracle failures, timeouts, and conditions for returning to the primary
* Chainlink oracle.
*/
contract MockPriceFeed is IPriceFeed, Ownable {
    using SafeMath for uint256;

    // The last good price seen from an oracle by Liquity
    uint public lastGoodPrice;
    uint public setPrice;

    // --- Dependency setters ---

    constructor() {}

    // --- Functions ---

    /*
    * fetchPrice():
    * Returns the latest price obtained from the Oracle. Called by Liquity functions that require a current price.
    *
    * Also callable by anyone externally.
    *
    * Non-view function - it stores the last good price seen by Liquity.
    *
    * Uses a main oracle (Chainlink) and a fallback oracle (Band) in case Chainlink fails. If both fail,
    * it uses the last good price seen by Liquity.
    *
    */
    function fetchPrice() external view override returns (uint) {
        uint price = _fetchPrice();
        return price;
    }

    function updatePrice() external override returns (uint) {
        uint price = _fetchPrice();
        lastGoodPrice = price;
        return price;
    }

    function setNewPrice(uint newPrice) external onlyOwner {
        setPrice = newPrice;
    }

    function _fetchPrice() internal view returns (uint) {
        uint price = setPrice;
        return price;
    }

}
