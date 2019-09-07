#  Localhost Mirror

It is a bash command utility that allows to create local mirrors of resources published on Internet.

It can be used to set a local mirror for a resource that usually is requested by a 3rd program from Internet many times. You only need to download the resources the first time and use this command utility to create a localhost mirror.

It depends on a web server like Apache2 or NGINX with the default server directory as `/var/www/html` to publish locally the resources.

## Requirements

* Unix Operating System (Eg.: Debian based OS).
* Apache2 or NGINX web server installed.
* `/var/www/html` as default server directory.

## Usage

```bash
$ lhmirror [ <command> ]
```

Where `<command>` is one of:

```bash
-h|--help 
-p|--publish <origin-url> <local-resource-path>
-u|--unpublish <origin-url>
-a|--unpublish-all
```

Command description:
* `-h|--help`: Show this help information.
* `-p|--publish`: Set the URL passed in `<origin-url>`, as local mirror, using the resource(s) passed in `<local-resource-path>`.
* `-u|--unpublish`: Remove the local mirror created for the URL passed in `<origin-url>`.
* `-a|--unpublish-all`: Remove all local mirrors created before

## How it's works

* The resource name (local file) downloaded must have the same name of the resource in the `<origin-url>` from Internet.

* The domain is extrated from the `<origin-url>` and pushed to the file `/etc/hosts` with this format: 
    ```bash
    127.0.0.1 my-domain.com
    ```

* The path of the file is extracted from the `<origin-url>` and recreated into the `/var/www/html` directory.

* Finally the file in `<local-resource-path>` is copied into the path recreated into the `/var/www/html` directory.

* You can set the `<local-resource-path>` as a directory, `lhmirror` will copy all files inside it, into the the `/var/www/html` directory.

* `lhmirror` creates a work directory in your home (`/home/user/.lhmirror/`) to store all temporary files.

## Warnings

If you set a local mirror for a certain domain, it means all request to that domain will serve from localhost in the browser, terminal, etc. If you wish to restore the navigation through the domain, just remove the local mirror.

## Things to do...

* Allows the activation/deactivation of a local mirror of a certain domain passed to the command, or just all domains, without remove the directory structure from the `/var/www/html`. This could be done by using comments on the `hosts` file.

* Allow set local mirror without copy fisically the resources to the `/var/www/html` directory. This could be done by using Virtual Hosts from Apache2 or NGINX.