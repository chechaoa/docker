#!/bin/bash
#
# The script builds base image, see usage function for how to run.
#

# dockerfile-release/
# └── library
#    └── alpine
#       └── 3.6
#            └── Dockerfile
# image will be named like cargo.caicloud.xyz/caicloud/alpine:3.6

set -e

function usage {
    echo -e "Usage:"
    echo -e "  ./docker-build.sh [OPTIONS]" 
    echo -e "  ./docker-build.sh [-h|--help]"
    echo -e ""
    echo -e "  The build script is used to build caicloud base image."
    echo -e ""
    echo -e "Options:"
    echo -e ""
    echo -e "  -c, --config=config.sh     Location of building image config files"
    echo -e "  -i, --image                Full name of image, including registry, project, repo and tag"
    echo -e "  -s, --registry-server      Registry server of image"
    echo -e "  -p, --project              Project name of image"
    echo -e "  -r, --repo                 Repo name of image"
    echo -e "  -t, --tag                  Tag name of image"
    echo -e "  -f, --dockerfile           Dockerfile of image"
    echo -e "  -l, --list=images.list     Location of images.list file, listing all images you want to build"
    echo -e "  --push=false               Push image or not, options: true or false. Default value: false"
    echo -e "  --remove=false             Remove image or not, options: true or false. Default value: false"
    echo -e "  --example                  Build an example image, e.g.cargo.caicloud.xyz/clever-base/tensorflow:v1.4.0"
    echo -e ""
    echo -e "Examples:"
    echo -e "  ./docker-build.sh -c tensorflow/config.sh"
    echo -e "  ./docker-build.sh -i cargo.caicloud.xyz/release/tensorflow:v1.4.0"
}

function clean {
    unset REPO_NAME
    unset TAG_NAME
    unset IMAGE_NAME
    unset DOCKERFILE
}

# Build, push and remove images. 
function build {
    
    # Compose image name if user doesn't set it by -i or --image option directly.
    if [[ ! "$IMAGE_NAME" ]]; then
        # If not specify anyone of arguments below, throw an error.
        if [[ ! "$REGISTRY_SERVER" || ! "$REGISTRY_PROJECT" || ! "$REPO_NAME" || ! "$TAG_NAME" ]]; then
            echo "Error: You must specify which image you want to build"
            exit 1
        fi
        IMAGE_NAME="$REGISTRY_SERVER/$REGISTRY_PROJECT/$REPO_NAME:$TAG_NAME"
    fi
    
    # If user specify image by -i or --image option directly, parse it.
    if [[ ! "$REGISTRY_SERVER" || ! "$REGISTRY_PROJECT" || ! "$REPO_NAME" || ! "$TAG_NAME" ]]; then
        # Set internal field separator
        IFS=":/" read -ra arr_vars <<< "$IMAGE_NAME"
        if [ ${#arr_vars[@]} -ne 4 ]; then
            echo "Error: Invalid image name: $IMAGE_NAME"
            exit 1
        else 
            REGISTRY_SERVER=${arr_vars[0]}
            REGISTRY_PROJECT=${arr_vars[1]}
            REPO_NAME=${arr_vars[2]}
            TAG_NAME=${arr_vars[3]}
        fi
    fi
    
    # Compose dockerfile if user doesn't set it by -f or --dockerfile option directly.
    if [[ ! "$DOCKERFILE" ]]; then
        if [[ $REPO_NAME && $TAG_NAME ]]; then
            DOCKERFILE="$REPO_NAME/$TAG_NAME/Dockerfile"
            if [[ -f release/${DOCKERFILE} ]]; then
                DOCKERFILE="release/$REPO_NAME/$TAG_NAME/Dockerfile"
            else
                DOCKERFILE="library/$REPO_NAME/$TAG_NAME/Dockerfile"
            fi
        fi
    fi

    echo "---------------------------------"
    echo "<<<< step0. check images with docker pull  $IMAGE_NAME "
    docker pull $IMAGE_NAME
    rc="$?"
   if [[ "$rc" -eq 0 ]]; then
        echo "Pull image $IMAGE_NAME  successfully"
    else
    echo "---------------------------------"
    echo " build $IMAGE_NAME        "
    echo "---------------------------------"
    echo "<<<< step1. docker build -t $IMAGE_NAME -f $DOCKERFILE . "
    
    docker build -t "$IMAGE_NAME" -f "$DOCKERFILE"  .
    fi
    
    # Decide if we need to push images to registry.
    if [[ "$PUSH" == "true" ]]; then
        echo "==== step2. docker push $IMAGE_NAME"
        docker push "$IMAGE_NAME"
    fi
    
    # Decide if we need to remove the images after operation.
    if [[ "$REMOVE" == "true" ]]; then
        echo -e ">>>> step3. docker rmi -f $IMAGE_NAME"
        docker rmi -f "$IMAGE_NAME" 
    fi      
}

function build_list {
    while IFS='' read -r line || [[ -n "$line" ]]; do
        clean
        export IMAGE_NAME=$line
        build
    done < "$IMAGES_LIST"
}

# Run example
function example {
    clean
    export IMAGE_NAME="cargo.caicloud.xyz/release/tensorflow:v1.4.0"
    export DOCKERFILE="tensorflow/v1.4.0/Dockerfile"
    build
}

# Print the usage.
if [[ "$#" == "0" ]]; then
    usage
    exit 0
fi

# Parse command line arguments
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -c|--config)
            CONFIG="$2"
            shift 2 # Past key and value
            ;;
        -i|--image)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -s|--registry-server)
            REGISTRY_SERVER="$2"
            shift 2
            ;;
        -p|--project)
            REGISTRY_PROJECT="$2"
            shift 2
            ;;
        -r|--repo)
            REPO_NAME="$2"
            shift 2
            ;;
        -t|--tag)
            TAG_NAME="$2"
            shift 2
            ;;
        -f|--dockerfile)
            DOCKERFILE="$2"
            shift 2
            ;;
        -l|--list)
            IMAGES_LIST="$2"
            build_list
            exit 0
            ;;
        --push)
            PUSH="true"
            shift 1
            ;;
       --remove)
           REMOVE="$2"
           shift 2
           ;;
        --example)
            example
            exit 0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Error: Unrecoginized keys: $key"
            exit 2
            ;;
    esac
done

# Source config file if user specified.
if [[ $CONFIG ]]; then
    source $CONFIG
fi

# -----------------------------------------------------------------------------
# Parameters for building docker image, see usage.
# -----------------------------------------------------------------------------
#
# Registry server of image.
REGISTRY_SERVER=${REGISTRY_SERVER:-""}
# Registry project of image.
REGISTRY_PROJECT=${REGISTRY_PROJECT:-""}
# Repo name of image.
REPO_NAME=${REPO_NAME:-""}
# Tag name of image.
TAG_NAME=${TAG_NAME:-""}
# Location of images list file
IMAGE_FILE=${IMAGE_FILE:-""}
# Dockerfile 
DOCKERFILE=${DOCKERFILE:-""}
# Decide if we need to push the new images to registry.
PUSH=${PUSH:-"false"}
# Decide if we need to remove the images after operation.
REMOVE=${REMOVE:-"false"}

# Build user specified image
build
