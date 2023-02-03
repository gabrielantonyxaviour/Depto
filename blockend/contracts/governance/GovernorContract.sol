// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "../Depto.sol";

contract GovernorContract is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorTimelockControl
{
    struct DAOMember {
        string name;
        address walletAddress;
        uint joinedAt;
        uint leftAt;
    }

    struct Application {
        address walletAddress;
        string metadata;
        uint appliedOn;
    }

    struct FalseClaim {
        address claimerWalletAddress;
        uint applierTokenId;
        uint falsePatentTokenId;
        string metadata;
        uint claimedOn;
    }

    uint public treasury;

    mapping(address => DAOMember) public daoMembers;
    uint public daoMemberCount;

    mapping(uint => Application) applications;
    uint public applicationsPointer;
    mapping(uint => bool) isApplicationHandled;

    mapping(uint => FalseClaim) falseClaims;
    uint public falseClaimPointer;
    mapping(uint => bool) isFalseClaimHandled;

    mapping(address => uint[]) daoMemberToApplications;
    mapping(address => uint[]) daoMemberToFalseClaims;
    mapping(address => bool) public isDAOMember;

    TimelockController timelock;

    mapping(address => uint256[]) public userToPatentClaims;
    mapping(address => uint256[]) public userToFalseClaims;

    uint256 public constant PROPOSAL_FEE = 2000000000000000000;
    uint256 public constant FALSE_CLAIM_FEE = 1000000000000000000;

    constructor(
        string memory deployerName,
        TimelockController _timelock,
        uint256 _votingPeriod,
        uint256 _votingDelay
    )
        payable
        Governor("GovernorContract")
        GovernorSettings(
            _votingDelay, /* 1 block */ // voting delay
            _votingPeriod, // 45818, /* 1 week */ // voting period
            0 // proposal threshold
        )
        GovernorTimelockControl(_timelock)
    {
        timelock = _timelock;
        treasury += msg.value;
        daoMembers[msg.sender] = DAOMember(
            deployerName,
            msg.sender,
            block.timestamp,
            0
        );
        daoMemberCount = 1;
        isDAOMember[msg.sender] = true;
    }

    modifier checkDAOMember(address caller) {
        require(
            isDAOMember[caller],
            "GovernorContract: Only DAO members can access this function"
        );
        _;
    }

    function votingDelay()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingDelay();
    }

    function votingPeriod()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    // The following functions are overrides required by Solidity.

    function state(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function addDAOMember(address newMember, string memory name) public {
        require(
            msg.sender == address(timelock),
            "TimeLock can only invoke this function"
        );
        daoMembers[msg.sender] = DAOMember(name, newMember, block.timestamp, 0);
        daoMemberCount += 1;
        isDAOMember[newMember] = true;
    }

    function applyPatent(string metadataURI) public payable {
        require(
            msg.value >= PROPOSAL_FEE,
            "Insufficient Fee to apply for a patent"
        );
        treasury += msg.value - PROPOSAL_FEE;
        applications[applicationsPointer] = Application(
            msg.sender,
            metadataURI,
            block.timestamp
        );
        userToPatentClaims[msg.sender].push(applicationsPointer);

        applicationsPointer += 1;
    }

    function applyFalseClaim(
        uint applierPatentTokenId,
        uint falsePatentTokenId,
        string metadataURI
    ) public payable {
        require(
            msg.value >= FALSE_CLAIM_FEE,
            "Insufficient Funds for False Claim"
        );
        treasury += msg.value - FALSE_CLAIM_FEE;

        falseClaims[falseClaimPointer] = FalseClaim(
            msg.sender,
            applierPatentTokenId,
            falsePatentTokenId,
            metadataURI,
            block.timestamp
        );
        userToFalseClaims[msg.sender].push(falseClaimPointer);
        falseClaimPointer += 1;
    }

    function propose(
        address[] memory targets,
        uint26[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public checkDAOMember(msg.sender) {
        super.propose(targets, values, calldatas, description);
    }

    function leaveDAO() public checkDAOMember(msg.sender) {
        isDAOMember[msg.sender] = false;
        daoMembers[msg.sender].leftAt = block.timestamp;
        uint funds = treasury / daoMemberCount;
        daoMemberCount -= 1;
        (bool success, bytes memory data) = payable(msg.sender).call{
            value: funds
        }("");
    }

    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor()
        internal
        view
        override(Governor, GovernorTimelockControl)
        returns (address)
    {
        return super._executor();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getPatentClaims(address user)
        public
        view
        returns (uint256[] memory)
    {
        return userToPatentClaims[user];
    }
}
