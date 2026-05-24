package make gdb strace cmake ninja gcc rust python python-pip nodejs npm jdk-openjdk php sqlite \
  texlive-basic texlive-latex texlive-latexrecommended texlive-fontsrecommended texlive-langgerman \
  texlive-binextra perl-file-homedir perl-yaml-tiny

dropin env.sh << EOF
CMAKE_GENERATOR="Ninja"
CMAKE_EXPORT_COMPILE_COMMANDS="ON"
EOF

package git git-delta
symlink -u res/git.conf .config/git/config

package paru base-devel devtools nvchecker
conf -e /etc/paru.conf BottomUp CleanAfter RemoveMake SudoLoop

package nix
run mv /nix /perm/nix
write -a /etc/fstab "/perm/nix /nix none bind 0 0"
copy res/nix.conf /etc/nix/nix.conf
dropin env.sh "NIX_PATH=nixpkgs=flake:nixpkgs"
systemd -e nix-daemon.service
timer nix-gc monthly /usr/bin/nix-collect-garbage --delete-old
