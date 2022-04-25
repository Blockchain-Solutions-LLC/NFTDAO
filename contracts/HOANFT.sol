// SPDX-License-Identifier: Unlicensed


pragma solidity ^0.8.0;


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
contract HOANFT is ERC721A, ReentrancyGuard, Ownable, ERC2981Collection {

    IERC20 ecosystemTokens;

    string private baseURI;

    enum PROFILES  { ADMIN, OWNER, TENANT}

//    mapping(uint256 => uint256) private tokenIdToPackedData; // compressed data for NFT
//    mapping(address => uint256) private whiteListHasMinted;
    mapping(uint256 => uint256) private tokenIdToPackedData; // compressed data for NFT

// Store in metadata
//    struct Unit {
//        string  ownerFirstName;
//        string  ownerLastName;
//        uint256 rooms;
//        uint256 squareFeet;
//        uint256 bathRooms;
//        uint256 bedRooms;
//        uint256 ammenities;
//        uint256 coverPhoto;
//        uint256 photoAlbum;
//    }


/// Lease, stored in metadata
//Lessee
//Start Date
//End Date
//Term
//Full Lease Link
//Process of approval
//Owner creates agreement
//Paper (?)
//Blockchain
//Prospective tenant onboarded into app
//Agreement signed
//Authorized by HOA (?) or Owner



    struct ContractSettings {
        uint208 mintFee;
        uint16 maxSupply;
    }

    // monthly fees should be stored on chain. However, there should be HOA info stored off chain, like pictures, videos, documents ,...
    struct HOAInfo {
        uint208 commonRooms;
        uint48 monthlyFee;
    }


    ContractSettings public contractSettings;


    /////////////////////////////
    //////  Get Functions ///////
    /////////////////////////////

    // return lent NFT
    function getTimeLeftInBorrowship(uint256 _tokenID) external returns(uint256) {
    }

    // returns a list of tokenIDs that msg.sender is allowing others to borrow
    function getMyBorrows() external returns(uint256[] memory) {
    }


    /////////////////////////////
    //////  Set Functions ///////
    /////////////////////////////

    function setERC20Address(address _addy) external onlyOwner {
        ecosystemTokens = IERC20(_addy);
    }


    //////////////////////////////
    //////  Main Functions ///////
    //////////////////////////////

    /** @dev Constructor for HOADAO
        @param _units -- number of units.
        @param _royaltiesCollector -- address to receive royalties ( nonbinding )
        @param _baseURI -- Background Image for tokenUri Image
      */
    constructor(uint256 _units, address _royaltiesCollector, string memory _baseURI)
            ERC721A("HOA DAO", "HOADAO") Ownable() ERC2981Collection(_royaltiesCollector, 1000) {
        baseURI = _baseURI;

        contractSettings = ContractSettings({
            mintFee: 0,
            maxSupply: 3000
        });

        // preminting isn't cheaper because of cost of transfers
        // todo
        _safeMint(msg.sender, _units);
    }

    // allow unit owner to create lease agreement, which will facilitate payments
    function createLeaseAgreement(uint256 _unit) external {
        // require caller to owner unit NFT (be careful if we implinent renting NFTs of ownership)
    }

    // lend unit NFT for profit
    function lendOwnership(uint256 _unit, address lendee) external {
    }

    // return lent NFT
    function claimOwnership(uint256 _unit) external {
    }


    // pays unit owner rent
    function payRent(uint256 _unit, address lendee) external payable {
    }

    // pays HOA (fees?)
    function payHOA(uint256 _unit, address lendee) external payable {
    }

    // authenticates and pays member of DAO
    function payMember(address _member) external payable {
    }

    // create rental terms
    // much to flush out
    function createRentalTerms(address _rentee, uint256 _rent, uint256 _start, uint256 _period) external payable {
    }



    // Required to receive ETH
    receive() external payable {
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