pragma solidity ^0.4.11;

import './utils/address-utils.sol';
import {EtherDragonsCore} from './EtherDragons.sol';

contract Presale
{
    // Extension ---------------------------------------------------------------
    using AddressUtils for address;

    // Events ------------------------------------------------------------------
    ///the event is fired when a new wave of presale stage starts
    event StageBegin(uint8 stage, uint256 timestamp);

    ///the event is fired when token sold
    event TokensBought(address buyerAddr, uint256[] tokenIds, bytes genomes);

    // Types -------------------------------------------------------------------
    struct Stage {
        // Predefined values
        uint256 price;      // token's price on the stage
        uint16 softcap;     // stage softCap
        uint16 hardcap;     // stage hardCap
        
        // Unknown values
        uint16 bought;      // sold on stage
        uint32 startDate;   // stage's beginDate
        uint32 endDate;     // stage's endDate
    }
    
    // Constants ---------------------------------------------------------------
    // 10 stages of 5 genocodes
    uint8 public constant STAGES = 10;
    uint8 internal constant TOKENS_PER_STAGE = 5;
    address constant NA = address(0);
    
    // State -------------------------------------------------------------------
    address internal CEOAddress;    // contract owner
    address internal bank_;         // profit wallet address (not a contract)
    address internal erc721_;       // main contract address
    
    /// @dev genomes for bounty stage
    string[TOKENS_PER_STAGE][STAGES] internal genomes_;

    /// stages data
    Stage[STAGES] internal stages_;
    
    // internal transaction counter, it uses for random generator
    uint32  internal counter_;
    
    /// stage is over
    bool    internal isOver_;

    /// stage number
    uint8   internal stageIndex_;

    ///  stage start Data
    uint32  internal stageStart_;

    // Lifetime ----------------------------------------------------------------
    constructor(
        address _bank,  
        address _erc721
    )
        public
    {
        require(_bank != NA, '_bank');
        require(_erc721.isContract(), '_erc721');

        CEOAddress = msg.sender;

        // Addresses should not be the same.
        require(_bank != CEOAddress, "bank = CEO");
        require(CEOAddress != _erc721, "CEO = erc721");
        require(_erc721 != _bank, "bank = erc721");

        // Update state
        bank_ = _bank;
        erc721_ = _erc721;
       
        // stages data 
        stages_[0].price = 10 finney;
        stages_[0].softcap = 100;
        stages_[0].hardcap = 300;
        
        stages_[1].price = 20 finney;
        stages_[1].softcap = 156;
        stages_[1].hardcap = 400;
    
        stages_[2].price = 32 finney;
        stages_[2].softcap = 212;
        stages_[2].hardcap = 500;
        
        stages_[3].price = 45 finney;
        stages_[3].softcap = 268;
        stages_[3].hardcap = 600;
        
        stages_[4].price = 58 finney;
        stages_[4].softcap = 324;
        stages_[4].hardcap = 700;
    
        stages_[5].price = 73 finney;
        stages_[5].softcap = 380;
        stages_[5].hardcap = 800;
    
        stages_[6].price = 87 finney;
        stages_[6].softcap = 436;
        stages_[6].hardcap = 900;
    
        stages_[7].price = 102 finney;
        stages_[7].softcap = 492;
        stages_[7].hardcap = 1000;
    
        stages_[8].price = 118 finney;
        stages_[8].softcap = 548;
        stages_[8].hardcap = 1100;
        
        stages_[9].price = 129 finney;
        stages_[9].softcap = 604;
        stages_[9].hardcap = 1200;
    }

    /// fill the genomes data
    function setStageGenomes(
        uint8 _stage,
        string _genome0, 
        string _genome1,
        string _genome2, 
        string _genome3, 
        string _genome4
    ) 
        external controllerOnly
    {
        genomes_[_stage][0] = _genome0;
        genomes_[_stage][1] = _genome1;
        genomes_[_stage][2] = _genome2;
        genomes_[_stage][3] = _genome3;
        genomes_[_stage][4] = _genome4;
    }

    /// @dev Contract itself is non payable
    function ()
        public payable
    {
        revert();
    }
    
    // Modifiers ---------------------------------------------------------------
    
    /// only from contract owner
    modifier controllerOnly() {
        require(msg.sender == CEOAddress, 'controller_only');
        _;
    }

    /// only for active stage
    modifier notOverOnly() {
        require(isOver_ == false, 'notOver_only');
        _;
    }

    // Getters -----------------------------------------------------------------
    /// owner address
    function getCEOAddress()
        public view returns(address)
    {
        return CEOAddress;
    }

    /// counter from random number generator
    function counter()
        internal view returns(uint32)
    {
        return counter_;
    }

    // tokens sold by stage ...
    function stageTokensBought(uint8 _stage)
        public view returns(uint16)
    {
        return stages_[_stage].bought;
    }

    // stage softcap
    function stageSoftcap(uint8 _stage)
        public view returns(uint16)
    {
        return stages_[_stage].softcap;
    }

    /// stage hardcap
    function stageHardcap(uint8 _stage)
        public view returns(uint16)
    {
        return stages_[_stage].hardcap;
    }

    /// stage Start Date    
    function stageStartDate(uint8 _stage)
        public view returns(uint)
    {
        return stages_[_stage].startDate;
    }
    
    /// stage Finish Date
    function stageEndDate(uint8 _stage)
        public view returns(uint)
    {
        return stages_[_stage].endDate;
    }

    /// stage token price
    function stagePrice(uint _stage)
        public view returns(uint)
    {
        return stages_[_stage].price;
    }
    
    // Genome Logic -----------------------------------------------------------------
    /// Dragons are created at the presale stage as the ancestors of all next dragon generations.
    /// These generations inherit the signs of their parents and may mutate in the future.
    /// Players combine dragons to bring out a breed with necessary features.
    /// They need to properly interbreed dragons in order to obtain the required set of combat skills.
    /// Dragons will receive these skills after they are transferred to the game server.   
    function nextGenome()
        internal returns(string)
    {
        uint8 n = getPseudoRandomNumber();

        counter_ += 1;
        
        return genomes_[stageIndex_][n];
    }

    function getPseudoRandomNumber()
        internal view returns(uint8 index)
    {
        uint8 n = uint8(
            keccak256(abi.encode(msg.sender, block.timestamp + counter_))
        );
        return n % TOKENS_PER_STAGE;
    }
    
    // PreSale Logic -----------------------------------------------------------------
    /// Presale stage0 begin date set
    /// presale start is possible only once    
    function setStartDate(uint32 _startDate)
        external controllerOnly
    {
        require(stages_[0].startDate == 0, 'already_set');
        
        stages_[0].startDate = _startDate;
        stageStart_ = _startDate;
        stageIndex_ = 0;
        
        emit StageBegin(stageIndex_, stageStart_); 
    }

    /// current stage number
    /// switches to the next stage if the time has come
    function stageIndex()
        external view returns(uint8)
    {
        Stage memory stage = stages_[stageIndex_];

        if (stage.endDate > 0 && stage.endDate <= now) {
            return stageIndex_ + 1;
        }
        else {
            return stageIndex_;
        }
    }
    
    /// check whether the phase started
    /// switch to the next stage, if necessary    
    function beforeBuy()
        internal
    {
        if (stageStart_ == 0) {
            revert('presale_not_started');
        }
        else if (stageStart_ > now) {
            revert('stage_not_started');
        }

        Stage memory stage = stages_[stageIndex_];
        if (stage.endDate > 0 && stage.endDate <= now) 
        {
            stageIndex_ += 1;
            stageStart_ = stages_[stageIndex_].startDate;

            if (stageStart_ > now) {
                revert('stage_not_started');
            }
        }
    }
    
    /// time to next midnight
    function midnight()
        public view returns(uint32)
    {
        uint32 tomorrow = uint32(now + 1 days);
        uint32 remain = uint32(tomorrow % 1 days);
        return tomorrow - remain;
    }
    
    /// buying a specified number of tokens
    function buyTokens(uint16 numToBuy)
        public payable notOverOnly returns(uint256[])
    {
        beforeBuy();
        
        require(numToBuy > 0 && numToBuy <= 10, "numToBuy error");

        Stage storage stage = stages_[stageIndex_];
        require((stage.price * numToBuy) <= msg.value, 'price');
        
        uint16 prevBought = stage.bought;
        require(prevBought + numToBuy <= stage.hardcap, "have required tokens");
        
        stage.bought += numToBuy;
        uint256[] memory tokenIds = new uint256[](numToBuy);
        
        bytes memory genomes = new bytes(numToBuy * 77);
        uint32 genomeByteIndex = 0;

        for(uint16 t = 0; t < numToBuy; t++) 
        {
            string memory genome = nextGenome();
            uint256 tokenId = EtherDragonsCore(erc721_).mintPresell(msg.sender, genome);

            bytes memory genomeBytes = bytes(genome);
            
            for(uint8 gi = 0; gi < genomeBytes.length; gi++) {
                genomes[genomeByteIndex++] = genomeBytes[gi];
            }

            tokenIds[t] = tokenId;
        }

        // Transfer mint fee to the fund
        bank_.transfer(address(this).balance);

        if (stage.bought == stage.hardcap) {
            stage.endDate = uint32(now);
            stageStart_ = midnight() + 1 days + 1 seconds;
            if (stageIndex_ < STAGES - 1) {
                stageIndex_ += 1;
            }
            else {
                isOver_ = true;
            }
        }
        else if (stage.bought >= stage.softcap && prevBought < stage.softcap) {
            stage.endDate = midnight() + 1 days;
            if (stageIndex_ < STAGES - 1) {
                stages_[stageIndex_ + 1].startDate = stage.endDate + 1 days;
            }
        }

        emit TokensBought(msg.sender, tokenIds, genomes);

        return tokenIds;
    }

    function currTime()
        public view returns(uint)
    {
        return now;
    }
    
    /// stages data
    function getStagesInfo() 
        public view returns (uint256[] prices, uint16[] softcaps, uint16[] hardcaps, uint16[] boughts) 
    {
            prices = new uint256[](STAGES);
            softcaps = new uint16[](STAGES);
            hardcaps = new uint16[](STAGES);
            boughts = new uint16[](STAGES);
            
            for(uint8 s = 0; s < STAGES; s++) {
                prices[s] = stages_[s].price;
                softcaps[s] = stages_[s].softcap;
                hardcaps[s] = stages_[s].hardcap;
                boughts[s] = stages_[s].bought;
            }
    }
    
    /// stages dates data
    function getStagesBeginEnd() 
        public view returns (uint32[] startDates, uint32[] endDates) 
    {
        startDates = new uint32[](STAGES);
        endDates = new uint32[](STAGES);
        
        for(uint8 s = 0; s < STAGES; s++) {
            startDates[s] = stages_[s].startDate;
            endDates[s] = stages_[s].endDate;
        }
    }

    /// returns data which genomes can be purchased at the stage
    function stageGenomes(uint8 _stage)
        public view returns(byte[])
    {
        byte[] memory genomes = new byte[](uint16(TOKENS_PER_STAGE) * 77);
        uint32 gbIndex = 0;

        for(uint8 tokenIndex = 0; tokenIndex < TOKENS_PER_STAGE; tokenIndex++) {
            
            bytes memory genomeBytes = bytes(genomes_[_stage][tokenIndex]);
            
            for(uint8 gi = 0; gi < genomeBytes.length; gi++) {
                genomes[gbIndex++] = genomeBytes[gi];
            }
        }

        return genomes;
    }
}
