// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Notarization is Ownable {
    
    struct USER_NOTARY {
        string document_data;
        bytes32 document_hash;
        uint256 timestamp;
        address notarized_by;
    }

    struct DOCUMENT {
        bytes32 document_hash;
        string document;
        string document_name;
        string owner;
        bool flag;
    }

    event Notarized(string indexed owner, bytes32 hash, string document_name, uint256 timestamp);
    event OwnerChanged(bytes32 indexed hash, string previous_owner, string new_owner);

    mapping (string => USER_NOTARY[]) private notary_data;
    mapping (bytes32 => DOCUMENT) private document_data;

    constructor(){ }

    function setData(string memory document, string memory user, string memory document_name) public returns(bytes32 hash, uint256 timestamp){
       // Create a hash of document 
       hash = createHash(document); 
       address signer = msg.sender;
       timestamp = block.timestamp; 
       DOCUMENT memory new_doc = document_data[hash]; 
       // If doument is new add the user as the owner of the document 
       if(new_doc.flag == false) {
           document_data[hash] = DOCUMENT(hash,document, document_name, user, true);
       } else {
           require(createHash(new_doc.owner) == createHash(user), "E1");
       }
    
       // Add to the mapping
       notary_data[user].push(USER_NOTARY(document, hash, timestamp, signer));
       
       document_data[hash] = DOCUMENT(hash, document,document_name, user, true);

       // emit event
       emit Notarized(user, hash, document_name, timestamp);
    }

    function verify_document(string memory user, string memory document) public view returns(bool verified) {
        // Create hash of a document
        bytes32 hash = createHash(document);

        // Compare the hash
        DOCUMENT memory document_details = document_data[hash];
        //verified = false;

        require(document_details.flag == true, "E2");

        bytes32 user_hash = createHash(user);
        bytes32 document_owner_hash = createHash(document_details.owner);

        verified = user_hash == document_owner_hash ? true:false;
        
       // (USER_NOTARY memory data, bool found) = find_hash(notary_data[user], hash, user);
        
      // verified = found; 
    }

    function createHash(string memory data) private pure returns(bytes32 hashed_data) {
        hashed_data = keccak256(abi.encodePacked(data));
    }

    function find_hash(USER_NOTARY[] memory hash_array, bytes32 hashed_data, string memory user) private view returns(USER_NOTARY memory user_data, bool found){
        
        string memory doc_owner = _documentOwner(hashed_data);

        found = false;

        bytes32 doc_owner_hash = createHash(doc_owner);
        bytes32 user_hash = createHash(user);

        for(uint i =0; i<hash_array.length;i++){
            if(hash_array[i].document_hash == hashed_data && doc_owner_hash == user_hash){
                user_data = hash_array[i];
                found = true;
                break;
            }
        }
    }

    // function getData(uint256 timestamp, string memory user, address notarized_by) public view returns (string memory user_data) {
    //     USER_NOTARY[] memory hash_array = notary_data[user];

    //     for(uint i = 0; i<hash_array.length;i++){
    //         if(hash_array[i].timestamp == timestamp && hash_array[i].notarized_by == notarized_by){
    //             user_data = hash_array[i].user_data;
    //         }
    //     }
    // }

    function changeDocumentOwner(string memory document, string memory new_owner) onlyOwner() public {
        // Create a hash of document 
        bytes32 hash = createHash(document); 

        DOCUMENT storage _document_data = document_data[hash];
        // Check if document exists
        require(_document_data.flag == true, "E2");
       
        string memory previous_owner = _document_data.owner;

        _document_data.owner = new_owner;

        emit OwnerChanged(hash, previous_owner, new_owner);
    }

    function getDocumentOwner(string memory document) public view returns(string memory documentOwner) {
        bytes32 document_hash = createHash(document);
        documentOwner = _documentOwner(document_hash);
    }

    function _documentOwner(bytes32 document_hash) private view returns (string memory owner){
        owner = document_data[document_hash].owner;
    }

    function documentExists(bytes32 hash) private view returns (bool) {
        return document_data[hash].flag;
    }

    // function getUserDoc(string memory user) public view returns(DOCUMENT[] memory){
    //     USER_NOTARY[] memory user_data = notary_data[user];
    //     DOCUMENT[] memory user_document = new DOCUMENT[](user_data.length);
    //     for(uint i = 0; i<user_data.length; i++) {
    //         user_document.push(document_data[user_data[i].document_hash]);
    //     }
    //     return user_document;
    // }

}