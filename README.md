# Centre

Small script to quickly work on current directory in a container.

## Usage
```
./centre [options] image [--]
```

## Images
This tool is built upon docker (it should be pretty easy to swap it out for podman). And so we defer all image management to that tool. If you need an image you can either pull or build it in the standard way (aka `docker pull` or `docker build`).

## Examples
### Basic usage
```
$ git clone git@github.com:OniOni/mec.git
$ cd mec

$ ./centre ubuntu
root@e48e4c34ffeb:/mec#
```

This will mount the current directory as an overlay mount. Meaning any changes made while in the container will be not be reflected directly on the host directory but rather "recorded" in another directory (by default `~.prjctz/$(basename $(pwd))`

So if we pick up our current session:
```
root@e48e4c34ffeb:/mec# echo "WTFPL" > LICENSE
root@e48e4c34ffeb:/mec# exit
$ head -n 1 LICENSE
                    GNU GENERAL PUBLIC LICENSE
$ tree ~/.prjctz/mec/
/home/<user>/.prjctz/mec/
└── overlay
    └── LICENSE

1 directory, 1 file
$ cat ~/.prjctz/mec/overlay/LICENSE
WTFPL
```

## Rationnal
I've grown weary of managing all the ancillary tooling (and all the files they leave around) for different coding projects. So I built so I could contain full developement environements, while keeping the files locally.