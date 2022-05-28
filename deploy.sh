#!/bin/sh

if [ -z "$1" ]
then
    echo "Usage: $0 <commit-msg>"
    exit 1
fi

BUILDDIR=$PWD/book
TEMPDIR=/tmp/ubmp-cn/deploy
BRANCH=gh-pages

[ -d $TEMPDIR ] && rm -rf $TEMPDIR 
mdbook build
mkdir -p $TEMPDIR
mv $BUILDDIR/* $TEMPDIR
git checkout $BRANCH
git pull
rm -rf *
mv $TEMPDIR/* ./
git add .
git commit -m "$1"
git push origin $BRANCH
rm -rf $TEMPDIR 
git checkout master
