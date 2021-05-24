#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

::registerHook after~App::buildLaunchCommand SourcemodHelper::updateInstance

SourcemodHelper::updateInstance () {
	SourcemodHelper::initVars
	SourcemodHelper::loadPlugin warmod
}
