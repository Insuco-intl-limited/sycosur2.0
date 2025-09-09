# Staticfiles Directory Permissions Guide

## Overview

This document explains how to properly set up permissions for the `staticfiles` directory when using Docker for deployment. Proper permissions are essential to avoid errors during the `collectstatic` process.

## Problem

When running Django in a Docker container with volume mounts for the `staticfiles` directory, you may encounter the following error:

```
chmod: changing permissions of 'staticfiles': Operation not permitted
```

This occurs because:

1. The Docker container runs as a non-root user (django)
2. The `staticfiles` directory is mounted from the host
3. The container cannot change permissions on host-mounted directories

## Solution

### 1. Create the staticfiles directory on the host

Before starting the containers, ensure the `staticfiles` directory exists in the backend directory:

```bash
mkdir -p backend/staticfiles
```

### 2. Set appropriate permissions on the host

Set permissions that allow the container's django user to write to the directory:

```bash
# On Linux/macOS
chmod -R 777 backend/staticfiles

# On Windows
# Ensure the directory has full control permissions for all users
```

### 3. Start the containers

After setting the proper permissions, start the containers:

```bash
docker-compose -f prod.yml up -d
```

## Why This Works

The Django container runs as the `django` user (UID 999 typically), but this user doesn't exist on your host system. By setting the directory permissions to 777, you ensure that any user (including the container's django user) can write to the directory.

## Security Considerations

Setting permissions to 777 (read/write/execute for all) is not ideal for production environments. In a production setup, consider:

1. Creating a user on the host with the same UID as the container's django user
2. Setting more restrictive permissions (e.g., 755 or 775)
3. Using Docker volumes instead of bind mounts for better permission handling

## Troubleshooting

If you still encounter permission issues:

1. Check that the directory exists on the host before starting containers
2. Verify the permissions are set correctly
3. Ensure the container is running as the expected user
4. Check the Docker Compose file for correct volume mount configuration