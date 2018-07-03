syntax on

set ruler
set nonumber
set tabstop=4
set list
set listchars=tab:▸\ ,eol:¬

set autowrite

"Plugins via vim-plug (https://github.com/junegunn/vim-plug)
call plug#begin('~/.vim/plugged')
	"General
	Plug 'w0rp/ale' 
	Plug 'vim-airline/vim-airline'
	Plug 'scrooloose/nerdtree'
	Plug 'maralla/completor.vim'

	"go-lang
	Plug 'fatih/vim-go'
	Plug 'nsf/gocode', { 'rtp': 'vim', 'do': '~/.vim/plugged/gocode/vim/symlink.sh' }

call plug#end()

"Enable powerline fonts
let g:airline_powerline_fonts = 1

" Error and warning signs.
let g:ale_sign_error = '⤫'
let g:ale_sign_warning = '⚠'

" Enable integration with airline.
let g:airline#extensions#ale#enabled = 1

" Use quickfix everywhere instead of location lists
let g:go_list_type = "quickfix"

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Global Keybindings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Quickfix 
map <C-n> :cnext<CR>
map <C-m> :cprevious<CR>
nnoremap <leader>a :cclose<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Filetype specific settings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Go
au FileType go set noexpandtab
au FileType go set shiftwidth=4
au FileType go set softtabstop=4
au FileType go set tabstop=4

autocmd FileType go nmap <leader>b  <Plug>(go-build)
autocmd FileType go nmap <leader>r  <Plug>(go-run)

let g:go_highlight_build_constraints = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_operators = 1
let g:go_highlight_structs = 1
let g:go_highlight_types = 1

let g:go_auto_sameids = 1 "highlight occurences of a variable

let g:go_fmt_command = "goimports" "auto import dependencies on saving a file

let g:go_auto_type_info = 1

let g:completor_gocode_binary = '/path/to/gocode' "for completor
