# About

Docker image for running qpdf

## Usage

Image can be used for single runs or for recurring scheduled runs with crontab.

### Paths

The image works (and uses) the following paths actively:

- config: directory where configuration files (i.e.: passwords file) be stored/read
- logs: directory where running logs will be stored
- source: (base) directory containing PDF files that you want to try to decrypt
- target: (base) directory for move the PDF files that were decrypted successfully

`source` & `target` volumes are *required* mappings, keep in mind carefuly referencing them on the organize-tool config files.

## Run Examples

### Single Run Example

``` bash
docker run -it --name docker-qpdf
 -v "/path/to/config/":/config
 -v "/path/to/logs/":/logs
 -v "/source-folder/":/source
 -v "/target-folder/":/target
 -e PASSWORDS_FILENAME=/config/passwords.csv
 docker-qpdf
```

### Single Run Example keeping source files

``` bash
docker run -it --name docker-qpdf
 -v "/path/to/config/":/config
 -v "/path/to/logs/":/logs
 -v "/source-folder/":/source
 -v "/target-folder/":/target
 -e PASSWORDS_FILENAME=/config/passwords.csv
 -e KEEP_SOURCEFILE=true
 docker-qpdf
```

### Single Run Example mapping source & target folders

``` bash
docker run -it --name docker-qpdf
 -v "/path/to/config/":/config
 -v "/path/to/logs/":/logs
 -v "/some/base/folder/":/source
 -v "/some/base/folder/":/target
 -e PASSWORDS_FILENAME=/config/passwords.csv
 -e SOURCE_FOLDER=/source/2decrypt
 -e TARGET_FOLDER=/target/decrypted
 -e MOVE_UNENCRYPTED=false
 docker-qpdf
```

### Recurring Scheduled Run Example (using crontab within the image)

``` bash
docker run -dit --rm --name docker-qpdf
 -v "/path/to/config/":/config
 -v "/path/to/logs/":/logs
 -v "/source-folder/":/source
 -v "/target-folder/":/target
 -e PASSWORDS_FILENAME=/config/passwords.csv
 -e TOOL_SCHEDULE="0 2 * * *"
 docker-qpdf
```

Other sample crontab schedules:

- `0 0,6,12,18 * * *` - Every 6 hours on the hour starting at midnight
- `0 12 * * 1,3,5` - At noon every Monday, Wednesday and Friday

More configurations can be generated at [Crontab Guru](https://crontab.guru/#0_3_*_*_*)

## Craftmanship

Made on my free time, troubleshooting is mainly when I find problems or misbehaviors.

I use it to automate synced mobile camera roll contents to archive folders.

Code for this image is stored in [GitHub](https://github.com/rkuzner/docker-qpdf).
