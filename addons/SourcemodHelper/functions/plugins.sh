#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

SourcemodHelper::loadPlugin () {
	: ../plugins/$1
	SourcemodPlugin.$1::download
}
