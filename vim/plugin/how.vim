function! OpenHowUrl(...)
  let args = a:000
  let howDir = "~/Dropbox/HOW"
  let howFile = ""

  if len(args) > 1
    let howDir = howDir . "/" .get(args, 1)
    let howFile = howDir . "/" . get(args, 0)
  else
    let howFile = howDir . "/" . get(args, 0)
  endif

  if !empty(glob(howFile))
    execute system("open $(cat " . howFile . ")")
  else
    silent "!mkdir -p " . howDir
    execute "tabe " . howFile
  end
endfunction

command! -nargs=* How :call OpenHowUrl(<f-args>)
