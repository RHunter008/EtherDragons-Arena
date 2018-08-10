pragma solidity ^0.4.11;

import "./ERC721.sol";
import "./DragonBase.sol";
import "../utils/string-utils.sol";
import "../utils/address-utils.sol";

/// @dev ERC721 methods
contract DragonOwnership is ERC721, DragonBase
{
    using StringUtils for string;
    using UintStringUtils for uint;    
    using AddressUtils for address;

    /// @dev Issued when a token is transferred to a new owner. Additional fields are petId, genes, params
    /// it uses for client-side indication
    event TransferInfo(address indexed _from, address indexed _to, uint256 _tokenId, uint256 petId, string genes, string params);

    /// @dev Specify if _addr is a token owner or an approvee. Also check if `_addr`
    /// is operator for a token owner.
    /// @param _tokenId Check if token belongs to address.
    /// @param _addr Address to check if it's an owner or an aprovee of `_tokenId`.
    /// @return True if a token can be managed by provided `_addr`.
    function isOwnerOrApproved(uint256 _tokenId, address _addr)
        public view returns(bool)
    {
        DragonToken memory token = tokens_[_tokenId];

        if (token.owner == _addr) {
            return true;
        }
        else if (isApprovedFor(_tokenId, _addr)) {
            return true;
        }
        else if (isApprovedForAll(token.owner, _addr)) {
            return true;
        }

        return false;
    }

    /// @dev Limit execution to token owner or approvee only.
    /// @param _tokenId Check if token belongs to address.
    modifier ownerOrApprovedOnly(uint256 _tokenId) {
        require(isOwnerOrApproved(_tokenId, msg.sender), "tokenOwnerOrApproved_only");
        _;
    }

    /// @dev The action is allowed only if the smart contract is token owner itself, not a player.
    /// @param _tokenId Contract's token id.
    modifier ownOnly(uint256 _tokenId) {
        require(tokens_[_tokenId].owner == address(this), "own_only");
        _;
    }

    /// @dev Determine if token is approved for specified approvee.
    /// @param _tokenId Target token id.
    /// @param _approvee Approvee address.
    /// @return True if so.
    function isApprovedFor(uint256 _tokenId, address _approvee)
        public view returns(bool)
    {
        return approvals_[_tokenId] == _approvee;
    }

    /// @dev Specify is given address set as operator with setApprovalForAll.
    /// @param _owner Token owner.
    /// @param _operator Address to check if it an operator.
    /// @return True if operator is set.
    function isApprovedForAll(address _owner, address _operator)
        public view returns(bool)
    {
        return operatorApprovals_[_owner][_operator];
    }

    /// @dev Check if `_tokenId` exists. Check if owner is not addres(0).
    /// @param _tokenId Token id
    /// @return Return true if token owner is real.
    function exists(uint256 _tokenId)
        public view returns(bool)
    {
        return tokens_[_tokenId].owner != NA;
    }

    /// @dev Get owner of a token.
    /// @param _tokenId Token owner id.
    /// @return Token owner address.
    function ownerOf(uint256 _tokenId)
        public view returns(address)
    {
        return tokens_[_tokenId].owner;
    }

    /// @dev Get approvee address. If there is not approvee returns 0x0.
    /// @param _tokenId Token id to get approvee of.
    /// @return Approvee address or 0x0.
    function getApproved(uint256 _tokenId)
        public view returns(address)
    {
        return approvals_[_tokenId];
    }

    /// @dev Grant owner alike controll permissions to third party.
    /// @param _to Permission receiver.
    /// @param _tokenId Granted token id.
    function approve(address _to, uint256 _tokenId)
        external ownerOrApprovedOnly(_tokenId)
    {
        address owner = ownerOf(_tokenId);
        require(_to != owner);

        if (getApproved(_tokenId) != NA || _to != NA) {
            approvals_[_tokenId] = _to;

            emit Approval(owner, _to, _tokenId);
        }
    }

    /// @dev Current total tokens supply. Always less then maxSupply.
    /// @return Difference between minted and burned tokens.
    function totalSupply()
        public view returns(uint256)
    {
        return mintCount_;
    }    

    /// @dev Get number of tokens which `_owner` owns.
    /// @param _owner Address to count own tokens.
    /// @return Count of owned tokens.
    function balanceOf(address _owner)
        external view returns(uint256)
    {
        return ownTokens_[_owner].length;
    }    

    /// @dev Internal set approval for all without _owner check.
    /// @param _owner Granting user.
    /// @param _to New account approvee.
    /// @param _approved Set new approvee status.
    function _setApprovalForAll(address _owner, address _to, bool _approved)
        internal
    {
        operatorApprovals_[_owner][_to] = _approved;

        emit ApprovalForAll(_owner, _to, _approved);
    }

    /// @dev Set approval for all account tokens.
    /// @param _to Approvee address.
    /// @param _approved Value true or false.
    function setApprovalForAll(address _to, bool _approved)
        external
    {
        require(_to != msg.sender);

        _setApprovalForAll(msg.sender, _to, _approved);
    }

    /// @dev Remove approval bindings for token. Do nothing if no approval
    /// exists.
    /// @param _from Address of token owner.
    /// @param _tokenId Target token id.
    function _clearApproval(address _from, uint256 _tokenId)
        internal
    {
        if (approvals_[_tokenId] == NA) {
            return;
        }

        approvals_[_tokenId] = NA;
        emit Approval(_from, NA, _tokenId);
    }

    /// @dev Check if contract was received by other side properly if receiver
    /// is a ctontract.
    /// @param _from Current token owner.
    /// @param _to New token owner.
    /// @param _tokenId token Id.
    /// @param _data Transaction data.
    /// @return True on success.
    function _checkAndCallSafeTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    )
        internal returns(bool)
    {
        if (! _to.isContract()) {
            return true;
        }

        bytes4 retval = ERC721Receiver(_to).onERC721Received(
            _from, _tokenId, _data
        );

        return (retval == ERC721_RECEIVED);
    }

    /// @dev Remove token from owner. Unrecoverable.
    /// @param _tokenId Removing token id.
    function _remove(uint256 _tokenId)
        internal
    {
        address owner = tokens_[_tokenId].owner;
        _removeFrom(owner, _tokenId);
    }

    /// @dev Completely remove token from the contract. Unrecoverable.
    /// @param _owner Owner of removing token.
    /// @param _tokenId Removing token id.
    function _removeFrom(address _owner, uint256 _tokenId)
        internal
    {
        uint256 lastIndex = ownTokens_[_owner].length.sub(1);
        uint256 lastToken = ownTokens_[_owner][lastIndex];

        // Swap users token
        ownTokens_[_owner][ownerIndex_[_tokenId]] = lastToken;
        ownTokens_[_owner].length--;

        // Swap token indexes
        ownerIndex_[lastToken] = ownerIndex_[_tokenId];
        ownerIndex_[_tokenId] = 0;

        DragonToken storage token = tokens_[_tokenId];
        token.owner = NA;
    }

    /// @dev Transfer token from owner `_from` to another address or contract
    /// `_to` by it's `_tokenId`.
    /// @param _from Current token owner.
    /// @param _to New token owner.
    /// @param _tokenId token Id.
    function transferFrom( address _from, address _to, uint256 _tokenId )
        public ownerOrApprovedOnly(_tokenId)
    {
        require(_from != NA);
        require(_to != NA);

        _clearApproval(_from, _tokenId);
        _removeFrom(_from, _tokenId);
        _addTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);

        DragonToken storage token = tokens_[_tokenId];
        emit TransferInfo(_from, _to, _tokenId, token.petId, token.genome, token.params);
    }

    /// @dev Update token params and transfer to new owner. Only contract's own
    /// tokens could be updated. Also notifies receiver of the token.
    /// @param _to Address to transfer token to.
    /// @param _tokenId Id of token that should be transferred.
    /// @param _params New token params.
    function updateAndSafeTransferFrom(
        address _to,
        uint256 _tokenId,
        string _params
    )
        public
    {
        updateAndSafeTransferFrom(_to, _tokenId, _params, "");
    }

    /// @dev Update token params and transfer to new owner. Only contract's own
    /// tokens could be updated. Also notifies receiver of the token and send
    /// protion of _data to it.
    /// @param _to Address to transfer token to.
    /// @param _tokenId Id of token that should be transferred.
    /// @param _params New token params.
    /// @param _data Notification data.
    function updateAndSafeTransferFrom(
        address _to,
        uint256 _tokenId,
        string _params,
        bytes _data
    )
        public
    {
        // Safe transfer from
        updateAndTransferFrom(_to, _tokenId, _params, 0, 0);
        require(_checkAndCallSafeTransfer(address(this), _to, _tokenId, _data));
    }

    /// @dev Update token params and transfer to new owner. Only contract's own
    /// tokens could be updated.
    /// @param _to Address to transfer token to.
    /// @param _tokenId Id of token that should be transferred.
    /// @param _params New token params.
    function updateAndTransferFrom(
        address _to,
        uint256 _tokenId,
        string _params,
        uint256 _petId, 
        uint256 _transferCost
    )
        public
        ownOnly(_tokenId)
        minionOnly
    {
        require(bytes(_params).length > 0, "params_length");

        // Update
        tokens_[_tokenId].params = _params;
        if (tokens_[_tokenId].petId == 0 ) {
            tokens_[_tokenId].petId = _petId;
        }

        address from = tokens_[_tokenId].owner;

        // Transfer from
        transferFrom(from, _to, _tokenId);

        // send to the server's wallet the transaction cost
        // withdraw it from the balance of the contract. this amount must be withdrawn from the player
        // on the side of the game server        
        if (_transferCost > 0) {
            msg.sender.transfer(_transferCost);
        }
    }

    /// @dev Transfer token from one owner to new one and check if it was
    /// properly received if receiver is a contact.
    /// @param _from Current token owner.
    /// @param _to New token owner.
    /// @param _tokenId token Id.
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
    {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    /// @dev Transfer token from one owner to new one and check if it was
    /// properly received if receiver is a contact.
    /// @param _from Current token owner.
    /// @param _to New token owner.
    /// @param _tokenId token Id.
    /// @param _data Transaction data.
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    )
        public
    {
        transferFrom(_from, _to, _tokenId);
        require(_checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
    }

    /// @dev Burn owned token. Increases `burnCount_` and decrease `totalSupply`
    /// value.
    /// @param _tokenId Id of burning token.
    function burn(uint256 _tokenId)
        public
        ownerOrApprovedOnly(_tokenId)
    {
        address owner = tokens_[_tokenId].owner;
        _remove(_tokenId);

        burnCount_ += 1;

        emit Transfer(owner, NA, _tokenId);
    }

    /// @dev Receive count of burned tokens. Should be greater than `totalSupply`
    /// but less than `mintCount`.
    /// @return Number of burned tokens
    function burnCount()
        external
        view
        returns(uint256)
    {
        return burnCount_;
    }

    function onERC721Received(address, uint256, bytes)
        public returns(bytes4) 
    {
        return ERC721_RECEIVED;
    }
}
