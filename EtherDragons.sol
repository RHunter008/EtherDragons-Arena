pragma solidity ^0.4.11;

import "./utils/safe-math.sol";
import "./utils/address-utils.sol";
import "./utils/string-utils.sol";
import "./utils/common-wallet.sol";
import "./parts/Ownership.sol";

/// @title Managing contract. Implements the logic of buying tokens, depositing / withdrawing of funds 
/// to the project account and tokens importing / exporting
contract EtherDragonsCore is DragonOwnership 
{
    using SafeMath8 for uint8;
    using SafeMath32 for uint32;
    using SafeMath256 for uint256;
    using AddressUtils for address;
    using StringUtils for string;
    using UintStringUtils for uint;

    // @dev Non Assigned address.
    address constant NA = address(0);

    /// @dev Bounty tokens count limit
    uint256 public constant BOUNTY_LIMIT = 2500;
    /// @dev Presale tokens count limit
    uint256 public constant PRESALE_LIMIT = 7500;
    ///@dev Total gen0tokens generation limit
    uint256 public constant GEN0_CREATION_LIMIT = 90000;
    
    /// @dev Number of tokens minted in presale stage
    uint256 internal presaleCount_;  
    /// @dev Number of tokens minted for bounty campaign
    uint256 internal bountyCount_;
   
    ///@dev Company bank address
    address internal bank_;

    // Extension ---------------------------------------------------------------

    /// @dev Contract is not payable. To fullfil balance method `depositTo`
    /// should be used.
    function ()
        public payable
    {
        revert();
    }

    /// @dev Funds amount on the contract account. This amount consists of deposits from players and the system reserve for payment of transactions
    /// A player may withdraw at any time the amount corresponding to his account in the game, minus transaction costs. 
    function getBalance() 
        public view returns (uint256)
    {
        return address(this).balance;
    }    

    /// @dev At the moment of the contract creation we transfer the bank address
    /// presell contract address set later
    constructor(
        address _bank
    )
        public
    {
        require(_bank != NA);
        
        controller_ = msg.sender;
        bank_ = _bank;
        
        // Meta
        name_ = "EtherDragons";
        symbol_ = "ED";
        url_ = "https://game.etherdragons.world/token/";

        // Token mint limit
        maxSupply_ = GEN0_CREATION_LIMIT + BOUNTY_LIMIT + PRESALE_LIMIT;
    }

    /// Number of tokens minted in presale stage
    function totalPresaleCount()
        public view returns(uint256)
    {
        return presaleCount_;
    }    

    /// @dev Number of tokens minted for bounty campaign
    function totalBountyCount()
        public view returns(uint256)
    {
        return bountyCount_;
    }    
    
    /// @dev Check if a new token could be minted. Return true if the count of minted
    /// tokens less than could be minted through contract deploy.
    /// @return True if the current count is less then maximum tokens available for now.
    function canMint()
        public view returns(bool)
    {
        return (mintCount_ + presaleCount_ + bountyCount_) < maxSupply_;
    }

    /// @dev Here we write the wallets'addresses of the server from which it is accessed
    /// to contract methods.
    /// @param _to New minion address
    function minionAdd(address _to)
        external controllerOnly
    {
        require(minions_[_to] == false, "already_minion");
        
        
        // allow the address to use contract tokens 
        _setApprovalForAll(address(this), _to, true);
        
        minions_[_to] = true;
    }

    /// @dev delete the address of the server wallet
    /// @param _to Minion address
    function minionRemove(address _to)
        external controllerOnly
    {
        require(minions_[_to], "not_a_minion");

        // and forbid this wallet to use tokens of the contract
        _setApprovalForAll(address(this), _to, false);
        minions_[_to] = false;
    }

    /// @dev Here a player can put funds to the account of the contract
    /// and get the same amount of in-game currency
    /// the game server understands who puts money at the wallet address
    function depositTo()
        public payable
    {
        emit Deposit(msg.sender, msg.value);
    }    
    
    /// @dev Transfer amount of ETHs to specified receiver. Only the owner can
    // call this method.
    /// @param _to Transfer receiver.
    /// @param _amount Transfer value.
    /// @param _transferCost Transfer cost.
    function transferAmount(address _to, uint256 _amount, uint256 _transferCost)
        external minionOnly
    {
        require((_amount + _transferCost) <= address(this).balance, "not enough money!");
        _to.transfer(_amount);

        // send the transfer cost to the wallet of the server 
        // withdraw  it from the balance of the contract. This amount must be withdrawn from the player
        // on the game server side
        if (_transferCost > 0) {
            msg.sender.transfer(_transferCost);
        }

        emit Withdraw(_to, _amount);
    }        

   /// @dev Mint a new token with specified params. Transfer `_fee` to the
    /// `bank`. 
    /// @param _to New token owner.
    /// @param _fee Transaction fee.
    /// @param _genNum Generation number..
    /// @param _genome New genome unique value.
    /// @param _parentA Parent A.
    /// @param _parentB Parent B.
    /// @param _petId Pet identifier.
    /// @param _params List of pet's parameters.
    /// @param _transferCost Transfer cost.
    /// @return New token id.
    function mintRelease(
        address _to,
        uint256 _fee,
        
        // Constant Token params
        uint8   _genNum,
        string   _genome,
        uint256 _parentA,
        uint256 _parentB,
        
        // Game-depening Token params
        uint256 _petId,  //if petID = 0, then it was created outside of the server
        string   _params,
        uint256 _transferCost
    )
        external minionOnly operateModeOnly returns(uint256)
    {
        require(canMint(), "can_mint");
        require(_to != NA, "_to");
        require((_fee + _transferCost) <= address(this).balance, "_fee");
        require(bytes(_params).length != 0, "params_length");
        require(bytes(_genome).length == 77, "genome_length");
        
        // Parents should be both 0 or both not.
        if (_parentA != 0 && _parentB != 0) {
            require(_parentA != _parentB, "same_parent");
        }
        else if (_parentA == 0 && _parentB != 0) {
            revert("parentA_empty");
        }
        else if (_parentB == 0 && _parentA != 0) {
            revert("parentB_empty");
        }

        uint256 tokenId = _createToken(_to, _genNum, _genome, _parentA, _parentB, _petId, _params);

        require(_checkAndCallSafeTransfer(NA, _to, tokenId, ""), "safe_transfer");

        // Transfer mint fee to the fund
        CommonWallet(bank_).receive.value(_fee)();

        emit Transfer(NA, _to, tokenId);

        // send the transfer cost to the server's wallet,
        // withdraw it from the balance of the contract. This amount must be withdrawn from the player
        // on the game server side
        if (_transferCost > 0) {
            msg.sender.transfer(_transferCost);
        }

        return tokenId;
    }

    /// @dev Create a new token via presale stage
    /// @param _to New token owner.
    /// @param _genome New genome unique value.
    /// @return New token id.
    /// at the pre-sale stage we sell zero-generation pets, which have only one genome.
    /// other attributes are get when it's importing to the server
    function mintPresell(address _to, string _genome)
        external presaleOnly presaleModeOnly returns(uint256)
    {
        require(presaleCount_ < PRESALE_LIMIT, "presale_limit");

        // Presale pet has no parameters. The pet receives them when enters the game.
        uint256 tokenId = _createToken(_to, 0, _genome, 0, 0, 0, "");
        presaleCount_ += 1;

        require(_checkAndCallSafeTransfer(NA, _to, tokenId, ""), "safe_transfer");

        emit Transfer(NA, _to, tokenId);
        
        return tokenId;
    }    
    
    /// @dev Create a new token for bounty activity
    /// @param _to New token owner.
    /// @return New token id.
    function mintBounty(address _to, string _genome)
        external controllerOnly returns(uint256)
    {
        require(bountyCount_ < BOUNTY_LIMIT, "bounty_limit");

        // bounty pet has no parameters. They will receive them after importing to the game.
        uint256 tokenId = _createToken(_to, 0, _genome, 0, 0, 0, "");
    
        bountyCount_ += 1;
        require(_checkAndCallSafeTransfer(NA, _to, tokenId, ""), "safe_transfer");

        emit Transfer(NA, _to, tokenId);

        return tokenId;
    }        
}
