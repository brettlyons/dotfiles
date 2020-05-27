if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim 
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin(stdpath('data') . '/plugged')

" Filetypes
" Plug 'jceb/vim-orgmode'
" Plug 'chrisbra/NrrwRgn'
" Plug 'vim-scripts/utl.vim'
Plug 'vimwiki/vimwiki'
Plug 'tpope/vim-markdown'
Plug 'editorconfig/editorconfig-vim'

" Pretty
Plug 'rakr/vim-one'
Plug 'rafi/awesome-vim-colorschemes'
Plug 'ryanoasis/vim-devicons'
Plug 'itchyny/lightline.vim'
Plug 'airblade/vim-gitgutter'

" Utility
Plug 'justinmk/vim-sneak'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'andymass/vim-matchup'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() }}
Plug 'junegunn/fzf.vim'
" Plug 'lotabout/skim', { 'dir': '~/.skim', 'do': './install' }
" Plug 'lotabout/skim.vim'
Plug 'preservim/nerdtree'
Plug 'mbbill/undotree'
Plug 'chrisbra/unicode.vim'
Plug 'yggdroot/indentLine'
Plug 'godlygeek/tabular'
Plug 'airblade/vim-rooter'

" Linter
Plug 'dense-analysis/ale'
Plug 'maximbaz/lightline-ale'

" Writing
Plug 'junegunn/limelight.vim'
Plug 'junegunn/goyo.vim'
Plug 'reedes/vim-pencil'

" Command of Completion / LSP
Plug 'neoclide/coc.nvim', {'branch':'release'}
Plug 'honza/vim-snippets'
" CoCInstall coc-snippets coc-pairs coc-clangd coc-jedi coc-rls 
" To see which extensions are installed, use :CocList extensions

call plug#end()

" Permanent Undo
set undodir=~/.vimdid
set undofile

" Ripgrep replacing
if executable('rg')
	set grepprg=rg\ --no-heading\ --vimgrep
	set grepformat=%f:%l:%c:%m
endif

" From FZF.vim github page
function! RipgrepFzf(query, fullscreen)
	let command_fmt = 'rg --column --line-number --no-heading --color=always --smart-case %s || true'
	let initial_command = printf(command_fmt, shellescape(a:query))
	let reload_command = printf(command_fmt, '{q}')
	let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
	call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
endfunction

command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0)

" From skim.vim github page
" command! -bang -nargs=* Rg
" 			\ call fzf#vim#grep(
" 			\   'rg --column --line-number --no-heading --color=always --smart-case '.shellescape(<q-args>), 1,
" 			\   <bang>0 ? fzf#vim#with_preview('up:60%')
" 			\           : fzf#vim#with_preview('right:50%:hidden', '?'),
" 			\   <bang>0)


let g:PaperColor_Theme_Options = {
			\   'theme': {
			\     'default': {
			\       'transparent_background': 1,
			\       'allow_bold': 1,
			\       'allow_italic': 1
			\     }
			\   }
			\ }

let g:one_allow_italics = 1
let g:gruvbox_italic = 1
set termguicolors

" let g:one_allow_italics = 1
" colorscheme PaperColor
" colorscheme one
colorscheme nord
" colorscheme dracula
" colorscheme gruvbox
" colorscheme elflord

" let g:lightline = { 'colorscheme': 'PaperColor' }
let g:lightline = { 'colorscheme': 'nord' }
" let g:lightline = { 'colorscheme': 'darcula' }
" let g:lightline = { 'colorscheme': 'jellybeans' } " gruvbox approx. 
" let g:lightline = { 'colorscheme': 'gruvbox' }

set background=dark

syntax enable
filetype plugin indent on
" Tabs, spelling, fancy ligatures etc
set tabstop=4
set shiftwidth=4
set conceallevel=2
set textwidth=80
set spell
set encoding=utf-8

set showmode

set expandtab
set number
set hidden
set ignorecase
set smartcase
set showcmd
set wildmenu
set showmatch
set autoindent
set smartindent

set incsearch
set hlsearch

set printoptions=paper:letter

" From github/jonhoo centering search text
nnoremap <silent> n nzz
nnoremap <silent> N Nzz
nnoremap <silent> * *zz
nnoremap <silent> # #zz
nnoremap <silent> g* g*zz


" ALE Linter configuration for writing
let g:ale_linters = {
			\  'org': ['proselint', 'write-good'],
			\  'text': ['proselint', 'languagetool'],
            \  'md': ['proselint'],
			\  'nix': ['nix-instantiate'],
			\}

let g:ale_completion_enabled = 1

" SOAP notes
augroup soap
	" Use the SOA:.skeleton file in the SOAP directory
	autocmd VimEnter */SOAP/** 0r SOA:.skeleton

	" Put the time/date at the top
	autocmd VimEnter */SOAP/** :put =strftime('%c')

	" Probably going to use a lot of the same words.
	autocmd VimEnter */SOAP/** set complete=k/home/blyons/SOAP/*
augroup END

" For Sending Email
au BufRead /tmp/neomutt-* set tw=72

" Keybindings
let mapleader = "\<Space>"
let maplocalleader = "\<Space>"

" Save buffer as root
cmap w!! w !sudo tee > /dev/null %

" manual reformatting shortcuts in Pencil
nnoremap <buffer> <silent> Q gqap
xnoremap <buffer> <silent> Q gq
nnoremap <buffer> <silent> <leader>Q vapJgqap

" Drawn inspiration
" {Space/Doom}macs backported to
" faithful recursion

"
nmap <Leader>vw <Plug>VimwikiIndex
nmap <Leader>vwt <Plug>VimwikiTabIndex
nmap <Leader>vwq <Plug>VimwikiUISelect
nmap <Leader>vwi <Plug>VimwikiDiaryIndex
nmap <Leader>vwd <Plug>VimwikiMakeDiaryNote
nmap <Leader>vwdy <Plug>VimwikiMakeYesterdayDiaryNote
nmap <Leader>vwdm <Plug>VimwikiMakeTomorrowDiaryNote
" Make Diary Tab Note
nmap <Leader>vwtd <Plug>VimwikiTabMakeDiaryNote

" CtrlP / FZF
" ff means find-file
" Open a file
nnoremap <silent> <Leader>ff :Files<CR>
" Save file
nnoremap <silent> <Leader>fs :w!<CR>

" Buffers list
nnoremap <silent> <Leader>bb :Buffers<CR>
nnoremap <silent> <Leader>bd :bd<CR>

" CoC setup

" if hidden is not set, TextEdit might fail.
set hidden

" Some servers have issues with backup files, see #649
set nobackup
set nowritebackup

" Better display for messages
set cmdheight=2

" You will have bad experience for diagnostic messages when it's default 4000.
set updatetime=300

" don't give |ins-completion-menu| messages.
set shortmess+=c

" always show signcolumns
set signcolumn=yes

" Use tab for trigger completion with characters ahead and navigate.
" Use command ':verbose imap <tab>' to make sure tab is not mapped by other plugin.
inoremap <silent><expr> <TAB>
			\ pumvisible() ? "\<C-n>" :
			\ <SID>check_back_space() ? "\<TAB>" :
			\ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
	let col = col('.') - 1
	return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current position.
" Coc only does snippet and additional edit on confirm.
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
" Or use `complete_info` if your vim support it, like:
" inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"

" Use `[g` and `]g` to navigate diagnostics
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
	if (index(['vim','help'], &filetype) >= 0)
		execute 'h '.expand('<cword>')
	else
		call CocAction('doHover')
	endif
endfunction

" Highlight symbol under cursor on CursorHold
autocmd CursorHold * silent call CocActionAsync('highlight')

" Remap for rename current word
nmap <leader>rn <Plug>(coc-rename)

" Remap for format selected region
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

augroup mygroup
	autocmd!
	" Setup formatexpr specified filetype(s).
	autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
	" Update signature help on jump placeholder
	autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Remap for do codeAction of selected region, ex: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap for do codeAction of current line
nmap <leader>ac  <Plug>(coc-codeaction)
" Fix autofix problem of current line
nmap <leader>qf  <Plug>(coc-fix-current)

" Create mappings for function text object, requires document symbols feature of languageserver.
xmap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap if <Plug>(coc-funcobj-i)
omap af <Plug>(coc-funcobj-a)

" Use <TAB> for select selections ranges, needs server support, like: coc-tsserver, coc-python
nmap <silent> <TAB> <Plug>(coc-range-select)
xmap <silent> <TAB> <Plug>(coc-range-select)

" Use `:Format` to format current buffer
command! -nargs=0 Format :call CocAction('format')

" Use `:Fold` to fold current buffer
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" use `:OR` for organize import of current buffer
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

" Add status line support, for integration with other plugin, checkout `:h coc-status`
set statusline^=%{coc#status()}%{get(b:,'coc_current_function',\'\')}

" Using CocList
" Show all diagnostics
nnoremap <silent> <space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions
nnoremap <silent> <space>e  :<C-u>CocList extensions<cr>
" Show commands
nnoremap <silent> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document
nnoremap <silent> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols
nnoremap <silent> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list
nnoremap <silent> <space>p  :<C-u>CocListResume<CR>

