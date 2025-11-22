// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {Collector} from '../../src/contracts/treasury/Collector.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {ERC1967Proxy} from 'openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol';

/**
 * Scenario suite for Collector gas consumption tests.
 */
/// forge-config: default.isolate = true
contract Collector_gas_Tests is Test {
    Collector public collector;
    
    // mock users
    address admin = makeAddr('admin');
    address fundsAdmin = makeAddr('fundsAdmin');
    address recipient = makeAddr('recipient');
    address user = makeAddr('user');
    
    // mock token
    MockERC20 mockToken;
    
    // stream parameters
    uint256 constant DEPOSIT_AMOUNT = 3600e18; // 1 hour worth of tokens at 1e18 per second
    uint256 startTime;
    uint256 stopTime;
    uint256 streamId;

    function setUp() public {
        // Deploy mock ERC20 token
        mockToken = new MockERC20("Mock Token", "MTK");
        
        // Deploy collector implementation
        Collector implementation = new Collector();
        
        // Deploy proxy and initialize
        bytes memory initData = abi.encodeWithSelector(
            Collector.initialize.selector,
            0,
            admin
        );
        
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );
        
        collector = Collector(payable(address(proxy)));
        
        // Grant FUNDS_ADMIN_ROLE to fundsAdmin - using startPrank/stopPrank
        vm.startPrank(admin);
        collector.grantRole(collector.FUNDS_ADMIN_ROLE(), fundsAdmin);
        vm.stopPrank();
        
        // Setup time parameters for streams
        startTime = block.timestamp;
        stopTime = startTime + 3600; // 1 hour duration
        
        // Fund the collector with tokens
        mockToken.mint(address(collector), 1000000e18);
        
        // Create a stream for withdrawal tests
        vm.prank(fundsAdmin);
        streamId = collector.createStream(
            recipient,
            DEPOSIT_AMOUNT,
            address(mockToken),
            startTime,
            stopTime
        );
    }

    function test_isFundsAdmin() external {
        collector.isFundsAdmin(fundsAdmin);
        vm.snapshotGasLastCall('Collector', 'isFundsAdmin');
    }

    function test_getNextStreamId() external {
        collector.getNextStreamId();
        vm.snapshotGasLastCall('Collector', 'getNextStreamId');
    }

    function test_getStream() external {
        collector.getStream(streamId);
        vm.snapshotGasLastCall('Collector', 'getStream');
    }

    function test_deltaOf_beforeStart() external {
        // Create future stream
        vm.prank(fundsAdmin);
        uint256 futureStreamId = collector.createStream(
            user,
            DEPOSIT_AMOUNT,
            address(mockToken),
            block.timestamp + 1000,
            block.timestamp + 4600
        );
        
        collector.deltaOf(futureStreamId);
        vm.snapshotGasLastCall('Collector', 'deltaOf_beforeStart');
    }

    function test_deltaOf_active() external {
        // Advance time to middle of stream
        vm.warp(startTime + 1800);
        
        collector.deltaOf(streamId);
        vm.snapshotGasLastCall('Collector', 'deltaOf_active');
    }

    function test_deltaOf_afterEnd() external {
        // Advance time past end of stream
        vm.warp(stopTime + 100);
        
        collector.deltaOf(streamId);
        vm.snapshotGasLastCall('Collector', 'deltaOf_afterEnd');
    }

    function test_balanceOf_recipient() external {
        // Advance time to middle of stream
        vm.warp(startTime + 1800);
        
        collector.balanceOf(streamId, recipient);
        vm.snapshotGasLastCall('Collector', 'balanceOf_recipient');
    }

    function test_balanceOf_sender() external {
        // Advance time to middle of stream
        vm.warp(startTime + 1800);
        
        collector.balanceOf(streamId, address(collector));
        vm.snapshotGasLastCall('Collector', 'balanceOf_sender');
    }

    function test_balanceOf_afterWithdrawal() external {
        // Advance time to middle of stream
        vm.warp(startTime + 1800);
        
        // Make a withdrawal first
        vm.prank(recipient);
        collector.withdrawFromStream(streamId, 1000e18);
        
        // Then check balance
        collector.balanceOf(streamId, recipient);
        vm.snapshotGasLastCall('Collector', 'balanceOf_afterWithdrawal');
    }

    function test_approve() external {
        vm.prank(fundsAdmin);
        collector.approve(mockToken, recipient, 1000e18);
        vm.snapshotGasLastCall('Collector', 'approve');
    }

    function test_transfer_ERC20() external {
        vm.prank(fundsAdmin);
        collector.transfer(IERC20(address(mockToken)), recipient, 1000e18);
        vm.snapshotGasLastCall('Collector', 'transfer_ERC20');
    }

    function test_transfer_ETH() external {
        // Fund collector with ETH
        vm.deal(address(collector), 10 ether);
        
        vm.prank(fundsAdmin);
        collector.transfer(
            IERC20(collector.ETH_MOCK_ADDRESS()),
            recipient,
            1 ether
        );
        vm.snapshotGasLastCall('Collector', 'transfer_ETH');
    }

    function test_createStream() external {
        vm.prank(fundsAdmin);
        collector.createStream(
            user,
            DEPOSIT_AMOUNT,
            address(mockToken),
            block.timestamp,
            block.timestamp + 3600
        );
        vm.snapshotGasLastCall('Collector', 'createStream');
    }

    function test_withdrawFromStream_partial() external {
        // Advance time to middle of stream
        vm.warp(startTime + 1800);
        
        uint256 withdrawAmount = 1000e18;
        
        vm.prank(recipient);
        collector.withdrawFromStream(streamId, withdrawAmount);
        vm.snapshotGasLastCall('Collector', 'withdrawFromStream_partial');
    }

    function test_withdrawFromStream_full() external {
        // Advance time to end of stream
        vm.warp(stopTime);
        
        uint256 balance = collector.balanceOf(streamId, recipient);
        
        vm.prank(recipient);
        collector.withdrawFromStream(streamId, balance);
        vm.snapshotGasLastCall('Collector', 'withdrawFromStream_full');
    }

    function test_withdrawFromStream_byFundsAdmin() external {
        // Advance time to middle of stream
        vm.warp(startTime + 1800);
        
        uint256 withdrawAmount = 1000e18;
        
        vm.prank(fundsAdmin);
        collector.withdrawFromStream(streamId, withdrawAmount);
        vm.snapshotGasLastCall('Collector', 'withdrawFromStream_byFundsAdmin');
    }

    function test_cancelStream_byRecipient() external {
        // Advance time to middle of stream
        vm.warp(startTime + 1800);
        
        vm.prank(recipient);
        collector.cancelStream(streamId);
        vm.snapshotGasLastCall('Collector', 'cancelStream_byRecipient');
    }

    function test_cancelStream_byFundsAdmin() external {
        // Create new stream for this test
        vm.prank(fundsAdmin);
        uint256 newStreamId = collector.createStream(
            user,
            DEPOSIT_AMOUNT,
            address(mockToken),
            block.timestamp,
            block.timestamp + 3600
        );
        
        // Advance time to middle of stream
        vm.warp(block.timestamp + 1800);
        
        vm.prank(fundsAdmin);
        collector.cancelStream(newStreamId);
        vm.snapshotGasLastCall('Collector', 'cancelStream_byFundsAdmin');
    }

    function test_cancelStream_noRecipientBalance() external {
        // Create new stream that hasn't started yet
        vm.prank(fundsAdmin);
        uint256 newStreamId = collector.createStream(
            user,
            DEPOSIT_AMOUNT,
            address(mockToken),
            block.timestamp + 100,
            block.timestamp + 3700
        );
        
        // Cancel immediately (no time passed, no recipient balance)
        vm.prank(fundsAdmin);
        collector.cancelStream(newStreamId);
        vm.snapshotGasLastCall('Collector', 'cancelStream_noRecipientBalance');
    }

    function test_cancelStream_withRecipientBalance() external {
        // Create new stream
        vm.prank(fundsAdmin);
        uint256 newStreamId = collector.createStream(
            user,
            DEPOSIT_AMOUNT,
            address(mockToken),
            block.timestamp,
            block.timestamp + 3600
        );
        
        // Advance time so recipient has balance
        vm.warp(block.timestamp + 1800);
        
        vm.prank(user);
        collector.cancelStream(newStreamId);
        vm.snapshotGasLastCall('Collector', 'cancelStream_withRecipientBalance');
    }
}

/**
 * @dev Mock ERC20 token for testing
 */
contract MockERC20 is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= amount;
        }
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
    
    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }
}