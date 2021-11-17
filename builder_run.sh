#!/bin/bash
pwd

git clone "https://github.com/digital-land/$REPOSITORY.git"

cd $REPOSITORY

make makerules

yes | make init 

make clobber

make

make push