// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract CrowdParticipationAI01 is Ownable {
    
    using SafeMath for uint256;
    
    address public _raiseToken;
    
    uint256 public _rate;                       //6 DECIMALS
    
    uint256 public _openTimestamp;
    
    uint256 public _cap;
    
    uint256 public _participated;
    uint256 public _participatedCount;
    
    bool public _closed;
    
    struct Release {
        uint256 fromTimestamp;
        uint256 toTimestamp;
        uint256 percent;                        //2 DECIMALS, eg. 33.33% = 3333
        mapping(address => uint256) claimed;
    }
    
    Release[] public _releases;
    
    address public _releaseToken;
    address public _releaseTokenPair;
    
    enum RoundClass { 
        ALLOCATION  , 
        FCFS_PREPARE, 
        FCFS 
        }
    
    struct Round {
        string name;
        uint256 durationSeconds;
        RoundClass class;
        uint256[] tierAllocations;
        mapping(address => uint256) participated;
    }
    
    Round[] public _rounds;
    
    struct Tier {
        string name;
        mapping(address => bool) allocated;
        uint256 allocatedCount;
    }
    
    Tier[] public _tiers;
    
    event Participated(address destination, uint256 amount);
    event Claimed(uint256 release, address destination, uint256 amount);

    constructor(
        address raiseToken,
        uint256 rate,
        uint256 openTimestamp,
        uint256 allocationDuration,
        uint256 fcfsDuration,
        uint256 cap,
        address releaseToken
    )   public
    {
        
        _raiseToken = raiseToken;
        _rate = rate;
        
        _openTimestamp = openTimestamp;
        
        _closed = false;
        
        _cap = cap;

        _tiers.push(Tier("Lottery Winners",0));
        _tiers.push(Tier("Top 100",0));
        _tiers.push(Tier("Top 200",0));
        _tiers.push(Tier("Top 300",0));
        _tiers.push(Tier("Top 400",0));
        _tiers.push(Tier("Top 500",0));
        _tiers.push(Tier("Top 600",0));
        _tiers.push(Tier("Top 700",0));
        _tiers.push(Tier("Top 800",0));
        _tiers.push(Tier("Top 900",0));
        _tiers.push(Tier("Top 1000",0));
        
        _rounds.push(Round("Allocation", allocationDuration, RoundClass.ALLOCATION, new uint256[](_tiers.length)));
        _rounds.push(Round("FCFS - Prepare", 900, RoundClass.FCFS_PREPARE, new uint256[](_tiers.length)));
        _rounds.push(Round("FCFS", fcfsDuration, RoundClass.FCFS, new uint256[](_tiers.length)));
        
        _releaseToken = releaseToken;
    }
    

    //checking
    function modifyRounds(string[] calldata nameList, uint256[] calldata durationList, RoundClass[] calldata classList, uint256 tiers) external onlyOwner() {
        
        require(nameList.length > 0, "Invalid rounds specified");
        require(nameList.length == durationList.length, "Invalid rounds specified");
        
        delete _rounds;
        
        for (uint256 i = 0; i < nameList.length; i++) {
            _rounds.push(Round(nameList[i], durationList[i], classList[i], new uint256[](tiers)));
        }

    }
    //converted
    function modifyRound(uint256 index, string calldata name, uint256 durationSeconds, RoundClass class) external onlyOwner() {
        
        require(index < _rounds.length, "Invalid round index");
        
        Round storage r = _rounds[index];
        
        r.name = name;
        r.durationSeconds = durationSeconds;
        r.class = class;

    }
    
    //converted
    function modifyRoundAllocations(uint256 index, uint256[] calldata tierAllocations) external onlyOwner() {
        
        require(index < _rounds.length, "Invalid round index");
        
        Round storage r = _rounds[index];
        
        r.tierAllocations = tierAllocations;

    }
    
    //converted
    function modifyTiers(string[] calldata nameList) external onlyOwner() {
        
        require(nameList.length > 0, "Invalid tiers specified");
        
        delete _tiers;
        
        for (uint256 i = 0; i < nameList.length; i++)
            _tiers.push(Tier(nameList[i], 0));

    }

    //converted
    function modifyTier(uint256 index, string calldata name) external onlyOwner() {
        
        require(index < _tiers.length, "Invalid tier index");
        
        Tier storage t = _tiers[index];

        t.name = name;

    }
    

     //converted
    function modifyTierAllocated(uint256 index, address[] calldata addresses, bool remove) external onlyOwner() {
        
        require(index < _tiers.length, "Invalid tier index");
        
        Tier storage t = _tiers[index];

        for (uint256 i = 0; i < addresses.length; i++) {
            
            address a = addresses[i];
            
            t.allocated[a] = !remove;
            
            if(!remove)
                t.allocatedCount++;
            else {
                if(t.allocatedCount > 0)
                    t.allocatedCount--;
            }
               
        }

    }
     //converted
    function setupReleaseToken(address token, address pair) external onlyOwner() {
        _releaseToken = token;
        _releaseTokenPair = pair;
    }
        
    
    //converted
    function setupReleases(uint256[] calldata fromTimestamps, uint256[] calldata toTimestamps, uint256[] calldata percents) external onlyOwner() {
        
        require(fromTimestamps.length == toTimestamps.length, "Invalid releases");
        require(toTimestamps.length == percents.length, "Invalid releases");
        
        delete _releases;

        for (uint256 i = 0; i < fromTimestamps.length; i++) {
            _releases.push(Release(fromTimestamps[i], toTimestamps[i], percents[i]));
        }
        
    }
    

    //converting
    function _getAllocation(address wallet, uint256 index) internal view returns (uint256 fromTimestamp, uint256 toTimestamp, uint256 percent, uint256 claimable, uint256 total, uint256 claimed, uint256 remaining, uint256 status) {
        
        require(index < _releases.length, "Invalid release index");
        
        uint256 raiseDecimals = raiseTokenDecimals();
        uint256 releaseDecimals = releaseTokenDecimals();
        
        uint256 participated = getParticipatedTotal(wallet);
        
        Release storage r = _releases[index];
        
        fromTimestamp = r.fromTimestamp;
        toTimestamp = r.toTimestamp;
        
        percent = r.percent;
        
        total = participated.mul(_rate).div(1000000).mul(percent).div(10000);
        
        if(raiseDecimals > releaseDecimals)
            total = total.div(10 ** (raiseDecimals - releaseDecimals));
        
        if(releaseDecimals > raiseDecimals)
            total = total.mul(10 ** (releaseDecimals - raiseDecimals));
            
        claimable = total;
        
        if(toTimestamp > fromTimestamp && block.timestamp < toTimestamp) {
            
            uint256 elapsed = 0;
    
            if(block.timestamp > fromTimestamp) {
                elapsed = block.timestamp.sub(fromTimestamp);
            }
            
            uint256 duration = toTimestamp.sub(fromTimestamp);
            
            claimable = total.mul(elapsed).div(duration);
            
        }
        
        claimed = r.claimed[wallet];
        
        if(claimed < claimable)
            remaining = claimable.sub(claimed);
        
        if(_releaseToken != address(0)) {
        
            if(fromTimestamp == 0 || now >= fromTimestamp) {
        
                status = 1;
                
                if(_releaseTokenPair != address(0) && IERC20(_releaseToken).balanceOf(_releaseTokenPair) == 0)
                    status = 2;
                
                if(remaining == 0 || remaining > IERC20(_releaseToken).balanceOf(address(this)))
                    status = 2;
            }
        
        }
        
        return (fromTimestamp, toTimestamp, percent, claimable, total, claimed, remaining, status);
        
    }
    
    function _getRemaining(uint256 allocation, uint256 claimed) internal pure returns (uint256) {
        
        uint256 remaining = 0;
                
        if(claimed < allocation)
            remaining = allocation.sub(claimed);
            
        return remaining;
    }

    
    function claimAdmin(uint256 index, address[] calldata addresses) external onlyOwner() {
        for(uint256 i = 0; i < addresses.length; i++) {
            _claim(index, addresses[i]);
        }
    }
    
    function claim(uint256 index) external {
        _claim(index, msg.sender);
    }
    
    function _claim(uint256 index, address claimant) internal {
        
        require(_releaseToken != address(0), "Release token not yet defined");
        
        require(index < _releases.length, "Invalid release index");
        
        for (uint256 i = 0; i <= index; i++) {
        
            (,,,,,,uint256 remaining,uint256 status) = _getAllocation(claimant, i);
            
            if(status != 1)
                continue;
                
            IERC20(_releaseToken).transfer(claimant, remaining);
            
            _releases[i].claimed[claimant] = _releases[i].claimed[claimant].add(remaining);
            
            emit Claimed(i.add(1), claimant, remaining);
            
        }

    }
    
    /*
     *
     * infoAllocations() - allocation specific wallet info, called by frontend
     * 
     * Returns :
     * 
     * - number list (int)
     * - allocation amount list (int)
     * - timestamp list (int)
     * - claimed amount list (int)
     * - claim status list (int)
     *      0 - PENDING
     *      1 - OPEN
     *      2 - CLOSED
     */

    function infoAllocations() external view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
        
        uint256[] memory allocNumberList;
        uint256[] memory allocAmountList;
        uint256[] memory allocClaimedList;
        uint256[] memory allocReleasedList;
        uint256[] memory allocStatusList;

        if(_releaseToken != address(0) && _releases.length > 0) {
            
            uint256 rows = _releases.length.mul(2);
            
            allocNumberList = new uint256[](rows);
            allocAmountList = new uint256[](rows);
            allocClaimedList = new uint256[](rows);
            allocReleasedList = new uint256[](rows);
            allocStatusList = new uint256[](rows);
        
            for(uint256 i = 0; i < _releases.length; i++) {
                
                uint256 row = i.mul(2);
                
                (uint256 fromTimestamp, uint256 toTimestamp, uint256 percent, uint256 claimable, uint256 total, uint256 claimed, , uint256 status) = _getAllocation(msg.sender, i);

                allocNumberList[row] = i.add(1);
                allocNumberList[row+1] = i.add(1);
                
                allocAmountList[row] = claimable;
                allocAmountList[row+1] = total;
                
                allocClaimedList[row] = claimed;
                allocClaimedList[row+1] = percent;
                
                allocReleasedList[row] = fromTimestamp;
                allocReleasedList[row+1] = toTimestamp;
                
                allocStatusList[row] = status;
                allocStatusList[row+1] = 0;
                
            }

        }
        
        return (allocNumberList, allocAmountList, allocReleasedList, allocClaimedList, allocStatusList);

    }
    
    function setRate(uint256 rate) external onlyOwner() {
        _rate = rate;
    }
    
    function setOpenTimestamp(uint256 openTimestamp) external onlyOwner() {
        _openTimestamp = openTimestamp;
    }
    

    //coverted
    function setClosed(bool closed) external onlyOwner() {
        _closed = closed;
    }
    

    function isClosed() public view returns (bool) {
        
        if(_closed || block.timestamp >= closeTimestamp() || _participated >= _cap)
            return true;
            
        return false;
    }
    
    function closeTimestamp() public view returns (uint256) {
        
        uint256 ts = _openTimestamp;
        
        for(uint256 i = 0; i < _rounds.length; i++) {
            ts = ts.add(_rounds[i].durationSeconds);
        }
        
        return ts;
    }
    

    //converted
    function fcfsTimestamp() public view returns (uint256) {
        
        uint256 ts = _openTimestamp;
        
        for(uint256 i = 0; i < _rounds.length; i++) {
            if(_rounds[i].class == RoundClass.FCFS_PREPARE)
                return ts;
            if(_rounds[i].class == RoundClass.FCFS)
                return ts;
            ts = ts.add(_rounds[i].durationSeconds);
        }
        
        return ts;
    }
    
//converted
    function setCap(uint256 cap) external onlyOwner() {
        _cap = cap;
    }
    
    function raiseTokenDecimals() public view returns (uint256 decimals) {
        
        decimals = 18;
        
        if(_raiseToken != address(0))
            decimals = IERC20(_raiseToken).decimals();
        
        return decimals;
        
    }
    
    function raiseTokenBalance(address wallet) public view returns (uint256 balanceRaising) {
        
        balanceRaising = wallet.balance;
        
        if(_raiseToken != address(0))
            balanceRaising = IERC20(_raiseToken).balanceOf(wallet);
        
        return balanceRaising;
        
    }
    
    function raiseTokenSymbol() public view returns (string memory symbol) {
        
        symbol = "BNB";
        
        if(_raiseToken != address(0))
            symbol = IERC20(_raiseToken).symbol();
        
        return symbol;
        
    }
    
    function releaseTokenDecimals() public view returns (uint256 decimals) {
        
        decimals = 18;
        
        if(_releaseToken != address(0))
            decimals = IERC20(_releaseToken).decimals();
        
        return decimals;
        
    }
    
    /**
     * info() - called by frontend
     * 
     * Returns :
     * 
     * - RAISE Token ADDRESS eg. address(0) = ETH, else BEP20 token
     * - RAISE Token SYMBOL (string) eg. BUSD
     * - RAISE Token DECIMALS eg. BUSD - 18
     * - rate (6 DECIMALS)
     * - GLOBAL OPEN timestamp
     * - FCFS OPEN timestamp
     * - GLOBAL CLOSED timestamp
     * - total count of wallets given allocation to project (INT)
     * - state ( P = Pending, O = Open, C = Closed )
     * - total count of users participated (INT)
     * - total funds participated (Token DECIMALS)
     * - project MAX total funds allocated (Token DECIMALS)
     */
    
    function info() public view returns (address, string memory, uint256, uint256, uint256, uint256 fcfsTS, uint256 closeTS, uint256 allocationsCount, string memory state, uint256, uint256, uint256) {
        
        fcfsTS = fcfsTimestamp();
        closeTS = closeTimestamp();
            
        state = "C";
        
        if(!isClosed()) {
            
            if(block.timestamp < _openTimestamp)
                state = "P";
            else {
                
                if(fcfsTS == closeTS && block.timestamp < closeTS || fcfsTS < closeTS && block.timestamp < fcfsTS)
                    state = "O";
                    
                if(fcfsTS < closeTS && block.timestamp >= fcfsTS && block.timestamp < closeTS)
                    state = "F";
                
            }
            
        }
        
        for(uint256 i = 0; i < _tiers.length; i++)
            allocationsCount = allocationsCount.add(_tiers[i].allocatedCount);

        return (_raiseToken, raiseTokenSymbol(), raiseTokenDecimals(), _rate, _openTimestamp, fcfsTS, closeTS, allocationsCount, state, _participatedCount, _participated, _cap);
        
    }
    
    //converted
    function getParticipatedTotal(address wallet) public view returns (uint256) {
        
        uint256 p = 0;
        
        for (uint256 i = 0; i < _rounds.length; i++) {
            p += _rounds[i].participated[wallet];
        }

        return p;
        
    }
    
    //
    function getTier(address wallet) public view returns (uint256) {
        
        for (uint256 i = _tiers.length; i > 0; i--) {
             if(_tiers[i.sub(1)].allocated[wallet]) {
                 return i;
             }
        }
        
        return 0;
        
        
    }
    
    //converted
    function getAllocationRemaining(uint256 round, uint256 tier, address wallet) public view returns (uint256) {
        
        if(round == 0 || tier == 0)
            return 0;
        
        uint256 roundIndex = round.sub(1);
        uint256 tierIndex = tier.sub(1);
        
        require(roundIndex < _rounds.length, "Invalid round");
        require(tierIndex < _tiers.length, "Invalid tier");
        
        if(_tiers[tierIndex].allocated[wallet]) {

            uint256 participated = _rounds[roundIndex].participated[wallet];
            uint256 allocated = _rounds[roundIndex].tierAllocations[tierIndex];
            
            if(participated < allocated)
                return allocated.sub(participated);
            
        }
            
        return 0;
        
    }
     
    function _infoWallet(address wallet) public view returns (uint256, uint256, uint256, string memory, uint256) {
        
        uint256 round = 0;
        uint256 roundState = 4;
        string memory roundStateText = "";
        uint256 roundTimestamp = 0;
        
        uint256 tier = getTier(wallet);
        
        if(!isClosed()) {
            
            uint256 ts = _openTimestamp;
            
            if(block.timestamp < ts) {
                
                roundState = 0;
                roundStateText = string(abi.encodePacked("Allocation Round <u>opens</u> in:"));
                roundTimestamp = ts;
                
            } else {
        
                Round storage r;
                
                for (uint256 i = 0; i < _rounds.length; i++) {
                    
                    round = i.add(1);
                    
                    r = _rounds[i];
                
                    ts = ts.add(r.durationSeconds);
                    
                    if(block.timestamp < ts) {
                        
                        if(r.class == RoundClass.ALLOCATION) {
                            
                            roundState = 1;
                            roundStateText = string(abi.encodePacked("Allocation Round <u>closes</u> in:"));
                            roundTimestamp = ts;

                        }

                        if(r.class == RoundClass.FCFS_PREPARE) {
                            
                            roundState = 2;
                            roundStateText = string(abi.encodePacked("FCFS Round <u>opens</u> in:"));
                            roundTimestamp = ts;

                        }

                        if(r.class == RoundClass.FCFS) {
                            
                            roundState = 3;
                            roundStateText = string(abi.encodePacked("FCFS Round <u>closes</u> in:"));
                            roundTimestamp = ts;

                        }
                        
                        break;
                        
                    }
                    
                }
            
            }
            
        }
        
        return (tier, round, roundState, roundStateText, roundTimestamp);
        
    }
    
    /*
     *
     * infoWallet() - wallet specific info
     * 
     * Returns :
     * 
     * - ETH balance (18 DECIMALS)
     * - RAISE token balance (Token DECIMALS)
     * - 
     * - Tier (string)
     * - Round state (INT)
     * 
     *      0 - Allocation Round - PENDING/OPENING
     *      1 - Allocation Round - OPEN
     *      2 - First Come First Serve (FCFS) Round - PENDING/OPENING
     *      3 - First Come First Serve (FCFS) Round - OPEN
     *      4 - CLOSED
     *
     * - Round state text (string) 
     * - Round Timestamp (INT)
     * - max Token allocation remaining (Token DECIMALS)
     * - user participation (Token DECIMALS)
     * 
     */
    
    function infoWallet() external view returns (uint256, uint256, string memory, uint256, string memory, uint256, uint256, uint256) {
        
        (uint256 tier, uint256 round, uint256 roundState, string memory roundStateText, uint256 roundTimestamp) = _infoWallet(msg.sender);
        
        string memory tierName = tier == 0 ? "-" : _tiers[tier.sub(1)].name;
          
        return (msg.sender.balance, raiseTokenBalance(msg.sender), tierName, roundState, roundStateText, roundTimestamp, getAllocationRemaining(round, tier, msg.sender), getParticipatedTotal(msg.sender));
    }

    /*
     *
     * infoWalletAdmin() - wallet specific info
     * 
     * Returns :
     * 
     * - Tier (INT)
     * - Round (INT)
     * - max Token allocation remaining for round (Token DECIMALS)
     * - user participation (all rounds) (Token DECIMALS)
     * 
     */  
    
    
    function infoWalletAdmin(address wallet) external onlyOwner() view returns (uint256, uint256, uint256, uint256) {
        
        (uint256 tier, uint256 round,,,) = _infoWallet(wallet);
                        
        return (tier, round, getAllocationRemaining(round, tier, wallet), getParticipatedTotal(wallet));
    }
    
    /*
     *
     * infoRounds() - tier specific info, called by frontend
     * 
     * Returns :
     * 
     * - Round name list (string)
     * - Round open timestamp list (int)
     * - Round close timestamp list (int)
     * 
     */
    
    function infoRounds() public view returns (string[] memory, uint256[] memory, uint256[] memory) {
        
        string[] memory nameList;
        uint256[] memory openTimestampList;
        uint256[] memory closeTimestampList;
            
        if(_rounds.length > 0) {
            
            nameList = new string[](_rounds.length);
            openTimestampList = new uint256[](_rounds.length);
            closeTimestampList = new uint256[](_rounds.length);
            
            uint256 ts = _openTimestamp;
            
            for(uint256 i = 0; i < _rounds.length; i++) {
                
                nameList[i] = _rounds[i].name;
                openTimestampList[i] = ts;
                
                ts = ts.add(_rounds[i].durationSeconds);
                
                closeTimestampList[i] = ts;
            
            }
            
        }
        
        return (nameList, openTimestampList, closeTimestampList);
    }
    
    function participate(address token, uint256 amount) public payable {
        
        require(token == _raiseToken, "Incorrect token specified");
        require(amount > 0, "Amount must be greater than zero");
        
        (uint256 tier, uint256 round, uint256 roundState,,) = _infoWallet(msg.sender);
        
        require(roundState == 1 || roundState == 3, "Participation not valid/open");
        require(amount <= getAllocationRemaining(round, tier, msg.sender), "Amount exceeds remaining allocation");
        
        if(_raiseToken == address(0)) {
          require(msg.value == amount, "Insufficent native token sent to contract");
        } else {
            IERC20 t = IERC20(_raiseToken);
            
            require(t.allowance(msg.sender, address(this)) >= amount, "Insufficent allowance granted to contract, Please approve first");
           
            t.transferFrom(msg.sender, address(this), amount);
            
        }
        
        emit Participated(msg.sender, amount);
        
        _participated = _participated.add(amount);
        
        if(getParticipatedTotal(msg.sender) == 0)
            _participatedCount = _participatedCount.add(1);
        
        Round storage r = _rounds[round.sub(1)];
        
        r.participated[msg.sender] = r.participated[msg.sender].add(amount);

    }
    
    function transferToken(address token, uint256 amount, address to) public onlyOwner() {
        IERC20 t = IERC20(token);
        
        require(t.balanceOf(address(this)) >= amount,"Insufficent token balance to transfer amount.");
        t.transfer(to, amount);
    }
    
    function transferNativeToken(uint256 amount, address payable to) public onlyOwner() {
        require(address(this).balance >= amount,"Insufficent native token balance to transfer amount.");
        to.transfer(amount);
    }
    
}