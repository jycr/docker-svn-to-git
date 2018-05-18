#!/bin/bash

set -e


SVN_PATH=${SVN_PATH}
SVN_PATH_TRUNK=${SVN_PATH_TRUNK:-"${SVN_PATH}trunk"}
SVN_PATH_BRANCHES=${SVN_PATH_BRANCHES:-"${SVN_PATH}branches"}
SVN_PATH_TAGS=${SVN_PATH_TAGS:-"${SVN_PATH}tags"}

SVN_DUMP_DIR=${SVN_REPO:-'/svn_dumps'}
SVN_AUTHORS=${SVN_REPO:-'/svn_dumps/authors.txt'}


WORK_TARGET_DIR=${WORK_TARGET_DIR:-"$SVN_DUMP_DIR"}
WORK_TARGET_DIR=/target

SVN_REPO=${SVN_REPO:-"$WORK_TARGET_DIR/svn_repo"}
GIT_REPO=${GIT_REPO:-"$WORK_TARGET_DIR/git_repo"}

SVN_ARCHIVE=${SVN_ARCHIVE:-"$WORK_TARGET_DIR/svn_repo.tar.xz"}
GIT_ARCHIVE=${GIT_ARCHIVE:-"$WORK_TARGET_DIR/git_repo.tar.xz"}

SVN_URL=file://$SVN_REPO

SVN_DUMP_FILES=$(ls $SVN_DUMP_DIR/*.svndump.xz)

set -u

__BASEDIR=$(readlink -f "$(dirname $0)")

_CMD_SUBGIT=/subgit/bin/subgit

mkdir -p "$WORK_TARGET_DIR"

function log () {
    local MESSAGE="$1"
    echo -e "$(date -Iseconds) | $MESSAGE"
}

log "Configuration:"
log " --env SVN_DUMP_DIR=$SVN_DUMP_DIR"
log " --env SVN_AUTHORS=$SVN_AUTHORS"
log " --env SVN_PATH=$SVN_PATH"

log "SVN Dump files:\n$SVN_DUMP_FILES"

function stage_restoreSvnRepo() {
    if [ ! -e "$SVN_REPO/format" ]; then
        log "Create svn repo: $SVN_REPO"
		mkdir -p "$SVN_REPO"
        svnadmin create "$SVN_REPO"
    fi
    
    for DUMP in $SVN_DUMP_FILES; do
        log "Loading dump: $DUMP"
        pv $DUMP | xz -d | svnadmin load $SVN_REPO > $DUMP.log
    done

	log "Optimize SVN repo"
	svnadmin pack $SVN_REPO -M 128
}

function stage_extractAuthors() {
	local RESULT_FILE="$WORK_TARGET_DIR/authors.tocheck.txt"
    log "Create authors file"
    svn log -q $SVN_URL \
        |  awk -F '|' '/^r/ {sub("^ ", "", $2); sub(" $", "", $2); \
            print $2" = "$2" <"$2">"}' \
        |  sort -u \
        > "$RESULT_FILE"
	log "Please check file '$RESULT_FILE', modify '$SVN_AUTHORS' if needed, and relaunch"
}

function stage_importSvnIntoGit() {
    log "Start import SVN -> Git (log: subgit.log)"

	log "Launching SubGit with following parameters (see https://subgit.com/import-book.html for more information):
	        --authors-file "$SVN_AUTHORS"
	        --trunk "$SVN_PATH_TRUNK"
	        --branches "$SVN_PATH_BRANCHES"
	        --tags "$SVN_PATH_TAGS"
	        --svn-url "$SVN_URL"
	"

    $_CMD_SUBGIT import \
        --authors-file "$SVN_AUTHORS" \
        --trunk "$SVN_PATH_TRUNK" \
        --branches "$SVN_PATH_BRANCHES" \
        --tags "$SVN_PATH_TAGS" \
        --svn-url "$SVN_URL" \
        "$GIT_REPO" \
        | tr '[' ' ' \
        | tr ']' '\n' \
        > "$WORK_TARGET_DIR/subgit.log"

	log "Import [SVN->Git] finished"
}

function stage_archiveGitRepo() {
	pushd $GIT_REPO > /dev/null
		log "Optimize Git repo"
		git gc --aggressive

		log "Archive Git repo"
		tar -cf - . \
		| xz \
			-9 \
			--extreme \
			--stdout \
			- > $GIT_ARCHIVE
		log "Git repo backup created:\n$(ls -lh $GIT_ARCHIVE)"
	popd > /dev/null
}

function stage_archiveSvnRepo() {
	pushd $SVN_REPO > /dev/null
		log "Archive SVN repo"
		tar -cf - . \
		| xz \
			-9 \
			--extreme \
			--stdout \
			- > $SVN_ARCHIVE
		log "SVN repo backup created:\n$(ls -lh $SVN_ARCHIVE)"
	popd > /dev/null
}
        
stage_restoreSvnRepo

stage_extractAuthors

stage_importSvnIntoGit

stage_archiveGitRepo
stage_archiveSvnRepo
