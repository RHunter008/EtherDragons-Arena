pragma solidity ^0.4.11;

/// @title A facet of DragonCore that manages special access privileges.
contract DragonAccessControl 
{
    // @dev Non Assigned address.
    address constant NA = address(0);

    /// @dev Contract owner
    address internal controller_;

    /// @dev Contract modes
    enum Mode {TEST, PRESALE, OPERATE}

    /// @dev Contract state
    Mode internal mode_ = Mode.TEST;

    /// @dev OffChain Server accounts ('minions') addresses
    /// It's used for money withdrawal and export of tokens 
    mapping(address => bool) internal minions_;
    
    /// @dev Presale contract address. Can call `presale` method.
    address internal presale_;

    // Modifiers ---------------------------------------------------------------
    /// @dev Limit execution to controller account only.
    modifier controllerOnly() {
        require(controller_ == msg.sender, "controller_only");
        _;
    }

    /// @dev Limit execution to minion account only.
    modifier minionOnly() {
        require(minions_[msg.sender], "minion_only");
        _;
    }

    /// @dev Limit execution to test time only.
    modifier testModeOnly {
        require(mode_ == Mode.TEST, "test_mode_only");
        _;
    }

    /// @dev Limit execution to presale time only.
    modifier presaleModeOnly {
        require(mode_ == Mode.PRESALE, "presale_mode_only");
        _;
    }

    /// @dev Limit execution to operate time only.
    modifier operateModeOnly {
        require(mode_ == Mode.OPERATE, "operate_mode_only");
        _;
    }

     /// @dev Limit execution to presale account only.
    modifier presaleOnly() {
        require(msg.sender == presale_, "presale_only");
        _;
    }

    /// @dev set state to Mode.OPERATE.
    function setOperateMode()
        external 
        controllerOnly
        presaleModeOnly
    {
        mode_ = Mode.OPERATE;
    }

    /// @dev Set presale contract address. Becomes useless when presale is over.
    /// @param _presale Presale contract address.
    function setPresale(address _presale)
        external
        controllerOnly
    {
        presale_ = _presale;
    }

    /// @dev set state to Mode.PRESALE.
    function setPresaleMode()
        external
        controllerOnly
        testModeOnly
    {
        mode_ = Mode.PRESALE;
    }    

        /// @dev Get controller address.
    /// @return Address of contract's controller.
    function controller()
        external
        view
        returns(address)
    {
        return controller_;
    }

    /// @dev Transfer control to new address. Set controller an approvee for
    /// tokens that managed by contract itself. Remove previous controller value
    /// from contract's approvees.
    /// @param _to New controller address.
    function setController(address _to)
        external
        controllerOnly
    {
        require(_to != NA, "_to");
        require(controller_ != _to, "already_controller");

        controller_ = _to;
    }

    /// @dev Check if address is a minion.
    /// @param _addr Address to check.
    /// @return True if address is a minion.
    function isMinion(address _addr)
        public view returns(bool)
    {
        return minions_[_addr];
    }   

    function getCurrentMode() 
        public view returns (Mode) 
    {
        return mode_;
    }    
}
