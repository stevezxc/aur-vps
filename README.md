# AUR-VPS

This repository contains Arch User Repository (AUR) package build scripts for a VPS.

Supports *-git packages and custom update logic for specific packages.

## Structure

- `Dockerfile` - Docker setup for building packages in a consistent environment.
- `update.sh` - Script to update packages.
- `aur_key` - SSH key for AUR access.
- `repos/` - Contains individual package repositories.

## Usage

1. Create a symbolic link to your AUR SSH key:

```bash
ln -sf /path/to/your/aur_key ./aur_key
```

1. Build the Docker image:

```bash
docker build -t <your-image-name> .
```

1. Writing your update rules and test:

```bash
./update.sh -d // for debug mode (does not push to AUR)
```

1. Set cron job to run `update.sh` periodically:

```bash
crontab -e
```

```crontab
0 0 * * * DOCKER_IMAGE=<your-image-name> /path/to/update.sh
```
