#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

SourcemodPackage.warmod::download () {
	SourcemodHelper::downloadSmx \
		https://warmod.bitbucket.io/plugins/warmod.smx \
		90c5bf7b3ca4edaad4d9dcbe25c0027614f4f6f3570886efe0012bd7c9014023
}
