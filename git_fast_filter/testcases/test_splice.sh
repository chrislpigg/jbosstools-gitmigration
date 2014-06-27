#!/bin/bash
(export R=repoA;  mkdir $R; cd $R; git init ; )
(export R=repoB;  mkdir $R; cd $R; git init ; )
(export R=out;  mkdir $R; cd $R; git init ; )
(export R=repoA;  cd $R; echo file_update1 > file ; git add file ; git commit -m 'update' ; )
(export R=repoB;  cd $R; echo file_update2 > file ; git add file ; git commit -m 'update' ; )
(export R=repoB;  cd $R; echo file_update3 > file ; git add file ; git commit -m 'update' ; )
(export R=repoA;  cd $R; echo file_update4 > file ; git add file ; git commit -m 'update' ; )
cd repoA/
git checkout HEAD^1
echo 'another_file' > file2
git add file2
git commit -m 'two files'
git merge master
cd ..

PYTHONPATH=jbosstools-gitmigration/git_fast_filter/ .jbosstools-gitmigration/git_fast_filter/testcases/splice_repos.py -k repoA repoB  out/

