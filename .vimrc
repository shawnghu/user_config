set nocompatible
filetype off                  " required due to some vundle runtimepath thing- refer to line below that turns it back on
"
" set the runtime path to include Vundle and initialize
" git clone https://github.com/VundleVim/Vundle.vim.git
" ~/.vim/bundle/Vundle.vim

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" Add all your plugins here (note older versions of Vundle used Bundle instead of Plugin)

"Python formatting
Plugin 'psf/black'
nnoremap <F9> :Black<CR>

" For parentheses n shit
Plugin 'tpope/vim-surround'

"Display indentation
Plugin 'Yggdroot/indentLine'
let g:indentLine_char = '|'

"marker; manual control of highlighting groups
Plugin 'inkarkat/vim-ingo-library' " dependency
Plugin 'inkarkat/vim-mark'

"don't add marked stuff to the search history
let g:mwHistAdd = '/@'

"automatically restore marks from previous sessions
let g:mwAutoLoadMarks = 1

"more colors
let g:mwDefaultHighlightingPalette = 'extended'


"
Plugin 'scrooloose/nerdtree'
" Display the same nerdtree every time, like an IDE panel
Plugin 'jistr/vim-nerdtree-tabs'

function! NERDTreeToggleInCurDir()
  " If NERDTree is open in the current buffer
  if (exists("t:NERDTreeBufName") && bufwinnr(t:NERDTreeBufName) != -1)
    exe ":NERDTreeTabsToggle"
  else
    if (expand("%:t") != '')
      exe ":NERDTreeFind %:p"
    else
      exe ":NERDTreeToggle"
    endif
  endif
endfunction

nnoremap <C-n> :call NERDTreeToggleInCurDir()<CR>



Plugin 'tpope/vim-fugitive'

Plugin 'vim-syntastic/syntastic' "syntax checker
"c++11
let g:syntastic_cpp_compiler_options = ' -std=c++11 -stdlib=libc++'

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_loc_list_height = 1
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 0
" see :h syntastic-loclist-callback
function! SyntasticCheckHook(errors)
    if !empty(a:errors)
        let g:syntastic_loc_list_height = min([len(a:errors), 5])
    endif
endfunction
let g:syntastic_enable_signs = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 1
let g:syntastic_enable_balloons = 1
let g:syntastic_enable_highlighting = 1

let g:syntastic_echo_current_error = 1

let g:syntastic_mode_map = {
    \ "mode": "active",
    \ "passive_filetypes": ["xml"] }

highlight SyntasticError guibg=#4f0000
highlight SyntasticWarning guibg=#2f000f

Plugin 'flazz/vim-colorschemes'

"fancy statusline plugin (can remove and configure own statusline if wanted)
Plugin 'itchyny/lightline.vim'

"Plugin 'nvie/vim-flake8' "pep8
"let python_highlight_all=1
"Plugin 'rhysd/vim-clang-format' "Plugin to interface with clang-format for C-family automatic formatting

" All of your Plugins must be added before the following line
call vundle#end()        
filetype plugin indent on

runtime macros/matchit.vim


let mapleader = ","

" suppress help menu, since f1 is next to f2
:nmap <F1> <nop>

"tmux and other multiplexers have to use escape sequences to send arrow keys,
"so this undoes the mapping inside vim
"set t_ku= [1;5A
"set t_kd= [1;5B
"set t_kr= [1;5C
"set t_kl= [1;5D
map <Esc>^[[A <Up>
map <Esc>^[[B <Down>
map <Esc>^[[C <Right>
map <Esc>^[[D <Left>
"map <Esc>[A <Up>
"map <Esc>[B <Down>
"map <Esc>[C <Right>
"map <Esc>[D <Left>
"" Console movement
"cmap <Esc>[A <Up>
"cmap <Esc>[B <Down>
"cmap <Esc>[C <Right>
"cmap <Esc>[D <Left>

"used to handle a phenomenon where xterm would clear the system clipboard
"upon exiting vim. requires xsel; if you want to fix this behavior for all
"programs and not just vim, install parcellite or glipper
"https://stackoverflow.com/questions/6453595/prevent-vim-from-clearing-the-clipboard-on-exit
"autocmd VimLeave * call system("xsel -ib", getreg('+'))
set clipboard=unnamedplus

if executable("xsel")

  function! PreserveClipboard()
    call system("xsel -ib", getreg('+'))
  endfunction

  function! PreserveClipboadAndSuspend()
    call PreserveClipboard()
    suspend
  endfunction

  autocmd VimLeave * call PreserveClipboard()
  nnoremap <silent> <c-z> :call PreserveClipboadAndSuspend()<cr>
  vnoremap <silent> <c-z> :<c-u>call PreserveClipboadAndSuspend()<cr>

endif


colorscheme molokai
hi VisualNOS guibg=#2D2B2B
hi Visual guibg=#2D2B2B
hi CursorLine guibg=#2B2929

let g:lightline = {
      \ 'colorscheme': 'PaperColor_dark',
      \ 'component_function': {
      \   'filename': 'LightLineFilename',
      \ },
      \ 'component_expand': {
      \   'syntastic': 'SyntasticStatuslineFlag',
      \ },
      \ 'component_type': {
      \   'syntastic': 'error',
      \ },
      \ }

function! LightLineFilename()
  return expand('%')
endfunction

"let g:lightline = {
"      \ 'colorscheme': 'ir_black',
"      \ }

" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just
" :PluginUpdate
" " :PluginSearch foo - searches for foo; append `!` to refresh local cache
" " :PluginClean      - confirms removal of unused plugins; append `!` to
" auto-approve removal

"enable mouse in all modes
set mouse=a

"leave status bar on at all times
set laststatus=2
"since it shows up in the status bar, destroy the mode line
set noshowmode

" This shows what you are typing as a command
set showcmd 

"syntax highlighting
syntax on
" don't set default 3000 char limit on syntax highlighting, (else we can break
" brace-matching and string highlighting can get really weird)
set synmaxcol=0

"save undo history in a file for persistent undo state
set undofile

"system clipboard reg to + reg
let g:clipbrdDefaultReg = '+'

" Set off the other paren
highlight MatchParen ctermbg=4

"search in ancestor directories for tag files
set tags=./tags;,tags;

"bash-like autocompletion behavior in command mode
set wildmode=longest,list
set wildmenu

"for editing in command mode (don't forget to use q: and C-F though)
cnoremap <C-a> <Home>
cnoremap <C-e> <End>
cnoremap <C-p> <Up>
cnoremap <C-n> <Down>
cnoremap <C-b> <Left>
cnoremap <C-f> <Right>
" these two don't even work
cnoremap <M-b> <S-Left>
cnoremap <M-f> <S-Right>



"switch between buffers without having to write changes, lose marks, etc.
"allows for multiple buffers to be open simultaneously
set hidden

"fix intermittent broken backspace
"https://chrisjean.com/fix-backspace-in-vim/
set bs=2

"switch buffers with prompt
nnoremap gB :ls<CR>:b<Space>
nnoremap gb :ls<CR>:sb<Space>
"nnoremap gv :ls<CR>:bd<Space>

" gw : Swap word with next word
nnoremap <silent> gw :s/\(\%#\w\+\)\(\_W\+\)\(\w\+\)/\3\2\1/<cr><c-o><c-l>
" swap with next arg (doesn't work yet)
"nnoremap <silent> ga :s/\(\%#\w\+\)\(,\s\)\(\w\+\)/\3\2\1/<cr><c-o><c-l>

" Allow saving of files as sudo when you forget to start vim using sudo
cmap w!! w !sudo tee > /dev/null %
"
" quick system grep, standard parameters for searching in drive repo
nnoremap gs :silent! grep! -rniI --exclude-dir={build,opt} . -e 
" current directory of file, hopefully
nnoremap gS :silent! grep! -rniI --exclude-dir={build,opt} %:p:h -e 
" word under cursor in cwd
nnoremap gr :silent! grep! -rniI --exclude-dir={build,opt} . -e <C-R><C-W>
" word under cursor in current directory of file
nnoremap gR :silent! grep! -rniI --exclude-dir={build,opt} %:p:h -e <C-R><C-W>

" https://vim.fandom.com/wiki/Search_for_visually_selected_text
" Search for selected text, forwards or backwards.
vnoremap // y/\V<C-R>=escape(@",'/\')<CR><CR>
vnoremap <silent> * :<C-U>
  \let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
  \gvy/<C-R>=&ic?'\c':'\C'<CR><C-R><C-R>=substitute(
  \escape(@", '/\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>
  \gVzv:call setreg('"', old_reg, old_regtype)<CR>
vnoremap <silent> # :<C-U>
  \let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
  \gvy?<C-R>=&ic?'\c':'\C'<CR><C-R><C-R>=substitute(
  \escape(@", '?\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>
  \gVzv:call setreg('"', old_reg, old_regtype)<CR>

" open quickfix window when updated, for grepping
augroup quickfix
    autocmd!
    autocmd QuickFixCmdPost [^l]* cwindow
    autocmd QuickFixCmdPost l* lwindow
augroup END
" automatically open quickfixes in new split window- doesn't seem to work, vim doesn't seem to receive the mapping.
" see :help augroup, help autocmd, help quickfix, https://stackoverflow.com/questions/16743112/open-item-from-quickfix-window-in-vertical-split,
" https://vi.stackexchange.com/questions/7722/how-to-debug-a-mapping

" an important keyword here is "buffer local mappings"; that's what <buffer> is here
"autocmd! FileType qf nnoremap <buffer> o <C-w><CR>
"autocmd! FileType qf nnoremap <buffer> o <C-w><CR>


" in quickfix windows only, remap enter so that it opens windows in splits, instead of voer existing window
" <buffer> is used to keep the mapping local to buffers of type qf

"split navigations
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" https://vim.fandom.com/wiki/Capture_ex_command_output
" log output, e.g, of :map, to buffer in new tab
function! TabMessage(cmd)
  redir => message
  silent execute a:cmd
  redir END
  if empty(message)
    echoerr "no output"
  else
    " use "new" instead of "tabnew" below if you prefer split windows instead of tabs
    tabnew
    setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted nomodified
    silent put=message
  endif
endfunction
command! -nargs=+ -complete=command TabMessage call TabMessage(<q-args>)

"set minimum window height and width to 0 to maximize minimization
set wmw=0
set wmh=0

"resize to equal using Ctrl
"nnoremap <C-s> <C-w>=

"quick resizing (doesn't work)
"nnoremap <S-Up> <C-w>+
"nnoremap <S-Down> <C-w>- 
"nnoremap <S-Left> <C-w>< 
"nnoremap <S-Right> <C-w>> 

"allow tabbing in insert mode (doesn't work)
"imap <F2> <C-o><C-w>
"imap <F3> <C-o><C-p>

"search in insert (doesn't work)
"imap <F4> <C-o>/

"delete with f4 and f6 so you don't need to move hands (doesn't work)
"inoremap <F5> <Backspace>
"inoremap <F6> <Backspace>

let paste_mode = 0 " 0 = normal, 1 = paste

func! Paste_on_off()
   if g:paste_mode == 0
      set paste
      let g:paste_mode = 1
   else
      set nopaste
      let g:paste_mode = 0
   endif
   return
endfunc
nnoremap <silent> <F10> :call Paste_on_off()<CR>
set pastetoggle=<F10>


" Enable folding
set foldmethod=indent
set foldlevel=99
" Enable folding with the spacebar
nnoremap <space> za

set tabstop=4
set softtabstop=4
set expandtab
set number
set bg=dark
set smarttab smartindent autoindent
set shiftwidth=4
set fileformat=unix
set cursorline

set encoding=utf-8

" Create Blank Newlines and stay in Normal mode
nnoremap <silent> zj o<Esc>
nnoremap <silent> zk O<Esc>

"gotoend with G
":nnoremap <CR> G

" Search mappings: These will make it so that going to the next one in a
" search will center on the line it's found in.
"map N Nzz
""map n nzz

"easier end of paragraph
:nnoremap ] }
:nnoremap [ {
"last location
:nnoremap ;; ``

"pan to result when searching
set incsearch
"make search case insensitive
set ignorecase
"unless you search or something with caps
set smartcase
"don't highlight search results
set nohlsearch
"toggle highlighting with ctrl-h
" removed because it conflicts with window navigation, which was moved from
" tab so that i could start to use the jumplist properly
" nnoremap <C-h> :set hlsearch!<CR>

" Highlight all instances of word under cursor, when idle.
" Useful when studying strange source code.
" Type z/ to toggle highlighting on/off.
nnoremap <C-t> :if AutoHighlightToggle()<Bar>set hls<Bar>endif<CR>
function! AutoHighlightToggle()
   let @/ = ''
   if exists('#auto_highlight')
     au! auto_highlight
     augroup! auto_highlight
     setl updatetime=4000
     echo 'Highlight current word: off'
     return 0
  else
    augroup auto_highlight
    au!
    au CursorHold * let @/ = '\V\<'.escape(expand('<cword>'), '\').'\>'
    augroup end
    setl updatetime=500
    echo 'Highlight current word: ON'
  return 1
 endif
endfunction

set history=100
set undolevels=1000
"leave a three line buffer when moving to top and bottom of screen, so one can
"see context
set scrolloff=3

"let switch to next window
"nnoremap <Tab> <C-w>w
nnoremap <F2> <C-w>w
nnoremap <F3> <C-w><C-p>

"ctrl-number to go to tab number
" doesn't work due to lack of support for c-num 
" https://unix.stackexchange.com/questions/116671/mapping-c-1-does-not-work-in-vim
"noremap <C-1> 1gt 

"set the up and down keys to behave intuitively on wrapped lines
nnoremap j gj
nnoremap k gk
nnoremap <Up> gk
nnoremap <Down> gj
vnoremap j gj
vnoremap k gk
vnoremap <Up> gk
vnoremap <Down> gj
inoremap <silent> <Up> <Esc>gka
inoremap <silent> <Down> <Esc>gja
"arrow keys still move up and down a line
"set the left and right arrow keys to wrap to next line when at end fo line
set whichwrap+=<,>,h,l,[,]

"switch colon and semicolon in normal mode to save keystrokes on ex mode
"commands
nnoremap ; :
nnoremap : ;
vnoremap ; :
vnoremap : ;

set visualbell

" make it particularly noticeable what's being highlighted
hi Visual cterm=bold ctermbg=Blue ctermfg=Yellow
