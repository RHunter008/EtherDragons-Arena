pragma solidity ^0.4.16;

import './utils/safe-math.sol';
import './utils/common-wallet.sol';
import './utils/datetime.sol';

contract Bank is CommonWallet, DateTime 
{
    event Withdraw(address indexed _sender, uint256 _value);
    event NewMonth(uint256 _monthNum);
    
    // Extension ---------------------------------------------------------------
    using SafeMath256 for uint256;
    // Types -------------------------------------------------------------------
    // Constants ---------------------------------------------------------------

    // @dev Non Assigned address.
    address constant NA = address(0);

    // State -------------------------------------------------------------------
    
    //месячный лимит СМО, устанавливается 1го числа месяца
    uint256 internal CMOLimit;
    
    //сколько уже выплачено в этом месяце
    uint256 internal CMOPayed;

    //месячный лимит СМО, устанавливается 1го числа месяца
    uint256 internal CFOLimit;
    
    //сколько уже выплачено в этом месяце
    uint256 internal CFOPayed;

    // адрес контролера
    address public CEOAddress;

    // деньги на маркетинг и маркетмейкинг
    address public CMOAddress;
    
    // деньги на развитие проекта
    address public CFOAddress;
    
    //деньги инвесторам
    address internal profitAddr;
    
    //
    uint internal prevTransfer = 0;
    uint8 internal prevMonth = 0;


    // Lifetime ----------------------------------------------------------------
    constructor(
        address _CMOAddress,
        address _CFOAddress,
        address _profitAddr
    )
        public
    {
        require(_profitAddr != NA, '_profitAddr');
        require(_CMOAddress != NA, '_CMOAddress');
        require(_CFOAddress != NA, '_CFOAddress');

        CEOAddress = msg.sender;

        profitAddr = _profitAddr;
        
        CMOAddress = _CMOAddress;
        CMOLimit = 20 ether; 
        
        CFOAddress = _CFOAddress;
        CFOLimit = 30 ether;
    }
    // Events ------------------------------------------------------------------
    // Modifiers ---------------------------------------------------------------
    modifier controllerOnly() {
        require(msg.sender == CEOAddress, 'controller_only');
        _;
    }

    // Methods -----------------------------------------------------------------
    function getBalance()
        public view returns(uint256)
    {
        return address(this).balance;   
    }
    
    function receive()
        external payable
    {
    }
    
    /// @dev Transfer control to new address. 
    /// @param _to New controller address.
    function setController(address _to)
        external controllerOnly
    {
        require(_to != NA, "_to");
        require(CEOAddress != _to, "already_controller");

        CEOAddress = _to;
    }
    
    function setCFO(address _newCFO, uint256 _newCFOLimit)
        external controllerOnly
    {
        require(_newCFO != NA, "_newCFO is null");
        CFOAddress = _newCFO;
        CFOLimit = _newCFOLimit;
    }

    function setCMO(address _newCMO, uint256 _newCMOLimit)
        external controllerOnly
    {
        require(_newCMO != NA, "_newCMO is null");
        CMOAddress = _newCMO;
        CMOLimit = _newCMOLimit;
    }    
    
    function setProfitAddr(address _newProfitAddr)
        external controllerOnly
    {
        require(_newProfitAddr != NA, "_newProfitAddr is null");
        profitAddr = _newProfitAddr;
    }          
    
    function transferFunds()
        external
    {
        require ( now - prevTransfer > 1 days, "too often" );
        prevTransfer = now;
        
        // сброс лимитов раз в месяц
        uint8 month = getMonth(now);
        if (month != prevMonth)
        {
            CFOPayed = 0;
            CMOPayed = 0;
            prevMonth = month;
            emit NewMonth(month);
        }

        uint toPayoff = address(this).balance;
        
        // выплата команде
        uint CFOShare = CFOLimit.sub(CFOPayed);
        
        if (CFOShare > toPayoff) 
            CFOShare = toPayoff;
        
        CFOPayed = CFOPayed.add(CFOShare);
        toPayoff = toPayoff.sub(CFOShare);
        
        if (CFOShare > 0) 
        {
            address(CFOAddress).transfer(CFOShare);            
            emit Withdraw(CFOAddress, CFOShare);
        }
        
        // выплата маркетологам
        uint CMOShare = CMOLimit.sub(CMOPayed);
        
        if (CMOShare > toPayoff) 
            CMOShare = toPayoff;
        
        CMOPayed = CMOPayed.add(CMOShare);
        toPayoff = toPayoff.sub(CMOShare);
        
        if (CMOShare > 0)
        {
            address(CMOAddress).transfer(CMOShare);       
            emit Withdraw(CMOAddress, CMOShare);
        }
            
        if (toPayoff > 0) 
        {
            CommonWallet(profitAddr).receive.value( toPayoff )();
            emit Withdraw(profitAddr, toPayoff);
        }
    }

    function getCMOData()
        external controllerOnly
        view returns(uint256 LimitValue, uint256 Payed )
    {
        return (CMOLimit, CMOPayed);
    }    

    function getCFOData()
        external controllerOnly
        view returns(uint256 LimitValue, uint256 Payed )
    {
        return (CFOLimit, CFOPayed);
    }        
    
    function canTransfer()
        external view returns (bool)
    {
        if (now - prevTransfer > 1 days) return true;
        else return false;
    }

}
