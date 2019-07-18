function! liquibase#rollbackStatement(statement)
  let tokens = split(a:statement, ' ')
  let rollback = ['--rollback']
  if tokens[0] ==? 'CREATE'
    let rollback = rollback + ['DROP'] + tokens[1:2]
    return join(rollback) . ';'
  endif
  if tokens[0] ==? 'ALTER'
    let rollback = rollback + tokens[0:2] + ['DROP'] + tokens[4:5]
    return join(rollback) . ';'
  endif
endfunction 

function liquibase#rollbackMysqlStatement(statement)
  let tokens = split(a:statement, ' ')
  let rollback = ['--rollback']
  if tokens[0] ==? 'CREATE'
    if tokens[1] ==? 'TABLE'
      let rollback = rollback + ['DROP'] + tokens[1:2]
      return join(rollback) . ';'
    endif
    if tokens[1] ==? 'INDEX'
      let rollback = rollback + ['ALTER', 'TABLE', substitute(tokens[4], '\v\(.+', '', 'g')] + ['DROP', 'INDEX', tokens[2] ] 
      return join(rollback) . ';'
    endif
  endif
  if tokens[0] ==? 'ALTER'
    if tokens[6] ==? 'FOREIGN'
      let rollback = rollback + tokens[0:2] + ['DROP'] + tokens[6:7] + [tokens[5]]
      return join(rollback) . ';'
    endif
    if tokens[6] ==? 'UNIQUE'
      let rollback = rollback + tokens[0:2] + ['DROP', 'INDEX'] + [tokens[5]]
      return join(rollback) . ';'
    endif
  endif
endfunction

function liquibase#rollback()
  let dbtype = split(expand('%:t:r'), '\v\.')[-1]
  execute "normal! gg"
  while 1
    let b:current = line('.')
    if b:current == line('$') 
      break
    endif
    let b:currentLine = getline(b:current)
    let b:nexttLine = getline(b:current + 1)
    if strlen(b:currentLine) == 0 || b:currentLine[0:1] == '--' || b:nexttLine[0:9] == '--rollback' 
      execute "normal! j"
      continue
    endif
    if dbtype == 'mysql'
      call append(b:current, liquibase#rollbackMysqlStatement(b:currentLine))
    else 
      call append(b:current, liquibase#rollbackStatement(b:currentLine))
    endif
    execute "normal! j"
  endw
endfunction 
