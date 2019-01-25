function! OpenTilFile(...)
  let tilDir = "~/Dropbox/TIL"
  let name = "general.md"
  let args = a:000

  if len(args) > 0
    let tilDir = tilDir . "/" . get(args, 0)
  endif

  if len(args) > 1
    let name = get(args, 1) . ".md"
  endif

  call mkdir(tilDir, "p")
  execute "tabe " . tilDir . "/" . name
endfunction

command! -nargs=* TIL :call OpenTilFile(<f-args>)
