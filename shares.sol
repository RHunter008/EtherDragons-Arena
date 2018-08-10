pragma solidity ^0.4.0;

import './utils/safe-math.sol';
import './utils/common-wallet.sol';

contract Shares is CommonWallet
{
    // Extension ---------------------------------------------------------------
    using SafeMath256 for uint256;
    // Types -------------------------------------------------------------------
    // Constants ---------------------------------------------------------------
    uint256 constant UNIT = 1000;

    struct Profit 
    {
        string  Name;
        uint256 ShareValue;
        address Wallet; 
        uint256 payed;
    }
    Profit[6] internal shares;

    uint256 internal remain_;
    
    // Lifetime ----------------------------------------------------------------
    function ()
        public payable
    {
        revert();
    }
    
    constructor()
        public
    {
        shares[0].Name = "RHunter";
        shares[0].ShareValue = 350;
        shares[0].Wallet = 0xd853a4a592ef30131d567a977b18260e462be9f6; //финалка
        shares[0].payed = 0;

        shares[1].Name = "AKlenin";
        shares[1].ShareValue = 200;
        shares[1].Wallet = 0x2222610843bf525d93b775b552e89721e8bfae69; //финалка
        shares[1].payed = 0;

        shares[2].Name = "ENikonorov";
        shares[2].ShareValue = 200;
        shares[2].Wallet = 0x1131484121a5ae9484d76342d8cb1b90fc5d3c04; //финалка
        shares[2].payed = 0;

        shares[3].Name = "DBelenkyi";
        shares[3].ShareValue = 100;
        shares[3].Wallet = 0x62Fcc105d40A8f5E8106D013C99C07F43338B3cB; //финалка
        shares[3].payed = 0;

        shares[4].Name = "KSahnov";
        shares[4].ShareValue = 75;
        shares[4].Wallet = 0xe97d5d7e662f76eff69dba806389f77b7457ba7a; //финалка
        shares[4].payed = 0; 

        shares[5].Name = "NLivanov";
        shares[5].ShareValue = 75;
        shares[5].Wallet = 0x47c5ed0e68b966d88ec0d6b88e2b4856fe481319; //финалка
        shares[5].payed = 0;
    }
    
    // Events ------------------------------------------------------------------
    // Modifiers ---------------------------------------------------------------
    // Methods -----------------------------------------------------------------
    function receive()
        external payable
    {
        uint256 total = msg.value.add(remain_);
        remain_ = total % UNIT;
        uint256 payment = total.sub(remain_);

        for (uint i = 0; i < shares.length; i++) 
        {
            // Send shares
            uint256 _share = payment.div(UNIT).mul(shares[i].ShareValue);
            address(shares[i].Wallet).transfer( _share );
            shares[i].payed += _share;
        }
    }
    
    function isInvestor() 
        internal view returns (bool)
    {
        for (uint i = 0; i < shares.length; i++) 
        {
            if (address(shares[i].Wallet) == msg.sender) return true;
        }  
        
        return false;
    }

    function getData(uint8 _investor)
        external view returns(string Name, uint256 ShareValue, uint256 Payed )
    {
        require(isInvestor(), "not_investor");
        require(_investor < shares.length , "not_investor");
        
        return ( shares[_investor].Name, shares[_investor].ShareValue, shares[_investor].payed);
    }
}
