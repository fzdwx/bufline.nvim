# bufline.nvim

🤏 A simple lua buffer line.

![img.png](img.png)

## 🤖 Installation

```lua
{
    "fzdwx/bufline.nvim",
    event = "BufEnter",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    config = function()
        local buf = require("bufline")
        buf.setup({
            separator = function()
                return {
                    str = '',
                    hl = ""
                }
            end
        })
    end,
},
```
## 📖 Configuration

```
---@class BufLineOpts
---@field title     function:Group
---@field modified  function:string
---@field devicon   function:Group
---@field separator function:Group
---@field cell      function:string
---@field bufline   function:string
---@field folder    function:Group
---@field dirName   function:string
---@field noname    string

---@class Group
---@field str string
---@field hl  string
--- group = {str = "helloworld", "BufLine"}

buf.setup(opts)
```

### 💥 Highlight

```text
BufLineTitleSel
BufLineTitleNoSel
BufLineFill
BufLine
BufLineFolder
```

## Thanks
1. [luatab](https://github.com/alvarosevilla95/luatab.nvim)
2. [barbar](https://github.com/romgrk/barbar.nvim)
