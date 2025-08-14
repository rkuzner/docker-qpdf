# Change Log

## Purpose of this file

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog][web_changelog], and this project adheres to [Semantic Versioning][web_semver].

### Guiding principles

- ChangeLogs are _for humans_, not machines.
- There should be an entry for every single version with it's release date.
- The same types of changes should be grouped.
- The latest version comes first.
- Versions should be linkable.

### Types of Changes

- ![img_add] for new features
- ![img_mod] for changes in existing functionality
- ![img_upd] for updates in existing features
- ![img_dep] for soon-to-be-removed features
- ![img_del] for now removed features
- ![img_fix] for any bug fixes
- ![img_sec] in case of vulnerabilities

## Unreleased

> Please list here the soon-to-be-released features

## 0.1.1 - 2025-08-14

![img_add]

- encapsulate tool into unpriviledged user
- allow crontab schedule via env vars
- encapsulate tool run in single script to be used by crontab and single runs consistently
- sample `env-vars.conf` & `passwords.csv` files
- docker image & manifest build script

## 0.1.0 - 2025-08-10

![img_add]

- pre-commit-config.yaml
- ReadMe
- ChangeLog

<!-- change type images & links -->
[img_add]: https://img.shields.io/badge/-added-green.svg "Added"
[img_mod]: https://img.shields.io/badge/-changed-blue.svg "Changed"
[img_upd]: https://img.shields.io/badge/-updated-orange.svg "Updated"
[img_dep]: https://img.shields.io/badge/-deprecated-yellow.svg "Deprecated"
[img_del]: https://img.shields.io/badge/-removed-lightgrey.svg "Removed"
[img_fix]: https://img.shields.io/badge/-fixed-red.svg "Fixed"
[img_sec]: https://img.shields.io/badge/-security-red.svg "Security"
[web_changelog]: https://keepachangelog.com "Keep a Changelog"
[web_semver]: https://semver.org "Semantic Versioning"
