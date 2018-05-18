# docker-svn-to-git
Docker image used to migrate SVN repo to Git

Example:

```
docker run \
  -v repo_volume:/svn_dumps \
  --env SVN_DUMP_DIR=/svn_dumps \
  --env SVN_AUTHORS=/svn_dumps/authors.txt \
  --env SVN_PATH=my_path_into_repo \
  jycr/svn-to-git
```

Or

```
docker volume create repo_volume
docker container create --name repo_migration -v repo_volume:/svn_dumps jycr/svn-to-git
docker cp ./repo.svndump.xz repo_migration:/svn_dumps/repo.svndump.xz

docker start repo_migration
docker logs repo_migration | sed -r -n -e '/<extracted-authors>/,/<\/extracted-authors>/{p}' | tail -n +2 | sed '$d' > authors.txt


# Check and modify authors.txt
docker cp ./authors.txt repo_migration:/svn_dumps/authors.txt
docker start repo_migration


```
