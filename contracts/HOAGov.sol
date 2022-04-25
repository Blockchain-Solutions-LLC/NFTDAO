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
contract HOAGOV is ReentrancyGuard, Ownable {

    IERC20  ecosystemTokens;
    IERC721 ecosystemNFTs;


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