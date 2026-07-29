run usermod --append --groups wheel pascal
write -a /etc/sudoers "pascal ALL=(ALL:ALL) ALL"

run -u git clone https://github.com/pdiehm/arch.git .config/syscfg
run -u git --git-dir .config/syscfg/.git remote set-url origin git@github.com:pdiehm/arch.git
symlink -u bin/manager.sh .local/bin/sm
persist -u .config/syscfg
