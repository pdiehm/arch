package make cmake ninja gcc gdb rust python python-pip nodejs npm jdk-openjdk sqlite \
  texlive-basic texlive-latex texlive-latexrecommended texlive-fontsrecommended texlive-langgerman \
  texlive-binextra perl-file-homedir perl-yaml-tiny

write -au .config/dropin/env.sh << EOF
CMAKE_GENERATOR="Ninja"
CMAKE_EXPORT_COMPILE_COMMANDS="ON"
EOF

package git git-delta
symlink -u res/git.conf .config/git/config

persist -u Repos
symlink -u res/bin/repo.sh .local/bin/repo
timer -nu repo-fetch hourly "%h/.local/bin/repo" fetch
