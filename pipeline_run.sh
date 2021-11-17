#!/bin/bash

git clone "https://github.com/digital-land/$REPOSITORY.git"

cd $REPOSITORY

make makerules

yes | make init 

make fetch-s3

if [ "$REBUILD" = true ] ; then
    make clobber
    make clobber-today
fi

make -j$(nproc) dataset

make push-dataset-s3