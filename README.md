
# Docker Tomcat - APR - MySQL

## Description

This image uses my previous project [Tomcat-APR](https://hub.docker.com/repository/docker/gbalboa72/tomcat-apr) and extend it to use MySQL database. 

The default configuration of the resulting image includes all the same as the [Tomcat-APR](https://hub.docker.com/repository/docker/gbalboa72/tomcat-apr) plus the following:

* Preconfigured to use a MySQL as database for Tomcat Users [DataSourceRealm](https://tomcat.apache.org/tomcat-9.0-doc/realm-howto.html#DataSourceRealm) 
* Preconfigured global JNDI DataSource server.xml to be used by deployed applications
* Encrypted DB Passwords stored in server.xml (Mor info in my project [Tomcat-security-utils](https://github.com/gbalboa-git/tomcat-security-utils))

## How to use it

### Running the default image

Available enviroment vars:
* **HTTP_TLS_CERTIFICATE:** This option can be used if want to bind mount your own certificate and want to use a different name than the defult.  Default value: /usr/opt/tomcat/certs/domain.crt
* **HTTP_TLS_KEY:** This option can be used if want to bind mount your own certificate KEY and want to use a different name than the defult.  Default value: /usr/opt/tomcat/certs/domain.key
* **TOMCAT_HTTP_PORT:**: Define the container HTTP port (-1 or omit
 to disable http. This is default)
* **TOMCAT_SSL_PORT:** Defines the container HTTPS port (Default 8443)
* **TOMCAT_SRV_USR:** Defines the username for service user (default: tomcat)
* **TOMCAT_SRV_UID:** Defines the UID for the service user (default: 997)
* **TOMCAT_DBUG_PORT:** Define the container HTTP DEBUG port (-1 or omit
 to disable debugging options. This is default)
* **DB_HOST:** Hosname of your database. 
* **DB_PORT:** Port of the database
* **DB_NAME:**: Database Name
* **DB_USR_NAME:** User defined to connect to the database
* **DB_USR_PASS:** **Encripted** database password (See how to encript thos passwords using the utility provided) 
* **DB_USR_TABLE:** Name of the table that stores the users (Tomcat Users). For more info consult the Tomcat Documentation [DataSourceRealm](https://tomcat.apache.org/tomcat-9.0-doc/realm-howto.html#DataSourceRealm)
* **DB_USR_NAMEFIELD:** Name of the column (of the users table) that stores the username. For more info consult the Tomcat Documentation [DataSourceRealm](https://tomcat.apache.org/tomcat-9.0-doc/realm-howto.html#DataSourceRealm)
* **DB_USR_PASSFIELD:** Name of the column (of the users table) that stores the password (the passwordmust be encripted using the Tomcat official tools) see examples below. For more info consult the Tomcat Documentation [DataSourceRealm](https://tomcat.apache.org/tomcat-9.0-doc/realm-howto.html#DataSourceRealm)
* **DB_USR_ROLE_TABLE:** Name of the table that stores the roles (Tomcat Users roles). For more info consult the Tomcat Documentation [DataSourceRealm](https://tomcat.apache.org/tomcat-9.0-doc/realm-howto.html#DataSourceRealm)
* **DB_ROLE_FIELDNAME:** Name of the column (of the users table) that stores the rolename. For more info consult the Tomcat Documentation [DataSourceRealm](https://tomcat.apache.org/tomcat-9.0-doc/realm-howto.html#DataSourceRealm)


#### Examples
#### How to encript the database passwords

To encript the passwor that will be used in the **_DB_USR_PASS_**, you can run the ``$CATALINA_HOME/bin/encrypt.sh`` inside the container as showed bellow, the only argument needed is the password to encrypt.
You can use Docker run for that:
```
root@host:# docker run -it \
                    --rm gbalboa72/tomcat-apr-mysql:latest \
                    bin/encrypt.sh 'YourVerySecretPass' 
YourVerySecretPass:8984bda4e2fdfc8284c0b305a129e1ad3623597777128dcc6b2f3f92fe0b333c58364443a2eb804a1ba4609f7ada1fdb83c673551e4b683bb5a4c7d833fefb02
root@host:#                    
``` 
If you password contains special characters, you need to escape them to the script runs properly. Here is an example:
```
# Password: webap$@91#0.$2#8 

root@host:# docker run -it \
                    --rm gbalboa72/tomcat-apr-mariadb:latest \
                    bin/encrypt.sh 'webap\$\@91\#0.\$2\#8' 
webap$@91#0.$2#8:b45b2a92ce4cd1e027dc3f511064235fb390518a1d892b490ce7352ddd25b73a0e1a10c6e6c467e0e696d91bd47d34bc107e26f68205d3f6503c1b3ee625055b
root@host:#                    
``` 

For the next example, lets create a testdb table in your MariaDB server, the databse will have 3 tables **_Users_**, **_Roles_** and **_UserRoles_**.

The users that will be stored in the database **must NOT** be encripted with the ``bin/encrypt.sh`` explained in the previous example, because are not the same, the ``encrypt.sh`` script is only intended for the database password. The users should be encripted with the same tool and algorithm used in the CredentialHandler defined in server.xml and the Tomcat-APR uses the **_org.apache.catalina.realm.SecretKeyCredentialHandler_** as showed here:
```
<CredentialHandler className="org.apache.catalina.realm.SecretKeyCredentialHandler"
            algorithm="PBKDF2WithHmacSHA512"/>
```
To create an initial load of you database you can use the ``CATALINA_HOME/bin/digest.sh`` provided by Tomcat, you can check the official documentation [here](https://tomcat.apache.org/tomcat-9.0-doc/realm-howto.html#Digested_Passwords). But here is an example using the Docker run command with the same procedure as before:

```
root@host:# docker run -it --rm \
      gbalboa72/tomcat-apr-mariadb:latest \
      bin/digest.sh -a "PBKDF2WithHmacSHA512" -h "org.apache.catalina.realm.SecretKeyCredentialHandler" 'admin\#904'

admin#904:50faf2e59ba7e704cc02c084685ac605292569b0fdd080ce38f0dd359fcefe6d$20000$a0db78b4c2ef216e8ede53d5740ca932a04e4193
```
To encrypt you passwords when you create users with your app you must code your app using the class **org.apache.catalina.realm.SecretKeyCredentialHandler** method mutate(...) with default options. If you want to change this, remember to also change the CredentialHandler Options in **server.xml**.

Now lets jump into the example:

```
# Create a user that you app will use to connect.
# Lets use the same password that we encrypt in the example above.

CREATE USER webappusr IDENTIFIED BY 'webap$@91#0.$2#8';
GRANT ALL PRIVILEGES ON testdb.* TO webappusr;
FLUSH PRIVILEGES;

# Create the tables
CREATE TABLE Roles (RoleId CHAR(20) NOT NULL,RoleDesc VARCHAR(200) NOT NULL,PRIMARY KEY (RoleId));
CREATE TABLE Users (LoginName VARCHAR(25) NOT NULL,PwdHash CHAR(200) NOT NULL, PRIMARY KEY (LoginName));
CREATE TABLE UserRoles (LoginName VARCHAR(25) NOT NULL,RoleId CHAR(20) NOT NULL, PRIMARY KEY (LoginName, RoleId));


ALTER TABLE UserRoles ADD CONSTRAINT roles_userroles_fk
FOREIGN KEY (RoleId)
REFERENCES Roles (RoleId)
ON DELETE NO ACTION
ON UPDATE NO ACTION;

ALTER TABLE UserRoles ADD CONSTRAINT users_userroles_fk
FOREIGN KEY (LoginName)
REFERENCES Users (LoginName)
ON DELETE NO ACTION
ON UPDATE NO ACTION;

# Add the Tomcat Roles to the Roles table
insert into Roles (RoleId, RoleDesc) values ("admin-gui", "Gui Administrator");
insert into Roles (RoleId, RoleDesc) values ("admin-script", "Script Administrator");
insert into Roles (RoleId, RoleDesc) values ("manager-gui", "Administrator of Manager App");
insert into Roles (RoleId, RoleDesc) values ("manager-script", "User with grant to script in Manager app");
insert into Roles (RoleId, RoleDesc) values ("manager-status", "User with status grant for manager app");
insert into Roles (RoleId, RoleDesc) values ("manager-jmx", "Verify");

# Create the users.
# and encript the passwords as explained before (in this example the passwords are admin#904 and deployer#904 )
insert into Users (LoginName, PwdHash) values ("admin", "50faf2e59ba7e704cc02c084685ac605292569b0fdd080ce38f0dd359fcefe6d$20000$a0db78b4c2ef216e8ede53d5740ca932a04e4193");
insert into Users (LoginName, PwdHash) values ("deployer","ef7a67770bdac3166d28d189cadc0d3cc343bb6cca72cf1be6f8893d5f02d231$20000$aa3e0d1b8e832de984f80d0bce30022165094b52");

# Add Tomcat Roles to the users
insert into UserRoles (LoginName, RoleId)values	("admin","admin-gui");
insert into UserRoles (LoginName, RoleId)values	("admin","admin-script");
insert into UserRoles (LoginName, RoleId)values	("admin","manager-gui");
insert into UserRoles (LoginName, RoleId)values	("admin","manager-script");
insert into UserRoles (LoginName, RoleId)values	("admin","manager-status");
insert into UserRoles (LoginName, RoleId)values	("admin","manager-jmx");

insert into UserRoles (LoginName, RoleId)values	("deployer","manager-script");
```
Now you are ready to run the container with Tomcat and your test db.
Asuming that your databse host is test_db :

```
root@host:# docker run -d \
            -e DB_HOST=test_db
            -e DB_PORT=3306 
            -e DB_NAME=testdb 
            -e DB_USR_NAME=webappusr
            -e DB_USR_PASS=b45b2a92ce4cd1e027dc3f511064235fb390518a1d892b490ce7352ddd25b73a0e1a10c6e6c467e0e696d91bd47d34bc107e26f68205d3f6503c1b3ee625055b
            -e DB_USR_TABLE=Users
            -e DB_USR_NAMEFIELD=LoginName
            -e DB_USR_PASSFIELD=PwdHash
            -e DB_USR_ROLE_TABLE=UserRoles
            -e DB_ROLE_FIELDNAME=RoleId
            -p 443:8443 \
           gbalboa72/tomcat-apr-mariadb:latest
``` 
#### Example with Docker Compose
The following exaple uses tomcat-apr-mysql and the official [mysql](https://hub.docker.com/_/mysql) image

```
version: "3.8"

services:
  db:
    image: mysql:latest
    hostname: test_db            
    environment:
      - MYSQL_INITDB_SKIP_TZINFO=yes
      - MYSQL_ROOT_PASSWORD=YourStrongSecret
      - MYSQL_DATABASE=testdb
      - MYSQL_USER=testuser
      - MYSQL_PASSWORD=YourStrongSecret
    healthcheck: 
      test: "mysql -u testuser --password='YourStrongSecret' -e 'Select 1'"
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s 
    ports:
      - 3306:3306    
    volumes:
      - ./init-testdb.sql:/docker-entrypoint-initdb.d/init-testdb.sql:ro   
  www:
    image: gbalboa72/tomcat-apr-mariadb:latest
    hostname: www                  
    depends_on:       
      - db
    command: [bin/wait-for-db.sh, "bin/catalina.sh","run", "-security" ] 
    environment:               
      - DB_HOST=test_db
      - DB_PORT=3306 
      - DB_NAME=testdb 
      - DB_USR_NAME=webappusr
      - DB_USR_PASS=b45b2a92ce4cd1e027dc3f511064235fb390518a1d892b490ce7352ddd25b73a0e1a10c6e6c467e0e696d91bd47d34bc107e26f68205d3f6503c1b3ee625055b
      - DB_USR_TABLE=Users
      - DB_USR_NAMEFIELD=LoginName
      - DB_USR_PASSFIELD=PwdHash
      - DB_USR_ROLE_TABLE=UserRoles
      - DB_ROLE_FIELDNAME=RoleId
    ports:
    - 443:8443
    - 8000:8000              
    
``` 



