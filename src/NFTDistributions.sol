// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Distributor is ERC721 {
// contract Distributor is ERC1155 {
    uint256 public currentTokenId = 0; // Initialize currentTokenId to 0
    address public owner;

    struct Park {
        string name;
        string imgUrl;
    }

    error InvalidParkName();
    error InvalidAccess();

    // Mapping from token ID to Park details
    mapping(uint256 => Park) public parks;

    // park anme => image url in IPFS
    mapping(string => string) public nationalParkBadges;
    mapping(address => uint256[]) public userCollections;
    mapping(address => bool) public isOperator;

    // modifier onlyOperator() {
    //     if (!isOperator[msg.sender]) {
    //         revert InvalidAccess();
    //     }
    //     _;
    // }
    modifier onlyOwner() {
        if (owner != msg.sender) {
            revert InvalidAccess();
        }
        _;
    }

    constructor() ERC721("National Park", "NP") {
        owner = msg.sender;
        nationalParkBadges[
            "yellowstone"
        ] = "https://gateway.btfs.io/btfs/QmQCwj7utxR6Mwev8spxhEDtU4K3KQcHWvGcMi4JGQmhGB?filename=yellowstone.jpg";
        // nationalParkBadges[
        //     "yosemite"
        // ] = "https://gateway.btfs.io/btfs/QmV13VBHGNJLftLzevUK5HpxoiTYdGMhnJqLy9J73wnUcW?filename=yosemite.jpg";
        // nationalParkBadges[
        //     "crater_lake"
        // ] = "https://gateway.btfs.io/btfs/QmUUkKczcdqoPyg8kC9FLTqpGiZfzbWnsvvCgSWgsetcow?filename=crater_lake.jpg";
    }
    
    function updateParkUrl(string memory _name, string memory _url, bool isAdd) external {
        if(isAdd) {
            nationalParkBadges[_name] = _url;
        } else {
            delete nationalParkBadges[_name];
        }
    }

    function setOperator(address _to, bool _isOperator) external onlyOwner {
        if(_to == address(0)) {
            revert InvalidAccess();
        }
        isOperator[_to] = _isOperator;
    }

    // Function to mint an unlimited number of NFTs for a national park
    function addBadge(string memory _name, address _to) external {
        uint256 tokenId = currentTokenId; // Assign the current token ID

        string memory _imgUrl = nationalParkBadges[_name];
        if (
            keccak256(abi.encodePacked((_imgUrl))) ==
            keccak256(abi.encodePacked(("")))
        ) {
            revert InvalidParkName();
        }
        // Store park details
        parks[tokenId] = Park(_name, _imgUrl);

        // Mint 1 NFT to the visitor (no cap on number of NFTs minted for the park)
        _mint(_to, tokenId);

        // Track the holder of the NFT
        // parkHolders[tokenId].push(_to);
        userCollections[_to].push(tokenId);

        // Increment the token ID for the next unique park
        currentTokenId++;
    }

    function getUserCollections(
        address _owner
    ) external view returns (Park[] memory) {
        uint256[] memory _collectionIndexes = userCollections[_owner];
        Park[] memory _userCollections = new Park[](_collectionIndexes.length);

        for (uint256 i = 0; i < _collectionIndexes.length; i++) {
            Park memory _park = parks[_collectionIndexes[i]];
            _userCollections[i] = _park;
        }
        return _userCollections;
    }
}
