function f --description 'Change directory and list contents helper.'
    if test (count $argv) -eq 0
        eza --tree --level=2
    else
        j $argv; and pwd;
        and git log --oneline -1;
        and git status;
        and eza;
    end
end