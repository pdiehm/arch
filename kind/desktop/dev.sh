package make gdb strace cmake ninja gcc rust python python-pip nodejs npm jdk-openjdk php sqlite \
  texlive-basic texlive-latex texlive-latexrecommended texlive-latexextra texlive-fontsrecommended texlive-langgerman \
  texlive-binextra perl-file-homedir perl-yaml-tiny

package paru base-devel devtools nvchecker
conf -e /etc/paru.conf BottomUp CleanAfter RemoveMake SudoLoop

package nix
persist /nix
copy res/nix.conf /etc/nix/nix.conf
write -au .config/dropin/env.sh "NIX_PATH=nixpkgs=flake:nixpkgs"
systemd -e nix-daemon.service
timer nix-gc monthly /usr/bin/nix-collect-garbage --delete-old

write -au .config/dropin/env.sh << EOF
CMAKE_GENERATOR="Ninja"
CMAKE_EXPORT_COMPILE_COMMANDS="ON"
EOF
