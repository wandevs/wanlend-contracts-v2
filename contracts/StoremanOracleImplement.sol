pragma solidity ^0.5.16;

import "./Exponential.sol";
import "./CToken.sol";

interface V1PriceOracleInterface {
    function assetPrices(address asset) external view returns (uint);
}

contract OracleStorage {
  /// @notice symbol -> price,
  constructor() public {
        
    }
  mapping(bytes32 => uint) public mapPrices;
  function getValue(bytes32 key) external view returns (uint);
}

contract StoremanOracleImplement is Exponential, V1PriceOracleInterface {

    address public owner;
    address public stormanOracle;
    mapping(address => bytes32) public _assetPrices;

    constructor(address _stormanOracle) public {
        owner = msg.sender;
        stormanOracle = _stormanOracle;
    }

    function() payable external {
        revert();
    }
    
    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    // function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
    //     assembly {
    //        result := mload(add(source, 32))
    //     }
    // }
    /**
      * @notice retrieves price of an asset
      * @dev function to get price for an asset
      * @param asset Asset for which to get the price
      * @return uint mantissa of asset price (scaled by 1e18) or zero if unset or contract paused
      */
    function assetPrices(address asset) public view returns (uint) {

        string memory symbol;

        CToken ct = CToken(asset);
        symbol = ct.symbol();
        
        // if(keccak256(abi.encodePacked(symbol)) == keccak256("WAN")) return 1e18;
        if(keccak256(abi.encodePacked(ct.name())) == keccak256("w2WAN")) return 1e18;

        CErc20Storage cerc20 = CErc20Storage(asset);
        EIP20Interface erc20 = EIP20Interface(cerc20.underlying());
        symbol = erc20.symbol();
        uint decimals = erc20.decimals();

        bytes32 key = stringToBytes32(symbol);
        bytes32 wanKey = stringToBytes32("WAN");
        
        OracleStorage oracleStorage = OracleStorage(stormanOracle);
        uint readValue = oracleStorage.getValue(key);
        uint readValueWan = oracleStorage.getValue(wanKey);

        Exp memory invertedVal;
        MathError error;
        uint256 scale;
        if(decimals > 18) {
            scale = 10**(decimals - 18);

            (error, invertedVal) = divScalar(Exp({mantissa: readValue}), scale);
            if (error != MathError.NO_ERROR) {return 0;}

        }
        else {
            scale = 10**(18-decimals);

            (error, invertedVal) = mulScalar(Exp({mantissa: readValue}), scale);
            if (error != MathError.NO_ERROR) {return 0;}

            
        }
        
        (error, invertedVal) = getExp(invertedVal.mantissa, uint256(readValueWan));
            
        if (error != MathError.NO_ERROR) {return 0;}

        // (MathError error, Exp memory invertedVal) = getExp(readValue, uint256(readValueWan));

        // if (error != MathError.NO_ERROR) {return 0;}

        return invertedVal.mantissa;
    }

    function getKey(address asset)public view returns (bytes32){
        string memory symbol;
        
        CToken ct = CToken(asset);
        if(keccak256(abi.encodePacked(ct.name())) == keccak256("w2WAN")) symbol = "WAN";
        else{
            CErc20Storage cerc20 = CErc20Storage(asset);
            EIP20Interface erc20 = EIP20Interface(cerc20.underlying());
            symbol = erc20.symbol();
        }

        bytes32 key = stringToBytes32(symbol);
        return key;
    }

    function getPriceByKey(bytes32 key)public view returns(uint) {
        OracleStorage oracleStorage = OracleStorage(stormanOracle);
        uint readValue = oracleStorage.getValue(key);
        return readValue;
    }

}
