vim.bo.omnifunc = "v:lua.OmniCC"

function OmniCC(findstart)
  if findstart == 1 then
    local cursor = vim.api.nvim_win_get_cursor(0)
    local prefix = vim.api.nvim_get_current_line():sub(1, cursor[2])

    if cursor[1] == 1 and not prefix:find("[^%w]") then
      return 0
    else
      return -2
    end
  else
    return {
      { word = "feat", info = "add or remove a feature" },
      { word = "fix", info = "patch a bug" },
      { word = "refactor", info = "change not affecting behavior" },
      { word = "style", info = "change not affecting artifacts" },
      { word = "perf", info = "performance improvement" },
      { word = "test", info = "testing improvement" },
      { word = "build", info = "update build system" },
      { word = "ci", info = "update continuous integration" },
      { word = "docs", info = "update documentation" },
      { word = "chore", info = "misc change" },
      { word = "merge", info = "merge commit" },
      { word = "revert", info = "revert commit" },
      { word = "init", info = "initial commit" },
    }
  end
end
