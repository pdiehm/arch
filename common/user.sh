run usermod --password "$(secret password)" pascal
run usermod --append --groups wheel pascal

run -u git clone https://github.com/pdiehm/arch.git .config/syscfg
run -u git --git-dir .config/syscfg/.git remote set-url origin git@github.com:pdiehm/arch.git
symlink -u bin/manager.sh .local/bin/sm
persist -u .config/syscfg

if [[ $HOST_KIND == desktop ]]; then
  write -a /etc/sudoers "pascal ALL=(ALL:ALL) ALL"
elif [[ $HOST_KIND == server ]]; then
  write -a /etc/sudoers "pascal ALL=(ALL:ALL) NOPASSWD: ALL"
else
  error "Illegal host kind: $HOST_KIND"
fi
