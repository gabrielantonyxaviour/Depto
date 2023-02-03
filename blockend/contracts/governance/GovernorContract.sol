// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";

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
    }

    struct Application {
        string name;
        address walletAddress;
        string metadataURI;
        uint appliedOn;
    }

    struct FalseClaim {
        string name;
        address claimerWalletAddress;
        uint applierTokenId;
        uint falsePatentTokenId;
        string metadata;
        uint claimedOn;
    }

    DAOMember[] public daoMembers;
    uint public daoMemberPointer;
    mapping(uint => Application) applications;
    uint public applicationsPointer;
    mapping(uint => FalseClaim) falseClaims;
    uint public falseClaimPointer;
    mapping(address => bool) public isDAOMember;

    mapping(address => uint256[]) public userToPatentClaims;

    uint256 public constant PROPOSAL_FEE = 2000000000000000000;
    uint256 public constant FALSE_CLAIM_FEE = 1000000000000000000;

    constructor(
        TimelockController _timelock,
        uint256 _votingPeriod,
        uint256 _votingDelay
    )
        Governor("GovernorContract")
        GovernorSettings(
            _votingDelay, /* 1 block */ // voting delay
            _votingPeriod, // 45818, /* 1 week */ // voting period
            0 // proposal threshold
        )
        GovernorTimelockControl(_timelock)
    {
        daoMemberPointer = 0;
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

    function applyPatent(string name, string metadataURI) public payable {
        require(
            msg.value >= PROPOSAL_FEE,
            "Insufficient Fee to apply for a patent"
        );
        // TODO: Remaining money handling
        applications[applicationsPointer] = Application(
            name,
            msg.sender,
            metadataURI,
            block.timestamp
        );
        applicationsPointer += 1;
    }

    function applyFalseClaim(
        string name,
        uint applierPatentTokenId,
        uint falsePatentTokenId,
        string metadataURI
    ) public payable {
        require(
            msg.value >= FALSE_CLAIM_FEE,
            "Insufficient Funds for False Claim"
        );
        falseClaims[falseClaimPointer] = FalseClaim(
            name,
            msg.sender,
            applierPatentTokenId,
            falsePatentTokenId,
            metadataURI,
            block.timestamp
        );
        falseClaimPointer += 1;
    }

    function proposePatent(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public checkDAOMember(msg.sender) {
        require(values[0] >= PROPOSAL_FEE, "Insufficient FEE to propose");
        require(checkDAOMember(targets[1]), "Proposal format invalid");
        super.propose(addresses, values, calldatas, description);
    }

    function proposeMember(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public checkDAOMember(msg.sender) {
        require(
            daoMemberPointer < 40,
            "Cannot add any more members in the DAO"
        );
        super.propose(addresses, values, calldatas, description);
    }

    function proposeFalseClaim(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public checkDAOMember(msg.sender) {
        require(
            daoMemberPointer < 40,
            "Cannot add any more members in the DAO"
        );
        super.propose(addresses, values, calldatas, description);
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(Governor, IGovernor) returns (uint256) {}

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
