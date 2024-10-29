// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {SP1Verifier} from "@sp1-contracts/v2.0.0/SP1VerifierPlonk.sol";
import {ISP1Verifier} from "@sp1-contracts/ISP1Verifier.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MDLCityVerifier is ERC721Enumerable {

    address public immutable verifier;
    bytes32 public immutable mdlCityProgramVKey;

    uint256 private _totalCreds;
    mapping(address owner => uint256[]) private _ownedCreds;
    mapping(uint256 => Cred) private _creds;
    mapping(uint256 => uint256) private _enumerated;



    struct Cred {
        address owner;
        bool locked;
        string value;
        uint256 issuedAt;
        uint256 lockedAt;
    }

    struct PublicValues {
        address owner;
        uint256 id;
        uint256 issuedAt;
        string value;
    }

    error ErrorFunctionDisabled();

    error ErrorBurningDisabled();


    constructor(address _verifier, bytes32 _mdlCityProgramVKey) ERC721("California mDL Over 21 Cred", "CRED") {
        verifier = _verifier;
        mdlCityProgramVKey = _mdlCityProgramVKey;
    }


    function updateCred(bytes calldata _publicValues, bytes calldata _proofBytes)
        external
    {
        PublicValues memory v = abi.decode(_publicValues, (PublicValues));

        if(block.timestamp > _creds[v.id].lockedAt + 26 weeks) {
            _creds[v.id].locked = false;
        }

        require(!_creds[v.id].locked || msg.sender == _creds[v.id].owner,
            "Cred locked, unlock or call this function with the holder owner to update.");
        require(block.timestamp >= v.issuedAt,
            "Block somehow older than the cred?");
        require(block.timestamp < v.issuedAt + 1 hours,
            "Cred must be issued less than 1 hour ago.");
        require(block.timestamp > _creds[v.id].issuedAt + 3 hours,
            "Cred reassignment heavily rate limited, try again in 3 hours.");



        ISP1Verifier(verifier).verifyProof(mdlCityProgramVKey, _publicValues, _proofBytes);

        if(v.owner == address(0)) {
            revert ErrorBurningDisabled();
        }

        if(_creds[v.id].owner == address(0)) {
            _enumerated[_totalCreds] = v.id;
            _totalCreds++;
        }

        if(_creds[v.id].owner != v.owner) {
            _removeCred(_creds[v.id].owner, v.id);
            _ownedCreds[v.owner].push(v.id);
            emit Transfer(_creds[v.id].owner, v.owner, v.id);
            _creds[v.id].owner = v.owner;
        }

        _creds[v.id].issuedAt = v.issuedAt;
        _creds[v.id].value = v.value;
    }


    function lockCred(bytes calldata _publicValues, bytes calldata _proofBytes)
        external
    {
        PublicValues memory v = abi.decode(_publicValues, (PublicValues));


        require(_creds[v.id].owner == msg.sender,
            "Cred can only be locked by its holder.");
        require(_creds[v.id].owner == v.owner,
            "Proof owner must match current cred owner.");
        require(_creds[v.id].issuedAt != v.issuedAt,
            "Locking proof must be issued separately from updating proof.");
        require(block.timestamp < _creds[v.id].issuedAt + 1 hours,
            "Cred must be locked within an hour of updating.");
        require(_equal(_creds[v.id].value, v.value),
            "Not sure how that happened.");
        require(block.timestamp < v.issuedAt + 1 hours,
            "Cred must be issued less than 1 hour ago.");
        require(block.timestamp >= v.issuedAt,
            "Block somehow older than the cred?");

        ISP1Verifier(verifier).verifyProof(mdlCityProgramVKey, _publicValues, _proofBytes);

        _creds[v.id].locked = true;
        _creds[v.id].lockedAt = block.timestamp;
    }

    function unlockCred(uint256 id)
        external
    {
        require(_creds[id].owner == msg.sender,
            "Cred can only be unlocked by its owner.");
        _creds[id].locked = false;
        _creds[id].lockedAt = 0;
    }


    function ownerCredIds(address owner)
        external
        view
        returns(uint256[] memory)
    {
        return _ownedCreds[owner];
    }


    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        override
        returns(uint256)
    {
        if (index >= balanceOf(owner)) {
            revert ERC721OutOfBoundsIndex(owner, index);
        }
        return _ownedCreds[owner][index];
    }


    function tokenByIndex(uint256 index) public view override returns (uint256) {
        if (index >= totalSupply()) {
            revert ERC721OutOfBoundsIndex(address(0), index);
        }
        return _enumerated[index];
    }


    function credOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns(Cred memory)
    {
        return _creds[_ownedCreds[owner][index]];
    }


    function balanceOf(address owner)
        override(ERC721, IERC721)
        public
        view
        returns(uint256)
    {
        return _ownedCreds[owner].length;
    }


    function ownerOf(uint256 _tokenId)
        override(ERC721, IERC721)
        public
        view
        returns(address)
    {
        return _creds[_tokenId].owner;
    }


    function cred(uint256 id)
        external
        view
        returns(Cred memory)
    {
        return _creds[id];
    }


    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwnedOverride(tokenId);

        return "ipfs://QmQfy9h4t7VyuZsp1FKEeNKiEetnH8otA6AXDRcFRfQdmA";
    }

    function totalSupply() public view override returns (uint256) {
        return _totalCreds;
    }


    function _ownerOf(uint256 tokenId) internal view override returns (address) {
        return _creds[tokenId].owner;
    }


    function _requireOwnedOverride(uint256 tokenId) internal view returns (address) {
        address owner = _ownerOf(tokenId);
        if (owner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
        return owner;
    }


    function _removeCred(address owner, uint256 id)
        internal
    {
        uint256 index;
        bool found = false;

        for(uint256 i = 0; i < _ownedCreds[owner].length; i++) {
            if(_ownedCreds[owner][i] == id) {
                index = i;
                found = true;
                break;
            }
        }

        if(!found) {
            return;
        }

        _ownedCreds[owner][index] = _ownedCreds[owner][_ownedCreds[owner].length - 1];
        _ownedCreds[owner].pop();
    }


    function _equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }


    // Overriding most base NFT functionality.

    function approve(address to, uint256 tokenId) public pure override(ERC721, IERC721) {
        revert ErrorFunctionDisabled();
    }

    function getApproved(uint256 tokenId) public pure override(ERC721, IERC721) returns (address) {
        revert ErrorFunctionDisabled();
    }

    function setApprovalForAll(address operator, bool approved) public pure override(ERC721, IERC721) {
        revert ErrorFunctionDisabled();
    }

    function isApprovedForAll(address owner, address operator) public pure override(ERC721, IERC721) returns (bool) {
        revert ErrorFunctionDisabled();
    }

    function transferFrom(address from, address to, uint256 tokenId) public pure override(ERC721, IERC721) {
        revert ErrorFunctionDisabled();
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public pure override(ERC721, IERC721) {
        revert ErrorFunctionDisabled();
    }




}
