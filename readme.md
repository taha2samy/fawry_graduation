#  MySQL Database

![Docker Build Status](https://img.shields.io/badge/docker-build-success.svg?style=for-the-badge&logo=docker)

This repository contains the necessary files to build a custom Docker image for a MySQL database. The image comes pre-initialized with the schema, tables, and stored procedures required for the "BucketList" application.

This approach simplifies development and deployment by providing a consistent, ready-to-use database environment out-of-the-box.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [1. Build the Docker Image](#1-build-the-docker-image)
  - [2. Run the Docker Container](#2-run-the-docker-container)
- [How It Works](#how-it-works)
- [Environment Variables](#environment-variables)
  - [Mandatory Variable](#mandatory-variable)
  - [Highly Recommended Variables](#highly-recommended-variables)
- [Persisting Data](#persisting-data)
- [Connecting to the Database](#connecting-to-the-database)
- [Files in this Repository](#files-in-this-repository)

## Overview

The primary goal of this project is to package a MySQL database definition into a portable and reproducible Docker image. When a container is launched from this image for the first time, it automatically creates the `BucketList` database and populates it with the required tables and logic defined in `BucketList.sql`.

## Features

- **Automated Initialization:** The database schema is created automatically on the first run.
- **Pre-loaded Stored Procedures:** All application-specific stored procedures (`sp_createUser`, `sp_addWish`, etc.) are ready to use.
- **Portable & Consistent:** Ensures every developer and every environment (development, testing, production) uses the exact same database setup.
- **Based on Official MySQL Image:** Built on top of the trusted and secure official MySQL 8.0 image.

## Prerequisites

- [Docker](https://www.docker.com/get-started) must be installed and running on your system.
- [Git](https://git-scm.com/) (for cloning the repository).

## Getting Started

### 1. Build the Docker Image

First, clone the repository and navigate into the project directory.

```bash
git clone <your-repository-url>
cd <repository-name>
```

Next, build the Docker image using the `docker build` command. You should tag it with a meaningful name.

```bash
# Example: Tagging the image as 'bucketlist-db'
docker build -t bucketlist-db:latest .
```

### 2. Run the Docker Container

Once the image is built, you can run it as a container. You **must** provide the `MYSQL_ROOT_PASSWORD` environment variable.

```bash
docker run -d \
  --name mysql-bucketlist-container \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=my-super-secret-pw \
  -e MYSQL_DATABASE=BucketList \
  bucketlist-db:latest
```

This command starts a container in the background, maps port 3306, and sets the required environment variables. Your database is now up and running!

## How It Works

This setup leverages a key feature of the official MySQL Docker image. Any `.sql` or `.sh` script placed inside the `/docker-entrypoint-initdb.d/` directory within the image will be executed automatically when the container is started for the first time.

The `Dockerfile` in this repository simply copies the `BucketList.sql` script into that special directory.

## Environment Variables

These variables are passed at runtime (`docker run -e ...`) to configure the MySQL instance.

### Mandatory Variable

| Variable              | Description                                                  | Example Value  |
| --------------------- | ------------------------------------------------------------ | -------------- |
| `MYSQL_ROOT_PASSWORD` | **Required.** Sets the password for the MySQL `root` user. The container will not start without it. | `my-secret-pw` |

### Highly Recommended Variables

| Variable         | Description                                                  | Example Value  |
| ---------------- | ------------------------------------------------------------ | -------------- |
| `MYSQL_DATABASE` | Creates a database with the given name. The `BucketList.sql` script will be executed within this database. | `BucketList`   |
| `MYSQL_USER`     | Creates a new user with superuser privileges on the database specified by `MYSQL_DATABASE`. Recommended for application access. | `app_user`     |
| `MYSQL_PASSWORD` | Sets the password for the new user created with `MYSQL_USER`. | `app_password` |

## Persisting Data

By default, all data will be lost if you remove the container. To persist data across container restarts, you should use a Docker volume.

```bash
docker run -d \
  --name mysql-bucketlist-container \
  -p 3306:3306 \
  -v mysql_db_data:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=my-super-secret-pw \
  bucketlist-db:latest
```

This command creates a named volume `mysql_db_data` and mounts it to the data directory inside the container, ensuring your data is safe.

## Connecting to the Database

You can connect to the running database instance using any standard MySQL client:

- **Host:** `127.0.0.1` (or `localhost`)
- **Port:** `3306` (or whichever host port you mapped)
- **User:** `root` (or the user you created with `MYSQL_USER`)
- **Password:** The password you provided.

## Files in this Repository

- **`Dockerfile`**: The blueprint for building the custom MySQL image.
- **`BucketList.sql`**: The SQL script containing the database schema, tables, stored procedures, and initial data.
- **`README.md`**: This file.

