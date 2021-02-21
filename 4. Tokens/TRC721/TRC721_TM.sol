pragma solidity ^0.4.26;

/**
 * Utility library of inline functions on addresses
 */
library Address {

	/**
	 * Returns whether the target address is a contract
	 * @dev This function will return false if invoked during the constructor of a contract,
	 * as the code is not actually created until after the constructor finishes.
	 * @param account address of the account to check
	 * @return whether the target address is a contract
	 */
	function isContract(address account) internal view returns (bool) {
		uint256 size;
		// XXX Currently there is no better way to check if there is a contract in an address
		// than to check the size of the code at that address.
		// See https://ethereum.stackexchange.com/a/14016/36603
		// for more details about how this works.
		// TODO Check this again before the Serenity release, because all addresses will be
		// contracts then.
		// solium-disable-next-line security/no-inline-assembly
		assembly { size := extcodesize(account) }
		return size > 0;
	}

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

	/**
	 * @dev Multiplies two numbers, reverts on overflow.
	 */
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b);

		return c;
	}

	/**
	 * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
	 */
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b > 0); // Solidity only automatically asserts when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}

	/**
	* @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
	*/
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b <= a);
		uint256 c = a - b;

		return c;
	}

	/**
	* @dev Adds two numbers, reverts on overflow.
	*/
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a);

		return c;
	}

	/**
	* @dev Divides two numbers and returns the remainder (unsigned integer modulo),
	* reverts when dividing by zero.
		*/
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b != 0);
		return a % b;
	}
}

contract IERC721Receiver {
	/**
	* @notice Handle the receipt of an NFT
	* @dev The ERC721 smart contract calls this function on the recipient
	* after a `safeTransfer`. This function MUST return the function selector,
	* otherwise the caller will revert the transaction. The selector to be
	* returned can be obtained as `this.onERC721Received.selector`. This
	* function MAY throw to revert and reject the transfer.
		* Note: the ERC721 contract address is always the message sender.
		* @param operator The address which called `safeTransferFrom` function
	* @param from The address which previously owned the token
	* @param tokenId The NFT identifier which is being transferred
	* @param data Additional data with no specified format
	* @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
	*/
	function onERC721Received(
		address operator,
		address from,
		uint256 tokenId,
		bytes data
	)
	public
	returns(bytes4);
}

contract IERC721 {

	event Transfer(
		address indexed from,
		address indexed to,
		uint256 indexed tokenId
	);
	event Approval(
		address indexed owner,
		address indexed approved,
		uint256 indexed tokenId
	);
	event ApprovalForAll(
		address indexed owner,
		address indexed operator,
		bool approved
	);

	function balanceOf(address owner) public view returns (uint256 balance);
	function ownerOf(uint256 tokenId) public view returns (address owner);

	function approve(address to, uint256 tokenId) public;
	function getApproved(uint256 tokenId)
	public view returns (address operator);

	function setApprovalForAll(address operator, bool _approved) public;
	function isApprovedForAll(address owner, address operator)
	public view returns (bool);

	function transferFrom(address from, address to, uint256 tokenId) public;
	function safeTransferFrom(address from, address to, uint256 tokenId)
	public;

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes data
	)
	public;
}

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is IERC721 {

	using SafeMath for uint256;
	using Address for address;

	// Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
	// which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
	bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

	// Mapping from token ID to owner
	mapping (uint256 => address) private _tokenOwner;

	// Mapping from token ID to approved address
	mapping (uint256 => address) private _tokenApprovals;

	// Mapping from owner to number of owned token
	mapping (address => uint256) private _ownedTokensCount;

	// Mapping from owner to operator approvals
	mapping (address => mapping (address => bool)) private _operatorApprovals;

	bytes4 private constant _InterfaceId_ERC721 = 0x80ac58cd;
	/*
	* 0x80ac58cd ===
	*   bytes4(keccak256('balanceOf(address)')) ^
	*   bytes4(keccak256('ownerOf(uint256)')) ^
	*   bytes4(keccak256('approve(address,uint256)')) ^
	*   bytes4(keccak256('getApproved(uint256)')) ^
	*   bytes4(keccak256('setApprovalForAll(address,bool)')) ^
	*   bytes4(keccak256('isApprovedForAll(address,address)')) ^
	*   bytes4(keccak256('transferFrom(address,address,uint256)')) ^
	*   bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
	*   bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'))
	*/

	constructor() public { }

	/**
	* @dev Gets the balance of the specified address
	* @param owner address to query the balance of
	* @return uint256 representing the amount owned by the passed address
	*/
	function balanceOf(address owner) public view returns (uint256) {
		require(owner != address(0));
		return _ownedTokensCount[owner];
	}

	/**
	* @dev Gets the owner of the specified token ID
	* @param tokenId uint256 ID of the token to query the owner of
	* @return owner address currently marked as the owner of the given token ID
	*/
	function ownerOf(uint256 tokenId) public view returns (address) {
		address owner = _tokenOwner[tokenId];
		require(owner != address(0));
		return owner;
	}

	/**
	* @dev Approves another address to transfer the given token ID
	* The zero address indicates there is no approved address.
		* There can only be one approved address per token at a given time.
		* Can only be called by the token owner or an approved operator.
		* @param to address to be approved for the given token ID
	* @param tokenId uint256 ID of the token to be approved
	*/
	function approve(address to, uint256 tokenId) public {
		address owner = ownerOf(tokenId);
		require(to != owner);
		require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

		_tokenApprovals[tokenId] = to;
		emit Approval(owner, to, tokenId);
	}

	/**
	* @dev Gets the approved address for a token ID, or zero if no address set
	* Reverts if the token ID does not exist.
			* @param tokenId uint256 ID of the token to query the approval of
		* @return address currently approved for the given token ID
			*/
	function getApproved(uint256 tokenId) public view returns (address) {
		require(_exists(tokenId));
		return _tokenApprovals[tokenId];
	}

	/**
	* @dev Sets or unsets the approval of a given operator
	* An operator is allowed to transfer all tokens of the sender on their behalf
	* @param to operator address to set the approval
	* @param approved representing the status of the approval to be set
	*/
	function setApprovalForAll(address to, bool approved) public {
		require(to != msg.sender);
		_operatorApprovals[msg.sender][to] = approved;
		emit ApprovalForAll(msg.sender, to, approved);
	}

	/**
	* @dev Tells whether an operator is approved by a given owner
	* @param owner owner address which you want to query the approval of
	* @param operator operator address which you want to query the approval of
	* @return bool whether the given operator is approved by the given owner
	*/
	function isApprovedForAll(
		address owner,
		address operator
	)
	public
	view
	returns (bool)
	{
		return _operatorApprovals[owner][operator];
	}

	/**
	* @dev Transfers the ownership of a given token ID to another address
	* Usage of this method is discouraged, use `safeTransferFrom` whenever possible
	* Requires the msg sender to be the owner, approved, or operator
	* @param from current owner of the token
	* @param to address to receive the ownership of the given token ID
	* @param tokenId uint256 ID of the token to be transferred
	*/
	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	)
	public
	{
		require(_isApprovedOrOwner(msg.sender, tokenId));
		require(to != address(0));

		_clearApproval(from, tokenId);
		_removeTokenFrom(from, tokenId);
		_addTokenTo(to, tokenId);

		emit Transfer(from, to, tokenId);
	}

	/**
	* @dev Safely transfers the ownership of a given token ID to another address
	* If the target address is a contract, it must implement `onERC721Received`,
	* which is called upon a safe transfer, and return the magic value
	* `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
	* the transfer is reverted.
		*
		* Requires the msg sender to be the owner, approved, or operator
	* @param from current owner of the token
	* @param to address to receive the ownership of the given token ID
	* @param tokenId uint256 ID of the token to be transferred
	*/
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	)
	public
	{
		// solium-disable-next-line arg-overflow
		safeTransferFrom(from, to, tokenId, "");
	}

	/**
	* @dev Safely transfers the ownership of a given token ID to another address
	* If the target address is a contract, it must implement `onERC721Received`,
	* which is called upon a safe transfer, and return the magic value
	* `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
	* the transfer is reverted.
		* Requires the msg sender to be the owner, approved, or operator
	* @param from current owner of the token
	* @param to address to receive the ownership of the given token ID
	* @param tokenId uint256 ID of the token to be transferred
	* @param _data bytes data to send along with a safe transfer check
	*/
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes _data
	)
	public
	{
		transferFrom(from, to, tokenId);
		// solium-disable-next-line arg-overflow
		require(_checkOnERC721Received(from, to, tokenId, _data));
	}

	/**
	* @dev Returns whether the specified token exists
	* @param tokenId uint256 ID of the token to query the existence of
	* @return whether the token exists
	*/
	function _exists(uint256 tokenId) internal view returns (bool) {
		address owner = _tokenOwner[tokenId];
		return owner != address(0);
	}

	/**
	* @dev Returns whether the given spender can transfer a given token ID
	* @param spender address of the spender to query
	* @param tokenId uint256 ID of the token to be transferred
	* @return bool whether the msg.sender is approved for the given token ID,
		*  is an operator of the owner, or is the owner of the token
	*/
	function _isApprovedOrOwner(
		address spender,
		uint256 tokenId
	)
	internal
	view
	returns (bool)
	{
		address owner = ownerOf(tokenId);
		// Disable solium check because of
		// https://github.com/duaraghav8/Solium/issues/175
		// solium-disable-next-line operator-whitespace
		return (
			spender == owner ||
			getApproved(tokenId) == spender ||
			isApprovedForAll(owner, spender)
		);
	}

	/**
	* @dev Internal function to mint a new token
	* Reverts if the given token ID already exists
		* @param to The address that will own the minted token
	* @param tokenId uint256 ID of the token to be minted by the msg.sender
	*/
	function _mint(address to, uint256 tokenId) internal {
		require(to != address(0));
		_addTokenTo(to, tokenId);
		emit Transfer(address(0), to, tokenId);
	}

	/**
	* @dev Internal function to burn a specific token
	* Reverts if the token does not exist
		* @param tokenId uint256 ID of the token being burned by the msg.sender
	*/
	function _burn(address owner, uint256 tokenId) internal {
		_clearApproval(owner, tokenId);
		_removeTokenFrom(owner, tokenId);
		emit Transfer(owner, address(0), tokenId);
	}

	/**
	* @dev Internal function to add a token ID to the list of a given address
	* Note that this function is left internal to make ERC721Enumerable possible, but is not
	* intended to be called by custom derived contracts: in particular, it emits no Transfer event.
		* @param to address representing the new owner of the given token ID
	* @param tokenId uint256 ID of the token to be added to the tokens list of the given address
	*/
	function _addTokenTo(address to, uint256 tokenId) internal {
		require(_tokenOwner[tokenId] == address(0));
		_tokenOwner[tokenId] = to;
		_ownedTokensCount[to] = _ownedTokensCount[to].add(1);
	}

	/**
	* @dev Internal function to remove a token ID from the list of a given address
	* Note that this function is left internal to make ERC721Enumerable possible, but is not
	* intended to be called by custom derived contracts: in particular, it emits no Transfer event,
	* and doesn't clear approvals.
	* @param from address representing the previous owner of the given token ID
	* @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
	*/
	function _removeTokenFrom(address from, uint256 tokenId) internal {
		require(ownerOf(tokenId) == from);
		_ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
		_tokenOwner[tokenId] = address(0);
	}

	/**
	* @dev Internal function to invoke `onERC721Received` on a target address
	* The call is not executed if the target address is not a contract
	* @param from address representing the previous owner of the given token ID
	* @param to target address that will receive the tokens
	* @param tokenId uint256 ID of the token to be transferred
	* @param _data bytes optional data to send along with the call
	* @return whether the call correctly returned the expected magic value
	 */
	function _checkOnERC721Received(
		address from,
		address to,
		uint256 tokenId,
		bytes _data
	)
	internal
	returns (bool)
	{
		if (!to.isContract()) {
			return true;
		}
		bytes4 retval = IERC721Receiver(to).onERC721Received(
			msg.sender, from, tokenId, _data);
			return (retval == _ERC721_RECEIVED);
	}

	/**
	* @dev Private function to clear current approval of a given token ID
	* Reverts if the given address is not indeed the owner of the token
		* @param owner owner of the token
	* @param tokenId uint256 ID of the token to be transferred
	*/
	function _clearApproval(address owner, uint256 tokenId) private {
		require(ownerOf(tokenId) == owner);
		if (_tokenApprovals[tokenId] != address(0)) {
			_tokenApprovals[tokenId] = address(0);
		}
	}
}

contract MyTRC721 is ERC721 {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev Constructor function
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
    }

    /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol.
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns an URI for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId));
        return _tokenURIs[tokenId];
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param uri string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId));
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned by the msg.sender
     */
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

