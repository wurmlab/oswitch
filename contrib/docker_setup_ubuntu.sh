#!/bin/bash

set -e
set -u

# This script was contributed to oswitch by Tim Booth, as part of the Bio-Linux project.
# It was designed for Bio-Linux but should help you to install the latest Docker on any
# Ubuntu system.

# Are we really on Ubuntu?
if ! [ "`lsb_release -si`" = Ubuntu ] ; then
    echo "According to lsb_release this is not an Ubuntu system.  Installation will not proceed."
    exit 1
fi

if ! [ `id -u` = 0 ] ; then
    echo "Please re-run this script with sudo to install Docker"
    exit 1
fi

echo "Docker will be installed from https://get.docker.com"

# Utility functions
anykey() { read -p "Press any key to continue..." -n1 ; echo ; echo ; }

yesnocancel() {
    read -p "$1 (Yes/No/Cancel): " -n1 a
    if   [[ "$a" == y || "$a" = Y ]] ; then
        echo ; return 0
    elif [[ "$a" == n || "$a" = N ]] ; then
        echo ; return 1
    elif
        [[ "$a" == c || "$a" = C ]] ; then
        echo ' 'Aborting ; exit 1
    fi
    yesnocancel "$@"
}

ALLUSERS=0
if yesnocancel "Would you like all users to be given permission to use Docker?" ; then
    ALLUSERS=1
fi

# We need this before adding the docker repo
# Note docker does need apparmor even though it does not declare the dependency.
# I'm installing all the depends/recommends from the docker.io package here
echo "Installing pre-requisite packages"
apt-get update
apt-get install apt-transport-https software-properties-common \
		ca-certificates apparmor cgroup-lite git git-man \
		liberror-perl aufs-tools bind9-host
add-apt-repository universe

# Now we can add the repo
cat >/etc/apt/sources.list.d/docker.list <<.
deb https://get.docker.com/ubuntu docker main
.
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys A88D21E9

echo "Installing Docker itself"
apt-get update && apt-get install lxc-docker

if [ "$ALLUSERS" = 1 ] ; then
    echo "Allowing all new users to be able to run Docker by default..."
    if ! grep -q '^EXTRA_GROUPS=".* docker.*"' /etc/adduser.conf ; then
	echo " Fixing EXTRA_GROUPS"
	sed -i 's/^[# ]*\(EXTRA_GROUPS="[^"]*\)"/\1 docker"/' /etc/adduser.conf
    fi

    if ! grep -q '^ADD_EXTRA_GROUPS=1' /etc/adduser.conf ; then
	echo " Fixing ADD_EXTRA_GROUPS"
	sed -i 's/^[ #]*\(ADD_EXTRA_GROUPS\)=.*/\1=1/' /etc/adduser.conf
    fi

    # Add all regular users.  This is a very dirty way to get a list of login users
    # but it should be adequate for our purposes.
    for user in `stat -c "%U" /home/* | sort -u` ; do
	[ "$user" = root ] && continue
	echo "Adding user $user to the docker group"
        usermod -aG docker "$user"
    done

    echo "You will need to log out and back in again to use oswitch and Docker"

else
    echo "Before you can use Docker, you must run:"
    echo "  sudo usermod -aG docker your_user_name"
    echo "And you will need to log out then back in again for this to take effect,"
    echo "or else you will just get a cryptic error message about 'docker.sock' and a"
    echo "'TLS-enabled daemon'."
fi

echo
echo "All done.  Docker package updates will now be managed by the regular update manager."
# done
