#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

SourcemodPackage.sourcemod::download () {
	SourcemodHelper::unpackTar \
		https://sm.alliedmods.net/smdrop/1.10/sourcemod-1.10.0-git6503-linux.tar.gz \
		a17c5755c4999052aee553cc8abf1f978ebab02e2072e31defca71c41c34589d
}
