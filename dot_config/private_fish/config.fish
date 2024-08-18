if status is-interactive
    # Commands to run in interactive sessions can go here
    #
    set -Ux CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense' # optional
    mkdir -p ~/.config/fish/completions
    carapace --list | awk '{print $1}' | xargs -I{} touch ~/.config/fish/completions/{}.fish # disable auto-loaded completions (#185)
    carapace _carapace | source
    # Navi widget
    navi widget fish | source
    # Starship prompt
    starship init fish | source
end

# source /etc/profile with bash
if status is-login
    exec bash -c "test -e /etc/profile && source /etc/profile;\
    exec fish"
end
