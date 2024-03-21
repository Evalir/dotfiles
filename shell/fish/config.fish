if status is-interactive
    # source fish functions
    source ~/.config/fish/functions/evalir.fish

    # Add cargo/rust related utils to PATH
    fish_add_path ~/.cargo/bin

    # Zig related utils
    fish_add_path ~/.zvm/bin
    set -gx ZIG_INSTALL ~/.zvm/self
    fish_add_path ~/.zvm/self

    # init starship
    starship init fish | source
end


