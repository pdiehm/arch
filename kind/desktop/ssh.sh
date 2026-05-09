symlink -u res/ssh/ssh_config .ssh/config
copy -nsu ssh/arch .ssh/arch
copy -nsu ssh/bowser .ssh/bowser
copy -nsu ssh/goomba .ssh/goomba
copy -nsu ssh/github .ssh/github

package sshfs
write -a /etc/fstab "pascal@bowser:shared /home/pascal/Shared sshfs Port=1970,IdentityFile=/home/pascal/.ssh/bowser,ConnectTimeout=5,ServerAliveInterval=5,allow_other,reconnect,delay_connect 0 0"
