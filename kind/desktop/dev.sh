package make cmake ninja gdb strace gcc rust python python-pip nodejs npm jdk-openjdk sqlite \
  texlive-basic texlive-latex texlive-latexrecommended texlive-fontsrecommended texlive-langgerman \
  texlive-binextra perl-file-homedir perl-yaml-tiny

write -au .config/dropin/env.sh << EOF
CMAKE_GENERATOR="Ninja"
CMAKE_EXPORT_COMPILE_COMMANDS="ON"
EOF

package nix
copy res/nix.conf /etc/nix/nix.conf
systemd -e nix-daemon.service
timer nix-gc monthly /usr/bin/nix-collect-garbage --delete-old

run mkdir /perm/nix
write -a /etc/fstab "/perm/nix /nix none bind 0 0"
write -au .config/env.sh "NIX_PATH=nixpkgs=flake:nixpkgs"

package paru base-devel devtools nvchecker
conf -e /etc/paru.conf BottomUp CleanAfter RemoveMake SudoLoop

package git git-delta
symlink -u res/git.conf .config/git/config

persist -u Repos
symlink -u res/bin/repo.sh .local/bin/repo
timer -nu repo-fetch hourly "%h/.local/bin/repo" fetch
