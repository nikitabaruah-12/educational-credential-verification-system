// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Educational Credential Verification System
 * @dev Smart contract for issuing and verifying educational credentials on blockchain
 * @author Educational Credential Verification Team
 */
contract EducationalCredentialVerification {
    
    // Struct to represent a credential
    struct Credential {
        string studentName;
        string institutionName;
        string courseName;
        string degree;
        uint256 graduationDate;
        uint256 issueDate;
        bool isValid;
        address issuer;
    }
    
    // Mapping from credential ID to credential details
    mapping(bytes32 => Credential) public credentials;
    
    // Mapping to track authorized institutions
    mapping(address => bool) public authorizedInstitutions;
    
    // Mapping to track student credentials
    mapping(address => bytes32[]) public studentCredentials;
    
    // Contract owner
    address public owner;
    
    // Events
    event CredentialIssued(bytes32 indexed credentialId, address indexed student, address indexed institution);
    event CredentialRevoked(bytes32 indexed credentialId, address indexed institution);
    event InstitutionAuthorized(address indexed institution, string institutionName);
    event InstitutionRevoked(address indexed institution);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can perform this action");
        _;
    }
    
    modifier onlyAuthorizedInstitution() {
        require(authorizedInstitutions[msg.sender], "Only authorized institutions can issue credentials");
        _;
    }
    
    modifier credentialExists(bytes32 _credentialId) {
        require(credentials[_credentialId].issuer != address(0), "Credential does not exist");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Core Function 1: Issue a new educational credential
     * @param _student Address of the student receiving the credential
     * @param _studentName Name of the student
     * @param _institutionName Name of the issuing institution
     * @param _courseName Name of the course/program
     * @param _degree Type of degree (Bachelor's, Master's, PhD, etc.)
     * @param _graduationDate Graduation date as timestamp
     * @return credentialId Unique identifier for the issued credential
     */
    function issueCredential(
        address _student,
        string memory _studentName,
        string memory _institutionName,
        string memory _courseName,
        string memory _degree,
        uint256 _graduationDate
    ) external onlyAuthorizedInstitution returns (bytes32) {
        
        require(_student != address(0), "Invalid student address");
        require(bytes(_studentName).length > 0, "Student name cannot be empty");
        require(bytes(_courseName).length > 0, "Course name cannot be empty");
        require(_graduationDate <= block.timestamp, "Graduation date cannot be in the future");
        
        // Generate unique credential ID
        bytes32 credentialId = keccak256(
            abi.encodePacked(
                _student,
                _institutionName,
                _courseName,
                _degree,
                _graduationDate,
                block.timestamp,
                msg.sender
            )
        );
        
        // Ensure credential doesn't already exist
        require(credentials[credentialId].issuer == address(0), "Credential already exists");
        
        // Create and store the credential
        credentials[credentialId] = Credential({
            studentName: _studentName,
            institutionName: _institutionName,
            courseName: _courseName,
            degree: _degree,
            graduationDate: _graduationDate,
            issueDate: block.timestamp,
            isValid: true,
            issuer: msg.sender
        });
        
        // Add to student's credential list
        studentCredentials[_student].push(credentialId);
        
        emit CredentialIssued(credentialId, _student, msg.sender);
        
        return credentialId;
    }
    
    /**
     * @dev Core Function 2: Verify the authenticity of a credential
     * @param _credentialId Unique identifier of the credential to verify
     * @return isValid Whether the credential is valid
     * @return credential Complete credential details
     */
    function verifyCredential(bytes32 _credentialId) 
        external 
        view 
        credentialExists(_credentialId) 
        returns (bool isValid, Credential memory credential) 
    {
        Credential memory cred = credentials[_credentialId];
        
        // Check if credential is valid and issuer is still authorized
        bool valid = cred.isValid && authorizedInstitutions[cred.issuer];
        
        return (valid, cred);
    }
    
    /**
     * @dev Core Function 3: Revoke a credential (can only be done by the issuing institution)
     * @param _credentialId Unique identifier of the credential to revoke
     */
    function revokeCredential(bytes32 _credentialId) 
        external 
        credentialExists(_credentialId) 
    {
        Credential storage credential = credentials[_credentialId];
        
        // Only the original issuer can revoke the credential
        require(msg.sender == credential.issuer, "Only the issuing institution can revoke this credential");
        require(credential.isValid, "Credential is already revoked");
        
        credential.isValid = false;
        
        emit CredentialRevoked(_credentialId, msg.sender);
    }
    
    /**
     * @dev Authorize an educational institution to issue credentials
     * @param _institution Address of the institution to authorize
     * @param _institutionName Name of the institution
     */
    function authorizeInstitution(address _institution, string memory _institutionName) 
        external 
        onlyOwner 
    {
        require(_institution != address(0), "Invalid institution address");
        require(bytes(_institutionName).length > 0, "Institution name cannot be empty");
        
        authorizedInstitutions[_institution] = true;
        
        emit InstitutionAuthorized(_institution, _institutionName);
    }
    
    /**
     * @dev Revoke authorization of an educational institution
     * @param _institution Address of the institution to revoke
     */
    function revokeInstitutionAuthorization(address _institution) 
        external 
        onlyOwner 
    {
        require(authorizedInstitutions[_institution], "Institution is not authorized");
        
        authorizedInstitutions[_institution] = false;
        
        emit InstitutionRevoked(_institution);
    }
    
    /**
     * @dev Get all credential IDs for a specific student
     * @param _student Address of the student
     * @return Array of credential IDs belonging to the student
     */
    function getStudentCredentials(address _student) 
        external 
        view 
        returns (bytes32[] memory) 
    {
        return studentCredentials[_student];
    }
    
    /**
     * @dev Check if an institution is authorized
     * @param _institution Address of the institution to check
     * @return Boolean indicating authorization status
     */
    function isInstitutionAuthorized(address _institution) 
        external 
        view 
        returns (bool) 
    {
        return authorizedInstitutions[_institution];
    }
    
    /**
     * @dev Get credential details by ID
     * @param _credentialId Unique identifier of the credential
     * @return Credential details
     */
    function getCredential(bytes32 _credentialId) 
        external 
        view 
        credentialExists(_credentialId) 
        returns (Credential memory) 
    {
        return credentials[_credentialId];
    }
}
