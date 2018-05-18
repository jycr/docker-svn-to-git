# docker-svn-to-git
Docker image used to migrate SVN repo to Git

Example:

```
docker run \
  --env SVN_DUMP_DIR=/svn_dumps \
  --env SVN_AUTHORS=/svn_dumps/authors.txt \
  --env SVN_PATH=my_path_into_repo \
  jycr/svn2git
