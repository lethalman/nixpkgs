#! @shell@

export LD_LIBRARY_PATH=@extraUtils@/lib
export PATH=@extraUtils@/bin
ln -s @extraUtils@/bin /bin
ln -s @extraUtils@/bin /sbin

mkdir -p /sysroot
mkdir -p /dev/.mdadm

mkdir -p /lib
ln -s @modulesClosure@/lib/modules /lib/modules

trap 'source @extraUtils@/bin/emergency.sh' 0


# Print a greeting.
echo
echo "[1;32m<<< NixOS Stage 1 >>>[0m"
echo


# Special file systems.
mkdir -p /proc
mount -t proc proc /proc
mkdir -p /sys
mount -t sysfs sysfs /sys
mount -t devtmpfs -o "size=@devSize@" devtmpfs /dev
mkdir -p /run
mount -t tmpfs -o "mode=0755,size=@runSize@" tmpfs /run
mkdir -p /etc
touch /etc/initrd-release # let systemd know it's running in initrd
touch /etc/machine-id # let systemd know /etc is not empty
touch /etc/fstab # to shut up mount
rm -f /etc/mtab
ln -sf /proc/self/mounts /etc/mtab # to shut up mount

echo @extraUtils@/bin/modprobe > /proc/sys/kernel/modprobe

# Process the kernel command line.
for o in $(cat /proc/cmdline); do
    case $o in
        root=*)
            # If a root device is specified on the kernel command
            # line, make it available through the symlink /dev/root.
            # Recognise LABEL= and UUID= to support UNetbootin.
            set -- $(IFS==; echo $o)
            if [ $2 = "LABEL" ]; then
                root="/dev/disk/by-label/$3"
            elif [ $2 = "UUID" ]; then
                root="/dev/disk/by-uuid/$3"
            else
                root=$2
            fi
            ln -s "$root" /dev/root
            ;;
    esac
done

# Load boot-time keymap before any LVM/LUKS initialization
@extraUtils@/bin/busybox loadkmap < "@busyboxKeymap@"

exec systemd
