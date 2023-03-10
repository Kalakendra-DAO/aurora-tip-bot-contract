pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BotV1 {
    address public owner;
    uint256 totalTip;
    uint256 withdrawnTokens;
    int256 usersCount;
    uint256 withdrawFee;
    // uint256 tipFee;
    mapping(address => uint256) public balances;
    mapping(string => uint256) public unClaimedBalances;
    mapping(string => address) public wallets;
    string[] users;
    struct Session {
        string token;
        string userName;
        address walletAddress;
    }
    mapping(string => Session) public Sessions;

    event Tip(address _sender, address _receiver, uint256 _amount);

    event withdrawTokens(address _walletAddress, uint256 _fee, uint256 _amount);

    address token;

    function initialize(address _token, uint256 _withdrawFee) public {
        owner = msg.sender;
        token = _token;
        withdrawFee = _withdrawFee;
    }

    function deposit(uint256 _amount) public payable {
        require(
            IERC20(token).balanceOf(msg.sender) >= _amount,
            "Insuffient Funds"
        );
        IERC20(token).transferFrom(msg.sender, address(this), _amount);
        balances[msg.sender] += _amount;
    }

    function getWithdrawFee() public view returns (uint256) {
        return withdrawFee;
    }

    function getBalance(address walletAddress) public view returns (uint256) {
        return balances[walletAddress];
    }

    function updateTransactionFees(uint256 _withdrawFess) public {
        require(msg.sender == owner, "403:FORBIDDEN");
        withdrawFee = _withdrawFess;
    }

    function loginWithTelegram(
        address _walletAddress,
        string memory _tUserName,
        string memory _jwtToken
    ) public {
        // require(msg.sender == owner, "403:FORBIDDEN");
        wallets[_tUserName] = _walletAddress;
        if (unClaimedBalances[_tUserName] > 0) {
            balances[wallets[_tUserName]] += unClaimedBalances[_tUserName];
        }
        Session memory session = Session(_jwtToken, _tUserName, _walletAddress);
        Sessions[_tUserName] = session;
        users.push(_tUserName);
    }

    function getAllSessions() public view returns (Session[] memory) {
        require(msg.sender == owner, "403:FORBIDDEN");
        Session[] memory sessions = new Session[](users.length);
        for (uint256 i = 0; i < users.length; i++) {
            sessions[i] = Sessions[users[i]];
        }

        return sessions;
    }

    function getSession(
        string memory _tUserName
    ) public view returns (Session memory) {
        require(msg.sender == owner, "403:FORBIDDEN");
        return Sessions[_tUserName];
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    // function logout(address _walletAddress) public {
    //     uint256 index;
    //     for (uint256 i = 0; i < sessionCount; i++) {
    //         if (Sessions[i].walletAddress == _walletAddress) {
    //             index = i;
    //             break;
    //         }
    //     }
    //     delete Sessions[index];
    // }

    function logout(string memory _tUserName) public {
        delete Sessions[_tUserName];
    }

    function getUserCount() public view returns (uint256) {
        return users.length;
    }

    function getTotalDepositedAmount() public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function getTotalWithDrawnAmount() public view returns (uint256) {
        return withdrawnTokens;
    }

    function getTotalTipAmount() public view returns (uint256) {
        return totalTip;
    }

    function getTokenBalance() public view returns (uint256) {
        return IERC20(token).balanceOf(msg.sender);
    }

    function withdrawFromContract() public payable {
        require(msg.sender == owner, "403:FORBIDDEN");
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, balance);
    }

    function tipAmount(
        string memory from,
        string memory to,
        uint256 amount
    ) public payable {
        address sender = wallets[from];
        address receiver = wallets[to];
        require(
            sender != address(0),
            "Telegram Account Not Linked With Your Wallet Address"
        );
        require(balances[sender] >= amount, "Insufficient Funds");
        require(msg.sender == owner, "403:FORBIDDEN");
        // uint256 fees = (amount * tipFee) / 100;
        if (receiver == address(0)) {
            balances[sender] -= amount;
            unClaimedBalances[to] += amount;
            totalTip += amount;
            emit Tip(sender, receiver, amount);
        } else {
            balances[sender] -= amount;
            balances[receiver] += amount;
            totalTip += amount;
            emit Tip(sender, receiver, amount);
        }
    }

    function withdraw(uint256 _amount) public payable {
        require(balances[msg.sender] >= _amount, "Insufficient Funds");
        balances[msg.sender] -= _amount;
        uint256 fees = (_amount * withdrawFee) / 100;
        IERC20(token).transfer(msg.sender, _amount - fees);
        withdrawnTokens += _amount - fees;

        emit withdrawTokens(msg.sender, fees, _amount - fees);
    }

    function withdrawFromBot(
        address _walletAddress,
        uint256 _amount
    ) public payable {
        require(msg.sender == owner, "403:FORBIDDEN");
        require(balances[_walletAddress] >= _amount, "Insufficient Funds");
        balances[_walletAddress] -= _amount;
        uint256 fees = (_amount * withdrawFee) / 100;
        IERC20(token).transfer(_walletAddress, _amount - fees);
        withdrawnTokens += _amount - fees;

        emit withdrawTokens(_walletAddress, fees, _amount - fees);
    }
}
