return {
  -- pokeruby/src/intro.c:826
  intro = "src.ui.game3.rs.intro",
  -- pokeruby/src/title_screen.c:519
  title = "src.ui.game3.rs.title",
  -- pokeruby/src/main_menu.c:185
  mainMenu = "src.ui.game3.rs.main_menu",
  -- pokeruby/src/main_menu.c:752
  newGame = "src.ui.game3.rs.birch_speech",
  introParams = {},
  titleParams = { song = "MUS_TITLE" },
  sceneOwnsRng = { intro = true, oak = true },
  -- pokeruby/title_screen.c:729
  titleCombos = {
    clearSave = "src.ui.game3.rs.clear_save_screen",
    resetRtc = "src.ui.game3.rs.reset_rtc_screen",
  },
  canResetRtc = "src.ui.game3.rs.reset_rtc_screen",
  -- pokeruby/src/new_game.c:76
  seedTrainerIdAt = "newGame",
  newGameFieldCallback = "truck",
}
