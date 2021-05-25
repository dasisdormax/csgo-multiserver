#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

SourcemodPackage.sourcemod::download () {
	SourcemodHelper::unpackTar \
		https://sm.alliedmods.net/smdrop/1.10/sourcemod-1.10.0-git6502-linux.tar.gz \
		e8dac72aeb3df8830c46234d7e22c51f92d140251ca72937eb0afed05cd32c66
}
