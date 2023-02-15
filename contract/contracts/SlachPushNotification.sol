// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPUSHCommInterface.sol";
import "./interfaces/ISlashCustomPlugin.sol";
import "./libs/UniversalERC20.sol";

// import "hardhat/console.sol";

contract SlachPushNotification is ISlashCustomPlugin, Ownable {
    using UniversalERC20 for IERC20;

    address public EPNS_COMM_ADDRESS =
        0xb3971BCef2D791bc4027BbfedFb47319A4AAaaAa;

    // This is the default title and message that will be sent to the user
    string defaultTitle = "";
    string defaultMessage = "";

    constructor(string memory title, string memory message) {
        defaultTitle = title;
        defaultMessage = message;
    }

    function updateDefaultContents(string memory title, string memory message)
        external
        onlyOwner
    {
        defaultTitle = title;
        defaultMessage = message;
    }

    // MARK: - ISlashCustomPlugin

    function receivePayment(
        address receiveToken,
        uint256 amount,
        string calldata paymentId,
        string calldata optional,
        bytes calldata reserved
    ) external payable {
        require(amount > 0, "invalid amount");

        IERC20(receiveToken).universalTransferFrom(msg.sender, owner(), amount);

        sendNotification(msg.sender, defaultTitle, defaultMessage);
    }

    function sendNotification(
        address to,
        string memory title,
        string memory message
    ) internal {
        IPUSHCommInterface(EPNS_COMM_ADDRESS).sendNotification(
            0x0CF4e589e3213F482ed897B38d69Be90002325A5, // from channel
            to,
            bytes(
                string(
                    // We are passing identity here: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/identity/payload-identity-implementations
                    abi.encodePacked(
                        "0", // this is notification identity: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/identity/payload-identity-implementations
                        "+", // segregator
                        "3", // this is payload type: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/payload (1, 3 or 4) = (Broadcast, targetted or subset)
                        "+", // segregator
                        "This is push from contract", // this is notificaiton title
                        "+", // segregator
                        "Hi! ", // notification body
                        addressToString(msg.sender), // notification body
                        " sent ", // notification body
                        " PUSH to you!" // notification body
                    )
                )
            )
        );
    }

    function supportSlashExtensionInterface()
        external
        pure
        override
        returns (uint8)
    {
        return 2;
    }

    // Helper function to convert address to string
    function addressToString(address _address)
        internal
        pure
        returns (string memory)
    {
        bytes32 _bytes = bytes32(uint256(uint160(_address)));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = "0";
        _string[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            _string[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }
}
