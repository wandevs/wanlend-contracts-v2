pragma solidity ^0.5.16;

import "./CErc20.sol";
import "./CToken.sol";
import "./PriceOracle.sol";
import "./Comptroller.sol";
import "./SafeMath.sol";

interface V1PriceOracleInterface {
    function assetPrices(address asset) external view returns (uint);
}

contract PriceOracleProxy is PriceOracle {
    using SafeMath for uint256;

    /**
     * @notice The v1 price oracle, which will continue to serve prices for v1 assets
     */
    V1PriceOracleInterface public v1PriceOracle;

    /**
     * @notice The comptroller which is used to white-list assets the proxy will price
     * @dev Assets which are not white-listed will not be priced, to defend against abuse
     */
    Comptroller public comptroller;

    /**
     * @notice address of the cEther contract, which has a constant price
     */
    // address public cWanAddress;

    /**
     * @notice Indicator that this is a PriceOracle contract (for inspection)
     */
    bool public constant isPriceOracle = true;

    /**
     * @param comptroller_ The address of the comptroller, which will be consulted for market listing status
     * @param v1PriceOracle_ The address of the v1 price oracle, which will continue to operate and hold prices for collateral assets
     */
    constructor(address comptroller_,
                address v1PriceOracle_//,
                // address cWanAddress_
               ) public {
        comptroller = Comptroller(comptroller_);
        v1PriceOracle = V1PriceOracleInterface(v1PriceOracle_);

        // cWanAddress = cWanAddress_;
    }

    /**
     * @notice Get the underlying price of a listed cToken asset
     * @param cToken The cToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(CToken cToken) public view returns (uint) {
        address cTokenAddress = address(cToken);
        (bool isListed,, ) = comptroller.markets(cTokenAddress);

        if (!isListed) {
            // not white-listed, worthless
            return 0;
        }

        // if (cTokenAddress == cWanAddress) {
        //     // ether always worth 1
        //     return 1e18;
        // }
        // otherwise just read from v1 oracle
        // address underlying = CErc20(cTokenAddress).underlying();
        // return v1PriceOracle.assetPrices(underlying);
        return v1PriceOracle.assetPrices(address(cToken));
    }
}
