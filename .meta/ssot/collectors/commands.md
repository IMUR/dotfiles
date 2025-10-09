systemctl list-unit-files --type=service | grep enabled
apt-mark showmanual
ls -a ~ | grep '^\.\w'
fd . /etc --type file --changed-within 365d
systemctl list-unit-files --type=timer | grep enabled
ss -tuln
ls -d ~/.*
fd . ~/.config --type file
cat ~/.gitconfig
ip a
cat ~/.ssh/authorized_keys
fc-list
crontab -l
lsmod
