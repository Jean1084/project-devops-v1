Project DevOps V1 | Docker & Docker-Compose | Secure Docker Registry
====================================================================

Environment Setup
-----------------

-   **Vagrant**: 2.4.1

-   **VirtualBox**: 7.0.16

-   **Ubuntu**: focal64 (Vagrant Box)

* * * * *

Infrastructure Automation
-------------------------
<img src="images/tools-use.PNG" width="210" height="390">

![Infrastructure of project](images/infrastructure.PNG)


Creating the `.env` File
------------------------

```
DOCKER_USER=XXXXXXXXXXXXX
DOCKER_PASS=XXXXXXXXXXXXX
GITHUB_USER=Jean1084
GITHUB_TOKEN=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

* * * * *

Deployment with `vagrant up`
----------------------------

With a single command, the following steps are automated:

-   **Create a VM (Ubuntu/focal64)**

-   **Install Docker**

-   **Install Docker-Compose**

-   **Add SSH key to GitHub account**

-   **Authenticate with GitHub**

-   **Clone the project repository**

-   **Build a Docker image**

-   **Authenticate with Docker Hub**

-   **Push the Docker image to Docker Hub**

-   **Run** `**docker-compose**`

* * * * *

API Testing via Command Line
----------------------------

```
curl -u jean:agree -X GET http://127.0.0.1:4000/simple-jean/api/v1.0/get_student_ages
curl -u jean:agree -X GET http://localhost:4000/simple-jean/api/v1.0/get_student_ages
```

### Expected Output:

```
{
  "student_ages": {
    "alice": "12",
    "bob": "13"
  }
}
```

* * * * *

API Testing via Web Browser
---------------------------

-   Navigate to `<ip_vm>:8082` (Initially, data access is restricted)

-   Run `docker-compose ps` inside the VM to retrieve the container name

-   Update the `index.php` file:

    -   **Before**: `http://<name_container_simple-api-jean:port>/simple-jean/api/v1.0/get_student_ages`

    -   **After**: `http://workspace-service-simple-api-jean-1:5000/simple-jean/api/v1.0/get_student_ages`

-   Retry accessing `<ip_vm>:8082` to confirm data availability

* * * * *

Advanced: Secure Docker Registry Setup (https://registry-jean.github.io/) (ex : Enable GitHub Pages in the repo settings => https://github.com/registry-jean/registry-jean.github.io.git )
--------------------------------------

Creating a **secure Docker registry** for **high-security enterprises** (e.g., banking, healthcare, defense) requires strong security measures. Below is a step-by-step guide:

### 1️⃣ Prerequisites

Ensure you have: ✅ A server (on-premise/cloud) with Linux (Ubuntu, CentOS, etc.)\
✅ Docker & Docker Compose installed\
✅ A domain or subdomain (`https://registry-jean.github.io/`)\
✅ SSL/TLS certificate (Let's Encrypt or enterprise CA)\
✅ Secure storage (S3, MinIO, NAS)\
✅ Secure authentication (LDAP, OAuth, Keycloak, etc.)

### 2️⃣ Install and Configure Docker Registry

#### **Deploy Docker Registry**

```
mkdir -p /opt/docker-registry/{data,auth,certs}
cd /opt/docker-registry
```

Create `docker-compose.yml`:

```
version: '3'
services:
  registry:
    image: registry:2
    container_name: docker-registry
    restart: always
    ports:
      - "5000:5000"
    environment:
      REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY: /var/lib/registry
      REGISTRY_HTTP_TLS_CERTIFICATE: /certs/registry.crt
      REGISTRY_HTTP_TLS_KEY: /certs/registry.key
      REGISTRY_AUTH: htpasswd
      REGISTRY_AUTH_HTPASSWD_REALM: "Registry Realm"
      REGISTRY_AUTH_HTPASSWD_PATH: /auth/htpasswd
    volumes:
      - ./data:/var/lib/registry
      - ./auth:/auth
      - ./certs:/certs
```

#### **Configure Authentication**

```
docker run --rm --entrypoint htpasswd httpd:2 -Bbn admin SecurePass123 > /opt/docker-registry/auth/htpasswd
```

#### **Enable SSL/TLS**

If using Let's Encrypt:

```
sudo apt install certbot
certbot certonly --standalone -d registry-jean.github.io
```

Copy certificates to `/opt/docker-registry/certs/` and update `docker-compose.yml`.

#### **Launch the Registry**

```
docker-compose up -d
docker ps
```

* * * * *

3️⃣ Secure the Infrastructure
-----------------------------

#### **Enable Firewall**

```
sudo ufw allow from 192.168.1.0/24 to any port 5000
```

#### **Enable Fail2Ban**

```
sudo apt install fail2ban
```

#### **Secure Access with Nginx Reverse Proxy**

```
server {
    listen 443 ssl;
    server_name registry-jean.github.io;

    ssl_certificate /etc/letsencrypt/live/registry-jean.github.io//fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/registry-jean.github.io/privkey.pem;

    location / {
        proxy_pass http://localhost:5000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        auth_basic "Docker Registry Authentication";
        auth_basic_user_file /opt/docker-registry/auth/htpasswd;
    }
}
```

Restart Nginx:

```
sudo systemctl restart nginx
```

* * * * *

4️⃣ Testing and Using the Registry
----------------------------------

#### **Login to Registry**

```
docker login registry-jean.github.io
```

#### **Push an Image**

```
docker tag nginx registry-jean.github.io/nginx:v1
docker push registry-jean.github.io/nginx:v1
```

#### **Pull an Image**

```
docker pull registry-jean.github.io/nginx:v1
```

* * * * *

5️⃣ Security Best Practices
---------------------------

✅ **Backup & High Availability**: Use MinIO/S3 and multi-region replication\
✅ **Advanced Authentication**: Use Keycloak, LDAP, or OAuth\
✅ **Monitoring**: Enable Prometheus & Grafana\
✅ **Docker Image Signing**: Implement Notary for integrity verification

* * * * *

Conclusion
----------

Following this guide, you now have a **secure Docker Registry**, suitable for **high-risk environments**. You can further integrate it with **Kubernetes or GitLab CI/CD** for a robust DevOps pipeline.

Would you like assistance with Kubernetes or CI/CD integration?