# https://stackoverflow.com/questions/60609535/how-to-install-and-use-docker-in-one-shell-script
# To run everything in the same shell. Otherwise `sudo usermod -aG docker $USER` or `newgrp docker` would be run in another shell.
cat << EOF | sudo apt-get update
  # Add Docker's official GPG key:
  sudo apt-get update
  sudo apt-get install ca-certificates curl -y
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  # Add the repository to Apt sources:
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update

  sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

  # Add permissons
  sudo chmod 666 /var/run/docker.sock
  sudo groupadd docker
  sudo usermod -aG docker $USER
  newgrp docker
  EOF