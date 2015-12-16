# Creates an Ambari Server base on vanilla centos
FROM sequenceiq/ambari:latest
MAINTAINER seanorama

RUN yum install -y screen git openssh-server openssh-clients unzip bind-utils sudo createrepo

## optional packages for students
RUN yum -y install screen jq tmux

RUN chkconfig sshd on
RUN service sshd start

RUN useradd student
RUN usermod -aG wheel student
RUN echo 'student:BadPass#1' | chpasswd
RUN sed -i -e 's/^# \(%wheel\)/\1/' /etc/sudoers
COPY authorized_keys /home/student/.ssh/authorized_keys

RUN cp -a /etc/ambari-agent/conf/internal-hostname.sh /etc/ambari-agent/conf/public-hostname.sh
RUN ambari-agent restart

ENV PS1 "[\u@\h \W]"\#" "
RUN echo 'export PS1="[\u@\h \W]"\#" "' >> /root/.bash_profile

EXPOSE 22
EXPOSE 8443
