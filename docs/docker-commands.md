# Docker Command Reference — Task 2 to 5

Repo: https://github.com/Bhandarihansraj/cyberSEC

All tasks 2-5 share one container: `dvwa-lab` (started by `task2_dvwa_setup`,
reused by task3/4/5 via `tasks/lib.sh`).

## Setup / lifecycle

```bash
# Start DVWA (or via ./menu.sh -> 2 -> s)
./tasks/task2_dvwa_setup/run.sh start
# same as: docker compose -f tasks/task2_dvwa_setup/docker-compose.yml up -d

# Stop and remove DVWA (or via ./menu.sh -> 2 -> x)
./tasks/task2_dvwa_setup/run.sh stop
# same as: docker compose -f tasks/task2_dvwa_setup/docker-compose.yml down
```

## Status / inspection

```bash
docker ps                          # confirm dvwa-lab is running
docker ps -a                       # include stopped containers
docker logs dvwa-lab               # container startup/error logs
docker logs -f dvwa-lab            # follow logs live (useful while testing payloads)
docker inspect dvwa-lab            # full container config (network, mounts, env)
docker port dvwa-lab               # confirm port mapping (127.0.0.1:4280 -> 80)
```

## Getting inside the container (used in Task 3/4/5)

```bash
docker exec -it dvwa-lab bash      # interactive shell inside DVWA
docker exec dvwa-lab cat /var/www/html/vulnerabilities/upload/source/high.php
docker exec dvwa-lab ls -la /var/www/html/hackable/uploads/
```

## Copying files in/out (Task 5 — file upload)

```bash
docker cp dvwa-lab:/var/www/html/hackable/uploads/shell.php ./shell.php
docker cp ./shell.gif dvwa-lab:/var/www/html/hackable/uploads/shell.gif
```

## Database access (useful while checking Task 3 — SQL Injection results)

```bash
docker exec -it dvwa-lab mysql -u root -p dvwa
# default DVWA db password: p@ssw0rd (as set in the image)
# then inside mysql:  SELECT user, password FROM users;
```

## Cleanup

```bash
docker rm -f dvwa-lab                          # force remove if stuck
docker network rm dvwa-isolated                # remove the lab's isolated network
docker system prune                            # reclaim space from stopped/old containers (careful — affects all containers, not just this lab)
```

## Security note
Every command above targets `dvwa-lab` specifically and the container only
listens on `127.0.0.1:4280` — nothing here exposes the lab beyond localhost.
Don't run `docker system prune -a` carelessly if you have other unrelated
containers/images you want to keep.
