#! @shell@

device="$1"
systemdPath="$2"

fsType=$(blkid -o value -s TYPE "$device")
if [ -n "$fsType" ]; then
    echo "detected $fsType on $device..." > /dev/kmsg
    mkdir -p /run/systemd/system/$systemdPath.mount.d/
    echo -e "[Mount]\nType=$fsType" > /run/systemd/system/$systemdPath.mount.d/fsprobe.conf
else
    echo "could not detect the filesystem type of $device..." > /dev/kmsg
fi

