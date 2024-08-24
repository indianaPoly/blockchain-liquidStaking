// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StBTC is ERC20 {
    constructor() ERC20("Synthetic Bitcoin", "StBTC") {}

    // 토큰 발행: 외부에서 호출 가능
    function mint(address to, uint256 amount) external {
        require(to != address(0), "Mint to the zero address");
        require(amount > 0, "Mint amount must be greater than zero");

        _mint(to, amount);

        emit Transfer(address(0), to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(from != address(0), "Burn from the zero address");
        require(amount > 0, "Burn amount must be greater than zero");
        require(balanceOf(from) >= amount, "Burn amount exceeds balance");

        _burn(from, amount);

        emit Transfer(from, address(0), amount);
    }
}
