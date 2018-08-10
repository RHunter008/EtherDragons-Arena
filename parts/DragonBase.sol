pragma solidity ^0.4.11;

import "./Control.sol";
import "../utils/safe-math.sol";
import "../utils/string-utils.sol";

/// @dev token description, storage and transfer functions
contract DragonBase is DragonAccessControl
{
    using SafeMath8 for uint8;
    using SafeMath32 for uint32;
    using SafeMath256 for uint256;
    using StringUtils for string;
    using UintStringUtils for uint;    

    /// @dev A Birth event is fired whenever a new dragon comes into existence. 
    event Birth(address owner, uint256 petId, uint256 tokenId, uint256 parentA, uint256 parentB, string genes, string params);

    /// @dev Token name
    string internal name_;
    /// @dev Token symbol
    string internal symbol_;
    /// @dev Token resolving url
    string internal url_;

    struct DragonToken {
        // Constant Token params
        uint8   genNum;  // generation number. uses for dragon view
        string  genome;  // genome description
        uint256 petId;   // offchain dragon identifier

        // Parents
        uint256 parentA;
        uint256 parentB;

        // Game-depening Token params
        string  params;  // can change in export operation

        // State
        address owner; 
    }

    /// @dev Count of minted tokens
    uint256 internal mintCount_;
    /// @dev Maximum token supply
    uint256 internal maxSupply_;
     /// @dev Count of burn tokens
    uint256 internal burnCount_;

    // Tokens state
    /// @dev Token approvals values
    mapping(uint256 => address) internal approvals_;
    /// @dev Operator approvals
    mapping(address => mapping(address => bool)) internal operatorApprovals_;
    /// @dev Token Index in owner's token list
    mapping(uint256 => uint256) internal ownerIndex_;
    /// @dev Owner's tokens list
    mapping(address => uint256[]) internal ownTokens_;
    /// @dev Tokens
    mapping(uint256 => DragonToken) internal tokens_;

    // @dev Non Assigned address.
    address constant NA = address(0);

    /// @dev Add token to a new owner. Increase owner's balance.
    /// @param _to Token receiver.
    /// @param _tokenId New token id.
    function _addTo(address _to, uint256 _tokenId)
        internal
    {
        DragonToken storage token = tokens_[_tokenId];
        require(token.owner == NA, "taken");

        uint256 lastIndex = ownTokens_[_to].length;
        ownTokens_[_to].push(_tokenId);
        ownerIndex_[_tokenId] = lastIndex;

        token.owner = _to;
    }

    /// @dev Create a new token and increase mintCount.
    /// @param _genome New token's genome.
    /// @param _params Token params string. 
    /// @param _parentA Token A parent.
    /// @param _parentB Token B parent.
    /// @return New token id.
    function _createToken(
        address _to,
        
        // Constant Token params
        uint8   _genNum,
        string   _genome,
        uint256 _parentA,
        uint256 _parentB,
        
        // Game-depening Token params
        uint256 _petId,
        string   _params        
    )
        internal returns(uint256)
    {
        uint256 tokenId = mintCount_.add(1);
        mintCount_ = tokenId;

        DragonToken memory token = DragonToken(
            _genNum,
            _genome,
            _petId,

            _parentA,
            _parentB,

            _params,
            NA
        );
        
        tokens_[tokenId] = token;
        
        _addTo(_to, tokenId);
        
        emit Birth(_to, _petId, tokenId, _parentA, _parentB, _genome, _params);
        
        return tokenId;
    }    
 
    /// @dev Get token genome.
    /// @param _tokenId Token id.
    /// @return Token's genome.
    function getGenome(uint256 _tokenId)
        external view returns(string)
    {
        return tokens_[_tokenId].genome;
    }

    /// @dev Get token params.
    /// @param _tokenId Token id.
    /// @return Token's params.
    function getParams(uint256 _tokenId)
        external view returns(string)
    {
        return tokens_[_tokenId].params;
    }

    /// @dev Get token parentA.
    /// @param _tokenId Token id.
    /// @return Parent token id.
    function getParentA(uint256 _tokenId)
        external view returns(uint256)
    {
        return tokens_[_tokenId].parentA;
    }   

    /// @dev Get token parentB.
    /// @param _tokenId Token id.
    /// @return Parent token id.
    function getParentB(uint256 _tokenId)
        external view returns(uint256)
    {
        return tokens_[_tokenId].parentB;
    }

    /// @dev Check if `_tokenId` exists. Check if owner is not addres(0).
    /// @param _tokenId Token id
    /// @return Return true if token owner is real.
    function isExisting(uint256 _tokenId)
        public view returns(bool)
    {
        return tokens_[_tokenId].owner != NA;
    }    

    /// @dev Receive maxium token supply value.
    /// @return Contracts `maxSupply_` variable.
    function maxSupply()
        external view returns(uint256)
    {
        return maxSupply_;
    }

    /// @dev Set url prefix for tokenURI generation.
    /// @param _url Url prefix value.
    function setUrl(string _url)
        external controllerOnly
    {
        url_ = _url;
    }

    /// @dev Get token symbol.
    /// @return Token symbol name.
    function symbol()
        external view returns(string)
    {
        return symbol_;
    }

    /// @dev Get token URI to receive offchain information by its id.
    /// @param _tokenId Token id.
    /// @return URL string. For example "http://erc721.tld/tokens/1".
    function tokenURI(uint256 _tokenId)
        external view returns(string)
    {
        return url_.concat(_tokenId.toString());
    }

     /// @dev Get token name.
    /// @return Token name string.
    function name()
        external view returns(string)
    {
        return name_;
    }

    /// @dev return information about _owner tokens
    function getTokens(address _owner)
        external view  returns (uint256[], uint256[], byte[]) 
    {
        uint256[] memory tokens = ownTokens_[_owner];
        uint256[] memory tokenIds = new uint256[](tokens.length);
        uint256[] memory petIds = new uint256[](tokens.length);

        byte[] memory genomes = new byte[](tokens.length * 77);
        uint index = 0;

        for(uint i = 0; i < tokens.length; i++) {
            uint256 tokenId = tokens[i];
            
            DragonToken storage token = tokens_[tokenId];

            tokenIds[i] = tokenId;
            petIds[i] = token.petId;
            
            bytes storage genome = bytes(token.genome);
            
            for(uint j = 0; j < genome.length; j++) {
                genomes[index++] = genome[j];
            }
        }
        return (tokenIds, petIds, genomes);
    }
    
}


