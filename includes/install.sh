#!/bin/bash

# INSTALL BeEF
wget https://github.com/beefproject/beef/archive/master.zip
unzip master.zip
cd beef-master
echo
echo "installing beef & Deps..."

set -euo pipefail
IFS=$'\n\t'

RUBYSUFFIX=''

command_exists () {

  command -v "${1}" >/dev/null 2>&1
}


check_os () {

  echo "Detecting OS..."

  OS=$(uname)
  readonly OS
  echo "Operating System: $OS"
  if [ "${OS}" = "Linux" ] ; then
    echo "Launching Linux install..."
    install_linux
  elif [ "${OS}" = "Darwin" ]; then
    echo "Launching Mac OSX install..."
    install_mac
  elif [ "${OS}" = "FreeBSD" ]; then
    echo "Launching FreeBSD install..."
    for SUFX in 26 25 24 23
    do
      if command_exists ruby${SUFX}
      then
        RUBYSUFFIX=${SUFX}
        break
      fi
    done
    install_freebsd
  elif [ "${OS}" = "OpenBSD" ]; then
    echo "Launching OpenBSD install..."
    for SUFX in 26 25 24 23
    do
      if command_exists ruby${SUFX}
      then
        RUBYSUFFIX=${SUFX}
        break
      fi
    done
    install_openbsd
  else
    echo "Unable to locate installer for your Operating system: $OS"
  fi
}



install_linux () {

  echo "Detecting Linux OS distribution..."

  Distro=''
  if [ -f /etc/redhat-release ] ; then
    Distro='RedHat'
  elif [ -f /etc/debian_version ] ; then
    Distro='Debian'
  elif [ -f /etc/alpine-release ] ; then
    Distro='Alpine'
  elif [ -f /etc/os-release ] ; then
    #DISTRO_ID=$(grep ^ID= /etc/os-release | cut -d= -f2-)
    DISTRO_ID=$(cat /etc/os-release | grep  ID= | grep -v "BUILD" | cut -d= -f2-)
    if [ "${DISTRO_ID}" = 'kali' ] ; then
      Distro='Kali'
    elif [ "${DISTRO_ID}" = 'arch' ] || [ "${DISTRO_ID}" = 'manjaro' ] ; then
      Distro='Arch'
    fi
  fi

  if [ -z "${Distro}" ] ; then
    echo "Unable to locate installer for your ${OS} distribution"
  fi

  readonly Distro
  echo "OS Distribution: ${Distro}"
  echo "Installing ${Distro} prerequisite packages..."
  if [ "${Distro}" = "Debian" ] || [ "${Distro}" = "Kali" ]; then
    sudo apt-get update
    sudo apt-get install curl git build-essential openssl libreadline6-dev zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev autoconf libc6-dev libncurses5-dev automake libtool bison nodejs ruby-dev libcurl4-openssl-dev -y
  elif [ "${Distro}" = "RedHat" ]; then
    sudo yum install -y git make gcc openssl-devel gcc-c++ patch readline readline-devel zlib zlib-devel libyaml-devel libffi-devel bzip2 autoconf automake libtool bison sqlite-devel nodejs
  elif [ "${Distro}" = "Arch" ]; then
    sudo pacman -Syu # Updates repo, dependencies, etc.
    sudo pacman -S curl git make openssl gcc readline zlib libyaml sqlite bzip2 autoconf automake libtool bison nodejs ruby ruby-rdoc # Installs dependencies
  elif [ "${Distro}" = "Alpine" ]; then
    apk update # Updates repo, dependencies, etc.
    apk add curl git build-base openssl readline-dev zlib zlib-dev libressl-dev yaml-dev sqlite-dev sqlite libxml2-dev libxslt-dev autoconf libc6-compat ncurses5 automake libtool bison nodejs  # Installs dependencies
  fi
}

install_openbsd () {

  sudo pkg_add curl git libyaml libxml libxslt bison node ruby${RUBYSUFFIX}-bundler lame espeak
}

install_freebsd () {

  sudo pkg install curl git libyaml libxslt devel/ruby-gems bison node espeak
}

install_mac () {

  local mac_deps=(curl git nodejs python3 \
  openssl readline libyaml sqlite3 libxml2 \
  autoconf ncurses automake libtool \
  bison wget)

  if ! command_exists brew; then
    echo "Homebrew (https://brew.sh/) required to install dependencies"
  fi
  
  echo "Installing dependencies via brew"

  brew update 

  for package in "${mac_deps[@]}"; do

    if brew install "${package}"; then
      echo "${package} installed"
    else
      echo "Failed to install ${package}"
    fi
    
  done
}


check_ruby_version () {

  echo 'Detecting Ruby environment...'

  MIN_RUBY_VER='2.5'
  if command_exists ruby${RUBYSUFFIX}
  then
    RUBY_VERSION=$(ruby${RUBYSUFFIX} -e "puts RUBY_VERSION")
    echo "Ruby version ${RUBY_VERSION} is installed"
    if [ "$(ruby${RUBYSUFFIX} -e "puts RUBY_VERSION.to_f >= ${MIN_RUBY_VER}")" = 'false' ]
    then
      echo "Ruby version ${RUBY_VERSION} is not supported. Please install Ruby ${MIN_RUBY_VER} (or newer) and restart the installer."
    fi
  else
    echo "Ruby is not installed. Please install Ruby ${MIN_RUBY_VER} (or newer) and restart the installer."
  fi
}

check_rubygems () {
  if command_exists gem${RUBYSUFFIX}
  then
    echo 'Updating rubygems...'
    gem${RUBYSUFFIX} update --system
  fi
}

check_bundler () {

  echo 'Detecting bundler gem...'
  
  if command_exists bundler${RUBYSUFFIX}
  then
    echo "bundler${RUBYSUFFIX} gem is installed"
  else
    echo 'Installing bundler gem...'
    gem${RUBYSUFFIX} install bundler
  fi
}


install_beef () { 

  echo "Installing required Ruby gems..."

  if [ -w Gemfile.lock ]
  then
    /bin/rm Gemfile.lock
  fi

  if command_exists bundler${RUBYSUFFIX}
  then
    bundle${RUBYSUFFIX} install --without test development
  else
    bundle install --without test development
  fi
}

finish () {
  echo
  echo "#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#"
  echo
  echo "Install completed successfully!"
  echo "Run './beef' to launch BeEF"
  echo
  echo "Next steps:"
  echo
  echo "* Change the default password in config.yaml"
  echo "* Run ./update-geoipdb to install the Maxmind GeoIP database"
  echo "* Review the wiki for important configuration information:"
  echo "  https://github.com/beefproject/beef/wiki/Configuration"
  echo
  echo "#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#"
  echo
}


main () {

  echo "#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#"
  echo "                   -- [ BeEF Installer ] --                      "
  echo "#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#"
  echo
  
  check_os
  check_ruby_version
  check_rubygems
  check_bundler
  install_beef
  finish
}

main "$@"
echo "..DONE.."
exit
