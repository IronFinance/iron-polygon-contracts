// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC20/ERC20Custom.sol";
import "./Share.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IDollar.sol";

contract Dollar is ERC20Custom, IDollar, Ownable, Initializable {
    // ERC20
    string public symbol;
    string public name;
    uint8 public constant decimals = 18;
    uint256 public constant genesis_supply = 5000 ether; // 5000 will be mited at genesis for liq pool seeding

    // CONTRACTS
    address public treasury;

    /* ========== MODIFIERS ========== */

    modifier onlyPools() {
        require(ITreasury(treasury).hasPool(msg.sender), "!pools");
        _;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address _treasury
    ) external initializer onlyOwner {
        name = _name;
        symbol = _symbol;
        treasury = _treasury;
        _mint(msg.sender, genesis_supply);
    }

    function poolBurnFrom(address _address, uint256 _amount) external override onlyPools {
        super._burnFrom(_address, _amount);
        emit DollarBurned(_address, msg.sender, _amount);
    }

    function poolMint(address _address, uint256 _amount) external override onlyPools {
        super._mint(_address, _amount);
        emit DollarMinted(msg.sender, _address, _amount);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setTreasuryAddress(address _treasury) public onlyOwner {
        require(_treasury != address(0), "Invalid address");
        treasury = _treasury;
        emit TreasuryChanged(_treasury);
    }

    /* ========== EVENTS ========== */

    event TreasuryChanged(address indexed newTreasury);
    event DollarBurned(address indexed from, address indexed to, uint256 amount);
    event DollarMinted(address indexed from, address indexed to, uint256 amount);
}
