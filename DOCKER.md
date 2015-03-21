# Running Onebody with Docker

**THIS IS EXPERIMENTAL.**

## Development on OS X

Set up boot2docker:

```
boot2docker up
$(boot2docker shellinit)
```

### NFS Share

Use NFS to mount your /Users folder into the boot2docker VM
(a workaround for [this bug](https://github.com/boot2docker/boot2docker/issues/581)):

```
boot2docker ip # note the IP address
vim /etc/exports
```

Put the following line in the file and save it:

```
/Users -mapall=timmorgan:staff 192.168.59.103
```

Then run:

```
sudo nfsd stop
sudo nfsd start
boot2docker ssh
sudo vi /var/lib/boot2docker/bootlocal.sh
```

Put the following in the file and save it:

```
sudo umount /Users
sudo /usr/local/etc/init.d/nfs-client start
sudo mount 192.168.59.3:/Users /Users -o rw,async,noatime,rsize=32768,wsize=32768,proto=tcp
```

Mark the file executable and exit ssh:

```
sudo chmod +x /var/lib/boot2docker/bootlocal.sh
exit
```

Now restart the boot2docker VM:

```
boot2docker restart
```

### Build and Run the Containers

```
cp config/database.yml{.docker-example,}
cp config/secrets.yml{.example,}
vim config/secrets.yml
```

Add a secret to the file and save it.

Run the database container:

```
docker run -d --name='onebody-data' -p 127.0.0.1:3306:3306 -v $PWD/db/data:/data -e USER='onebody' -e PASS='onebody' paintedfox/mariadb
```

Build and run the container for OneBody:

```
docker build -t onebody .
docker run --rm --link onebody-data:db -v $PWD:/var/www/onebody onebody script/docker/setup development
docker run --name='onebody-web' -d --link onebody-data:db -v $PWD:/var/www/onebody -p 8080:3000 onebody
```

## Production Deployment

```
cp config/database.yml{.docker-example,}
cp config/secrets.yml{.example,}
vim config/secrets.yml
```

Add a secret to the file and save it.

Run the database container:

```
docker run -d --name='onebody-data' -p 127.0.0.1:3306:3306 -v $PWD/db/data:/data -e USER='onebody' -e PASS='onebody' paintedfox/mariadb
```

Build and run the container for OneBody:

```
docker build -t onebody .
docker run --rm --link onebody-data:db -v $PWD:/var/www/onebody onebody script/docker/setup production
docker run --name='onebody-web' -d --link onebody-data:db -v $PWD:/var/www/onebody -p 8080:3000 -e "RAILS_ENV=production" onebody
```
