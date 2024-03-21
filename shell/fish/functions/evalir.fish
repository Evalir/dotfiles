function ls
    command eza $argv
end

function ll
    command eza -l -b $argv
end

# Cleans up a rust project using clippy nightly and all unstable options.
function ferris
    command cargo +nightly clippy --fix --all-features --workspace -Z unstable-options --allow-dirty --allow-staged && cargo +nightly fmt $argv
end

function gorris
    command cargo clippy --fix --all-features --allow-dirty --allow-staged && cargo fmt $argv
end

function rclip
    command cargo +nightly clippy --fix --all-features --workspace -Z unstable-options --allow-dirty --allow-staged $argv
end

function rfmt
    command cargo +nightly fmt $argv
end

# one-word commit & push
function ship
    command git commit $argv && git push
end

# quick git log with no page
function glog
  command git --no-pager log --oneline -50 $argv
end

# Fancier git log
function glog1
    command git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
end

# Neovim
function nv
    command nvim $argv
end

function gp
    command git push $argv
end
