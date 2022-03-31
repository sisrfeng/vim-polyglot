"  本来和这个文件完全一样:
"  /home/linuxbrew/.linuxbrew/Cellar/neovim/0.6.1/share/nvim/runtime/ftplugin/help.vim



" 这个block: 决定是否要继续改设置:
    if polyglot#init#is_disabled(expand('<sfile>:p'), 'help', 'ftplugin/help.vim')
        finish
    endif

    " Vim filetype plugin file

    if exists("b:did_ftplugin")
        finish
    endif


    let b:did_ftplugin = 1

    let s:cpo_save = &cpo
    set cpo&vim

    let b:undo_ftplugin = "setl fo< tw< cole< cocu< keywordprg<"


" set options
func! g:Help_opts()
    setlocal formatoptions+=tcroql textwidth=100
                                 " textwidth=78
    setlocal tabstop=4 expandtab
    echom '进来了_Help_opts 确实进来了, 但expandtab没生效'
    " 这个文件改了后, 要重启vim才能生效
    setlocal list
    setlocal modifiable  noreadonly

    " 默认的一些set
        " 'iskeyword'         nearly all ASCII chars except ' ', '*', '"' and '|'
        " 'foldmethod'        "manual"
        " 'foldenable'        off
        " 'tabstop'           8
        " 'modifiable'        off
        " 'list'              off

    if has("conceal")
        " setlocal cole=2 cocu=nc
        setlocal conceallevel=2 concealcursor=n
    endif

    setlocal keywordprg=:help
        " Prefer Vim help instead of manpages.
endf

" call Help_opts()
" 要放到help配置.vim里定义?

" toc
    if !exists('g:no_plugin_maps')
        nnor <silent><buffer> go :call <sid>show_toc()<cr>:call TOC_leo()<CR>

        function! s:show_toc() abort
            let my_bufname = bufname('%')
            let info = getloclist(0, {'winid': 1})
            if !empty(info)   &&  getwinvar(info.winid, 'qf_toc') ==# my_bufname
                lopen
                 " location list window open
                return
            endif

            let toc = []
            let lnum = 2
              " v:lnum, 折叠时涉及到
            let last_line = line('$') - 1
              " 最后一行的行号
            let last_added_lnum = 0
            let has_section = 0
            let has_sub_section = 0

            while lnum && lnum <= last_line
                let level    = 0
                let text     = getline(lnum)
                   " 逐行读取
                let add_text = ''

                " 这样的视为section heading: =======================
                " A de-facto section heading.    Other headings are inferred.
                if text =~# '^=\+$' &&  lnum + 1 < last_line
                        " # for matching case
                        " ?  for ignoring case,
                    let has_section = 1
                    let has_sub_section = 0
                    let lnum = nextnonblank(lnum + 1)
                    let text = getline(lnum)
                    let add_text = text
                    while add_text =~# '\*[^*]\+\*\s*$'
                        let add_text = matchstr(add_text, '.*\ze\*[^*]\+\*\s*$')
                    endwhile
                elseif text =~# '^[A-Z0-9][-A-ZA-Z0-9 .][-A-Z0-9 .():]*\%([ \t]\+\*.\+\*\)\?$'
                    " Any line that's yelling(大写) is important.
                    let has_sub_section = 1
                    let level = has_section
                    let add_text = matchstr(text, '.\{-}\ze\s*\%([ \t]\+\*.\+\*\)\?$')
                elseif text =~# '\~$'
                            \ && matchstr(text, '^\s*\zs.\{-}\ze\s*\~$') !~# '\t\|\s\{2,}'
                            \ && getline(lnum - 1) =~# '^\s*<\?$\|^\s*\*.*\*$'
                            \ && getline(lnum + 1) =~# '^\s*>\?$\|^\s*\*.*\*$'
                    " These lines could be headers or code examples.    We only want the
                    " ones that have subsequent lines at the same indent or more.
                    let l = nextnonblank(lnum + 1)
                    if getline(l) =~# '\*[^*]\+\*$'
                        " Ignore tag lines
                        let l = nextnonblank(l + 1)
                    endif

                    if indent(lnum) <= indent(l)
                        let level = has_section + has_sub_section
                        let add_text = matchstr(text, '\S.*')
                    endif
                endif


                let add_text = substitute(add_text, '\s\+$', '', 'g')
                                                  " 扔掉空格
                if !empty(add_text) &&   last_added_lnum != lnum
                    let last_added_lnum = lnum
                    " 往toc这个list里加一个dict
                    call add(  toc,
                               \{
                                    \'bufnr': bufnr('%'),
                                    \'lnum': lnum,
                                    \'text': repeat('  ', level) .. add_text,
                               \},
                            \)
                endif
                let lnum = nextnonblank(lnum + 1)
            endwhile

            " 主体: 设置location list window
                " create a new list:
                call setloclist(
                    \0,
                    \toc,
                    \)
                    " 0: current window
                call setloclist(
                    \0,
                    \[],
                    \'a',
                    \{'title': '目录'},
                    \)
                    " a表示add, 添加
                lopen
            let w:qf_toc = my_bufname
        endf

    endif




let &cpo = s:cpo_save
unlet s:cpo_save
