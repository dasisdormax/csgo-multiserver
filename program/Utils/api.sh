#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




CL_API_TOKEN="d05836cac806b383ea815d6416999908f93983ee"
CL_API="https://campuslan.csn.tu-chemnitz.de/api/v1"

cl_api_get () {
	true
	# curl -s -L -X GET -H "Authorization: Token $CL_API_TOKEN" $CL_API/$1
}


# Gets teamname of team id $1
cl_teamname () {
	cl_api_get teams/$1/name
}


cl_team_steamids () {
	cl_api_get teams/$1/steamids
}
