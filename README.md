# storeBackup
## Description
`storeBackup` is a backup utility that stores files on other disks. It's able to compress data, and recognize copying and moving of files and directories (deduplication), and unifies the advantages of traditional full and incremental backups. It can handle big image files with block-wise changes efficiently. Depending on its contents, every file is stored only once on disk. Tools for analyzing backup data and restoring are provided. Once archived, files are accessible by mounting file systems (locally, or via Samba or NFS). It is easy to install and configure. Additional features are backup consistency checking, offline backups, and replication of backups.
## Origin
* [Savannah](http://download.savannah.gnu.org/releases/storebackup/): http://download.savannah.gnu.org/releases/storebackup/

### Documentation
* [English](http://www.nongnu.org/storebackup/en/): http://www.nongnu.org/storebackup/en/
* [German](http://www.nongnu.org/storebackup/de/): http://www.nongnu.org/storebackup/de/

# Container
## Environment
### TIMEZONE
Because of `storeBackup` relies on `cron`, the container should knows about the actual time zone. If you do not specify the 'TIMEZONE' then it defaults to "Etc/UTC". You can use every <continent\>/<city\> combination present in the underlaying linux. If you do not know, which combinations exist, start the container with `docker run <IMAGE NAME> timezones`
## Volumes
### /in
Bind here the source, which shall be backed up. Please remember to start the `sourceDir=/in/...` with this prefix in your `storeBackup` configuration file.
### /out
Bind here the target, where the backup shall go to. Please remember to start the `backupDir=/out/...` with this prefix in your `storeBackup` configuration file. You have to ensure, that the complete path exists before starting `storeBackup`.
### /storebackup.d
Bind here the directory containing the `storeBackup` configuration file. Please remember to start the paths in`sourceDir=/in/...` and the `backupDir=/out/...` with the volume names `/in` and `/out`!
## Entry Point
### /docker-entrypoint.sh
This containers entry point `/docker-entrypoint.sh` accepts these arguments (called 'CMD' in `docker`):
#### continous
This is the normal run state. The container runs forever and `cron` is working.  Therefore, `storeBackup` wakes up one time a day and does its job.
You have to ensure, that `docker` calls this command after bringing up the container. That is the default behavior with the default 'Dockerfile'.
#### health-check
If you want `docker` to check the health of the container, let `docker` run this command. That is the default behavior with the default 'Dockerfile'.
#### run
You can use the `run` command to run `storeBackup` out of the regular `cron` schedules. But remember that `storeBackup` prevents itself from running more then once. Please check the logfile.
#### stop
Stops/kills a running `storeBackup` no matter if `storeBackup` is started via `cron` or the 'run' command. It does not stop or shut down the container. Therefore, `storeBackup` will restart with its new `cron` cycle or by the 'run' command. Stopping the container cannot be done within this entry point. Please use the `docker` mechanisms.
#### timezones
Lists the <continent\>/<city\> combinations you can use with the image environment variable TIMEZONE or argument/CMD 'timezone'. Finally these combinations are noting else then one selected file from '/usr/share/zoneinfo/*/*'. A few of them deviates from the <continent\>/<city\> scheme but can also be used.
#### timezone <continent\>/<city\>
Sets the timezone during runtime. See 'timezones' above for further information.
## Health Check
Use `/docker-entrypoint.sh health-check` as regular as you want for checking the health. Because of `storeBackup` is not running the whole day, the health check only reports the state of `cron`.
## Ports
No ports are used!
## Docker Compose
Just an example...

    version: "2.0"
    
    services:
      storebackup:
        image: th0masrad/storebackup:latest
      environment:
        - TIMEZONE=America/New_York
        volumes:
          - /local/storebackup.d:/storebackup.d:ro
          - /local/source:/in:ro
          - volume_target:/out
        restart: unless-stopped
    
    volumes:
      volume_target:
        driver: local
        driver_opts:
          type: "nfs"
          o: "addr=192.168.1.7,rw,nfsvers=4"
          device: ":/Backup"
