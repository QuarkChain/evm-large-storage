// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SimpleFlatDirectory.sol";

contract SimpleFlatDirectoryWithManualResolver is SimpleFlatDirectory {
    constructor(uint8 slotLimit) SimpleFlatDirectory(slotLimit) {}

    function resolveMode() external pure override returns (bytes32) {
        return "manual";
    }

    fallback(bytes calldata cdata) external override returns (bytes memory) {
        bytes memory content;
        if (cdata.length == 0) {
            // TODO: redirect to "/"?
            return bytes("");
        } else if (cdata[0] != 0x2f) {
            // Should not happen since manual mode will have prefix "/" like "/....."
            return bytes("incorrect path");
        }

        if (cdata.length == 1) {
            content = files(defaultFile);
        } else {
            content = files(cdata[1:]);
        }

        bytes memory returnData = abi.encode(content);
        return returnData;
    }
}
