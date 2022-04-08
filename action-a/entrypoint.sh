#!/bin/sh -l

sh -c "echo Hello world my name is $INPUT_MY_NAME"
sh -c "echo THE CHECKOUT PATH IS: $GITHUB_WORKSPACE"
sh -c "for FILE in ${GITHUB_WORKSPACE}/*.*
do
  echo $(basename ${FILE})
done"
