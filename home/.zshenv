# Fix a bug in my ~/.zshrc that drove me nuts for ages
skip_global_compinit=1

# Resolve any symlinks in ~/.zsh/functions and prepend the result to fpath
fpath=(~/.zsh/functions(:A) $fpath)
