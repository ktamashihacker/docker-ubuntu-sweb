ARG TARGET_TAG
FROM ubuntu:${TARGET_TAG}

ENV DEBIAN_FRONTEND noninteractive
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1
ARG TARGETARCH

####################
# Upgrade
####################
RUN apt-get update -q \
    && apt-get upgrade -y \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*
    
####################
# Add Ubuntu Mate
####################
RUN apt-get update -q \
    && apt-get upgrade -y \
    && apt-get install -y \
        ubuntu-mate-desktop \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

####################
# Add Package
####################
RUN apt-get update \
    && apt-get install -y \
        supervisor wget gosu git sudo python3-pip \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*
RUN wget -qO- https://github.com/kasmtech/KasmVNC/releases/download/v0.9.1-beta/KasmVNC_0.9.1-beta_Ubuntu_18.04.tar.gz | tar xz --strip 1 -C /
    
####################
# Add User
####################
ENV USER ubuntu
ENV PASSWD ubuntu
RUN useradd --home-dir /home/$USER --shell /bin/bash --create-home --user-group --groups adm,sudo $USER
RUN echo $USER:$USER | /usr/sbin/chpasswd
RUN mkdir -p /home/$USER/.vnc 
    && chmod 600 /home/$USER/.vnc/passwd \
    && chown -R $USER:$USER /home/$USER

####################
# noVNC and Websockify
####################
RUN pip install git+https://github.com/novnc/websockify.git@v0.10.0
####################
# Disable Update and Crash Report
####################
RUN sed -i 's/Prompt=.*/Prompt=never/' /etc/update-manager/release-upgrades
RUN sed -i 's/enabled=1/enabled=0/g' /etc/default/apport

####################
# Supervisor
####################
ENV CONF_PATH /etc/supervisor/conf.d/supervisord.conf
RUN echo '[supervisord]' >> $CONF_PATH \
    && echo 'nodaemon=true' >> $CONF_PATH \
    && echo 'user=root'  >> $CONF_PATH \
    && echo '[program:vnc]' >> $CONF_PATH \
    && echo 'command=gosu '$USER' /opt/KasmVNC/bin/vncserver :0 -fg -wm mate -geometry 1920x1080 -depth 24' >> $CONF_PATH \
    && echo '[program:novnc]' >> $CONF_PATH \
    && echo 'command=gosu '$USER' bash -c "websockify --web=/usr/lib/novnc 80 localhost:5900"' >> $CONF_PATH
CMD ["bash", "-c", "supervisord -c $CONF_PATH"]
