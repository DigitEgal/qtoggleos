#!/bin/sh

set -e

export TARGET="$1"
export BOARD=$(basename $(dirname ${TARGET}))
export COMMON_DIR=$(dirname $0)
export BOARD_DIR=${COMMON_DIR}/../${BOARD}
export BOOT_DIR=${TARGET}/../images/boot/
export IMG_DIR=${TARGET}/../images

mkdir -p ${BOOT_DIR}

if [ -x ${BOARD_DIR}/postscript.sh ]; then
    ${BOARD_DIR}/postscript.sh
fi

# cleanups
${COMMON_DIR}/cleanups.sh
if [ -x ${BOARD_DIR}/cleanups.sh ]; then
    ${BOARD_DIR}/cleanups.sh
fi

# transform /var contents as needed
rm -rf ${TARGET}/var/cache
rm -rf ${TARGET}/var/lib
rm -rf ${TARGET}/var/lock
rm -rf ${TARGET}/var/log
rm -rf ${TARGET}/var/run
rm -rf ${TARGET}/var/spool
rm -rf ${TARGET}/var/tmp

ln -s /tmp ${TARGET}/var/cache
ln -s /tmp ${TARGET}/var/lock
ln -s /tmp ${TARGET}/var/run
ln -s /tmp ${TARGET}/var/spool
ln -s /tmp ${TARGET}/var/tmp
ln -s /tmp ${TARGET}/run
mkdir -p ${TARGET}/var/lib
mkdir -p ${TARGET}/var/log

# board-specific os.conf
if [ -r ${BOARD_DIR}/os.conf ]; then
    for line in $(cat ${BOARD_DIR}/os.conf); do
        key=$(echo ${line} | cut -d '=' -f 1)
        sed -i -r "s/${key}=.*/${line}/" /${TARGET}/etc/os.conf
    done
fi

# add admin user alias
if ! grep -E '^admin:' ${TARGET}/etc/passwd &> /dev/null; then
    echo "admin:x:0:0:root:/root:/bin/sh" >> ${TARGET}/etc/passwd
fi

# make sure "qtoggleserver" namespace is never touched by packages
sed -ri 's/^qtoggleserver$//g' ${TARGET}/usr/lib/python*/site-packages/*.egg-info/top_level.txt

# copy uncompiled Python source required by pip
cp ${BUILD_DIR}/python-pip-20.0.2/src/pip/_vendor/pep517/_in_process.py \
   ${TARGET}/usr/lib/python*/site-packages/pip/_vendor/pep517
