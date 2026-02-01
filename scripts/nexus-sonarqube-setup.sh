#!/bin/bash
set -e

# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Set hostname
sudo hostnamectl set-hostname nexus-sonarqube

# Install Docker
sudo apt-get install -y ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu

# Install Java
sudo apt-get install -y fontconfig openjdk-17-jre

# Create Docker Compose file for Nexus and SonarQube
sudo mkdir -p /opt/devops-tools
cat <<'EOF' | sudo tee /opt/devops-tools/docker-compose.yml
version: '3.8'

services:
  nexus:
    image: sonatype/nexus3:latest
    container_name: nexus
    restart: always
    ports:
      - "8081:8081"
    volumes:
      - nexus-data:/nexus-data
    environment:
      - INSTALL4J_ADD_VM_PARAMS=-Xms512m -Xmx512m -XX:MaxDirectMemorySize=273m

  sonarqube:
    image: sonarqube:lts-community
    container_name: sonarqube
    restart: always
    ports:
      - "9000:9000"
    volumes:
      - sonarqube-data:/opt/sonarqube/data
      - sonarqube-extensions:/opt/sonarqube/extensions
      - sonarqube-logs:/opt/sonarqube/logs
    environment:
      - SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true

volumes:
  nexus-data:
  sonarqube-data:
  sonarqube-extensions:
  sonarqube-logs:
EOF

# Set system limits for SonarQube
cat <<EOF | sudo tee -a /etc/sysctl.conf
vm.max_map_count=524288
fs.file-max=131072
EOF

sudo sysctl -p

cat <<EOF | sudo tee -a /etc/security/limits.conf
sonarqube   -   nofile   131072
sonarqube   -   nproc    8192
EOF

# Start services
cd /opt/devops-tools
sudo docker compose up -d

# Create helper script to get Nexus admin password
cat <<'NEXUS_PASS' | sudo tee /home/ubuntu/get-nexus-password.sh
#!/bin/bash
echo "Waiting for Nexus to initialize..."
sleep 30
sudo docker exec nexus cat /nexus-data/admin.password 2>/dev/null || echo "Nexus not ready yet. Wait a few minutes and try again."
NEXUS_PASS

sudo chmod +x /home/ubuntu/get-nexus-password.sh
sudo chown ubuntu:ubuntu /home/ubuntu/get-nexus-password.sh

echo "Setup complete!"
echo "Nexus will be available at http://<instance-ip>:8081"
echo "SonarQube will be available at http://<instance-ip>:9000"
echo "Run /home/ubuntu/get-nexus-password.sh to get Nexus admin password"
echo "SonarQube default credentials: admin/admin"
