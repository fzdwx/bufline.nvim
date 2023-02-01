# bufline.nvim

🤏 A lua buffer line.

![img.png](img.png)

## 🤖 Installation

```lua
{
    "fzdwx/bufline.nvim",
    event = "BufReadPre",
    dependencies = {
        "nvim-tree/nvim-web-devicons", -- optional dependency
    },
    config = function()
        local buf = require("bufline")
        buf.setup({
            separator = function(index)
                return {
                    str = '',
                    hl = ""
                }
            end
        })
    end,
},
```

## 💥 Highlight

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