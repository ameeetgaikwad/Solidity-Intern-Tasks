pragma solidity ^0.8.18;

/**
@title IMinterController
@dev Interface for the MinterController contract, which provides functions for minting ERC721 tokens with a URI (Uniform Resource Identifier).
*/
interface IMinterController {
    /**
@dev Function to mint ERC721 tokens with a URI (Uniform Resource Identifier) and transfer them to the specified address.
@param to The address to which the minted token will be transferred.
@param label The label or domain name for the token being minted.
*/
    function mintURI(address to, string calldata label) external;

    /**
@dev Function to mint ERC721 tokens with a URI (Uniform Resource Identifier) and transfer them to the specified address, with a specified resolver address.
@param to The address to which the minted token will be transferred.
@param label The label or domain name for the token being minted.
@param resolver The address of the resolver contract to store external data for the token being minted.
*/
    function mintURIWithResolver(
        address to,
        string calldata label,
        address resolver
    ) external;
}
