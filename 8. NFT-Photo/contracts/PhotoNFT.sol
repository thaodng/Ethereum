pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import { ERC721Full } from "./openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
import { SafeMath } from "./openzeppelin-solidity/contracts/math/SafeMath.sol";
import { PhStorage } from "./storage/PhStorage.sol";
import { PhOwnable } from "./modifiers/PhOwnable.sol";


/**
 * @notice - This is the NFT contract for a photo
 */
contract PhotoNFT is ERC721Full, PhOwnable {
    using SafeMath for uint256;

    uint256 public currentPhotoId;

    struct PhotoData {  /// [Key]: photoNFT contract address
        string photoNFTName;
        string photoNFTSymbol;
        address ownerAddress;
        uint photoPrice;
        string ipfsHashOfPhoto;
        uint256 reputation;
    }
    mapping (address => PhotoData) photoDatas;  /// [Key]: photoNFT contract address
    
    constructor(
        string memory _nftName, 
        string memory _nftSymbol
    ) public ERC721Full(_nftName, _nftSymbol) {
        _mint(msg.sender, currentPhotoId);
    }

    /** 
     * @notice - Save a photoNFT data
     */
    function savePhotoNFTData(string memory _photoNFTName, string memory _photoNFTSymbol, address _ownerAddress, uint _photoPrice, string memory _ipfsHashOfPhoto) public returns (bool) {
        PhotoData storage photoData = photoDatas[address(this)];
        photoData.photoNFTName = _photoNFTName;
        photoData.photoNFTSymbol = _photoNFTSymbol;
        photoData.ownerAddress = _ownerAddress;
        photoData.photoPrice = _photoPrice;
        photoData.ipfsHashOfPhoto = _ipfsHashOfPhoto;
        photoData.reputation = 0;
    }

    /** 
     * @dev mint a photoNFT
     */
    function mint(address to) public returns (bool) {
        /// Mint a new PhotoNFT
        uint newPhotoId = getNextPhotoId();
        currentPhotoId++;
        _mint(to, newPhotoId);
    }


    ///--------------------------------------
    /// Getter methods
    ///--------------------------------------
    function getPhotoData(address photoNFTContractAddress) public view returns (PhotoData memory _photoData) {
        PhotoData memory photoData = photoDatas[photoNFTContractAddress];
        return photoData;
    }


    ///--------------------------------------
    /// Private methods
    ///--------------------------------------
    function getNextPhotoId() private returns (uint nextPhotoId) {
        return currentPhotoId.add(1);
    }
    

}
