#! /bin/bash

# (C) 2016 Maximilian Wende <maximilian.wende@gmail.com>
#
# This file is licensed under the Apache License 2.0. For more information,
# see the LICENSE file or visit: http://www.apache.org/licenses/LICENSE-2.0




#######################
#                     #
#  TODO: Add logging  #
#                     #
#######################




caterr  () { printf "\x1b[31m" 1>&2; cat 1>&2; printf "\x1b[m" 1>&2; }

catwarn () { printf "\x1b[33m" 1>&2; cat 1>&2; printf "\x1b[m" 1>&2; }

catinfo () { printf "\x1b[36m"     ; cat     ; printf "\x1b[m"     ; }

# Make text $1 bold
bold () { printf "\x1b[1m%s\x1b[22m" "$1"; }