# shellcheck shell=bash

export BOARD_NAME="Radxa Zero 3"
export BOARD_MAKER="Radxa"
export BOARD_SOC="Rockchip RK3566"
export BOARD_CPU="ARM Cortex A55"
export UBOOT_PACKAGE="u-boot-turing-rk3588"
export UBOOT_RULES_TARGET="radxa-zero3-rk3566"
export COMPATIBLE_SUITES=("jammy" "noble")
export COMPATIBLE_FLAVORS=("server" "desktop")

function config_image_hook__radxa-zero3() {
    local rootfs="$1"
    local overlay="$2"
    local suite="$3"

    if [ "${suite}" == "jammy" ] || [ "${suite}" == "noble" ]; then
        # Kernel modules to blacklist
        (
            echo "blacklist aic8800_bsp"
            echo "blacklist aic8800_fdrv"
            echo "blacklist aic8800_btlpm"
        ) > "${rootfs}/etc/modprobe.d/aic8800.conf"

        chroot "${rootfs}" apt-get install -y software-properties-common mtd-utils linux-base
        chroot "${rootfs}" add-apt-repository ppa:jjriek/rockchip
        # uname -r
        # chroot "${rootfs}" uname -r
        chroot "${rootfs}" apt-mark hold linux-headers-6.8.0-31 linux-headers-6.8.0-31-generic linux-headers-generic
        # chroot "${rootfs}" apt-mark showhold
        # chroot "${rootfs}" apt-get -o Debug::pkgProblemResolver=true -o Debug::pkgDPkgPM=true -y install dkms mtd-utils
        #echo "kernel_source_dir=/usr/src/linux-headers-6.1.0-1025-rockchip" > "${rootfs}/etc/dkms/framework.conf"
        #cat ${rootfs}/etc/dkms/framework.conf
        
        # Install AIC8800 SDIO WiFi and Bluetooth DKMS
        chroot "${rootfs}" apt-get -y install dkms aic8800-firmware aic8800-sdio-dkms
        # chroot "${rootfs}" /bin/bash -c 'kernel_source_dir=/usr/src/linux-headers-6.1.0-1025-rockchip; echo ${kernel_source_dir}; apt-get -y install aic8800-firmware aic8800-sdio-dkms'

        # shellcheck disable=SC2016
        echo 'SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="88:00:*", NAME="$ENV{ID_NET_SLOT}"' > "${rootfs}/etc/udev/rules.d/99-radxa-aic8800.rules"

        # Enable the on-board bluetooth module AIC8800
        mkdir -p "${rootfs}/usr/lib/scripts/"
        cp "${overlay}/usr/bin/bt_test" "${rootfs}/usr/bin/bt_test"
        cp "${overlay}/usr/lib/scripts/aic8800-bluetooth.sh" "${rootfs}/usr/lib/scripts/aic8800-bluetooth.sh"
        cp "${overlay}/usr/lib/systemd/system/aic8800-bluetooth.service" "${rootfs}/usr/lib/systemd/system/aic8800-bluetooth.service"
        chroot "${rootfs}" systemctl enable aic8800-bluetooth
    fi

    return 0
}
