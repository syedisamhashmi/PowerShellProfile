" Set tab size.
set tabstop=2
set shiftwidth=2
set smartindent
set autoindent

" To copy to system clipboard
set clipboard=unnamed,unnamedplus

" Display a line under the current line.
set cursorline

" Set lines to use hybrid style
set number relativenumber
set nu rnu

" Spaces instead of tabs
set expandtab

" No line wrap
set nowrap

" Extend history of commands
set history=100

" Syntax highlighting
syntax on

"[filetype]
filetype on
filetype plugin on
filetype indent on

" Color
set background=dark

" Mouse - Use scrollback with mouse scroll
set mouse=a

silent! packadd nerd_tree
if exists(':NERDTree')
  map <F1> :NERDTreeToggle<CR>
endif

hi DiffAdd      ctermfg=NONE          ctermbg=Green
hi DiffChange   ctermfg=NONE          ctermbg=NONE
hi DiffDelete   ctermfg=LightBlue     ctermbg=Red
hi DiffText     ctermfg=Yellow        ctermbg=Red
