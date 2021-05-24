#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

::registerHook after~App::BuildLaunchCommand SourcemodHelper::updateInstance

SourcemodHelper::updateInstance () {
	info <<< "UpdateInstance called"
}
