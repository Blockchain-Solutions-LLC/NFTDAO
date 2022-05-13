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
import './RelativeTokenHolding.sol';

contract HOANFT is ERC721A, ReentrancyGuard, Ownable, ERC2981Collection, RelativeTokenHolding {

    IERC20 ecosystemToken;
    string private baseURI;
    enum PROFILES  { ADMIN, OWNER, TENANT}

    mapping(uint256 => UnitData) private tokenIdToUnitData; // compressed data for NFT
    mapping(address => uint256[] ) public renterAddressToLeaseIDs;
    mapping(uint256 => LeaseInfo ) public leaseIDToLease;
    uint256 public totalLeases;

// Store in metadata
// Unit Info
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

/// Store in metadata
//Lease Info
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


    enum PeriodType { SECOND, MINUTE, HOUR, DAY, WEEK, MONTH, YEAR, CUSTOM}

    // todo -- consider storing IPFS hash here for each contract
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

    // todo -- is this going to serve as a template for one lease, or will multiple leases fit into this data
    // todo -- if the latter, we need to add minTime and check for pockets that are being invalidated
    struct UnitData {
        uint256[] leases;
        address borrowerAddress;
        uint40 claimTime;
        uint8 startMonth; // 0 to 11 -- constraits for when leasese can be created
        uint16 startYear; // 2022, for example -- constraits for when leasese can be created
        uint8 endMonth; // 0 to 11 -- constraits for when leasese can be created
        uint16 endYear; // 2022, for example -- constraits for when leasese can be created
        uint40 minTime; // seconds for minimum time to be created.
        uint40 paymentPerPeriod; // amount of USD owned per period
        bool filled;
        PeriodType periodType;
    }


    event MyData(uint256 A, uint256 B, uint256 C, uint256 D, uint256 E);


    function getTimeGivenTimestamp(uint256 _timestamp) public returns(uint256 second, uint256 minute, uint256 hour,
        uint256 day, uint256 month, uint256 year){
        year = 1970 + _timestamp / (365 days);
        uint256 rem = _timestamp % (_timestamp / (365 days));
        uint256 total_days = rem /365;
        second;
        minute;
        hour;
        day;
        month;
        // todo -- complete this
    }

    /**
     * @dev Converts a specific month to seconds
     * @param month , 0 - 11 representation of month.
     * @param year , year in which month occurs.
     */
    function getSecondsInGivenMonth(uint256 month, uint256 year) view public returns (uint256)    {
        uint256 duration = 31 days;
        // if 30-day month
        if (month == 3 || month == 5 ||  month == 8 || month == 10){
            duration -= 1 days;
        }
        // if leap year
        else if (month == 1){
            if (year %4 ==0){
                duration -= 2 days;
            }
            else {
                duration -= 3 days;
            }
        }
        return duration;
    }

    /**
     * @dev Gets estimated timestamp for a future date, assuming seconds, minutes, hours, day = 0
     * @param month , 0 - 11 representation of month.
     * @param year , year in which month occurs.
     */
    function getTimestampEstimate(uint256 month, uint256 year) view public returns (uint256)    {
        return getTimestampEstimate(0, 0, 0, 0, month, year);
    }

    /**
     * @dev timestamp estimate based on time 0 at January 1, 1970 (midnight UTC/GMT),
     * @param second , 0 - 59
     * @param minute , 0 - 59
     * @param hour , 0 - 23
     * @param day , 0 - 30
     * @param month , 0 - 11
     * @param year , > 1970
     */
    function getTimestampEstimate(uint256 second, uint256 minute, uint256 hour, uint256 day, uint256 month, uint256 year) view public returns (uint256)    {
        require(second < 60 && minute < 60 && hour < 24 && month < 12 && year > 1969, "invalid time");
        require(day < getSecondsInGivenMonth(month, year) / 86400, "invalid days");

        // seconds in incomplete year, excluding completed months
        uint256 timestamp = second + minute*60 + hour * 3600 + day*86400; // todo verify timestamp is correct

        uint16[12] memory cumulative_days_in_month = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]; //, 365];

        // calculated completed months
        uint256 secondsInFullMonths = cumulative_days_in_month[month] * 86400; // need to add in leap year if in march
//        if (month > 0){
//            secondsInFullMonths;
//        }
//
//        for(uint256 i=0; i < month;i++){
//            secondsInFullMonths += getSecondsInGivenMonth(i, year);
//        }

        // seconds in leap days
        uint256 affective_years = month > 2 ? year : year - 1;

        uint256 leapYears = affective_years > 1971 ? (affective_years - 1968) / 4 : 0; // protect against underflow

        // add in months, years, and leap days
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
        return duration;
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


    // todo -- getRentDue given renter address

    // todo -- must include lease #
    function getRentDue(uint _leaseID) public view returns(uint256){
        require(_leaseID < totalLeases, "invalid Lease");
//        UnitData memory unitData =  tokenIdToUnitData[_unitID];
//        require(unitData.leases.length > 0, "No Lease.");
//        LeaseInfo memory leaseInfo =  unitData.leases[0]; // todo -- get correct leaseInfo in stack -- figure out how to store
        LeaseInfo memory leaseInfo =  leaseIDToLease[_leaseID]; // todo -- get correct leaseInfo in stack -- figure out how to store

//        uint256 startDateTimestamp = getSecondsInGivenMonth(leaseInfo.startMonth, leaseInfo.startYear);
        uint256 startDateTimestamp = getTimestampEstimate(leaseInfo.startMonth, leaseInfo.startYear);

        // if before lease
        if (block.timestamp <= startDateTimestamp) {
            return 0;
        }

        // todo -- if periodType == month, different logic. Will need start date and end date
        uint256 periodsPassed;
        uint256 periodTime;
        uint256 rentDue;

        if (leaseInfo.periodType == PeriodType.MONTH) {
            periodsPassed = 30 days; // todo --this is innacurate and needs to be changed
            rentDue = periodsPassed * leaseInfo.paymentPerPeriod;
        }
        else {
            periodTime = getSecondsGivenPeriodType(leaseInfo.periodType);
            periodsPassed = (block.timestamp - startDateTimestamp ) / periodTime;// - (block.timestamp - startDateTimestamp ) % periodTime; // whole number of periods passed
            rentDue = periodsPassed * leaseInfo.paymentPerPeriod; // todo -- potentially add tax contractSettings.tax
        }

        return leaseInfo.totalRentPaid > rentDue ? 0 : rentDue - leaseInfo.totalRentPaid;
    }

    // essentially already implemented
//    function getMyRentDue(uint256 _leaseID) external returns(uint256) {
//        // require _unitID _exists
//        // loop over leases, get amount due
//        // renterAddressToLeaseIDs()
//    }


    function getMyRentDueEverywhere() external view returns(uint256) {
        uint256 totalRentDue;
        for(uint256 i =0; i < renterAddressToLeaseIDs[msg.sender].length;  i++){
            totalRentDue += getRentDue(renterAddressToLeaseIDs[msg.sender][0]);
        }
        return totalRentDue;
    }

    // todo -- potential to fail if there are large amounts of rentals (large for loop)
    function getMyLeases() external view returns(uint256[] memory) {
//        uint256 totalRentDue;
//        for(uint256 i =0; i< renterAddressToLeaseIDs[msg.sender].length < i++){
//            totalRentDue += getRentDue(renterAddressToLeaseIDs[msg.sender][0]);
//        }
        return renterAddressToLeaseIDs[msg.sender];
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
    function getLeaseInfo(uint256 _leaseID) public view returns(uint8 _startMonth, uint16 _startYear, uint8 _endMonth,
        uint16 _endYear, uint40 _paymentPerPeriod, uint40 totalRentPaid, address lessee, PeriodType _periodType) {
        require(_leaseID < totalLeases, "invalid Lease");
        LeaseInfo memory leaseInfo =  leaseIDToLease[_leaseID]; // tokenIdToUnitData[_unitID].leases[0]; // todo get specific lease
        return(leaseInfo.startMonth, leaseInfo.startYear, leaseInfo.endMonth, leaseInfo.endYear, leaseInfo.paymentPerPeriod,
        leaseInfo.totalRentPaid, leaseInfo.lessee, leaseInfo.periodType);
    }


    /////////////////////////////
    //////  Set Functions ///////
    /////////////////////////////

    function setERC20Address(address _addy) external onlyOwner {
        ecosystemToken = IERC20(_addy);
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
    constructor(uint256 _units, address _royaltiesCollector, string memory _baseURI, address _economyToken)
            ERC721A("HOA DAO", "HOADAO") Ownable() ERC2981Collection(_royaltiesCollector, 1000)
            RelativeTokenHolding(_economyToken) {
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
        // todo -- check for existing data (leases) and keep that info
        // todo -- check that new dates don't interfere with existing leases


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


    // todo -- return lease #???
    // allow unit owner to create lease agreement, which will facilitate payments
    function commitToLease(uint256 _unitID //, uint8 _startMonth, uint16 _startYear, uint8 _endMonth, uint16 _endYear
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

        require(unitData.filled==false, "already filled.");
        unitData.filled = true;

        // if viable, we create a new LeaseInfo and add it to UnitData
        LeaseInfo memory leaseInfo = LeaseInfo({
            startMonth: unitData.startMonth,
            startYear: unitData.startYear,
            endMonth: unitData.endMonth,
            endYear: unitData.endYear,
            paymentPerPeriod : unitData.paymentPerPeriod,
            totalRentPaid: 0,
            lessee: msg.sender,
            periodType: unitData.periodType
        });

        leaseIDToLease[totalLeases] = leaseInfo;
        // store info in UnitData
        unitData.leases.push(totalLeases);

        // store data for user
        renterAddressToLeaseIDs[msg.sender].push(totalLeases);

        // increment leases
        totalLeases += 1;
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
        // receive rent in stablecoin
        // store amount in a variable for whoever receives rent
        // lend out USD if over threshold
    }


    function cashOut(uint256 _amount) external nonReentrant {
        // withdraw _amount from lending vault
        // reduce amount in variable
        // transfer to msg.sender
    }


    // pays HOA (fees?)
    function payHOA(uint256 _unitID, address lendee) external payable {
        // create a step function for payments and a way to see if the payment has been created
        // receive fee in stablecoin
        // store amount in a variable for HOA
    }

    // authenticates and pays member of DAO -- takes fee?
    function payMember(address _receiver) external payable nonReentrant {
        // money in
        // authenticate receiver
        // transfer to receiver
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