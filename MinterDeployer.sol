// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MinterDeployer{
    
    address payable owner;
    uint deploymentPrice;
    mapping (uint => address) public minteraddresses;
    uint currentMinterId;
    
    constructor(uint _price){
        owner = payable(msg.sender);
        deploymentPrice = _price;
        currentMinterId = 0;
    }
    
    function deployMinter(string memory _name, string memory _symbol, uint _maxMintAllowed, uint _price) public payable returns(uint){
        require(msg.value >= deploymentPrice, "Not enough ETH sent");
        owner.transfer(msg.value);
        currentMinterId ++;
        minteraddresses[currentMinterId] =  address(new NftMinter(_name,_symbol, msg.sender, _maxMintAllowed, _price));
        return currentMinterId;
    }
    
    function getMinterAddress(uint _id) public view returns(address){
        return address(minteraddresses[_id]);
    }
}

contract NftMinter is ERC721{
    using Strings for uint256;
    address payable owner;
    bool killSwitch;
    uint256 price;
    uint256 lastSoldId;
    uint256 soldId;

    mapping (uint256 => string) private _tokenURIs;
    uint256 nftsMinted;
    uint256 maxMintAllowed;


    // Base URI
    string private _baseURIextended = "https://gateway.pinata.cloud/ipfs/";


    constructor(
        string memory _name,
        string memory _symbol,
        address _owner,
        uint _maxMintAllowed,
        uint _price
        ) ERC721(_name, _symbol){
        owner = payable(_owner);
        killSwitch = false;
        lastSoldId = 0;
        maxMintAllowed = _maxMintAllowed;
        price = _price;
    }

    function setMintFee(uint256 _newPrice) onlyOwner public {
        price = _newPrice;
    }

    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }

    function flipSaleState() public onlyOwner {
        killSwitch = !killSwitch;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _setTokenURI(uint256 tokenId, string memory uri) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, _tokenURI,".JSON"));
    }


    function mint(string[] memory uri, uint256[] memory tokenId) external payable {
        require(killSwitch == false, "This function is not available at this time");
        require(msg.value >= price*tokenId.length, "Not enough eether was sent");
        require(uri.length == tokenId.length, "Error in inputs");
        require(uri.length <= 10, "You can only mint a max of 10 NFTs at once");
        require(nftsMinted +uri.length<=maxMintAllowed, "Can not mint more than the max NFTs allowed");
        owner.transfer(msg.value);

        for(uint i = 0; i<10 &&i<uri.length; i++){
            _mint(msg.sender, tokenId[i]);
            _setTokenURI(tokenId[i], uri[i]);
            nftsMinted = nftsMinted +1;

        }
    }

    function setOwner(address _to) external onlyOwner {
        owner = payable(_to);
    }


}