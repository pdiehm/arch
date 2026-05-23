package make gdb strace cmake ninja gcc rust python python-pip nodejs npm jdk-openjdk php sqlite \
  texlive-basic texlive-latex texlive-latexrecommended texlive-fontsrecommended texlive-langgerman \
  texlive-binextra perl-file-homedir perl-yaml-tiny

dropin env.sh << EOF
CMAKE_GENERATOR="Ninja"
CMAKE_EXPORT_COMPILE_COMMANDS="ON"
EOF

package git git-delta
symlink -u res/git.conf .config/git/config

persist -u Repos
symlink -u res/bin/repo.sh .local/bin/repo
timer -nu repo-fetch hourly "%h/.local/bin/repo" fetch

package paru base-devel devtools nvchecker
conf -e /etc/paru.conf BottomUp CleanAfter RemoveMake SudoLoop

package nix
copy res/nix.conf /etc/nix/nix.conf
systemd -e nix-daemon.service
timer nix-gc monthly /usr/bin/nix-collect-garbage --delete-old

run mv /nix /perm/nix
write -a /etc/fstab "/perm/nix /nix none bind 0 0"
dropin env.sh "NIX_PATH=nixpkgs=flake:nixpkgs"
