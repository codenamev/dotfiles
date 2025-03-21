" Function to capture visual selection
function! GetVisualSelection()
  " Ensure normal mode
  execute "normal! \<Esc>"

  " Get the selection
  let [line_start, column_start] = getpos("'<")[1:2]
  let [line_end, column_end] = getpos("'>")[1:2]
  let lines = getline(line_start, line_end)

  " Adjust for partial line selection
  if len(lines) == 0
    return ''
  endif
  let lines[-1] = lines[-1][: column_end - 1]
  let lines[0] = lines[0][column_start - 1:]
  return join(lines, "\n")
endfunction

function! SendDataToServer(selected_text)
  let json_data = json_encode({"description": a:selected_text, "buffer_id": b:original_buffer_id, "start_line": b:selection_start, "end_line": b:selection_end})
  let url = 'http://blueprints.dev.doximity.cloud/api/v1/blueprint_variants'
  let cmd = ['curl', '-s', '-X', 'POST', '-H', 'Content-Type: application/json', '-d', json_data, url]

  let job_opts = { 'out_io': 'buffer', 'out_name': 'http_buffer', 'out_cb': 'ProcessServerResponse' }

  call job_start(cmd, job_opts)
endfunction

function! ProcessServerResponse(channel, msg)
  let data = json_decode(a:msg)

  if has_key(data, 'error')
    echoerr data.error
    return
  endif

  let lines = split(data.result, "\n")

  let target_buf = data.buffer_id
  let start_line = data.start_line
  let end_line = data.end_line

  if bufexists(target_buf)
    let delete_end = start_line + len(lines) - 1
    call setbufline(target_buf, start_line, lines[0])

    if len(lines) > 1
      call appendbufline(target_buf, start_line, lines[1:])
    endif
    if delete_end < end_line
      call deletebufline(target_buf, delete_end + 1, end_line)
    endif
  endif
endfunction

function! ReplaceVisualSelectionWithServerResponse()
  let selected_text = GetVisualSelection()

  let b:original_buffer_id = bufnr('%')
  let b:selection_start = getpos("'<")[1]
  let b:selection_end = getpos("'>")[1]

  call SendDataToServer(selected_text)
endfunction

function! SubmitVisualSelectionAsBlueprint()
  let selected_text = GetVisualSelection()

  let json_data = json_encode({"code": selected_text})
  let url = 'http://blueprints.dev.doximity.cloud/api/v1/blueprints'
  let cmd = ['curl', '-s', '-X', 'POST', '-H', 'Content-Type: application/json', '-d', json_data, url]

  let job_opts = { 'out_io': 'null' }

  call job_start(cmd, job_opts)
endfunction

function! PromptForChangeDescription()
  return input('Enter description of changes: ')
endfunction

function! SendDataToServerWithDescription(selected_text, description)
  let json_data = json_encode({"description": a:description, "code": a:selected_text, "buffer_id": b:original_buffer_id, "start_line": b:selection_start, "end_line": b:selection_end})
  let url = 'http://blueprints.dev.doximity.cloud/api/v1/blueprint_changes'
  let cmd = ['curl', '-s', '-X', 'POST', '-H', 'Content-Type: application/json', '-d', json_data, url]
  let job_opts = {'out_io': 'buffer', 'out_name': 'http_buffer', 'out_cb': 'ProcessServerResponse'}
  call job_start(cmd, job_opts)
endfunction

function! ReplaceVisualSelectionWithServerResponseFromChanges()
  let selected_text = GetVisualSelection()
  let description = PromptForChangeDescription()
  let b:original_buffer_id = bufnr('%')
  let b:selection_start = getpos("'<")[1]
  let b:selection_end = getpos("'>")[1]
  call SendDataToServerWithDescription(selected_text, description)
endfunction

xnoremap <Leader>0 :<C-u>call ReplaceVisualSelectionWithServerResponse()<CR>
xnoremap <Leader>1 :<C-u>call SubmitVisualSelectionAsBlueprint()<CR>
