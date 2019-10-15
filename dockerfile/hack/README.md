
## How to make images

It's easy to get the help doc by typing as below:

```shell
$ bash docker-build.sh -h
Usage:
  bash docker-build.sh [OPTIONS]
  bash docker-build.sh [-h|--help]

  The build script is used to build caicloud base image.

Options:

  -c, --config=config.sh     Location of building image config files
  -i, --image                Full name of image, including registry, project, repo and tag
  -s, --registry-server      Registry server of image
  -p, --project              Project name of image
  -r, --repo                 Repo name of image
  -t, --tag                  Tag name of image
  -f, --dockerfile           Dockerfile of image
  -l, --list=images.list     Location of images.list file, listing all images you want to build
  --push=false               Push image or not, options: true or false. Default value: false
  --remove=false             Remove image or not, options: true or false. Default value: false
  --example                  Build an example image, e.g.cargo.caicloud.xyz/library/node:10.16-stretch

Examples:
  bash docker-build.sh -c node/config.sh
  bash docker-build.sh -i cargo.caicloud.xyz/library/node:10.16-stretch 
```


### Build an image with config.sh

If you'd like to build an image with specific tag, you could file a `config.sh` as below:

```shell
#!/bin/bash
set -e

REGISTRY_SERVER="cargo.caicloud.xyz"
REGISTRY_PROJECT="library"
REPO_NAME="node"
TAG_NAME="10.16-stretch"
```

Then you can build the TensorFlow image with `config.sh`:

```shell
bash docker-build.sh -c config.sh
```

The full image name would be `cargo.caicloud.xyz/library/node:10.16-stretch`.

### Build an image with specific name

If you just want to build an image at once, you could use `-i` or `--image` option. All you need to do is specify the image name, then we would parse the name and check whether there is a corresponding `Dockerfile`. For example, we could build `cargo.caicloud.xyz/library/node:10.16-stretch` image as below:

```shell
bash docker-build.sh -i cargo.caicloud.xyz/library/node:10.16-stretch 
```

It also works without registry hostname and project name.

### Build many images with image list

If you want to build many images in one time, you could file a `images.list` as below:

```shell
cargo.caicloud.xyz/library/node:10.16-stretch
cargo.caicloud.xyz/release/all-in-one:1.9
```

Running the script with `-l` or `--list` option like the following. Then it would build both `cargo.caicloud.xyz/library/node:10.16-stretch` and `cargo.caicloud.xyz/release/all-in-one:1.9` once.

```shell
bash docker-build.sh -l images.list
```
