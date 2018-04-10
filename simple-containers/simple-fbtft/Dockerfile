FROM opensourcefoundries/minideb:stretch

RUN install_packages \
  xserver-xorg \
  xinit \
  xserver-xorg-video-fbdev \
  xserver-xorg-input-evdev \
  lxde \
  lxde-common \
  lightdm \
  git \
  ca-certificates

COPY calibration.conf /etc/X11/xorg.conf.d/
COPY fbtft.conf /etc/X11/xorg.conf.d/
COPY start.sh /usr/bin/start.sh

ENTRYPOINT ["/usr/bin/start.sh"]
CMD startx
