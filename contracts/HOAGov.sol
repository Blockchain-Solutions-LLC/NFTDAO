pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicensed


import "./interfaces/IERC20.sol";
import "./interfaces/IERC165.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Enumerable.sol";
import "./helpers/base64.sol";
import './helpers/ERC721A.sol';
import './helpers/ERC721.sol';
import './helpers/ERC165.sol';
import './helpers/Ownable.sol';
import './helpers/Context.sol';
import './helpers/ReentrancyGuard.sol';
import './helpers/ERC2981Collection.sol';
import './libraries/Strings.sol';
import './libraries/Address.sol';


//contract BMMultipass is ERC721Enumerable, ReentrancyGuard, Ownable {
contract HOAGOV is ReentrancyGuard, Ownable {

    IERC20  ecosystemTokens;
    IERC721 ecosystemNFTs;

    // the value stored here is shifted over by one because 0 means no vote, 1 means voting for slot 0
    mapping (uint256 => mapping (uint256 => uint256)) public proposalToNFTVotes;

    struct ContractSettings {
        uint208 mintFee;
        uint16 maxSupply;
    }

    // monthly fees should be stored on chain. However, there should be HOA info stored off chain, like pictures, videos, documents ,...
    struct HOAInfo {
        uint208 commonRooms;
        uint48 monthlyFee;
    }

    struct Proposal {
        string IPFSHash;
        uint16 numberOfOptions;
        uint16[8] votes; // todo -- do we really want this many
        uint40 totalVotes;
        uint40 votingEndTimestamp;
    }

    mapping (uint256 => Proposal) public proposals;
    uint256 totalProposals;

    ContractSettings public contractSettings;


    /////////////////////////////
    //////  Get Functions ///////
    /////////////////////////////

    function getVotes(uint256 proposalID) external returns (uint16[] memory) {
        require(proposalID < totalProposals, "no such proposal");
        uint16[] memory voteArray = new uint16[](proposals[proposalID].numberOfOptions);
        for(uint256 i = 0; i< voteArray.length; i++){
            voteArray[i] = proposals[proposalID].votes[i];
        }
        return voteArray;
    }

    function getWinningVote(uint256 proposalID) external returns (uint256 ) {
        require(proposalID < totalProposals, "no such proposal");
        require( block.timestamp > proposals[proposalID].votingEndTimestamp, "voting still active"); // todo -- end voting only on time? Or, what?
        // todo -- is there a need to win by a certain percent?
        uint256 winningVote;
        uint256 winningVoteAmount;
        uint256 tie=0;
        for(uint256 i=0; i< proposals[proposalID].numberOfOptions; i++){ // start at 1 as 0 means no vote???
            if(proposals[proposalID].votes[i] > winningVoteAmount) {
                winningVoteAmount = proposals[proposalID].votes[i];
                winningVote = i;
                if (tie==1) { tie = 0;}
            }
            else if(proposals[proposalID].votes[i] == winningVoteAmount){
                tie=1;
            }
        }
        require(tie==0, "there was a tie.");
        return winningVote;
    }

    /////////////////////////////
    //////  Set Functions ///////
    /////////////////////////////

    function setNFTAddress(address _addy) external onlyOwner {
        ecosystemNFTs = IERC721(_addy);
    }

    function setERC20Address(address _addy) external onlyOwner {
        ecosystemTokens = IERC20(_addy);
    }

    //////////////////////////////
    //////  Main Functions ///////
    //////////////////////////////

    /** @dev Constructor for HOADAO
        @param _erc20 -- contract address for _erc20 token.
        @param _nft -- contract address for NFTs
      */
    constructor(address _erc20, address _nft){
        ecosystemTokens = IERC20(_erc20);
        ecosystemNFTs = IERC721(_nft);

//        contractSettings = ContractSettings({
//        });

    }

    // Required to receive ETH
    receive() external payable {
    }

    function vote(uint256 proposalID, uint256 NFTID, uint256 _vote) external {
        require(proposalID < totalProposals, "no such proposal");
        require(ecosystemNFTs.ownerOf(NFTID)==msg.sender, "not owner of NFT");
        require(proposalToNFTVotes[proposalID][NFTID]==0, "already voted");
        require(_vote!=0 && _vote <= proposals[proposalID].numberOfOptions);
        require(block.timestamp < proposals[proposalID].votingEndTimestamp);
        proposalToNFTVotes[proposalID][NFTID] = _vote + 1; // vote reference shifted by one
        proposals[proposalID].votes[_vote] += 1; // increment votes
        proposals[proposalID].totalVotes += 1;
    }

    // todo -- should only be called by certain users
    function createProposal(string calldata _IPFSHash, uint16 _numberOfOptions, uint40 _votingEndTimestamp) external {
        require(_numberOfOptions > 1 && _numberOfOptions < 257, "invalid number of options");
        Proposal storage myProposal = proposals[totalProposals];
        myProposal.votingEndTimestamp = _votingEndTimestamp;
        myProposal.numberOfOptions = _numberOfOptions;
        myProposal.IPFSHash = _IPFSHash;
        totalProposals += 1;
    }

    //////////////////////
    ////// Modifiers /////
    //////////////////////

    modifier onlyAdmin() {
        require(false,'Must be admin');
        _;
    }

    modifier onlyNFTOwner() {
        require(false,'Must be admin');
        _;
    }

    modifier onlyLessee() {
        require(false,'Must be lessee');
        _;
    }

    modifier onlyMember() {
        require(false,'Must be member');
        _;
    }

    modifier onlyLessor() {
        require(false,'Must be lessor');
        _;
    }




}