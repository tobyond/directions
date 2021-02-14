local api, cmd, fn, g, vim = vim.api, vim.cmd, vim.fn, vim.g, vim

-- Settings
local ls_query = 'gls -ap --group-directories-first'
local fzf_options = '--reverse --expect=ctrl-t,ctrl-v,ctrl-x,ctrl-a'

-- predefined
local file_processor, directions

-- state
local opts = {
  fzf_action = {
    ['ctrl-t'] = 'tabedit',
    ['ctrl-v'] = 'vsplit',
    ['ctrl-x'] = 'split',
    ['ctrl-a'] = 'files'
  },
  commands_list = { 'mkdir', 'touch', 'mv', 'rm', 'rmrf', 'cp' },
  command_opts = {
    mkdir = 'mkdir ',
    touch = 'touch ',
    mv    = 'mv ',
    rm    = 'rm ',
    rmrf  = 'rm -rf ',
    cp    = 'cp ',
  },
  steps = {},
  command_table = {
    executeable = '',
    selected = ''
  }
}

local function working_directory()
  if #opts.steps == 0 then
    return ''
  else
    return table.concat(opts.steps)
  end
end

-------------------- UTILS -----------------------

local function is_empty(args)
  return args == nil or args == ''
end

local function is_directory()
  return fn['isdirectory'](working_directory()) == 1
end

local function complete_dir()
  return fn['getcwd']() .. '/' .. working_directory()
end

local function list_source()
  return ls_query .. ' ' .. working_directory()
end

-------------------- EXECUTORS -----------------------

local function reset_steps(hard)
  if hard then
    opts.steps = {}
  else
    table.remove(opts.steps)
  end
end

local function step_adder(s)
  if not is_empty(s) and s ~= './'  then
    table.insert(opts.steps, s)
  end
end

local function process_file(key)
  key = opts.fzf_action[key]
  if key and key ~= 'files' then
    cmd(key .. ' ' .. working_directory())
  elseif key == 'files' then
    file_processor()
  else
    cmd('e ' .. working_directory())
  end
  reset_steps(true)
end

local function directions_handler(args)
  if not args or #args < 2 then return end
  local key = args[1]
  step_adder(args[2])

  if is_empty(key) and is_directory() then
    return directions()
  else
    return process_file(key)
  end
end

-------------------- PREDICATES -----------------------

local function to_reset_steps()
  local to_reset = opts.command_table.selected == 'mv' or opts.command_table.selected == 'cp'
  return to_reset
end

-------------------- EDIT FUNCTIONS -----------------------

local function command_builder()
  local resolved_command = opts.command_opts[opts.command_table.selected]

  if is_empty(resolved_command) then return end

  local str = resolved_command .. complete_dir()

  if to_reset_steps() then str = str .. ' ' .. complete_dir() end

  opts.command_table.executeable = str
end

local function post_edit_cleanup()
  if opts.command_table.selected == 'rm' or to_reset_steps() then
    reset_steps(false)
  end
  opts.command_table.selected = ''
end

local function action_retriever()
  local selected_option = fn['confirm']('Edit:', "mk&dir\n&touch\n&mv\n&rm\nrmr&f\n&copy", 0)
  opts.command_table.selected = opts.commands_list[selected_option]
  command_builder()
end

function file_processor()
  action_retriever()
  fn['nvim_feedkeys'](':! ' .. opts.command_table.executeable, 'n', true)

  return post_edit_cleanup()
end

---------------- Preview String ------------------

local function bash_script()
  local string =    'if [[ -f "$(pwd)/' .. working_directory() .. '$(echo {})" ]];'
  string = string .. 'then cat "$(pwd)/' .. working_directory() .. '$(echo {})";'
  string = string .. 'else ' .. 'ls -p "$(pwd)/' .. working_directory() .. '$(echo {})";'
  string = string ..'fi;'
  return string
end

--------------------- MAIN -----------------------

function directions()
  local extended_opts = fzf_options .. ' --preview "' .. bash_script() .. '"'
  local fzf_opts_wrap = fn['fzf#wrap']({ source = list_source(), options = extended_opts })
  fzf_opts_wrap['sink*'] = directions_handler

  return fn['fzf#run'](fzf_opts_wrap)
end

return {
  directions = directions
}
