#!/bin/bash

# Get the directory of the script
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

DATABASES_TO_BACKUP_STRING="shlink,invoiceplane"

# Set comma as the delimiter
IFS=','

read -ra DATABASES_TO_BACKUP_ARRAY <<< "$DATABASES_TO_BACKUP_STRING"


# Check if .env file exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    # Extract the required variables
    DB_HOST='database'
    DB_PORT='3306'
    DB_USER="root"
    DB_PASS=$(grep "^DB_CLUSTER_ROOT_PASSWORD=" "$SCRIPT_DIR/.env" | cut -d '=' -f2 | tr -d '"')
    S3_BUCKET=$(grep "^BACKUP_S3_BUCKET_NAME=" "$SCRIPT_DIR/.env" | cut -d '=' -f2 | tr -d '"')
    AWS_ACCESS_KEY_ID=$(grep "^BACKUP_S3_KEY_ID=" "$SCRIPT_DIR/.env" | cut -d '=' -f2 | tr -d '"')
    AWS_SECRET_ACCESS_KEY=$(grep "^BACKUP_S3_ACCESS_KEY=" "$SCRIPT_DIR/.env" | cut -d '=' -f2 | tr -d '"')

    for DATABASE in "${DATABASES_TO_BACKUP_ARRAY[@]}"; do

        echo "start backup for database '$DATABASE'"

        # Create the Docker container without starting it
        CONTAINER_ID=$(docker create \
            --name mariadb-backup \
            -e DB_HOST="$DB_HOST" \
            -e DB_PORT="$DB_PORT" \
            -e DB_NAME="$DATABASE" \
            -e DB_USER="$DB_USER" \
            -e DB_PASS="$DB_PASS" \
            -e S3_BUCKET="$S3_BUCKET" \
            -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
            -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
            ghcr.io/fermionhq/mariadb-backup-dump-to-s3:7877541009-1)

        # Connect the container to the "server-deployment_local" network
        docker network connect server-deployment_local $CONTAINER_ID

        # Connect the container to the "server-deployment_public" network
        docker network connect server-deployment_public $CONTAINER_ID

        # Start the container and wait for it to exit
        docker start $CONTAINER_ID
        docker wait $CONTAINER_ID

        # Stop and remove the container
        docker stop $CONTAINER_ID
        docker rm $CONTAINER_ID

        # docker stop mariadb-backup
        echo "finished script execution"
        exit 1
        done

else
    echo "Error: .env file not found in the script directory"
    exit 1
fi