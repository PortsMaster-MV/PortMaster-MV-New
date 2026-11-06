return function(V)
  local sym = V.sym
  -- pokeemerald/src/graphics.c:1394
  V.NAMING = {
    keyboard_pal = sym("naming_screen.o:sKeyboard_Pal"),
    menu_pal = sym("gNamingScreenMenu_Pal"),
    menu_gfx = sym("gNamingScreenMenu_Gfx"),
    background_map = sym("gNamingScreenBackground_Tilemap"),
    keyboard_upper_map = sym("gNamingScreenKeyboardUpper_Tilemap"),
    keyboard_lower_map = sym("gNamingScreenKeyboardLower_Tilemap"),
    keyboard_symbols_map = sym("gNamingScreenKeyboardSymbols_Tilemap"),
    page_swap_frame = sym("gNamingScreenPageSwapFrame_Gfx"),
    back_button = sym("gNamingScreenBackButton_Gfx"),
    ok_button = sym("gNamingScreenOKButton_Gfx"),
    page_swap_upper = sym("gNamingScreenPageSwapUpper_Gfx"),
    page_swap_lower = sym("gNamingScreenPageSwapLower_Gfx"),
    page_swap_others = sym("gNamingScreenPageSwapOthers_Gfx"),
    cursor = sym("gNamingScreenCursor_Gfx"),
    cursor_squished = sym("gNamingScreenCursorSquished_Gfx"),
    cursor_filled = sym("gNamingScreenCursorFilled_Gfx"),
    page_swap_button = sym("gNamingScreenPageSwapButton_Gfx"),
    input_arrow = sym("gNamingScreenInputArrow_Gfx"),
    underscore = sym("gNamingScreenUnderscore_Gfx"),
    pc_icon_off = sym("naming_screen.o:sPCIconOff_Gfx"),
    pc_icon_on = sym("naming_screen.o:sPCIconOn_Gfx"),
  }
  V.BOOT_RSE_FORMAT = require("src.import.gba.rse.boot_gfx").FORMAT
end
