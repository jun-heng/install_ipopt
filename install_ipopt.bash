#!/bin/bash

set -e # exit on first error

comment_out_lines()
{
  FILE_PATH=$1
  START_LINE=$2
  END_LINE=$3

  if [ ! -f "$FILE_PATH" ]; then
      echo "File not found: $FILE_PATH"
      exit 1
  fi

  echo "Commenting out lines $START_LINE–$END_LINE in $FILE_PATH..."
  sed -i "${START_LINE},${END_LINE} s/^/# /" "$FILE_PATH"
  echo "Lines $START_LINE–$END_LINE have been commented out in $FILE_PATH."
}

install_ipopt()
{

    echo "Prepare to install IPOPT ..."
    IPOPT="Ipopt"
    VERSION="3.12.8"
    IPOPT_URL="https://www.coin-or.org/download/source/Ipopt/$IPOPT-$VERSION.tgz"
    CURRENT_DIR="$PWD"
    IPOPT_TGZ="$CURRENT_DIR/$IPOPT-$VERSION.tgz"

    sudo apt-get -qq install cppad gfortran
    echo "decide whether to install"

    if ( ldconfig -p | grep libipopt ); then
      echo "Ipopt is already installed."
      read -p "Do you want to remove the existing IPOPT installation? (y/n): " REMOVE_IPOPT
      if [[ "$REMOVE_IPOPT" =~ ^[Yy]$ ]]; then
        echo "Removing existing IPOPT installation..."
        sudo apt-get remove -y libipopt-dev
        sudo apt-get autoremove -y
        cd /usr/lib
        sudo rm libipopt*
        cd /usr/local/lib
        sudo rm libipopt*
        cd pkgconfig
        sudo rm ipopt*
        cd ../../include
        sudo rm -r coin/
        sudo lpconfig
        echo "Existing IPOPT installation removed."
      else
        echo "Skipping IPOPT installation."
        return 0
      fi
    fi

    if [ -f "$IPOPT_TGZ" ]; then
      echo "Tarball already exists: $IPOPT_TGZ"
    else
      echo "Downloading Ipopt, version: $VERSION ..."
      wget -q -O "$IPOPT_TGZ" "$IPOPT_URL" || { echo "Download failed"; exit 1; }
      echo "Downloaded Ipopt tarball to $IPOPT_TGZ"
    fi

    echo "Extracting Ipopt ..."
    tar -xf "$IPOPT_TGZ"
    rm -rf "$IPOPT_TGZ"

    echo "Moving Files.."
    cp "metis-4.0.3.tar.gz" "$IPOPT-$VERSION/ThirdParty/Metis"
    cp "MUMPS_4.10.0.tar.gz" "$IPOPT-$VERSION/ThirdParty/Mumps"
    GET_METIS_FILE="$IPOPT-$VERSION/ThirdParty/Metis/get.Metis"  # Adjust path as needed
    GET_MUMPS_FILE="$IPOPT-$VERSION/ThirdParty/Mumps/get.Mumps"
    comment_out_lines "$GET_METIS_FILE" 24 26
    comment_out_lines "$GET_MUMPS_FILE" 28 31

    echo "Installing third party dependencies ..."
    cd Ipopt-3.12.8/ThirdParty/Blas
    ./get.Blas    
    cd ../Lapack  
    ./get.Lapack  
    cd ../Mumps
    ./get.Mumps  
    cd ../Metis  
    ./get.Metis 

    # configure,build and install the IPOPT
    echo "Configuring and building IPOPT ..."
    cd ..
    cd ..
    mkdir build  && cd build 
    ../configure  
    make -j4  
    make install  
    sudo cp -a include/* /usr/include/.  
    sudo cp -a lib/* /usr/lib/.  
    cd ../..
    rm -rf "$IPOPT-$VERSION"
    echo "IPOPT installed successfully"
}

install_ipopt
