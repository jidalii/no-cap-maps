// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract Distributor is ERC1155, Ownable {
    uint256 public currentTokenId = 0;

    uint256 public constant MAX_SUPPLY = 1000;

    struct Park {
        string name;
        string imgUrl;
    }

    mapping(uint256 => Park) public parks;
    mapping(uint256 => address[]) public parkHolders;
    mapping(address => uint256[]) public userCollections;

    event NewBadgeAdded(string name, string category, string url);

    error InvalidNewBadge();

    constructor() ERC1155("") {}

    function _validateAddBadges(
        Park[] memory _badges
    ) internal pure {
        for (uint i = 0; i < _badges.length; i++) {
            if (
                keccak256(abi.encodePacked(_badges[i].name)) ==
                keccak256(abi.encodePacked("")) ||
                keccak256(abi.encodePacked(_badges[i].imgUrl)) ==
                keccak256(abi.encodePacked(""))
            ) {
                revert InvalidNewBadge();
            }
        }
    }

    function addBadges(
        Park[] memory _badges,
        string memory _category
    ) external {
        _validateAddBadges(_badges, _category);
        Park[] storage _collections = NFTCollections[_category];
        for (uint i = 0; i < _badges.length; i++) {
            _collections.push(_badges[i]);
            emit NewBadgeAdded(
                _badges[i].name,
                _badges[i].category,
                _badges[i].imgUrl
            );
        }
    }

    function mintNFT(
        string memory _name,
        string memory _imgUrl,
        address _to
    ) external onlyOwner {
        uint256 tokenId = currentTokenId; // Assign the current token ID

        // Store park details
        parks[tokenId] = Park(_name, _imgUrl);

        // Mint 1 NFT to the visitor (no cap on number of NFTs minted for the park)
        _mint(_to, tokenId, 1, "");

        // Track the holder of the NFT
        parkHolders[tokenId].push(_to);

        // Increment the token ID for the next unique park
        currentTokenId++;
    }

    // Function to get details of a specific park NFT
    function getParkDetails(
        uint256 _tokenId
    ) external view returns (string memory name, string memory imgUrl) {
        require(_tokenId < currentTokenId, "Invalid token ID");
        Park memory park = parks[_tokenId];
        return (park.name, park.imgUrl);
    }

    // Function to get the list of holders for a specific park (token ID)
    function getParkHolders(
        uint256 _tokenId
    ) external view returns (address[] memory) {
        return parkHolders[_tokenId];
    }

    function getUserCollection(address _owner) public view returns(Park[] memory) {
        uint256[] memory tokenIds =  userCollections[_owner];
        Park[] memory collections = new Park[](tokenIds.length); 
        for (uint256 i=0; i<tokenIds.length; i++) {
            collections[i] = parks[tokenIds[i]];
        }
        return collections;
    }

    // Override the URI function to return metadata for a specific token ID
    function uri(
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(_tokenId < currentTokenId, "Token does not exist");
        return
            string(
                abi.encodePacked(
                    "https://api.nationalparknft.com/metadata/",
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }

    function getUserNFTs(
        address _user
    ) external view returns (uint256[] memory) {
        uint256[] memory userTokens = new uint256[](currentTokenId); // Array to store token IDs
        uint256 counter = 0; // Count how many tokens the user owns

        for (uint256 i = 0; i < currentTokenId; i++) {
            if (balanceOf(_user, i) > 0) {
                userTokens[counter] = i; // Add token ID to array if balance > 0
                counter++;
            }
        }

        // Create a new array of the correct size (removing empty slots)
        uint256[] memory result = new uint256[](counter);
        for (uint256 i = 0; i < counter; i++) {
            result[i] = userTokens[i];
        }

        return result;
    }
}
