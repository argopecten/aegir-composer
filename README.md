# Composer project to deploy Aegir 3.x

This project provides a deployment method to install and update Aegir 3.x by
managing dependencies with [Composer](https://getcomposer.org/), and by
providing bash scripts for install and update functions of Aegir backend and
frontend.

## Usage

First you need to have full root access and need to setup a LAMP environment for
Drupal 7.x on a modern Ubuntu server (LTS 22.04).

See the [aegir branch of this cloud-init config file](https://github.com/argopecten/drupal-cloud-init/tree/aegir) for orientation.
This config is fully compatible with this deployment method, installs and
configure the Aegir dependencies (Nginx, MySQL, PHP, ...), including
[composer](https://getcomposer.org/).

Having this LAMP setup in place, you can create the project with a regular user
with sudo privilages:

```
composer create-project --repository '{"type": "vcs","url":  "https://github.com/argopecten/aegir-composer"}' argopecten/aegir-composer /tmp/aegir-composer dev-dev/aegir-d10
```

Before running composer create-project, you might need to delete the /tmp/aegir-composer folder if exists:

```
[[ -d /tmp/aegir-composer ]] && sudo su -c "rm -rf /tmp/aegir-composer"
```

And add a proper github authentication to composer if missing:

```
composer config -g github-oauth.github.com <ghp_YOUR_GITHUB_AUTH_TOKEN>
```

## What does the template do?

When installing the given `composer.json` some tasks are taken care of:

* Drupal 7 will be installed in the `hostmaster`-directory.
* Modules (packages of type `drupal-module`) will be placed in `hostmaster/sites/all/modules/contrib/`
* Theme (packages of type `drupal-module`) will be placed in `hostmaster/sites/all/themes/contrib/`
* The Aegir Hostmaster profile will be placed in `hostmaster/profiles/`
* Creates `hostmaster/sites/default/files`-directory.
* A fork of drush 8.x is installed locally for use at `vendor/bin/drush`.
* pre-install and post-install scripts are run to configure Aegir
