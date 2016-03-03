#!/bin/sh

IS_DOWNLOAD=true
IS_COMPILE=true
IS_ADDITION=true

PYUSER=pyuser
PYUSER_DIR=/home/$PYUSER

yum groupinstall -y "Development tools"
# without readline-devel lib, <BS> will be recognized as a normal character in console mode.
yum install -y zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel libffi-devel

PREINSTALL_LIBRARY=(setuptools virtualenv)
# visit https://www.python.org/downloads/source/ and get the url.
TGZ_URLS=(
   https://www.python.org/ftp/python/2.7.11/Python-2.7.11.tgz
   https://www.python.org/ftp/python/3.5.1/Python-3.5.1.tgz
)
OPT_DIR=/usr/local
BASHRC_FILE=$HOME/.bashrc
BASHRC_ADD_FILE=$HOME/bin/_python_commands
mkdir -p $HOME/bin
sed -i '/'`basename $BASHRC_ADD_FILE`'/d' $BASHRC_FILE
echo '. '$BASHRC_ADD_FILE >>$BASHRC_FILE
cat >$BASHRC_ADD_FILE <<STRING_LINES
function turn_python()
{
    RES=\`echo \$PATH | awk '{printf "export PATH=%s", ADDPATH!=""?ADDPATH":":""; for(i=1;i<NF;++i) if (\$i!~"Python-" && \$i!="") printf "%s:", \$i; printf \$NF"\n"; exit}' FS=':' ADDPATH=\$1\`
    \$RES
}

function turn_py26()
{
    turn_python
    unset PYTHONHOME
    unset LD_LIBRARY_PATH
    unset PYTHONPATH
}
STRING_LINES
. $BASHRC_FILE

for TGZ_URL in ${TGZ_URLS[*]}
do
    cd $OPT_DIR
    TGZ_FILE=`basename $TGZ_URL`

    $IS_DOWNLOAD && {
        wget --no-check-certificate $TGZ_URL -O $TGZ_FILE
    }
    PYTHONHOME=$OPT_DIR/`tar ztf $TGZ_FILE | head -1`

    $IS_COMPILE && {
        if tar zxvf $TGZ_FILE
        then
            cd $PYTHONHOME
            ./configure --prefix=$PYTHONHOME --enable-shared
            ## --enable-shared is needed for pyinstaller
            make
            make altinstall
            ln -s $PYTHONHOME/python $PYTHONHOME/bin/python
        else
            echo "$TGZ_FILE is missing or illegal."
            continue
        fi
    }
    turn_python ${PYTHONHOME}bin
    export LD_LIBRARY_PATH=${PYTHONHOME}lib
    VERNUM=`$PYTHONHOME/bin/python --version 2>&1 | awk '{print $2 $3; exit}' FS='[ .]'`
    VERDOTNUM=`$PYTHONHOME/bin/python --version 2>&1 | awk '{print $2"." $3; exit}' FS='[ .]'`
    export PYTHONPATH=${PYTHONHOME}lib/python${VERDOTNUM}:${PYTHONHOME}lib/python${VERDOTNUM}/site-packages:${PYTHONHOME}Lib/python${VERDOTNUM}:${PYTHONHOME}Lib/python${VERDOTNUM}/site-packages

    $IS_ADDITION && {
        curl -k https://bootstrap.pypa.io/get-pip.py | $PYTHONHOME/bin/python                              ### install pip
        [ -x $PYTHONHOME/bin/pip ] && $PYTHONHOME/bin/pip install --upgrade pip ${PREINSTALL_LIBRARY[*]}        ### install and upgrade the needed lib
        [ -x $PYTHONHOME/bin/pip3.5 ] && $PYTHONHOME/bin/pip3.5 install --upgrade pip ${PREINSTALL_LIBRARY[*]}  ###
    }

    cat >>$BASHRC_ADD_FILE <<STRING_LINES
function turn_py$VERNUM()
{
    turn_python ${PYTHONHOME}bin
    export PYTHONHOME=${PYTHONHOME}
    export LD_LIBRARY_PATH=${PYTHONHOME}lib
    export PYTHONPATH=${PYTHONHOME}lib/python${VERDOTNUM}:${PYTHONHOME}lib/python${VERDOTNUM}/site-packages:${PYTHONHOME}Lib/python${VERDOTNUM}:${PYTHONHOME}Lib/python${VERDOTNUM}/site-packages
}
STRING_LINES

###PYTHONHOME
### Change the  location  of  the  standard  Python  libraries.   By  default,  the  libraries  are  searched  in  ${prefix}/lib/python<version>  and  ${exec_pre-
### fix}/lib/python<version>,  where  ${prefix} and ${exec_prefix} are installation-dependent directories, both defaulting to /usr/local.  When $PYTHONHOME is set
### to a single directory, its value replaces both ${prefix} and ${exec_prefix}.  To specify different values for these, set $PYTHONHOME to  ${prefix}:${exec_pre-
### fix}.
###
###PYTHONPATH
### Augments  the  default  search path for module files.  The format is the same as the shell's $PATH: one or more directory pathnames separated by colons.  Non-
### existent directories are silently ignored.  The default search path is installation dependent, but generally begins  with  ${prefix}/lib/python<version>  (see
### PYTHONHOME above).  The default search path is always appended to $PYTHONPATH.  If a script argument is given, the directory containing the script is inserted
### in the path in front of $PYTHONPATH.  The search path can be manipulated from within a Python program as the variable sys.path .

done
cd $OPT_DIR
. $BASHRC_FILE

useradd $PYUSER -g 0 -d $PYUSER_DIR
mkdir -p $PYUSER_DIR/bin
###cp -f $BASHRC_ADD_FILE

