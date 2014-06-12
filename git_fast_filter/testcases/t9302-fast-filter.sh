#!/bin/sh
#
# Copyright (c) 2007 Johannes E. Schindelin
# Copyright (c) 2009 Elijah Newren
# (Copied heavily from git.git's t/t9301-fast-export.sh)

test_description='git_fast_filter.py'
. ./test-lib.sh

test_expect_success 'setup' '

	echo hello > world &&
	git add world &&
	test_tick &&
	git commit -m initial &&
	echo -n "The launch code is 1-2-3-4." > secret &&
	git add secret &&
	test_tick &&
	git commit -m "Sssh.  Dont tell no one" &&
	echo A file that you cant trust > file.doc &&
	echo there >> world &&
	git add file.doc world &&
	test_tick &&
	echo -e "Random useless changes\n\nLet us be like the marketing group.  Marketing is staffed with pansies" | git commit -F - &&
	echo Do not use a preposition to end a setence with > advice &&
	git add advice &&
	test_tick &&
	GIT_AUTHOR_NAME="Copy N. Paste" git commit -m "hypocrisy is fun" &&
	echo Avoid cliches like the plague >> advice &&
	test_tick &&
	GIT_AUTHOR_EMAIL="foo@my.crp" git commit -m "it is still fun" advice &&
	echo "  \$Id: A bunch of junk$" > foobar.c &&
	git add foobar.c &&
	test_tick &&
	git commit -m "Brain damage"
'

test_expect_success 'commit_info.py' '
	mkdir new &&
	git --git-dir=new/.git init &&
	git fast-export --all |
	PYTHONPATH=$TEST_DIRECTORY/..: $TEST_DIRECTORY/commit_info.py |
	(cd new &&
	 git fast-import --quiet &&
	 test 0e5a1029 = $(git rev-parse --short=8 --verify refs/heads/master))
'

test_expect_success 'file_filter.py' '
	rm -rf new &&
	mkdir new &&
	git --git-dir=new/.git init &&
	git fast-export --all |
	PYTHONPATH=$TEST_DIRECTORY/..: $TEST_DIRECTORY/file_filter.py |
	(cd new &&
	 git fast-import --quiet &&
	 test ee59e2b4 = $(git rev-parse --short=8 --verify refs/heads/master))
'

test_expect_success 'print_progress.py' '
	MASTER=$(git rev-parse --verify master) &&
	rm -rf new &&
	PYTHONPATH=$TEST_DIRECTORY/..: $TEST_DIRECTORY/print_progress.py . new &&
	(cd new &&
	 test $MASTER = $(git rev-parse --verify refs/heads/master))
'

test_expect_success 'rename-master-to-slave.py' '
	MASTER=$(git rev-parse --verify master) &&
	rm -rf new &&
	mkdir new &&
	git --git-dir=new/.git init &&
	git fast-export --all |
	PYTHONPATH=$TEST_DIRECTORY/..: $TEST_DIRECTORY/rename-master-to-slave.py |
	(cd new &&
	 git fast-import --quiet &&
	 test $MASTER = $(git rev-parse --verify refs/heads/slave))
'

test_expect_success 'strip-cvs-keywords.py' '
	rm -rf new &&
	mkdir new &&
	git --git-dir=new/.git init &&
	git fast-export --all |
	PYTHONPATH=$TEST_DIRECTORY/..: $TEST_DIRECTORY/strip-cvs-keywords.py |
	(cd new &&
	 git fast-import --quiet &&
	 test 2306fc7c = $(git rev-parse --short=8 --verify refs/heads/master))
'

test_expect_success 'git-fast-export new enough' '
	rm -rf new &&
	mkdir new &&
	git --git-dir=new/.git init &&
	git fast-export master~3..master |
	(cd new &&
	 git fast-import --quiet &&
	 test 5 = $(git ls-tree master | wc -l))
'

test_expect_success 'setup two extra repositories' '
	mkdir repo1 &&
	cd repo1 &&
	git init &&
	echo hello > world &&
	git add world &&
	test_tick &&
	git commit -m "Commit A" &&
	echo goodbye > world &&
	git add world &&
	test_tick &&
	git commit -m "Commit C" &&
	cd .. &&
	mkdir repo2 &&
	cd repo2 &&
	git init &&
	echo foo > bar &&
	git add bar &&
	test_tick &&
	git commit -m "Commit B" &&
	echo fooey > bar &&
	git add bar &&
	test_tick &&
	git commit -m "Commit D" &&
	cd ..
'

test_expect_success 'splice_repos.py' '
	rm -rf new &&
	PYTHONPATH=$TEST_DIRECTORY/..: $TEST_DIRECTORY/splice_repos.py repo1 repo2 new &&
	(cd new &&
         test 4 = $(git rev-list master | wc -l))
'

test_expect_success 'setup two interrelated branched repositories ' '
mkdir repoA
mkdir repoB
cd repoA
git init
cd ../repoB
git init
test_tick ; cd ../repoA ; echo 'test A' > A ; git add A ; git commit -m "add A"
test_tick ; cd ../repoB ; echo 'test B' > B ; git add B ; git commit -m "add B"
test_tick ; cd ../repoA ; echo 'test A2' > A ; git add A ; git commit -m "change A"
test_tick ; cd ../repoB ; echo 'test B2' > B ; git add B ; git commit -m "change B"
test_tick ; cd ../repoA ; git checkout -b the-branch
test_tick ; cd ../repoB ; git checkout -b the-branch
test_tick ; cd ../repoA ; echo 'test A3' > A ; git add A ; git commit -m "change A on branch"
test_tick ; cd ../repoB ; echo 'test B3' > B ; git add B ; git commit -m "change B on branch"
test_tick ; cd ../repoA ; git checkout master
test_tick ; cd ../repoB ; git checkout master
test_tick ; cd ../repoA ; echo 'test A4' > A ; git add A ; git commit -m "change A on master"
test_tick ; cd ../repoB ; echo 'test B4' > B ; git add B ; git commit -m "change B on master"
'

test_expect_success 'create_fast_export_output.py' '
	rm -rf new &&
	mkdir new &&
	git --git-dir=new/.git init &&
	PYTHONPATH=$TEST_DIRECTORY/..: $TEST_DIRECTORY/create_fast_export_output.py |
	(cd new &&
	 git fast-import --quiet &&
	 test e5e0569b = $(git rev-parse --short=8 --verify refs/heads/master) &&
	 test abc74172 = $(git rev-parse --short=8 --verify refs/heads/devel) &&
	 test a12e90d3 = $(git rev-parse --short=8 --verify refs/tags/v1.0))
'

test_expect_success 'collab' '
	rm -rf new &&
	mkdir new &&
	cd new &&
	git init &&
	PYTHONPATH=$TEST_DIRECTORY/..: $TEST_DIRECTORY/collab clone .. --exclude=secret &&
	test 18dd5834 = $(git rev-parse --short=8 refs/remotes/collab/master) &&
	git merge collab/master &&
	cd .. &&
	echo content > another-file &&
	git add another-file &&
	git commit -m "Yet another commit" &&
	cd new &&
	PYTHONPATH=$TEST_DIRECTORY/..: $TEST_DIRECTORY/collab pull-grafts &&
	test d042f798 = $(git rev-parse --short=8 refs/remotes/collab/master) &&
	git merge collab/master &&
	echo more content >> another-file &&
	git commit -m "And yet another commit" another-file &&
	PYTHONPATH=$TEST_DIRECTORY/..: $TEST_DIRECTORY/collab push-grafts &&
	cd .. &&
	test d50d11fc = $(git rev-parse --short=8 refs/remotes/collab/master)
'

test_done
