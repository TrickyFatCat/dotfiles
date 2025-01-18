function code --wraps='flatpak run com.visualstudio.code' --description 'alias code=flatpak run com.visualstudio.code'
    flatpak run com.visualstudio.code $argv
end

function zed --wraps='flatpak run dev.zed.Zed' --description 'alias zed=flatpak run dev.zed.Zed'
    flatpak run dev.zed.Zed $argv
end

function q --wraps=exit --description 'alias q=exit'
    exit $argv
end

function vim --wraps=nvim --description 'alias vim=nvim'
    nvim $argv
end

function open --wraps=nvim --description 'alias open=nvim'
    nvim $argv
end

function icat --description 'alias icat=kitten icat'
    kitten icat $argv
end
