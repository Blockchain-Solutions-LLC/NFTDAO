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


contract HOANFT is ERC721A, ReentrancyGuard, Ownable, ERC2981Collection {

    IERC20 ecosystemTokens;
    string private baseURI;
    enum PROFILES  { ADMIN, OWNER, TENANT}

    mapping(uint256 => UnitData) private tokenIdToUnitData; // compressed data for NFT

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

    enum PeriodType { SECOND, MINUTE, HOUR, DAY, WEEK, MONTH, YEAR, CUSTOM}

    struct LeaseInfo {
        uint8 startMonth; // 0 to 11
        uint16 startYear; // 2022, for example
        uint8 endMonth; // 0 to 11
        uint16 endYear; // 2022, for example
        uint40 paymentPerPeriod; // amount of USD owned per period
        uint40 totalRentPaid; // total paid during lease
        address lessee;
        PeriodType periodType;
    }

    struct UnitData {
        LeaseInfo[] leases;
        address borrowerAddress;
        uint40 claimTime;
        uint8 startMonth; // 0 to 11 -- constraits for when leasese can be created
        uint16 startYear; // 2022, for example -- constraits for when leasese can be created
        uint8 endMonth; // 0 to 11 -- constraits for when leasese can be created
        uint16 endYear; // 2022, for example -- constraits for when leasese can be created
        uint40 paymentPerPeriod; // amount of USD owned per period
        PeriodType periodType;
    }


    event MyData(uint256 A, uint256 B, uint256 C, uint256 D, uint256 E);


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
// Month, Day, Year --> stored on chain
// payment frequency --> daily, weekly, monthly
// tenancy[]

    // January = 0
    /**
     * @dev Converts a specific month to seconds
     * @param month 0 - 11 representation of month.
     * @param year year in which month occurs.
     */
    function getSecondsInGivenMonth(uint256 month, uint256 year) view public returns (uint256)    {
        uint256 duration = 31 days;
        // if 30
        if (month == 3 || month == 5 ||  month == 8 || month == 10){
            duration -= 1 days;
        }
        else if (month == 1){
            // if leap year, subtract 2, otherwise subtract 3
            if (year %4 ==0){
                duration -= 2 days;
            }
            else {
                duration -= 3 days;
            }
        }
        return duration;
    }


    function getTimestampEstimate(uint256 month, uint256 year) view public returns (uint256)    {
        return getTimestampEstimate(0, 0, 0, 0, month, year);
    }

    /**
     * @dev timestamp estimate based on time 0 at January 1, 1970 (midnight UTC/GMT),
     * @param month 0 - 11 representation of month.
     * @param year year in which month occurs.
     */
    function getTimestampEstimate(uint256 second, uint256 minute, uint256 hour, uint256 day, uint256 month, uint256 year) view public returns (uint256)    {
        require( year > 1969, "invalid year.");
        // seconds in incomplete year
        uint256 timestamp = second + minute*60 + hour * 3600 + day*86400; // todo verify timestamp is correct

        // todo -- this could be precalculated (11 numbers)
        uint256 secondsInFullMonths;
        for(uint256 i=0; i < month;i++){
            secondsInFullMonths += getSecondsInGivenMonth(i, year);
        }

        // seconds in leap days
        uint256 leapYears = year > 1971 ? (year - 1968) / 4 : 0;

        timestamp += secondsInFullMonths + 31536000 * (year - 1970) + 86400*leapYears;

        return timestamp;
    }


    function getSecondsGivenPeriodType(PeriodType _periodType) view public returns (uint256)    {
        uint256 duration = 1;

        if (_periodType == PeriodType.SECOND){
            duration = 1;
        }
        else if (_periodType == PeriodType.MINUTE){
            duration = 60;
        }
        else if (_periodType == PeriodType.HOUR){
            duration = 3600;
        }
        else if (_periodType == PeriodType.DAY){
            duration = 1 days;
        }
        else if (_periodType == PeriodType.WEEK){
            duration = 7 days;
        }
        else if (_periodType == PeriodType.MONTH){
            duration = 30 days; // todo -- need to execute in a different way
        }
        else if (_periodType == PeriodType.YEAR){
            duration = 365 days;
        }
        else if (_periodType == PeriodType.CUSTOM){
            duration = 100 days; // todo -- add custom logic
        }
        else {
        }

//        require(_periodType!=PeriodType.SECOND, "period type is SECON");
//        require(_periodType!=PeriodType.MINUTE, "period type is MINUTE");
//        require(_periodType!=PeriodType.HOUR, "period type is HOUR");
//        require(_periodType!=PeriodType.DAY, "period type is DAY");
//        require(_periodType!=PeriodType.WEEK, "period type is WEEK");
//        require(_periodType!=PeriodType.MONTH, "period type is MONTH");
//        require(_periodType!=PeriodType.YEAR, "period type is YEAR");
//        require(_periodType!=PeriodType.CUSTOM, "period type is CUSTOM");
        return duration;
    }

    // returns time until date is hit based on current timestamp
    function timeHelper(uint256 day, uint256 month) public returns (uint256){

    }


    // todo -- how to use Chainink?
    // RNG for: lottery, votes,
    /// Everyone who pays on time gets entered into the lottery. Lottery funds from DeFi (reinvest)
    // API for weather for NFT, for ...


    // todo --
    // propertyOwners get a def reward for keeping their funds in
    //

    // todo -- lottery. initiated monthly. Check who is in good standing. Sends reward. Chainlink Random function
    // call monthly --- decentralized or not.


    function getRentDue(uint _unitID) public view returns(uint256){
        require(_exists(_unitID), "invalid NFT");
        UnitData memory unitData =  tokenIdToUnitData[_unitID];
        require(unitData.leases.length > 0, "No Lease.");
        LeaseInfo memory leaseInfo =  unitData.leases[0]; // todo -- get correct leaseInfo in stack -- figure out how to store

//        uint256 startDateTimestamp = getSecondsInGivenMonth(leaseInfo.startMonth, leaseInfo.startYear);
        uint256 startDateTimestamp = getTimestampEstimate(leaseInfo.startMonth, leaseInfo.startYear);

        // if before lease
        if (block.timestamp <= startDateTimestamp) {
            return 0;
        }

        // todo -- if periodType == month, different logic. Will need start date and end date
        uint256 periodTime = getSecondsGivenPeriodType(leaseInfo.periodType);
        uint256 periodsPassed = (block.timestamp - startDateTimestamp ) / periodTime;// - (block.timestamp - startDateTimestamp ) % periodTime; // whole number of periods passed
        uint256 rentDue = periodsPassed * leaseInfo.paymentPerPeriod; // todo -- potentially add tax contractSettings.tax

//        emit MyData(block.timestamp, startDateTimestamp, periodTime, periodsPassed, uint256(leaseInfo.periodType));

        return leaseInfo.totalRentPaid > rentDue ? 0 : rentDue - leaseInfo.totalRentPaid;
    }

    struct ContractSettings {
        uint208 mintFee; // probably removed
        uint16 maxSupply;
        // 32 bits left
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

    function getUnitData(uint256 _unitID) public view returns(uint8 _startMonth, uint16 _startYear, uint8 _endMonth,
        uint16 _endYear, uint40 _paymentPerPeriod, address borrower, PeriodType _periodType) {
        require(_exists(_unitID), "invalid NFT");
        UnitData memory unitData =  tokenIdToUnitData[_unitID];
        return(unitData.startMonth, unitData.startYear, unitData.endMonth, unitData.endYear, unitData.paymentPerPeriod,
        unitData.borrowerAddress, unitData.periodType);
    }

    // todo -- specify lease ?? via selector?
    function getLeaseInfo(uint256 _unitID) public view returns(uint8 _startMonth, uint16 _startYear, uint8 _endMonth,
        uint16 _endYear, uint40 _paymentPerPeriod, uint40 totalRentPaid, address lessee, PeriodType _periodType) {
        require(_exists(_unitID), "invalid NFT");
        LeaseInfo memory leaseInfo =  tokenIdToUnitData[_unitID].leases[0]; // todo get specific lease
        return(leaseInfo.startMonth, leaseInfo.startYear, leaseInfo.endMonth, leaseInfo.endYear, leaseInfo.paymentPerPeriod,
        leaseInfo.totalRentPaid, leaseInfo.lessee, leaseInfo.periodType);
    }

//    struct LeaseInfo {
//        uint8 startMonth; // 0 to 11
//        uint16 startYear; // 2022, for example
//        uint8 endMonth; // 0 to 11
//        uint16 endYear; // 2022, for example
//        uint40 paymentPerPeriod; // amount of USD owned per period
//        uint40 totalRentPaid; // total paid during lease
//        address lessee;
//        PeriodType periodType;
//    }


    /////////////////////////////
    //////  Set Functions ///////
    /////////////////////////////

    function setERC20Address(address _addy) external onlyOwner {
        ecosystemTokens = IERC20(_addy);
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
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

//        contractSettings = ContractSettings({
//            mintFee: 0,     // todo -- we probably will never need a mint fee
//            maxSupply: 3000 // todo -- we probably don't need max supply
//        });

        // preminting isn't cheaper because of cost of transfers
        // todo
        _safeMint(msg.sender, _units); // todo -- disable transfers except for admin
        // we will transfer NFT to new owner
        // or, the app knows who gets what and it is minted for them.
    }


    function createLeaseTerms(uint256 _unitID, uint8 _startMonth, uint16 _startYear, uint8 _endMonth,
        uint16 _endYear, uint40 _paymentPerPeriod, PeriodType _periodType) external {

        require(_exists(_unitID), "invalid NFT");
        require(ownerOf(_unitID) == msg.sender || false); // todo, add logic for borrower
        UnitData storage unitData =  tokenIdToUnitData[_unitID];
        unitData.startMonth = _startMonth;
        unitData.startYear = _startYear;
        unitData.endMonth = _endMonth;
        unitData.endYear = _endYear;
        //  unitData.borrowerAddress =
        unitData.periodType = _periodType;
        unitData.paymentPerPeriod = _paymentPerPeriod;
//        emit MyData(0, 0, 0, 0, uint256(_periodType));
    }



    // allow unit owner to create lease agreement, which will facilitate payments
    function commitToLease(uint256 _unitID, uint8 _startMonth, uint16 _startYear, uint8 _endMonth, uint16 _endYear
        ) external {
        // require caller to own unit NFT (be careful if we implement renting NFTs of ownership)
        // this data is going to be stored on IPFS
        // creating this will require new baseURI
        // Lessor creates agreement
        // how to do this in a decentralized way where we can update the lease agreements often and not need to
        // upload new files

        // format: standard lease agreement off chain
        // on chain -- signature, including dates, payment terms, and more
        // ??



        require(_exists(_unitID), "invalid NFT");
        UnitData storage unitData =  tokenIdToUnitData[_unitID];

        // todo -- check to see if timing works out ( within constraits of lease and not blocked by other leases)
        // start data and end date are within correct places
        // minimum rate met?


        // if viable, we create a new LeaseInfo and add it to UnitData
        LeaseInfo memory leaseInfo = LeaseInfo({
            startMonth: _startMonth,
            startYear: _startYear,
            endMonth: _endMonth,
            endYear: _endYear,
            paymentPerPeriod : unitData.paymentPerPeriod, // todo -- have lessor create this requirement
            totalRentPaid: 0,
            lessee: msg.sender,
            periodType: unitData.periodType
        });

        // todo -- insert leaseInfo correctly

        unitData.leases.push(leaseInfo);

    }


    // one issue with trading NFTs -- we want the owner to vote and be authenticated. It would be good if there was a
    // second NFT for trading which dealt with the profits. For now, the only approach I see is to create a payee field, which can be purchased

    // lend unit NFT for profit
    function lendOwnership(uint256 _unitID, address lendee) external {
        // require lending available
        // require financial terms met
        // transfer financial terms
        // set reclaim/reset times
    }

    // return lent NFT
    function claimOwnership(uint256 _unitID) external {
        // depends on implimentation
    }

    // used if ownerShip not transferred. Should also enable admins to transfer ownership.

    // burns an NFT
    // new tokenId will point to new space in IPFS
    function burnNFT(uint256 _tokenID) external onlyAdmin {
        // transferFrom to 0x0...dEaD
    }

    // mint new NFT
    function mint(address _member) external onlyAdmin {
//        _safeMint(msg.sender, _unitIDs);

    }


    // pays unit owner rent
    function payRent(uint256 _unitID, address lendee) external payable {
    }

    // pays HOA (fees?)
    function payHOA(uint256 _unitID, address lendee) external payable {
        // create a step function for payments and a way to see if the payment has been created
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