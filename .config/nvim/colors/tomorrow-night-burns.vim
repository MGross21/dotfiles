set background=dark

hi clear
if exists("syntax_on")
  syntax reset
endif

let g:colors_name = "tomorrow-night-burns"

" Define ANSI colors
hi Normal       guifg=#A1B0B8 guibg=#151515
hi Cursor       guifg=#FF443E guibg=#FF443E
hi Visual       guibg=#2A2D32
hi LineNr       guifg=#5D6F71 guibg=#151515
hi Comment      guifg=#708284
hi Constant     guifg=#FC595F
hi Identifier   guifg=#A63C40
hi Statement    guifg=#832E31
hi PreProc      guifg=#DF9395
hi Type         guifg=#BA8586
hi Special      guifg=#EA4047
hi Underlined   guifg=#819090 gui=underline
hi Error        guifg=#FF0000 guibg=#151515
hi Todo         guifg=#CAA1A2 guibg=#151515

" Additional UI colors
hi Pmenu        guibg=#262728 guifg=#A1B0B8
hi PmenuSel     guibg=#708284 guifg=#151515
hi TabLine      guibg=#2A2D32 guifg=#A1B0B8
hi TabLineSel   guibg=#708284 guifg=#151515
hi StatusLine   guibg=#2A2D32 guifg=#A1B0B8
hi StatusLineNC guibg=#151515 guifg=#5D6F71
