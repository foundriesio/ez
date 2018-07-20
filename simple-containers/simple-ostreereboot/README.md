# Simple container to watch ostree files and reboot & if there is a mismatch

```
docker run -i -t -v /proc/sysrq-trigger:/sysrq -v /boot/loader/entries/ostree-lmp-0.conf:/ostree0.conf -v /boot/loader/entries/ostree-lmp-0.conf:/ostree1.conf -v /proc/cmdline:/cmdline foundriesio/simple-ostreereboot
```
