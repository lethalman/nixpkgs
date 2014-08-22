#! @shell@
console=tty1
pid=$(cut -d ' ' -f 4 /proc/self/stat)

# Process the kernel command line.
for o in $(cat /proc/cmdline); do
    case $o in
        console=*)
            set -- $(IFS==; echo $o)
            params=$2
            set -- $(IFS=,; echo $params)
            console=$1
            ;;
        boot.trace|debugtrace)
            # Show each command.
            set -x
            ;;
        boot.shell_on_fail)
            allowShell=1
            ;;
        boot.panic_on_fail|stage1panic=1)
            panicOnFail=1
            ;;
    esac
done

if [ "$pid" -eq 1 -a -n "$panicOnFail" ]; then exit 1; fi

# If starting stage 2 failed, allow the user to repair the problem
# in an interactive shell.
cat <<EOF

  An error occurred in stage 1 of the boot process, which must mount the root file system.

EOF

if [ "$pid" -ne 1 -a -n "$allowShell" ]; then
    # If it's not PID 1, then we got called by systemd emergency.service.
    echo "Starting interactive shell..."
    setsid @shell@ -c "@shell@ < /dev/$console >/dev/$console 2>/dev/$console" || fail
else

    if [ "$pid" -eq 1 -a -n "$allowShell" ]; then cat <<EOF
  i) to launch an interactive shell
  f) to start an interactive shell having pid 1 (needed if you want to
     start stage 2's init manually)
EOF
    else
cat <<EOF
  Press one of the following keys:

  r) to reboot immediately
  *) to ignore the error and continue
EOF
fi

    read reply

    if [ -n "$allowShell" -a "$reply" = f ]; then
        exec setsid @shell@ -c "@shell@ < /dev/$console >/dev/$console 2>/dev/$console"
    elif [ -n "$allowShell" -a "$reply" = i ]; then
        echo "Starting interactive shell..."
        setsid @shell@ -c "@shell@ < /dev/$console >/dev/$console 2>/dev/$console" || fail
    elif [ "$reply" = r ]; then
        echo "Rebooting..."
        reboot -f
    else
        echo "Continuing..."
    fi
fi