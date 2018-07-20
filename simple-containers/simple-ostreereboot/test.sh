while [ 1 ]; do
  s1=`grep ostree= /cmdline | sed "s/^.*ostree=//g" `
  s2=`grep ostree= /ostree0.conf | sed "s/^.*ostree=//g"`
  if [[ "$s1" == "$s2" ]]; then
    echo match
  else
    echo mis-match
    echo b > /sysrq
  fi
  sleep 10;
done
