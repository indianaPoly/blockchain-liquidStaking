// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./StBTC.sol";

contract Staking is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable WBTC;
    StBTC public immutable StBTCToken;

    uint256 public stakedWBTCBuffer; // staking된 WBTC를 저장하는 버퍼
    uint256 public lastArbitrageSendTime = block.timestamp;
    uint256 public sendInterval = 3600; // 3600초

    struct Stake {
        uint256 amount;
        uint256 timestamp;
    }

    struct Reward {
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => Stake) public stakedBalances; // 사용자별로 staking한 WBTC 양을 저장함.
    address[] public stakers;
    mapping(address => bool) public hasStaked;
    mapping(address => Reward) public rewards;

    event Staked(address indexed user, uint256 amount, uint256 timestamp);
    event MintStBTC(address indexed user, uint256 amount, uint256 timestamp); // 사용자에게 StBTC가 성공적으로 전송이 되었을 때 발생하는 이벤트
    event Withdrawn(address indexed user, uint256 amount, uint256 timestamp); // 사용자가 WBTC를 성공적으로 출금하였을 때 발생하는 이벤트
    event BurnStBTC(address indexed user, uint256 amount, uint256 timestamp); // 사용자의 StBTC를 성공적으로 소각시켰을 때 발생하는 이벤트
    event SentToSwap(
        address indexed swapContract,
        uint256 amount,
        uint256 timestamp
    );
    event RewardReceived(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    constructor(address _WBTC, address _StBTCToken) Ownable(msg.sender) {
        require(_WBTC != address(0) && _StBTCToken != address(0));
        WBTC = IERC20(_WBTC);
        StBTCToken = StBTC(_StBTCToken);
    }

    function totalStake() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < stakers.length; i++) {
            total += stakedBalances[stakers[i]].amount;
        }

        return total;
    }

    function getStakingAmount(address _user) external view returns (uint256) {
        return stakedBalances[_user].amount;
    }

    function stake(uint256 amount) external {
        address staker = msg.sender;
        uint256 stbtcBalance = StBTCToken.balanceOf(staker);

        require(amount > 0, "Cannot stake 0"); // amount가 0인 경우에는 stake 불가하므로 revert
        require(WBTC.balanceOf(staker) >= amount, "Insufficient WBTC balance"); // 사용자가 보유한 WBTC가 staking하고자 하는 것 보다 많아야 함.
        require(
            WBTC.allowance(staker, address(this)) >= amount,
            "WBTC allowance is not enough"
        ); // 사용자가 해당 컨트랙트에 승인된 WBTC가 amount보다 많아야 함.

        // staking을 여부를 체킹함.
        if (!hasStaked[staker]) {
            hasStaked[staker] = true;
            stakers.push(staker);
            rewards[staker] = Reward(0, block.timestamp);
        }

        WBTC.safeTransferFrom(msg.sender, address(this), amount); // 사용자 계정에서 해당 계정으로 amount 만큼을 보냄.

        stakedBalances[staker].amount = stbtcBalance + amount; // 사용자 계정에 amount 만큼 추가
        stakedBalances[staker].timestamp = block.timestamp; // 시간 입력
        emit Staked(msg.sender, amount, block.timestamp); // staker 이벤트 발생

        stakedWBTCBuffer += amount; // 버퍼에 사용자가 전송한 WBTC를 저장

        StBTCToken.mint(staker, amount); // 사용자 계정으로 StBTC를 보냄
        emit MintStBTC(staker, amount, block.timestamp); // stbtc 발행 이벤트 발생
    }

    function unstake(uint256 amount) external nonReentrant {
        address unstaker = msg.sender;
        uint256 stbtcBalance = StBTCToken.balanceOf(unstaker);

        require(amount > 0, "Cannot withdraw 0");
        require(amount <= stbtcBalance, "Insufficient StBTC balance");
        require(
            stakedBalances[unstaker].amount >= amount,
            "INSUFFICIENT WBTC balace"
        );

        StBTCToken.burn(unstaker, amount);
        emit BurnStBTC(unstaker, amount, block.timestamp);

        stakedBalances[unstaker].amount = stbtcBalance - amount; // 사용자가 보유하고 있는 stbtc가 있어야 됨.

        uint256 reward = rewards[unstaker].amount;
        rewards[unstaker].amount = 0;

        // 만약 버퍼에 금액이 amount 보다 크다면 버퍼에서 amount 만큼 차감
        if (stakedWBTCBuffer >= amount) {
            stakedWBTCBuffer -= amount;
            WBTC.safeTransfer(unstaker, amount + reward);
            emit Withdrawn(unstaker, amount, block.timestamp);
        }

        if (stakedBalances[unstaker].amount == 0) {
            hasStaked[unstaker] = false;
            for (uint256 i = 0; i < stakers.length; i++) {
                if (stakers[i] == unstaker) {
                    stakers[i] = stakers[stakers.length - 1];
                    stakers.pop();
                    break;
                }
            }
        }
    }

    receive() external payable {}
}
