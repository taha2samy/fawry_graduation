FROM mysql:latest 
COPY ./BucketList.sql / docker-entrypoint-initdb.d/
EXPOSE 3306

