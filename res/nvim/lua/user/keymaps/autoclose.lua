local function map(key, fn)
  vim.keymap.set("i", key, function()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    return fn(line:sub(col, col + 1), line:sub(1, col), line:sub(col + 1))
  end, { expr = true })
end

map("<BS>", function(pair)
  if vim.list_contains({ '""', "''", "``", "()", "[]", "{}" }, pair) then
    return "<BS><Del>"
  else
    return "<BS>"
  end
end)

map("<CR>", function(pair, pre)
  if vim.list_contains({ '""', "''", "``", "()", "[]", "{}", "><" }, pair) then
    return "<CR><Esc>O"
  elseif pre:match("```%w+$") then
    return "<CR><Esc>O"
  else
    return "<CR>"
  end
end)

for _, char in pairs({ '"', "'", "`" }) do
  map(char, function(pair, pre)
    if pair:sub(2, 2) == char then
      return "<Right>"
    elseif char == "'" and pair:sub(1, 1):match("%w") then
      return "'"
    elseif char == "'" and pre:sub(-2, -1) == "''" then
      return "''<Left><Left>"
    elseif char == "`" and pre:sub(-2, -1) == "``" then
      return "````<Left><Left><Left>"
    elseif vim.list_contains({ '""', "''", "``" }, pair) then
      return char
    else
      return char .. char .. "<Left>"
    end
  end)
end

for open, close in pairs({ ["("] = ")", ["["] = "]", ["{"] = "}" }) do
  map(open, function()
    return open .. close .. "<Left>"
  end)

  map(close, function(pair)
    if pair:sub(2, 2) == close then
      return "<Right>"
    else
      return close
    end
  end)
end
