#!/bin/bash

# Installation of GesApl files in /usr/local and /etc/gesapl
DIR="$( cd "$( dirname "$0" )" && pwd )"

printf "\nInstallation of GesApl 2.00 files in /usr/local and /etc/gesapl\n\n"

cp -v ${DIR}/bin/* /usr/local/bin/
cp -va ${DIR}/lib/* /usr/local/lib/
cp -va ${DIR}/etc/gesapl /etc/gesapl

