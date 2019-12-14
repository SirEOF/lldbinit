#
# Copyright (C) 2018-2019 Secure Substrates Inc. All rights reserved.
# SPDX-License-Identifier: MIT. The file is under the MIT license.
#
# Author: Arputha Ganesan (arputha.ganesan@securesubstrates.com)
#

# This script is meant for codesigning rust banaries so that it can be
# debugged using rust-lldb. On osx Catalina onwards, OSX requires
# special entitlement before it can be debugged. This script makes it
# easy to do this.


KEYCHAIN_ASCCESS=/usr/bin/security
CODESIGN=/usr/bin/codesign

list_developer_identites() {
    "$KEYCHAIN_ASCCESS" find-identity -p codesigning -v
}

codesign_exec( ) {

    if [ "$#" -ne 2 ]
    then
	echo "Usage: <executable> <identity>"
	echo "Use 'list_developer_identites' command to find developer identities"
	return 255
    fi

    exec_name="$1"
    identity="$2"

    sign_entitlement="<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"><plist version=\"1.0\"><dict><key>com.apple.security.get-task-allow</key><true/></dict></plist>"

    $CODESIGN -v $exec_name 2> /dev/null

    if [ "$?" -eq 0 ]
    then
	echo "$exec_name is already signed..."
    else
	tmpfile=$(mktemp "/tmp/entitlement.XXXXXX")
	if [ "$?" -ne 0 ]
	then
	    echo "Failed to create temporary file... "
	    return 255
	fi
	echo $sign_entitlement > "$tmpfile"
	echo "Unlocking login keychain"
	$KEYCHAIN_ASCCESS unlock-keychain

	if [ "$?" -ne 0 ]
	then
	    return 254
	fi

	$CODESIGN -s "$identity" --entitlements "$tmpfile" --timestamp=none "$exec_name"
	$KEYCHAIN_ASCCESS lock-keychain
	unlink "$tmpfile"
    fi
}

if [ "$#" -eq 2 ]
then
    codesign_exec $1 $2
elif [ "$#" -eq 1 ]
then
    list_developer_identites
else
    echo "Usage: $0 <exec_name> <identity>  Codesign for debugging"
    echo "Usage: $0 -l                      List codesigning identities"
fi
