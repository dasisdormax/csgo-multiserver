#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

SourcemodPackage.metamod::download () {
	SourcemodHelper::unpackTar \
		https://mms.alliedmods.net/mmsdrop/1.11/mmsource-1.11.0-git1144-linux.tar.gz \
		7f41c7cfcd86aa9e610b2e341b30edd9618d5c4533fa982721c564e47487e96e
}
