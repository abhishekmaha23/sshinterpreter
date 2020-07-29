# Can be any Docker image that's built purely with libraries, and purely for Debian based systems. 
# For images that have a specific ENTRYPOINT of their own, this will not work directly, and thus more involved modification is necessary.
# This specific image is to provide SSH access to the tensorflow 1.15.2-gpu-py3 version
FROM tensorflow/tensorflow:1.15.2-gpu-py3

# Updating packages and installing OpenSSH Server 
RUN	apt-get update && apt-get -y upgrade
RUN apt-get install -y openssh-server

# Creating a temp user for access
# Username is pycharmuser
# Password is pypass
# Home directory is /home/pycharmuser
# Shell is /bin/bash
RUN useradd -s /bin/bash -d /home/pycharmuser -p $(echo pypass | openssl passwd -1 -stdin) pycharmuser
RUN mkdir /home/pycharmuser
RUN chown pycharmuser /home/pycharmuser

# Helps debug, but shouldn't be needed/used for the final build.
# RUN apt-get install -y vim
# RUN apt-get install -y x11-apps

# Needed for OpenCV specific to the Ubuntu base image used by Tensorflow 1.15.2 GPU version
RUN apt-get install -y libsm6 libxext6 libxrender-dev

# Needed for Gym rendering over OpenGL
# RUN apt-get install -y freeglut3-dev 
# RUN apt-get install -y mesa-utils
# libgl1-mesa-dri libgl1-mesa-dev libglu1-mesa libglu1-mesa-dev
# RUN apt-get install -y libgl1-mesa-dev
# RUN apt-get install python-pyglet

USER pycharmuser

# Creating folders 
RUN mkdir -p /home/pycharmuser/ssh
RUN mkdir -p /home/pycharmuser/var/run
RUN mkdir -p /home/pycharmuser/shared

# Generating SSH keys for the user
RUN ssh-keygen -t rsa -f /home/pycharmuser/ssh/ssh_host_rsa_key -N ''

# Copying over the sample sshd_config file that allows the SSH server to be run as the non-root user pycharmuser.
COPY --chown=pycharmuser sshd_config /home/pycharmuser/ssh/sshd_config

# Starts the SSH server and starts a bash to keep the container active 
ENTRYPOINT /usr/sbin/sshd -f /home/pycharmuser/ssh/sshd_config && bash

# Port to be mapped to a custom port while initializing a container
EXPOSE 2022
