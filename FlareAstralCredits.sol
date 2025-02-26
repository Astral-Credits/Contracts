pragma solidity 0.8.19;

// Standard ERC20 interface
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// AstralPlane - Bridge contract interface to check claims
interface IAstralPlane {
    function claims(string calldata tx_hash) external view returns (address claimer, uint256 claim_amount);
}

// ERC20 token contract
contract FlareAstralCredits is IERC20 {
    string public name = "AstralCredits";
    string public symbol = "FXAC";
    uint8 public decimals = 18;

    mapping(address => uint256) private _balances; // Who’s got the loot?
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    address public immutable astralPlaneAddress;
    address public immutable admin; // For potential future governance or emergency controls

    event Mint(address indexed to, uint256 amount, string tx_hash);

    constructor(address _astralPlaneAddress) {
        astralPlaneAddress = _astralPlaneAddress;
        admin = msg.sender;
        _totalSupply = 0; // No pre-mine yo
    }

    // ERC20 standard functions and stuff
    function totalSupply() external view returns (uint256) {
        return _totalSupply; // Show me da money
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    // Internal ERC20 helpers
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Mint on Burn function - Based on AstralPlane claims (claim_amount)
    function mintFromBurn(string calldata tx_hash) external {
        IAstralPlane astralPlane = IAstralPlane(astralPlaneAddress);
        (address claimer, uint256 claim_amount) = astralPlane.claims(tx_hash);

        require(claim_amount > 0, "No tokens claimed for this tx_hash");
        require(claimer == msg.sender, "Only the claimer can mint tokens");

        // Mint the exact claim_amount
        _totalSupply += claim_amount;
        _balances[claimer] += claim_amount;

        emit Mint(claimer, claim_amount, tx_hash);
        emit Transfer(address(0), claimer, claim_amount); // Standard ERC20 minting event
    }
}
