FROM ubuntu:18.04

MAINTAINER FND <fndemers@gmail.com>

ENV TERM=xterm\
    TZ=America/Toronto\
    DEBIAN_FRONTEND=noninteractive

# Access SSH login
ENV USERNAME=ubuntu
ENV PASSWORD=ubuntu

ENV PROJECTNAME=SCRIBUS

ENV WORKDIRECTORY /home/ubuntu

RUN apt-get update

RUN apt install -y apt-utils

RUN apt-get install -y vim-nox curl git exuberant-ctags

# Install a basic SSH server
RUN apt install -y openssh-server
RUN sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd
RUN mkdir -p /var/run/sshd
RUN /usr/bin/ssh-keygen -A

# Add user to the image
RUN adduser --quiet --disabled-password --shell /bin/bash --home /home/${USERNAME} --gecos "User" ${USERNAME}
# Set password for the Ubuntu user (you may want to alter this).
RUN echo "$USERNAME:$PASSWORD" | chpasswd

# For Timezone
RUN apt-get clean && apt-get -y update && apt-get install -y locales && locale-gen fr_CA.UTF-8
ENV TZ=America/Toronto
RUN unlink /etc/localtime
RUN ln -s /usr/share/zoneinfo/$TZ /etc/localtime

# Installation X11.
RUN apt install -y xauth vim-gtk

# Installation de FZF.
RUN apt install -y silversearcher-ag


RUN apt-get install -y build-essential cmake python-dev python3-dev

RUN apt install -y fish

# Installation de Scribus 1.5
RUN apt -y install software-properties-common dirmngr apt-transport-https lsb-release ca-certificates
RUN add-apt-repository ppa:scribus/ppa
RUN apt-get -y update
RUN apt-get -y install scribus-trunk scribus-ng

#ENV QT_ACCESSIBILITY=0
RUN echo "export QT_ACCESSIBILITY=0" >> ${WORKDIRECTORY}/.bash_profile

# Ajout des droits sudoers
RUN apt-get install -y sudo
RUN echo "%ubuntu ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

WORKDIR ${WORKDIRECTORY}

RUN cd ${WORKDIRECTORY} \
    && git clone git://github.com/zaiste/vimified.git \
    && ln -sfn vimified/ ${WORKDIRECTORY}/.vim \
    && ln -sfn vimified/vimrc ${WORKDIRECTORY}/.vimrc \
    && cd vimified \
    && mkdir bundle \
    && mkdir -p tmp/backup tmp/swap tmp/undo \
    && git clone https://github.com/gmarik/vundle.git bundle/vundle \
    && echo "let g:vimified_packages = ['general', 'coding', 'fancy', 'indent', 'css', 'os', 'ruby', 'js', 'haskell', 'python', 'color']" > local.vimrc

COPY after.vimrc ${WORKDIRECTORY}/vimified/

COPY extra.vimrc ${WORKDIRECTORY}/vimified

# Générer les tags de ctags.
RUN echo "ctags -f ${WORKDIRECTORY}/mytags -R ${WORKDIRECTORY}" >> ${WORKDIRECTORY}/.bash_profile

#RUN echo "vim +BundleInstall +qall" >> ${WORKDIRECTORY}/.bash_profile

RUN echo "export PS1=\"\\e[0;31m $PROJECTNAME\\e[m \$PS1\"" >> ${WORKDIRECTORY}/.bash_profile

# Compiling YouCompleteMe only once...
RUN echo "if ! [ -f ~/.runonce_install ]; then" >> ${WORKDIRECTORY}/.bash_profile
RUN echo "touch ~/.runonce_install" >> ${WORKDIRECTORY}/.bash_profile
RUN echo "vim +BundleInstall +qall" >> ${WORKDIRECTORY}/.bash_profile
RUN echo "cd ~/.vim/bundle/YouCompleteMe" >> ${WORKDIRECTORY}/.bash_profile
RUN echo "./install.py --clang-completer" >> ${WORKDIRECTORY}/.bash_profile
RUN echo "fi" >> ${WORKDIRECTORY}/.bash_profile
RUN echo "cd ~/" >> ${WORKDIRECTORY}/.bash_profile

RUN echo "export XDG_RUNTIME_DIR='/tmp/runtime-ubuntu'" >> ${WORKDIRECTORY}/.bash_profile
RUN echo "export DISPLAY=:0.0" >> ${WORKDIRECTORY}/.bash_profile
RUN echo "export XDG_RUNTIME_DIR='/tmp/runtime-ubuntu'" >> /root/.bash_profile
RUN echo "export DISPLAY=:0.0" >> /root/.bash_profile

RUN cd ${WORKDIRECTORY} \
    && mkdir work \
    && chown -R $USERNAME:$PASSWORD work vimified .vim .vimrc .bash_profile

# Standard SSH port
EXPOSE 22

# Start SSHD server...
CMD ["/usr/sbin/sshd", "-D"]

