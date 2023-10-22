#!/bin/bash
echo "set t_Co=256" >> ~/.vimrc
if [ ! -f ~/.vim/autoload/plug.vim ]; then
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi
grep -q "Plug 'dracula/vim', { 'as': 'dracula' }" ~/.vimrc || {
    echo "call plug#begin('~/.vim/plugged')" >> ~/.vimrc
    echo "Plug 'dracula/vim', { 'as': 'dracula' }" >> ~/.vimrc
    echo "call plug#end()" >> ~/.vimrc
}
vim +PlugInstall +qall
echo "colorscheme dracula" >> ~/.vimrc
echo "256 colors and Dracula theme have been enabled in Vim."
