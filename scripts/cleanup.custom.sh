#!/usr/bin/bash -x

# Clean the pacman cache.
echo ">>>> cleanup.sh: Cleaning pacman cache.."
/usr/bin/pacman -Scc --noconfirm


echo ">>>> cleanup.sh: Removing git.."
sudo /usr/bin/pacman -R --noconfirm git

echo ">>>> cleanup.sh: Removing plymouth source directory.."
sudo rm -rf /home/vagrant/plymouth

# Write zeros to improve virtual disk compaction.
if [[ $WRITE_ZEROS == "true" ]]; then
  echo ">>>> cleanup.sh: Writing zeros to improve virtual disk compaction.."
  zerofile=$(/usr/bin/mktemp /zerofile.XXXXX)
  /usr/bin/dd if=/dev/zero of="$zerofile" bs=1M
  /usr/bin/rm -f "$zerofile"
  /usr/bin/sync
fi
