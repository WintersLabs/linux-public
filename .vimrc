"Allow vim to tell they filetype its editing and load the indent and plugin file for the detected type"
filetype plugin indent on
"Colors the code you are editing"
syntax on
"Disables compatibility with vi"
set nocompatible
"Highlights the row the cursor is on"
set cursorline
"Highlights the column the cursor is on"
set cursorcolumn
"Set the shift width to 4"
set shiftwidth=4
"Set the tab width to 4"
set tabstop=4
"Use space chars instead of tabs"
set expandtab
"Incrementally highlight as you search"
set incsearch
"Highlight the search results"
set hlsearch
"Show partial command you type in the last line of the screen"
set showcmd
"Show the mode on the last line"
set showmode
"Show matching words during a search"
set showmatch
"Show the line number you are on"
set number
"Show the relative line number you are on"
set relativenumber
"Allows you to take into account case when you search"
set smartcase
"Auto complete menu after pressing TAB"
set wildmenu
"Make it look like bash"
set wildmode=list:longest
"Ignore these file types when you are using wildmenu"
set wildignore=*.docx,*.jpg,*.png,*.gif,*.pdf,*.exe,*.flv,*.img,*.xlsx
set lazyredraw
set linebreak
set title
set background=dark
set foldmethod=syntax
set foldlevel=3
set foldlevelstart=99
set spellsuggest=best
set t_vb=
nmap <F1> <nop>
"Enable persistent undo"
set undofile
"Enable spell checking"
set spell
