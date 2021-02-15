# directions

Vim Fzf with directories, only works in latest nvim 0.5+
I realized I only keep nerdtree or netrw around to access files where I know the directory, but not the name of the file. This has been quite difficult to do in the fzf world that I prefer. So having seen the [FZF Interactive CD](https://github.com/junegunn/fzf/wiki/examples#integration-with-zsh-interactive-cd) I saw how I wanted to navigate in neovim. Since none of the countless file navigation options for vim offer this, I took it as an opportunity to spend some time with lua.

### Installation

```
Plug 'tobyond/directions'
```

```
# in lua
require'directions'.directions()

# in init.vim
lua require'directions'.directions()
# or even
command! Directions lua require'directions'.directions()
```
