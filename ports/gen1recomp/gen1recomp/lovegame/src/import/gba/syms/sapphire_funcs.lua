return {
  game = "sapphire",
  kind = "func",
  objs = [==[
agb_flash_mx.o
angel_kiss.o
aurora.o
battle_ai_script_commands.o
battle_ai_switch_items.o
battle_anim.o
battle_anim_effects_3.o
battle_anim_mon_movement.o
battle_anim_special.o
battle_anim_status_effects.o
battle_bg.o
battle_controller_player.o
battle_controller_wally.o
battle_controllers.o
battle_interface.o
battle_intro.o
battle_main.o
battle_party_menu.o
battle_records.o
battle_script_commands.o
battle_setup.o
battle_tower.o
battle_transition.o
berry.o
berry_blender.o
berry_tag_screen.o
beta_beat_up.o
bike.o
blow_kiss.o
bottle.o
brace.o
bubble.o
bug.o
bullet.o
cable_car.o
cable_club.o
choose_party.o
clear_save_data_menu.o
clock.o
contest_ai.o
contest_effect.o
contest_link.o
contest_link_util.o
contest_painting.o
coord_event_weather.o
crash.o
credits.o
cube.o
current.o
curtain.o
dark.o
daycare.o
dewford_trend.o
diploma.o
dp-bit.o
dragon.o
draw.o
easy_chat_2.o
egg_hatch.o
energy_wave.o
espeed.o
evasion.o
event_object_movement.o
evolution_graphics.o
evolution_scene.o
field_camera.o
field_control_avatar.o
field_door.o
field_effect.o
field_effect_helpers.o
field_fadetransition.o
field_message_box.o
field_player_avatar.o
field_poison.o
field_screen_effect.o
field_specials.o
field_tasks.o
field_weather.o
field_weather_effects.o
fieldmap.o
fight.o
finger.o
fire.o
fire_2.o
flash.o
fldeff_berrytree.o
fldeff_cut.o
fldeff_decoration.o
fldeff_flash.o
fldeff_poison.o
fldeff_secret_base_pc.o
fldeff_secretpower.o
fldeff_softboiled.o
fldeff_strength.o
fldeff_sweetscent.o
fldeff_teleport.o
flying.o
flying_hearts.o
flying_path.o
flying_petals.o
fp-bit.o
ghost.o
grip.o
ground.o
grow.o
guillotine.o
hall_of_fame.o
heal_bell.o
hidden_power_orbit.o
hof_pc.o
homing.o
hop_2.o
ice.o
intro.o
item.o
item_menu.o
item_use.o
landmark.o
leaf.o
link.o
load_save.o
lottery_corner.o
love_bg.o
lunge.o
m4a_1.o
mail.o
main.o
main_menu.o
map_name_popup.o
matsuda_debug_menu.o
mauville_man.o
menu.o
menu_helpers.o
mon_markings.o
money.o
moon.o
move_tutor_menu.o
musical.o
mystery_event_menu.o
mystery_event_script.o
naming_screen.o
noise.o
normal.o
note_spin.o
option_menu.o
orbit.o
orbs.o
overworld.o
palette.o
party_menu.o
pc_screen_effect.o
perceive.o
player_pc.o
poison.o
pokeball.o
pokeblock.o
pokeblock_feed.o
pokedex.o
pokedex_area_screen.o
pokemon_menu.o
pokemon_size_record.o
pokemon_storage_system_3.o
pokemon_summary_screen.o
powder.o
psychic.o
rain.o
region_map.o
reshow_battle_screen.o
ring.o
rock.o
rom6.o
rom_8077ABC.o
roots.o
rotating_gate.o
roulette_util.o
safari_zone.o
save.o
save_failed_screen.o
scan.o
scanline_effect.o
scary_face.o
scrcmd.o
script.o
script_menu.o
script_movement.o
script_pokemon_util_80F99CC.o
secret_base.o
seed.o
sfx.o
shadow_enlarge.o
shadow_minimize.o
shield.o
shop.o
siirtc.o
silhouette.o
slash.o
sleep.o
slice.o
slot_machine.o
smokescreen.o
sound.o
spit.o
splash.o
sprite.o
start_menu.o
starter_choose.o
strike.o
string_util.o
struggle.o
switch.o
sword.o
task.o
tendrils.o
text.o
text_window.o
thought.o
thrashing.o
thunder.o
tile.o
tileset_anim.o
time_events.o
title_screen.o
trade.o
trainer_card.o
trainer_see.o
twinkle.o
unknown_debug_menu.o
unused_2.o
unused_3.o
unused_6.o
unused_7.o
unused_8.o
unused_9.o
uproar.o
use_pokeblock.o
wallclock.o
water.o
whip.o
wild_encounter.o
wisp_fire.o
wisp_orb.o
withdraw.o
]==],
  collide = [==[
ClearObjectEvent
MainCB
MainCB2
VBlankCB
_fpadd_parts
do_boulder_dust
]==],
  data = [==[
AIStackPop 109908 34
AIStackPushAIPtr 1098e4 24
AIStackPushVar 1098c4 20
AI_CalcDmg 1caf8 f4
AI_TrySwitchOrUseItem 36b0c 140
AI_TypeCalc 1d45c 118
AbilityBattleEffects 18324 1c8c
AccessHallOfFamePC 10d618 14
AccuracyCalcHelper 1c174 146 20
AcroBikeHandleInputBunnyHop e54f4 a8 28
AcroBikeHandleInputNormal e5340 9a 28
AcroBikeHandleInputSidewaysJump e5678 5c 28
AcroBikeHandleInputTurnJump e56d4 24 28
AcroBikeHandleInputTurning e53dc 78 28
AcroBikeHandleInputWheelieMoving e559c dc 28
AcroBikeHandleInputWheelieStanding e5454 9e 28
AcroBikeTransition_FaceDirection e56f8 e 28
AcroBikeTransition_Moving e5744 78 28
AcroBikeTransition_NormalToWheelie e57bc 3c 28
AcroBikeTransition_SideJump e5920 70 28
AcroBikeTransition_TurnDirection e5708 3c 28
AcroBikeTransition_TurnJump e5990 e 28
AcroBikeTransition_WheelieHoppingMoving e58ac 74 28
AcroBikeTransition_WheelieHoppingStanding e5870 3c 28
AcroBikeTransition_WheelieIdle e5834 3c 28
AcroBikeTransition_WheelieLoweringMoving e5ac0 78 28
AcroBikeTransition_WheelieMoving e59a0 8e 28
AcroBikeTransition_WheelieRisingMoving e5a30 8e 28
AcroBikeTransition_WheelieToNormal e57f8 3c 28
AcroBike_GetJumpDirection e5c2c 50 28
AcroBike_TryHistoryUpdate e5b60 68 28
ActivatePerStepCallback 6955c 48
AddBagItem a9424 112
AddBirchSpeechObjects b2cc 120 128
AddCameraObject 5c288 44
AddCoins 11a840 58
AddDecoration 13402c 48
AddDecorationIconObjectFromObjectEvent ff780 11c
AddHatchedMonToParty 429ec bc 59
AddMoney b79b8 28
AddPCItem a9760 94
AddPointillismPoints fd1c8 1d2
AddPseudoObjectEvent 5b394 80
AddSelectIconToRegisteredItem a413c 28 116
AddSpriteIndex 75944 2e 6
AddSpriteToOamBuffer 273c 6c
AddSpritesToOamBuffer b44 98 204
AddStartMenuAction 70fec 1c 205
AddSubspritesToOamBuffer 27a8 204
AddTextCharacter b7174 24 141
AddTextColorCtrlCode 10a410 1c
AddToCursorX 3cc8 3a 214
AddToCursorY 3d04 2c 214
AdjustFriendship 3fcd4 19c
AdjustSecretPowerSpritePixelOffsets c6280 42 92
AdjustSelectedDriverParam bacdc 80
AdvanceClock 10aefc 9a 236
AdvancePlayhead 11a15c 6c
AffineAnimCmd_end 1bec 3c 204
AffineAnimCmd_frame 1c28 38 204
AffineAnimCmd_jump 1ba0 4c 204
AffineAnimCmd_loop 1a94 34 204
AffineAnimDelay 1a60 32 204
AffineAnimStateReset 1d58 28 204
AffineAnimStateRestartAnim 1d14 1c 204
AffineAnimStateStartAnim 1d30 28 204
AgbMain 24c f4
AlignFishingAnimationFrames 5a958 fc 73
AlignInt1 4988 be
AlignInt1InMenuWindow 72c18 30
AlignInt2 4a48 dc
AlignInt2InMenuWindow 72c48 30
AlignString 4b24 a8
AlignStringInMenuWindow 72c78 30
AllMonsFainted c56a8 34 74
AllocOamMatrix 2160 38
AllocPaintingResources 106f4c 20 44
AllocSpritePalette 2690 30
AllocSpriteTileRange 2524 48 204
AllocSpriteTiles 1084 11c 204
AllocTilesForSpriteSheet 2318 2c
AllocTilesForSpriteSheets 2344 2a
AlterEggSpeciesWithIncenseItem 41e8c 60 52
AnimAuroraRings d33b4 98
AnimBasicFistOrFoot d90a4 50
AnimBoneHitProjectile e1004 74 104
AnimBonemerangProjectile e0f1c 68 104
AnimBonemerangProjectileEnd e0fe8 1a 104
AnimBonemerangProjectileStep e0f84 64 104
AnimBubbleEffect d9f88 68
AnimBubbleEffectStep d9ff0 42 154
AnimCmd_end 1780 16 204
AnimCmd_frame 16d4 ac 204
AnimCmd_jump 1798 c8 204
AnimCmd_loop 1860 1e 204
AnimConfusionDuck e1cb4 6c 143
AnimConfusionDuckStep e1d20 64 143
AnimCuttingSlice cc914 a8
AnimDigDirtMound e17cc 98 104
AnimDirtParticleAcrossScreen dd3ac e4
AnimDirtScatter e1078 90 104
AnimEmberFlare d51a8 68
AnimFallingFeather da4d8 218 97
AnimFireCross d5374 40
AnimFireRing d522c 28
AnimFireRingStep1 d5254 58 84
AnimFireRingStep2 d52ac 78 84
AnimFireRingStep3 d5324 22 84
AnimFissureDirtPlumeParticle e1728 88 104
AnimFissureDirtPlumeParticleStep e17b0 1a 104
AnimFlickerIceEffectParticle d7a28 3a 113
AnimGrowAuroraRings d344c 44 3
AnimHailBegin d8d1c e4 113
AnimHailContinue d8e00 4c 113
AnimIceBallParticle d8f74 4c 113
AnimIceBeamParticle d792c 88 113
AnimIceEffectParticle d79b4 74 113
AnimIcePunchSwirlingParticle d78ec 40 113
AnimKnockOffStrike 132370 70
AnimKnockOffStrikeStep 132318 58 7
AnimLeechSeed cab18 70
AnimLeechSeedSprouts cabc0 38 188
AnimLeechSeedStep cab88 38 188
AnimMissileArc dccfc 7c
AnimMissileArcStep dcd78 c8 33
AnimMoveParticleBeyondTarget d7cd4 144 113
AnimMovePowderParticle ca710 58
AnimMovePowderParticleStep ca768 48 164
AnimMoveTwisterParticle cb144 60
AnimMoveTwisterParticleStep cb1a4 b8 119
AnimMudSportDirt e1108 90 104
AnimMudSportDirtFalling e11d4 6e 104
AnimMudSportDirtRising e1198 3a 104
AnimOrbitFast d26a4 60
AnimOrbitFastStep d2704 dc 109
AnimOrbitScatter d27e0 54
AnimOrbitScatterStep d2834 48 109
AnimRaiseSprite dd490 44
AnimRecycle 1323e0 50
AnimRecycleStep 132430 f8 7
AnimShadowBallStep ddfe8 114 102
AnimSimplePaletteBlend e1d84 40 143
AnimSimplePaletteBlendStep e1e0c 20 143
AnimSliceStep ccb00 6c 198
AnimSonicBoomProjectile cf6dc 104
AnimSpinningKickOrPunch d943c 38
AnimSpinningKickOrPunchFinish d9474 34 81
AnimStompFoot d94a8 24
AnimStompFootEnd d9524 1c 81
AnimStompFootStep d94cc 58 81
AnimSwirlingFogAnim d8048 96 113
AnimSwirlingSnowball_End d7c8c 48 113
AnimSwirlingSnowball_Step1 d7a64 13c 113
AnimSwirlingSnowball_Step2 d7ba0 68 113
AnimSwirlingSnowball_Step3 d7c08 84 113
AnimTask_BlendInterfaceColor d6080 34
AnimTask_BlendMonInAndOut 79794 5c
AnimTask_BlendMonInAndOutSetup 797f0 28
AnimTask_BlendMonInAndOutStep 79818 96
AnimTask_BlendSpriteColor e2c60 2c
AnimTask_BlendSpriteColor_Step1 e2c8c 44 143
AnimTask_BlendSpriteColor_Step2 e2cd0 a8 143
AnimTask_CountIceBallThrows d8fc0 30
AnimTask_CreateSurfWave d38bc 2a4
AnimTask_GetBattleEnvironment e4008 20
AnimTask_GetReturnPowerLevel 1318f0 54
AnimTask_GetWeather 132528 52
AnimTask_Hail1 d8adc 1c
AnimTask_Hail2 d8af8 ae 113
AnimTask_Haze1 d80e0 100
AnimTask_Haze2 d81e0 200 113
AnimTask_LoadMistTiles d8414 108
AnimTask_Minimize d0488 58
AnimTask_Minimize_Step d04e0 134 191
AnimTask_OverlayFogTiles d851c 1e4 113
AnimTask_RolePlaySilhouette 12efc8 270
AnimTask_RolePlaySilhouetteStep1 12f238 58 7
AnimTask_RotateMonPalette1 d3490 44
AnimTask_RotateMonPalette2 d34d4 80 3
AnimTask_ScaleMonAndRestore a8d34 58
AnimTask_ScaleMonAndRestoreStep a8d8c 76 8
AnimTask_ShakeAndSinkMon a8314 60
AnimTask_ShakeAndSinkMonStep a8374 94 8
AnimTask_ShakeMon a7e7c 74
AnimTask_ShakeMon2 a7fa0 ec
AnimTask_ShakeMon2Step a808c c6 8
AnimTask_ShakeMonInPlace a8154 84
AnimTask_ShakeMonInPlaceStep a81d8 13a 8
AnimTask_ShakeMonStep a7ef0 b0 8
AnimTask_SlackOffSquish 13257c 48
AnimTask_SlackOffSquishStep 1325c4 98 7
AnimTask_SnatchOpposingMonMove 131944 574
AnimTask_SnatchPartnerMove 131ffc 1a0
AnimTask_Splash d074c 60
AnimTask_SplashStep d07ac 11c 203
AnimTask_SwayMon a8b88 84
AnimTask_SwayMonStep a8c0c 128 8
AnimTask_TeeterDanceMovement 13219c 78
AnimTask_TeeterDanceMovementStep 132214 104 7
AnimTask_TranslateMonElliptical a8408 80
AnimTask_TranslateMonEllipticalRespectSide a8500 30
AnimTask_WindUpLunge a8920 94
AnimTask_WindUpLungePart1 a89b4 64 8
AnimTask_WindUpLungePart2 a8a18 68 8
AnimThrowIceBall d8ee0 30 113
AnimThrowMistBall d83e0 34 113
AnimTranslateLinearSingleSineWave cafd0 cc
AnimTranslateLinearSingleSineWaveStep cb09c a6 119
AnimTranslateStinger dcbcc 130
AnimWaveFromCenterOfTarget d7e88 86 113
AnimWiggleParticleTowardsTarget d7e18 70 113
AnimateAudience b1ddc 20
AnimateBallOpenParticles 14086c c4
AnimateSliderHearts b25e4 e4
AnimateSprite 14fc 48
AnimateSprites 794 4c
AppendBattleTowerBannedSpeciesName 1350e0 120
AppendGenderSymbol 425c4 50 52
AppendMonGenderSymbol 42614 1c 52
AppendToList 71c40 e
ApplyAffineAnimFrame 1f18 3e 204
ApplyAffineAnimFrameAbsolute 1d80 24 204
ApplyAffineAnimFrameRelativeAndUpdateMatrix 1dfc 98 204
ApplyCleanseTagEncounterRateMod 85640 28 239
ApplyColors_ShadowedFont 3bcc d2 214
ApplyColors_UnshadowedFont 3b30 9a 214
ApplyCurrentWarp 53270 44 148
ApplyDaycareExperience 4151c 54 52
ApplyDroughtGammaShiftWithBlend 7d304 120 78
ApplyFluteEncounterRateMod 85600 40 239
ApplyFogBlend 7d424 11a 78
ApplyGammaShift 7cebc 300 78
ApplyGammaShiftWithBlend 7d1bc 148 78
ApplyImageEffect_BlackAndWhite fccbc 98
ApplyImageEffect_BlackOutline fcd54 150
ApplyImageEffect_Blur fcb5c bc
ApplyImageEffect_BlurDown fd114 b4
ApplyImageEffect_BlurRight fd06c a8
ApplyImageEffect_Grayscale fcac4 98
ApplyImageEffect_Invert fcea4 98
ApplyImageEffect_PersonalityColor fcc18 a4
ApplyImageEffect_Pointillism fcaa4 20
ApplyImageEffect_RedChannelGrayscale fc92c b8
ApplyImageEffect_RedChannelGrayscaleHighlight fc9e4 c0
ApplyImageEffect_Shimmer fcf3c 130
ApplyImageProcessingEffects fc7a0 18c
ApplyImageProcessingQuantization fda18 ca
ApplyNextTurnOrder b159c 134
ApplyPlayerChosenFrameToBattleMenu d74c 6c
ApplyWeatherGammaShiftToPal 7d874 20
ArcTan2 1e0770 4
ArcTan2Neg 790f4 18
ArcTan2_ 790dc 16 172
AreAllMovesUnusable 15c90 cc
AreMovesContestCombo b7d24 66
ArePlayerFieldControlsLocked 6554c c
AreStatsRaised 3665c 48 5
AreZCoordsCompatible 63e2c 20
Ash_Finish 7f934 68
Ash_InitAll 7f858 30
Ash_InitVars 7f7f8 60
Ash_Main 7f888 aa
AtkCanceller_UnableToUseMove 17718 900
AttacksThisTurn 283b4 6a 20
AwardBattleTowerRibbons 135e50 98
BGMusicStopped 54038 e
BardSing f7fb0 1d4 131
BasicInitMenuWindow 71e30 24
BattleAICmd_call 1096dc 30 4
BattleAICmd_count_alive_pokemon 108534 fc 4
BattleAICmd_end 10972c 20 4
BattleAICmd_flee 1093b8 10 4
BattleAICmd_get_ability 108670 130 4
BattleAICmd_get_considered_move 108630 18 4
BattleAICmd_get_considered_move_effect 108648 28 4
BattleAICmd_get_gender 1094b8 54 4
BattleAICmd_get_highest_possible_damage 1087a0 ec 4
BattleAICmd_get_hold_effect 10943c 7c 4
BattleAICmd_get_move 1083d4 50 4
BattleAICmd_get_move_effect_from_result 109654 28 4
BattleAICmd_get_move_power 1081cc 28 4
BattleAICmd_get_move_power_from_result 10962c 28 4
BattleAICmd_get_move_type_from_result 109604 28 4
BattleAICmd_get_protect_count 10967c 48 4
BattleAICmd_get_stockpile_count 109554 48 4
BattleAICmd_get_turn_count 1080d0 20 4
BattleAICmd_get_type 1080f0 dc 4
BattleAICmd_get_used_item 1095c0 44 4
BattleAICmd_get_weather 108aec 5c 4
BattleAICmd_if_arg_equal 108424 38 4
BattleAICmd_if_arg_not_equal 10845c 38 4
BattleAICmd_if_can_faint 108d78 ec 4
BattleAICmd_if_cant_faint 108e64 d8 4
BattleAICmd_if_damage_bonus 10888c ce 4
BattleAICmd_if_dont_have_move 109010 d2 4
BattleAICmd_if_effect 108b48 48 4
BattleAICmd_if_encored 109330 86 4
BattleAICmd_if_equal 107c20 38 4
BattleAICmd_if_equal_32 107d30 4e 4
BattleAICmd_if_has_move 108f3c d2 4
BattleAICmd_if_hp_equal 107738 66 4
BattleAICmd_if_hp_less_than 107668 66 4
BattleAICmd_if_hp_more_than 1076d0 66 4
BattleAICmd_if_hp_not_equal 1077a0 66 4
BattleAICmd_if_in_bytes 107e50 64 4
BattleAICmd_if_in_words 107f1c 68 4
BattleAICmd_if_last_move_did_damage 1092a8 86 4
BattleAICmd_if_less_than 107bb0 38 4
BattleAICmd_if_less_than_32 107c90 4e 4
BattleAICmd_if_level_compare 10974c d6 4
BattleAICmd_if_more_than 107be8 38 4
BattleAICmd_if_more_than_32 107ce0 4e 4
BattleAICmd_if_move 107dd0 40 4
BattleAICmd_if_move_effect 1090e4 f0 4
BattleAICmd_if_not_effect 108b90 48 4
BattleAICmd_if_not_equal 107c58 38 4
BattleAICmd_if_not_equal_32 107d80 4e 4
BattleAICmd_if_not_in_bytes 107eb4 66 4
BattleAICmd_if_not_in_words 107f84 6a 4
BattleAICmd_if_not_move 107e10 40 4
BattleAICmd_if_not_move_effect 1091d4 d4 4
BattleAICmd_if_not_status 10787c 74 4
BattleAICmd_if_not_status2 107964 74 4
BattleAICmd_if_not_status3 107a48 70 4
BattleAICmd_if_not_status4 107b34 7c 4
BattleAICmd_if_not_taunted 109874 50 4
BattleAICmd_if_random_100 1093c8 64 4
BattleAICmd_if_random_equal 1075ac 40 4
BattleAICmd_if_random_greater_than 10756c 40 4
BattleAICmd_if_random_less_than 10752c 40 4
BattleAICmd_if_random_not_equal 1075ec 40 4
BattleAICmd_if_stat_level_equal 108ca8 68 4
BattleAICmd_if_stat_level_less_than 108bd8 68 4
BattleAICmd_if_stat_level_more_than 108c40 68 4
BattleAICmd_if_stat_level_not_equal 108d10 68 4
BattleAICmd_if_status 107808 74 4
BattleAICmd_if_status2 1078f0 74 4
BattleAICmd_if_status3 1079d8 70 4
BattleAICmd_if_status4 107ab8 7c 4
BattleAICmd_if_status_in_party 108964 c4 4
BattleAICmd_if_status_not_in_party 108a28 c4 4
BattleAICmd_if_taunted 109824 50 4
BattleAICmd_if_user_can_damage 107ff0 6e 4
BattleAICmd_if_user_cant_damage 108060 6e 4
BattleAICmd_if_would_go_first 108494 4c 4
BattleAICmd_if_would_not_go_first 1084e0 4c 4
BattleAICmd_is_double_battle 10959c 24 4
BattleAICmd_is_first_turn 10950c 48 4
BattleAICmd_is_most_powerful_move 1081f4 1e0 4
BattleAICmd_jump 10970c 20 4
BattleAICmd_nullsub_2A 10852c 2 4
BattleAICmd_nullsub_2B 108530 2 4
BattleAICmd_nullsub_32 10895c 2 4
BattleAICmd_nullsub_33 108960 2 4
BattleAICmd_nullsub_52 1096c4 2 4
BattleAICmd_nullsub_53 1096c8 2 4
BattleAICmd_nullsub_54 1096cc 2 4
BattleAICmd_nullsub_55 1096d0 2 4
BattleAICmd_nullsub_56 1096d4 2 4
BattleAICmd_nullsub_57 1096d8 2 4
BattleAICmd_score 10762c 3c 4
BattleAICmd_watch 10942c 10 4
BattleAI_DoAIProcessing 107374 e8
BattleAI_GetAIActionToUse 1072a8 cc
BattleAI_HandleItemUseBeforeAISetup 1070d4 88
BattleAI_SetupAIData 10715c 14c
BattleAnimAdjustPanning 76f9c fa
BattleAnimAdjustPanning2 77098 70
BattleBeginFirstTurn 11b00 2c8
BattleControllerDummy 2bf70 2
BattleIntroTask_80E4C34 e4c34 294 16
BattleIntroTask_FadeScenery e46cc 2f4 16
BattleIntroTask_ScrollAndFadeScenery e49c0 274 16
BattleIntroTask_ScrollScenery e448c 240 16
BattleLoadOpponentMonSprite 31794 168
BattleLoadPlayerMonSprite 318fc 168
BattleLoadSubstituteSprite 32350 114
BattleMainCB1 10824 50
BattleMainCB2 f808 20
BattlePrepIntroSlide 11334 50 17
BattleScene_DrawChoices 8bd6c 40 145
BattleScene_ProcessInput 8bd4c 20 145
BattleScriptExecute 19fb0 3c
BattleScriptPop 15870 24
BattleScriptPush 1582c 20
BattleScriptPushCursor 1584c 24
BattleScriptPushCursorAndCallback 19fec 40
BattleSetup_ConfigureTrainerBattle 823c8 f8
BattleSetup_GetBattleTowerBattleTransition 82138 30
BattleSetup_GetEnvironmentId 81d3c 152
BattleSetup_GetScriptAddrAfterBattle 826e8 18
BattleSetup_GetTrainerPostBattleScript 82700 18
BattleSetup_StartRematchBattle 826b0 28
BattleSetup_StartRoamerBattle 81a5c 48
BattleSetup_StartScriptedWildBattle 81b3c 3c
BattleSetup_StartTrainerBattle 825e4 28
BattleSetup_StartWildBattle 81a00 18
BattleStartClearSetData 10874 314
BattleStopLowHpSound 325b8 4c
BattleStringExpandPlaceholders 120ffc a6a
BattleStringExpandPlaceholdersToDisplayedString 120f88 10
BattleStyle_DrawChoices 8bdcc 40 145
BattleStyle_ProcessInput 8bdac 20 145
BattleTowerEntryMenuCallback_Enter 122694 94 37
BattleTowerEntryMenuCallback_Exit 122838 1a 37
BattleTowerEntryMenuCallback_NoEntry 122770 8c 37
BattleTowerEntryMenuCallback_Summary 12265c 38 37
BattleTowerUtil 1358a4 170
BattleTower_SoftReset 135c38 a
BattleTransition_Start 11aad8 e
BattleTransition_StartOnField 11aabc 1c
BattleTurnPassed 11e8c 19c
BedroomPC 139c74 40
BeginAffineAnim 194c 7c 204
BeginAffineAnimLoop 1ac8 3c 204
BeginAnim 1544 f0 204
BeginAnimLoop 1880 38 204
BeginEvolutionScene 111924 60
BeginFastPaletteFade 744b4 24
BeginFastPaletteFadeInternal 744d8 84 149
BeginHardwarePaletteFade 748d4 9c
BeginNormalPaletteFade 73bf8 148
BerryTagScreen_814625C 14625c 2c
BerryTreeGetNumStagesWatered b4d4c 3c 24
BerryTreeGrow b4abc a8 24
BerryTreeTimeUpdate b4b64 a0
BerryTypeToItemId b4cec 26 24
Berry_FadeAndGoToBerryBagMenu b4ee4 10
BgAffineSet 1e0774 4
BikeClearState e5fcc 44
Bike_CheckCollisionTryAdvanceCollisionCount e5da0 4a 28
Bike_DPadToDirection e5cf4 3e 28
Bike_HandleBumpySlopeJump e6084 54
Bike_SetBikeStill e6024 10 28
Bike_TryAcroBikeHistoryUpdate e5b38 28
Bike_TryAdvanceCyclingRoadCollisions e5e4c 24 28
Bike_UpdateABStartSelectHistory e5cb8 3c 28
Bike_UpdateBikeCounterSpeed e6010 14
Bike_UpdateDirTimerHistory e5c7c 3c 28
BlendAudienceBackground b1ea8 a4
BlendPalette 41210 a0
BlendPalettes 74b40 3a
BlendPalettesUnfaded 74b7c 34
BlenderDebug_CalculatePokeblock 50744 1c 25
BlenderDebug_PrintBerryData 52530 28c 25
Blender_CalculatePokeblock 50520 224 25
Blender_ControlHitPitch 4e290 2c 25
Blender_CopyBerryData 4e844 3e 25
Blender_GetPokeblockColor 502f8 1f6
Blender_PrintBlendingRanking 52228 292 25
Blender_PrintBlendingResults 51c58 3c4
Blender_PrintMadePokeblockString 5201c b0 25
Blender_SetBankBerryData 516c4 34
Blender_SetPlayerNamesLocal 4e884 10c 25
Blender_SortBasedOnPoints 520cc 58 25
Blender_SortScores 52124 104 25
Blender_TrySettingRecord 51c24 34
BlinkContestantBox b0bc4 96
BootTMHM c9ee4 2c 117
BoxMonRestorePP 40b28 62
BoxSetMosaic 98044 4c
BrailleWait_CheckButtonPress 147774 3e
BtlController_EmitBallThrowAnim c808 20
BtlController_EmitBattleAnimation d1ac 2c
BtlController_EmitChooseAction cb58 2c
BtlController_EmitChooseItem cbe0 34
BtlController_EmitChooseMove cba4 3c
BtlController_EmitChoosePokemon cc14 3c
BtlController_EmitChosenMonReturnValue cef8 38
BtlController_EmitCmd23 cc50 20
BtlController_EmitCmd32 ce84 48
BtlController_EmitCmd37 cf88 20
BtlController_EmitCmd38 cfa8 20
BtlController_EmitCmd39 cfc8 20
BtlController_EmitCmd40 cfe8 20
BtlController_EmitCmd42 d028 20
BtlController_EmitCmd55 d218 20
BtlController_EmitDMA3Transfer cdd4 68
BtlController_EmitDataTransfer cd8c 48
BtlController_EmitDrawPartyStatusSummary d100 48
BtlController_EmitDrawTrainerPic c748 20
BtlController_EmitEndBounceEffect d168 20
BtlController_EmitExpUpdate cca8 34
BtlController_EmitFaintAnimation c7a8 20
BtlController_EmitFaintingCry d0a0 20
BtlController_EmitGetMonData c618 24
BtlController_EmitGetRawMonData c63c 28
BtlController_EmitHealthBarUpdate cc70 38
BtlController_EmitHidePartyStatusSummary d148 20
BtlController_EmitHitAnimation d008 20
BtlController_EmitIntroSlide d0c0 20
BtlController_EmitIntroTrainerBallThrow d0e0 20
BtlController_EmitLinkStandbyMsg d1d8 20
BtlController_EmitLoadMonSprite c6e4 20
BtlController_EmitMoveAnimation c870 d8
BtlController_EmitOneReturnValue cf30 2c
BtlController_EmitOneReturnValue_Duplicate cf5c 2c
BtlController_EmitPaletteFade c7c8 20
BtlController_EmitPause c828 48
BtlController_EmitPlayBGM ce3c 48
BtlController_EmitPlayFanfareOrBGM d074 2c
BtlController_EmitPlaySE d048 2c
BtlController_EmitPrintSelectionString ca68 f0
BtlController_EmitPrintString c948 120
BtlController_EmitResetActionMoveSelection d1f8 20
BtlController_EmitReturnMonToBall c728 20
BtlController_EmitSetMonData c664 40
BtlController_EmitSetRawMonData c6a4 40
BtlController_EmitSpriteInvisibility d188 24
BtlController_EmitStatusAnimation cd30 3c
BtlController_EmitStatusIconUpdate ccdc 54
BtlController_EmitStatusXor cd6c 20
BtlController_EmitSuccessBallThrowAnim c7e8 20
BtlController_EmitSwitchInAnim c704 24
BtlController_EmitTrainerSlide c768 20
BtlController_EmitTrainerSlideBack c788 20
BtlController_EmitTwoReturnValues cecc 2c
BtlController_EmitUnknownYesNoBox cb84 20
Bubbles_Finish 8056c 1a
Bubbles_InitAll 804c8 30
Bubbles_InitVars 80474 54
Bubbles_Main 804f8 74
BufferContestTrainerAndMonNames c4c64 12
BufferCryWaveformSegment 11a0c0 64
BufferEReaderTrainerName 10f414 10
BufferLottoTicketNumber 10f9ac a8
BufferPartyVsScreenHealth_AtStart e9ec c0
BufferRandomHobbyOrLifestyleString eb83c 2c
BufferSecretBaseOwnerName bc224 44
BufferStreakTrainerText 10fdac 70
BufferStringBattle 120aa8 4e0
BufferTrendyPhraseString fa5bc 28
BuildAreaGlowTilemap 110c34 450 159
BuildEggMoveset 41bc4 2a0
BuildGammaShiftTables 7cb10 114 78
BuildOamBuffer 7e0 4c
BuildSendCmd 79a8 16c 120
BuildSpritePriorities 8f0 40 204
BuildStartMenuActions 70fb8 32 205
BuildStartMenuActions_Link 710a4 3c 205
BuildStartMenuActions_Normal 71008 6c 205
BuildStartMenuActions_SafariZone 71074 30 205
ButtonMode_DrawChoices 8bfd8 54 145
ButtonMode_ProcessInput 8bf94 44 145
BuyMenuDisplayMessage a67f4 48 116
BuyMenuDrawGraphics b3108 138 193
BuyMenuDrawMapMetatile b3330 a0 193
BuyMenuDrawMapMetatileLayer b3308 26 193
BuyMenuDrawMapPartialMetatile b33d0 50 193
BuyMenuDrawTextboxBG b3720 44 193
BuyMenuDrawTextboxBG_Old b32ec 1c 193
BuyMenuDrawTextboxBG_Restore b379c 50 193
BuyMenuFreeMemory f9828 c
BuyMenuPrintItemQuantityAndPrice a6798 5c 116
C2_NamingScreen b59fc a4 141
CB1_Overworld 54354 20 148
CB2_BeginEvolutionScene 111894 e 65
CB2_ChooseBerry a68cc 24
CB2_ChooseStarter 109e80 29c
CB2_ClearSaveDataScreen 148954 e 38
CB2_ContestPainting 106668 a
CB2_ContinueSavedGame 54738 74
CB2_CrashIdle ab184 28 46
CB2_Credits 14395c 74 47
CB2_EggHatch_0 42ce8 2a0 59
CB2_EggHatch_1 4300c 2d8 59
CB2_EndFirstBattle 82228 14 21
CB2_EndScriptedWildBattle 81cec 50 21
CB2_EndTrainerBattle 8260c 50
CB2_EndTrainerEyeRematchBattle 8265c 54
CB2_EndWildBattle 81c8c 60 21
CB2_EvolutionSceneLoadGraphics 111c90 1f0 65
CB2_EvolutionSceneUpdate 112270 20 65
CB2_FadeAndReturnToTitleScreen 1471a4 48 178
CB2_FieldInitRegionMap 13eee4 cc
CB2_FieldRegionMap 13efc4 16
CB2_FieldShowRegionMap 10e404 10
CB2_FlyRegionMap fc228 1c
CB2_GameplayCannotBeContinued 147154 50 178
CB2_GiveStarter 82188 50 21
CB2_GoToClearSaveDataScreen 7c7b0 1c 222
CB2_GoToCopyrightScreen 7c794 1c 222
CB2_GoToMainMenu 7c778 1c 222
CB2_GoToResetRtcScreen 7c7cc 1c 222
CB2_HallOfFame 141e4c 16 107
CB2_HandleStartBattle ec9c 390
CB2_HandleStartMultiBattle f298 570
CB2_HoldContestPainting 106808 e 44
CB2_InitBattle e7c4 34
CB2_InitBattleInternal e7f8 1f4
CB2_InitClearSaveDataScreen 148800 1c
CB2_InitCopyrightScreenAfterBootup 13ba44 44
CB2_InitCopyrightScreenAfterTitleScreen 13ba88 a
CB2_InitFlyRegionMap fc074 1a0
CB2_InitMainMenu 96f0 c
CB2_InitMainMenuFromOptions 96fc c 128
CB2_InitMoveTutorMenu 1326d8 cc 137
CB2_InitMysteryEventMenu 146930 7c
CB2_InitOptionMenu 8b63c 388
CB2_InitPartyMenu 6b464 48 150
CB2_InitPokedex 8c27c 2c4
CB2_InitResetRtcScreen 6aadc d8
CB2_InitTitleScreen 7c0f4 364
CB2_LinkError 85bc 94
CB2_LinkTest 75cc 24 120
CB2_LoadMap 544e0 30
CB2_LoadMap2 54510 28
CB2_MainMenu 96c4 16 128
CB2_MoveTutorMenu 132870 78 137
CB2_MysteryEventMenu 1469e4 42c 139
CB2_NewGame 54414 58
CB2_Overworld 543a8 2c 148
CB2_OverworldBasic 5439c a
CB2_PartyMenuMain 6aee0 58
CB2_PokeblockFeed 147890 16 157
CB2_PreparePokeblockFeedScene 147adc 26
CB2_PrintErrorMessage 8650 6c
CB2_QuitContestPainting 106818 14 44
CB2_ResetRtcScreen 6abb4 16
CB2_ReshowBattleScreenAfterMenu 7adac 2c4 168
CB2_ReturnToField 545e8 2c
CB2_ReturnToFieldContinueScriptPlayMapMusic 546d8 1c
CB2_ReturnToFieldLink 54638 28
CB2_ReturnToFieldLocal 54614 24
CB2_ReturnToMoveTutorMenu 1327a4 cc
CB2_ReturnToTitleScreen 1471ec 2c 178
CB2_SaveFailedScreen 146e50 1f8 178
CB2_ShowDiploma 145d88 174
CB2_SlotMachineLoop 101954 16 199
CB2_SlotMachineSetup 1018b8 9c 199
CB2_SoftReset 148b34 58 38
CB2_SoundCheckMenu ba0a8 16
CB2_StartContest ab47c 158
CB2_StartCreditsSequence 1439d0 168
CB2_StartFirstBattle 821d8 50 21
CB2_StartSoundCheckMenu ba0ec 16c
CB2_StartWallClock 10a8f4 120
CB2_TradeEvolutionSceneLoadGraphics 111e80 264 65
CB2_TradeEvolutionSceneUpdate 112290 24 65
CB2_UnusedPokedexAreaScreen 110680 15c 159
CB2_ViewWallClock 10aa14 128
CB2_WhiteOut 5446c 74
CB2_WipeSave 147048 10c 178
CB_ContinueNewGameSpeechPart2 b060 1dc 128
CableCar 123218 2c
CableCarMainCallback_Run 123724 1a 35
CableCarMainCallback_Setup 123244 4e0 35
CableCarTask1 1231ec 2c 35
CableCarUtil_CopyWrapped 124f08 8a
CableCarUtil_FillWrapped 124e7c 8a
CableCarVblankCallback 123c40 74 35
CableCarWarp 10e30c 3c
CalcBarFilledPixels 4602c 9a 15
CalcBerryYield b4df4 2c 24
CalcBerryYieldInternal b4da0 52 24
CalcCRC16 41174 58
CalcCRC16WithTable 411cc 44
CalcCenterToCornerVec 1040 44
CalcChecksum 12616c 20 140
CalcMinHandDelta 10ae84 26 236
CalcNewMinHandAngle 10aeac 50 236
CalcRecordMixingGiftChecksum 126268 20 140
CalcTimeDifference 9624 66
CalcWordPitch 14a2b8 18
CalcZoomScrollParams fb170 c8 167
CalculateAppealMoveImpact b114c 2a0
CalculateBaseDamage 3ba2c 91c
CalculateBoxMonChecksum 3b124 92
CalculateChecksum 125c10 2c 177
CalculateContestantRound1Points ae770 bc
CalculateEnemyPartyCount 3da5c 44
CalculateFinalScores af668 1e
CalculateMonAverageEVs bc298 68 187
CalculateMonStats 3b1b8 2fc
CalculatePPWithBonus 3ddec 48
CalculatePanIncrement 77130 3e
CalculatePlayerPartyCount 3da18 44
CalculateRamScriptChecksum 65764 28 183
CalculateRound1Points ae82c 2c
CalculateTotalPointsForContestant af630 38
CallCallbacks 3a8 24 127
CameraMove 56998 d0
CameraObjectGetFollowedObjectId 5c418 18
CameraObjectReset1 5c3e0 1c
CameraObjectReset2 5c430 e
CameraObjectSetFollowedObjectId 5c3fc 1a
CameraObject_0 5c2f4 3c 63
CameraObject_1 5c330 38 63
CameraObject_2 5c368 30 63
CameraPanningCB_PanAhead 582dc a0 66
CameraUpdate 580f0 110
CameraUpdateCallback 58070 28 66
CanBikeFaceDirOnMetatile e5e70 4e 28
CanCameraMoveInDirection 568d8 44
CanFish c92e4 92
CanMonLearnTMHM 40374 58
CanMonParticipateInContest ae47c 98
CanResetRTC 691e0 32
CanRunFromBattle 12028 230
CanUnnerveContestant b90c0 60 41
CanUseEscapeRopeOnCurrMap ca1c8 1a
CancelMultiTurnMoves 155f4 6c
CantUseSoftboiled 133eb8 40 93
CastformDataTypeChange 181b8 16c
CaveEntranceSpriteCallback1 c644c 1c 92
CaveEntranceSpriteCallback2 c6468 30 92
CaveEntranceSpriteCallbackEnd c6498 10 92
CgbModVol 1de984 7c
CgbOscOff 1de934 50
CgbSound 1dea00 44a
ChangeBattleTowerPartyMenuSelection 6c65c 238
ChangeDefaultPartyMenuSelection 6c1e8 12c 150
ChangeDoubleBattlePartyMenuSelection 6c314 180 150
ChangeLinkDoubleBattlePartyMenuSelection 6c494 1c8
ChangePartyMenuSelection 6bf78 270
ChangePartyMenuSwitchPokemonSelection 6cb00 78
ChangePocket a3b04 c0 116
ChangePokemonNickname bf9f8 bc
ChangePokemonNickname_CB bfab4 2c
ChangeSpriteAffineAnim 2068 38
ChangeSpriteAffineAnimIfDifferent 20a0 34
ChangeStatBuffs 25e20 4a4 20
ChangeToBattleMoveInfoWindow 133248 58 137
ChangeToContestMoveInfoWindow 1330e8 58 137
ChangeWeather 7c91c 6c
CheckBagHasItem a92d4 70
CheckBagHasSpace a9344 e0
CheckChangeScene 144454 c0 47
CheckCompatibility 126098 38 140
CheckDecorationInventoryHasSpace 134074 32
CheckErrorStatus 854c 70 120
CheckFeebas 84a44 110 239
CheckFocusPunch_ClearVarsBeforeTurnStarts 137cc 124
CheckForBigMovieOrEmergencyNewsOnTV bfbb0 5e
CheckForFlashMemory 479cc 2c
CheckForObjectEventCollision 58e24 ce
CheckForPlayerAvatarCollision 58db8 6c 73
CheckForRotatingGatePuzzleCollision c80a0 e4
CheckFreePokemonStorageSpace 10f6ec 4c
CheckIfItemIsTMHMOrEvolutionStone c911c 38
CheckLanguageMatch 146914 1c 139
CheckLeadMonBeauty 10ef68 2a
CheckLeadMonCool 10ef3c 2a
CheckLeadMonCute 10ef94 2a
CheckLeadMonSmart 10efc0 2a
CheckLeadMonTough 10efec 2a
CheckMasterOrSlave 8974 2c 120
CheckMatch 1027a0 30 199
CheckMatch_CenterRow 1027d0 70 199
CheckMatch_Diagonals 10290c c8 199
CheckMatch_TopAndBottom 102840 cc 199
CheckMonBattleTowerBanlist 135200 e4 22
CheckMoveLimitations 15a98 1f8
CheckMovementInputAcroBike e5314 2c 28
CheckMovementInputNotOnBike 58ca8 44 73
CheckObjectGraphicsInFrontOfPlayer 10b2d4 54
CheckPCHasItem a9718 46
CheckPartyBattleTowerBanlist 1352e4 178
CheckPartyHasHadPokerus 40178 5e
CheckPartyMonHasHeldItem c5450 4e
CheckPartyPokerus 40110 66
CheckPathBetweenTrainerAndPlayer 84218 ae 225
CheckPlayerHasSecretBase bb63c 30
CheckRelicanthWailord 147478 50
CheckStandardWildEncounter 689b4 4e 67
CheckTrainer 84004 54 225
CheckTrainers 83fbc 46
CheckWonderGuardAndLevitate 1cf3c 28c 20
ChnVolSetAsm 1dda60 30
ChooseAmbientCrySpecies 54168 44 148
ChooseBattleTowerPlayerParty c55b0 18
ChooseMoveUsedParticle 121d1c 58
ChooseNextBattleTowerTrainer 1347f8 204
ChooseSendDaycareMon 42888 1c
ChooseSpecialBattleTowerTrainer 1346f4 104
ChooseTypeOfMoveUsedString 121d74 9c
ChooseWildMonIndex_Fishing 84c94 9c 239
ChooseWildMonIndex_Land 84b84 ba 239
ChooseWildMonIndex_Water 84c40 54 239
ChooseWildMonLevel 84d30 3a 239
CleanUpItemMenuMessage a5c48 54
CleanUpOverworldMessage a5c9c 28
Clear64byte 1de220 14
ClearAllObjectEvents 5aa74 28 63
ClearAllPokeblockFeeders c82d8 14 176
ClearBGMem 29e8 34 214
ClearBGTilemapBuffers f9020 38
ClearBag a3714 2c
ClearBattleAnimationVars 75628 dc
ClearBattleMonForms 40710 18
ClearBattleTowerRecord 135ce8 12 22
ClearBerryTrees b4a90 2c
ClearChain 1de20c 14
ClearContestVars ab398 e4
ClearDailyFlags 690b8 14
ClearDaycareMail 417f4 2e 52
ClearDecorationInventories 133f80 1a
ClearDecorationInventory 133f4c 34
ClearEReaderTrainer 1360ac 12 22
ClearEnigmaBerries b4884 24
ClearItemPurchases b4534 1c 193
ClearItemSlots a9684 28
ClearLinkCallback 7b60 c
ClearLinkCallback_2 7b6c c
ClearLinkPlayerObjectEvent 55958 6
ClearLinkPlayerObjectEvents 55960 14
ClearLowestWallpaperTiles 9a14c 70
ClearMailData a2b18 28
ClearMailStruct a2b40 54
ClearModM 1defb8 1e
ClearMonListEntry 8e090 3c 158
ClearMonSprites 8e82c 5c 158
ClearMoveAnimData b28cc 24
ClearObjectEvent 55974 e 148
ClearObjectEvent 5aa54 20 63
ClearObjectEventMovement 5fd1c 1e 63
ClearPartySelection 121e58 20 37
ClearPlayerAvatarInfo 599e4 14
ClearPlayerFieldInput 67ef0 2c
ClearPoisonStepCounter 6894c 14
ClearPokeblock 10c950 44 156
ClearPokeblockFeeder c82bc 1c 176
ClearPokeblocks 10c994 1a
ClearPokedexFlags 52d78 30
ClearPokedexView 8c0cc 1b0 158
ClearPokemonCrySongs 724 24
ClearRamScript 6578c 20
ClearRecordMixingGift 1262c0 24 140
ClearRoamerData 1341f8 14
ClearRoamerLocationData 13420c 34
ClearSav2 52e24 28
ClearSavedMapView 56650 24 80
ClearSecretBase bb4ac e8
ClearSecretBase2Field_9 47a04 c
ClearSecretBase2Field_9_2 47a34 c
ClearSpriteCopyRequests fa0 40 204
ClearSpriteIndex 75974 32 6
ClearTVShowData bd7a8 58
ClearTempFieldEventData 69070 48
ClearTilesetAnimDmas 72dfc 2c 220
ClearTrainerEyeRematchFlag 82ae4 2c
ClearTrainerFlag 825d0 14
ClearVerticalScrollIndicatorPalettes f944c 34
ClearVideoCallbacks f9438 12
ClearWindowTextLines_TextMode0_TextMode1 436c 56 214
ClearWindowTextLines_TextMode2 43c4 94 214
ClipLeft 3d70 dc 214
ClipRight 3e4c f0 214
ClonedMinimizeSprite_Step d0704 48
CloseLink 740c 1c
CloseMenu 71c24 1c
CloseMoneyWindow b7c98 50
ClosePartyPopupMenu 6e7d4 4a
Clouds_Finish 7df54 48
Clouds_InitAll 7dec4 30
Clouds_InitVars 7de78 4c
Clouds_Main 7def4 60
CompactPCItems a982c 58 115
CompactPartySlots 9bd3c 9c
CompareBarboachSize c5c0c 2c
CompareMonSize c5a8c 8e 161
CompareShroomishSize c5bb4 28
CompleteOnBankSpriteCallbackDummy2 137908 38 13
CompleteOnBattlerSpriteCallbackDummy 13741c 38 13
CompleteOnChosenItem 1374fc 3c 13
CompleteOnFinishedAnimation 1374ac 18 13
CompleteOnFinishedBattleAnimation 137940 2c 13
CompleteOnFinishedStatusAnimation 1379e4 2c 13
CompleteOnHealthbarDone 1377b0 70 13
CompleteOnInactiveTextPrinter 137454 18 13
CompletedHoennPokedex 90fc0 32
CompletedNationalPokedex 90ff4 6a
ContestAICmd_check_can_participate 12a0bc 44 40
ContestAICmd_check_combo_finisher 129c40 74 40
ContestAICmd_check_combo_starter 129b44 74 40
ContestAICmd_check_for_exciting_move 12acfc 54 40
ContestAICmd_check_move_has_highest_appeal 1295b8 7e 40
ContestAICmd_check_would_finish_combo 129d3c 5c 40
ContestAICmd_get_condition 129e20 44 40
ContestAICmd_get_contest_type 129244 20 40
ContestAICmd_get_excitement 128c0c 20 40
ContestAICmd_get_move_effect 129434 3c 40
ContestAICmd_get_move_effect_type 1294f0 48 40
ContestAICmd_get_move_excitement 1292e4 40 40
ContestAICmd_get_move_used_count 1299f0 54 40
ContestAICmd_get_turn 128af0 1c 40
ContestAICmd_get_used_combo_starter 129f64 58 40
ContestAICmd_get_user_condition_maybe 128e50 40 40
ContestAICmd_get_user_order 128d2c 24 40
ContestAICmd_get_val_812A188 12a188 3c 40
ContestAICmd_unk_00 128aa8 48 40
ContestAICmd_unk_02 128b0c 40 40
ContestAICmd_unk_03 128b4c 40 40
ContestAICmd_unk_04 128b8c 40 40
ContestAICmd_unk_05 128bcc 40 40
ContestAICmd_unk_07 128c2c 40 40
ContestAICmd_unk_08 128c6c 40 40
ContestAICmd_unk_09 128cac 40 40
ContestAICmd_unk_0A 128cec 40 40
ContestAICmd_unk_0C 128d50 40 40
ContestAICmd_unk_0D 128d90 40 40
ContestAICmd_unk_0E 128dd0 40 40
ContestAICmd_unk_0F 128e10 40 40
ContestAICmd_unk_11 128e90 40 40
ContestAICmd_unk_12 128ed0 40 40
ContestAICmd_unk_13 128f10 40 40
ContestAICmd_unk_14 128f50 40 40
ContestAICmd_unk_15 128f90 2c 40
ContestAICmd_unk_16 128fbc 4a 40
ContestAICmd_unk_17 129008 4a 40
ContestAICmd_unk_18 129054 4a 40
ContestAICmd_unk_19 1290a0 4a 40
ContestAICmd_unk_1A 1290ec 28 40
ContestAICmd_unk_1B 129114 4a 40
ContestAICmd_unk_1C 129160 4a 40
ContestAICmd_unk_1D 1291ac 4a 40
ContestAICmd_unk_1E 1291f8 4a 40
ContestAICmd_unk_20 129264 40 40
ContestAICmd_unk_21 1292a4 40 40
ContestAICmd_unk_23 129324 42 40
ContestAICmd_unk_24 129368 42 40
ContestAICmd_unk_25 1293ac 42 40
ContestAICmd_unk_26 1293f0 42 40
ContestAICmd_unk_28 129470 40 40
ContestAICmd_unk_29 1294b0 40 40
ContestAICmd_unk_2B 129538 40 40
ContestAICmd_unk_2C 129578 40 40
ContestAICmd_unk_2E 129638 44 40
ContestAICmd_unk_2F 12967c 7e 40
ContestAICmd_unk_30 1296fc 44 40
ContestAICmd_unk_31 129740 58 40
ContestAICmd_unk_32 129798 40 40
ContestAICmd_unk_33 1297d8 40 40
ContestAICmd_unk_34 129818 40 40
ContestAICmd_unk_35 129858 40 40
ContestAICmd_unk_36 129898 58 40
ContestAICmd_unk_37 1298f0 40 40
ContestAICmd_unk_38 129930 40 40
ContestAICmd_unk_39 129970 40 40
ContestAICmd_unk_3A 1299b0 40 40
ContestAICmd_unk_3C 129a44 40 40
ContestAICmd_unk_3D 129a84 40 40
ContestAICmd_unk_3E 129ac4 40 40
ContestAICmd_unk_3F 129b04 40 40
ContestAICmd_unk_41 129bb8 44 40
ContestAICmd_unk_42 129bfc 44 40
ContestAICmd_unk_44 129cb4 44 40
ContestAICmd_unk_45 129cf8 44 40
ContestAICmd_unk_47 129d98 44 40
ContestAICmd_unk_48 129ddc 44 40
ContestAICmd_unk_4A 129e64 40 40
ContestAICmd_unk_4B 129ea4 40 40
ContestAICmd_unk_4C 129ee4 40 40
ContestAICmd_unk_4D 129f24 40 40
ContestAICmd_unk_4F 129fbc 40 40
ContestAICmd_unk_50 129ffc 40 40
ContestAICmd_unk_51 12a03c 40 40
ContestAICmd_unk_52 12a07c 40 40
ContestAICmd_unk_54 12a100 44 40
ContestAICmd_unk_55 12a144 44 40
ContestAICmd_unk_57 12a1c4 44 40
ContestAICmd_unk_58 12a208 44 40
ContestAICmd_unk_59 12a24c 48 40
ContestAICmd_unk_5A 12a294 44 40
ContestAICmd_unk_5B 12a2d8 44 40
ContestAICmd_unk_5C 12a31c 44 40
ContestAICmd_unk_5D 12a360 44 40
ContestAICmd_unk_5E 12a3a4 40 40
ContestAICmd_unk_5F 12a3e4 44 40
ContestAICmd_unk_60 12a428 44 40
ContestAICmd_unk_61 12a46c 44 40
ContestAICmd_unk_62 12a4b0 44 40
ContestAICmd_unk_63 12a4f4 44 40
ContestAICmd_unk_64 12a538 40 40
ContestAICmd_unk_65 12a578 40 40
ContestAICmd_unk_66 12a5b8 40 40
ContestAICmd_unk_67 12a5f8 40 40
ContestAICmd_unk_68 12a638 3c 40
ContestAICmd_unk_69 12a674 40 40
ContestAICmd_unk_6A 12a6b4 40 40
ContestAICmd_unk_6B 12a6f4 40 40
ContestAICmd_unk_6C 12a734 40 40
ContestAICmd_unk_6D 12a774 50 40
ContestAICmd_unk_6E 12a7c4 40 40
ContestAICmd_unk_6F 12a804 40 40
ContestAICmd_unk_70 12a844 28 40
ContestAICmd_unk_71 12a86c 2c 40
ContestAICmd_unk_72 12a898 34 40
ContestAICmd_unk_73 12a8cc 30 40
ContestAICmd_unk_74 12a8fc 30 40
ContestAICmd_unk_75 12a92c 4c 40
ContestAICmd_unk_76 12a978 4c 40
ContestAICmd_unk_77 12a9c4 4c 40
ContestAICmd_unk_78 12aa10 4c 40
ContestAICmd_unk_79 12aa5c 4e 40
ContestAICmd_unk_7A 12aaac 4e 40
ContestAICmd_unk_7B 12aafc 4e 40
ContestAICmd_unk_7C 12ab4c 4e 40
ContestAICmd_unk_7D 12ab9c 4a 40
ContestAICmd_unk_7E 12abe8 4a 40
ContestAICmd_unk_7F 12ac34 20 40
ContestAICmd_unk_80 12ac54 30 40
ContestAICmd_unk_81 12ac84 20 40
ContestAICmd_unk_83 12ad50 44 40
ContestAICmd_unk_84 12ad94 44 40
ContestAICmd_unk_85 12add8 6c 40
ContestAICmd_unk_86 12ae44 44 40
ContestAICmd_unk_87 12ae88 44 40
ContestAI_DoAIProcessing 1289ac d0 40
ContestAI_GetActionToUse 128944 68
ContestAI_ResetAI 1288f4 50
ContestClearGeneralTextWindow af138 24
ContestDebugDoPrint b0d7c 16c
ContestDebugTogglePointTotal b0cf4 88
ContestEffect_AffectedByPrevAppeal b8a48 6e 41
ContestEffect_AppealAsGoodAsPrevOne b8740 78 41
ContestEffect_AppealAsGoodAsPrevOnes b86a0 a0 41
ContestEffect_AvoidStartle b7e5c 2c 41
ContestEffect_AvoidStartleOnce b7e34 28 41
ContestEffect_AvoidStartleSlightly b7e88 28 41
ContestEffect_BadlyStartleMonsWithGoodAppeals b8efc 80 41
ContestEffect_BadlyStartlesMonsInGoodCondition b8584 74 41
ContestEffect_BetterIfDiffType b89a4 a4 41
ContestEffect_BetterIfFirst b85f8 54 41
ContestEffect_BetterIfLast b864c 54 41
ContestEffect_BetterIfSameType b88cc d8 41
ContestEffect_BetterWhenAudienceExcited b8f7c 7c 41
ContestEffect_BetterWhenLater b87b8 76 41
ContestEffect_BetterWithGoodCondition b8b10 4a 41
ContestEffect_DontExciteAudience b8ff8 40 41
ContestEffect_ExciteAudienceInAnyContest b8ebc 40 41
ContestEffect_GreatAppealButNoMoreMoves b7dbc 2c 41
ContestEffect_HighlyAppealing b7d8c 2 41
ContestEffect_ImproveConditionPreventNervousness b8ab8 56 41
ContestEffect_JamsOthersButMissOneTurn b81a4 30 41
ContestEffect_MakeFollowingMonNervous b829c 72 41
ContestEffect_MakeFollowingMonsNervous b8310 1e8 41
ContestEffect_MakeScramblingTurnOrderEasier b8db4 2 41
ContestEffect_NextAppealEarlier b8b5c 126 41
ContestEffect_NextAppealLater b8c84 130 41
ContestEffect_QualityDependsOnTiming b8830 9c 41
ContestEffect_RepetitionNotBoring b7de8 4c 41
ContestEffect_ScrambleNextTurnOrder b8db8 104 41
ContestEffect_ShiftJudgeAttention b8070 9c 41
ContestEffect_StartleFrontMon b7edc 60 41
ContestEffect_StartleMonWithJudgesAttention b810c 98 41
ContestEffect_StartleMonsBeautyAppeal b822c 1c 41
ContestEffect_StartleMonsCoolAppeal b8210 1c 41
ContestEffect_StartleMonsCuteAppeal b8248 1c 41
ContestEffect_StartleMonsSameTypeAppeal b81d4 3c 41
ContestEffect_StartleMonsSmartAppeal b8264 1c 41
ContestEffect_StartleMonsToughAppeal b8280 1c 41
ContestEffect_StartlePrevMon2 b7fa0 34 41
ContestEffect_StartlePrevMons b7f3c 64 41
ContestEffect_StartlePrevMons2 b7fd4 9c 41
ContestEffect_UserLessEasilyStartled b7eb0 2c 41
ContestEffect_UserMoreEasilyStartled b7d90 2c 41
ContestEffect_WorsenConditionOfPrevMons b84f8 8c 41
ContestLinkTransfer c4980 44
ContestMainCallback2 abaac 16
ContestPaintingMosaic 106a58 54 44
ContestPrintLinkStandby af860 3c
ContestVBlankCallback abac4 ac
Contest_ClearMoveDescriptionBox aed58 24
Contest_CopyAndConvertNicknameI_Intl c4698 54
Contest_CopyAndConvertTrainerName_Intl c4674 22
Contest_CopyStringWithColor ae598 24
Contest_CreatePlayerMon ae098 300
Contest_GetMoveExcitement b19fc 30
Contest_GetNicknameI_StringVar1 c4740 18
Contest_GetSpeciesNameI_StringVar1 c48f4 20
Contest_GetTrainerNameI_StringVar1 c46ec 54
Contest_InitAllPokemon ae398 e4
Contest_IsMonsTurnDisabled af59c 32
Contest_ResetWinners b2d1c 38
Contest_RunTextPrinter 37a0 28
Contest_SaveWinner b2a7c 1d0
Contest_StartTextPrinter 2eb0 94
ContestantCanUseTurn af404 32
ContinueAffineAnim 19c8 98 204
ContinueAffineAnimLoop 1b04 30 204
ContinueAnim 1634 a0 204
ContinueAnimLoop 18b8 20 204
ConvertBcdToBinary 9120 28
ConvertColorToGrayscale fd39c 34
ConvertCoolColor fd3d0 3c
ConvertDateToDayCount 9180 8c
ConvertEasyChatWordsToString eb4b4 90
ConvertImageProcessingToGBA fd8cc 14c
ConvertIntToDecimalString 6ddc 68
ConvertIntToDecimalStringN 6bc4 a0
ConvertIntToDecimalStringN_DigitWidth6 6c64 c2
ConvertIntToHexStringN 6d28 b2
ConvertInternationalString 4e9c 66
ConvertScaleParam 1e94 18 204
CoordEventWeather_Ash 693c4 c 45
CoordEventWeather_Clouds 69370 c 45
CoordEventWeather_Dark 693dc c 45
CoordEventWeather_DiagonalFog 693b8 c 45
CoordEventWeather_Drought 693e8 c 45
CoordEventWeather_Fog 693ac c 45
CoordEventWeather_LightRain 69388 c 45
CoordEventWeather_Route119Cycle 693f4 c 45
CoordEventWeather_Route123Cycle 69400 c 45
CoordEventWeather_Sandstorm 693d0 c 45
CoordEventWeather_Snow 69394 c 45
CoordEventWeather_Sunny 6937c c 45
CoordEventWeather_Thunderstorm 693a0 c 45
CopyAllBattleSpritesInvisibilities 31f24 64
CopyContestCategoryToStringVar befa4 bc
CopyDoorTilesToVram 5837c 14 68
CopyEasyChatGroupName ead64 18
CopyFromSprites 1324 28
CopyItemName a9224 3a
CopyLocationName fc02c 20
CopyMapName fbff8 32
CopyMapTilesetsToVram 56d70 18
CopyMatricesToOamBuffer af0 54 204
CopyMon 3d910 a
CopyOamMatrix 1c60 20 204
CopyPlayerPartyMonToBattleData 3de88 304
CopyPrimaryTilesetToVram 56d2c 10
CopySecondaryTilesetToVram 56d3c 14
CopySpriteTiles 40f80 1cc
CopyTextLine a4a54 44 116
CopyTilesetToVram 56c9c 24 80
CopyToSprites 134c 28
CopyValue16Bit 896f4 20 180
CopyValue32Bit 89714 20 180
CopyWallpaperTilemap 99f58 1f2
CopyWallyMonData 137a84 7ac 13
CopyablePlayerMovement_FaceDirection 5f3f4 48
CopyablePlayerMovement_GoSpeed0 5f43c b8
CopyablePlayerMovement_GoSpeed1 5f4f4 b8
CopyablePlayerMovement_GoSpeed2 5f5ac b8
CopyablePlayerMovement_GoSpeed4 5f764 b8
CopyablePlayerMovement_Jump 5f81c c8
CopyablePlayerMovement_None 5f3f0 4
CopyablePlayerMovement_Slide 5f664 b8
Cos 40e08 20
Cos2 40e6c 18
CountAliveMons 3c348 ec
CountAlivePartyMonsExceptOne 95bb4 5c
CountAlivePartyMonsExceptSelectedOne 95c10 18
CountBattleTowerBanlistCaught 13509c 44
CountPlayerMuseumPaintings c4d50 30
CountPokemonInBoxN 95adc 48
CountPokemonInDaycare 412f0 32
CountSSTidalStep 10d9b0 3c
CountTrailingZeroBits 4114c 26
CountUsedBagPocketSlots a9260 3a
CountUsedPCItemSlots a96e4 34
CpuFastSet 1e0778 4
CpuSet 1e077c 4
Crash ab084 100
CreateAnimRaindrops d30f0 94
CreateApplauseMeterSprite b00c8 50
CreateAreaMarkerSprites 111658 e0 159
CreateAreaUnknownSprites 1117e4 b0 159
CreateAshSprites 7f9ac a8
CreateAvailableDecorationsMenu 109a48 ec
CreateAzurillSprite b25c 70 128
CreateBagPokeballSprite a7c20 44 116
CreateBagSprite a7b10 18 116
CreateBattleStartTask 819c4 3c 21
CreateBerrySprite a7d8c 38
CreateBirchSprite 85a94 40
CreateBlendedOutlineCursor 14ac58 ec
CreateBoxMon 3a808 2d4
CreateCaughtBall 8df88 5c 158
CreateCityTownFlyTargetIcons fc374 110 167
CreateCloudSprites 7dfd4 cc
CreateContestPaintingPicture 107090 44 44
CreateContestantBoxBlinkSprites b09e4 178
CreateContestantSprite ae9fc 120
CreateCopySpriteAt 5c4a4 70
CreateCopyrightBanner 7bf88 5c 222
CreateCreditsMonSprite 1456b4 158 47
CreateEgg 42044 b8
CreateEggShardSprite 43654 80 59
CreateEnterUndergroundEffectTask 10cff8 14 89
CreateExitUndergroundTask 10ce48 14 89
CreateFanfareTask 74f4c 24 201
CreateFieldMessageBoxTask 64b3c 14 72
CreateFlyTargetGraphics fc31c 58 167
CreateFog1Sprites 7f6e8 bc 79
CreateFog2Sprites 7fd30 b8
CreateGameFreakLogo 13d954 110 114
CreateGenderMenu b700 60 128
CreateHeldItemIcon 6db10 84
CreateHeldItemIcon_806DCD4 6dcd8 a8
CreateHeldItemIcons 6db94 a4
CreateHeldItemIcons_806DC34 6dc38 a0
CreateInGameTradePokemon 4db68 1c
CreateInitialRoamerMon 134240 cc
CreateInterfaceSprites 8e978 418 158
CreateInvisibleBattleTargetSprite b292c 3c
CreateInvisibleSprite c9c 48
CreateInvisibleSpriteWithCallback 40eb4 3c
CreateItemUseMoveMenu 702e8 90
CreateJudgeAttentionEyeTask b0324 44
CreateJudgeSpeechBubbleSprite ae8b4 54
CreateJudgeSprite ae858 5c
CreateLinkPlayerSprite 55e60 7c 148
CreateMaleMon 3ac44 66
CreateMinimizeSprite d0614 f0
CreateMon 3a798 70
CreateMonDexNum 8deb0 d8 158
CreateMonIcon 9d2fc a8
CreateMonIconSprite 9d710 d8
CreateMonIcon_LinkMultiBattle 6d9a0 70
CreateMonListEntry 8dbe8 2c8 158
CreateMonName 8dfe4 aa 158
CreateMonSpriteFromNationalDexNumber 918ec 160
CreateMonSprite_FieldMove 85b88 bc
CreateMonSprite_PicBox 85ad4 b4
CreateMonSpritesAtPos 8e0cc 13c 158
CreateMonWithEVSpread 3ad60 88
CreateMonWithGenderNatureLetter 3ab44 fe
CreateMonWithIVsOTID 3acec 72
CreateMonWithIVsPersonality 3acac 3e
CreateMonWithNature 3aadc 66
CreateNPCTrainerParty f8e8 3ec
CreateNameMenu b770 88 128
CreateNextTurnSprites b0034 94
CreatePartyMenuMonIcon 6d884 8c
CreatePartyStatusSummarySprites 44804 49c
CreatePhase1Task 11d4c8 64 23
CreatePokeballGlowSprite 8604c 54
CreatePokeballSprite 472f0 e0
CreatePokeblockSprite 14817c 34 157
CreatePokedexMonSprite 8e8c8 b0 158
CreatePokemonFrontSprite 10a580 ac 206
CreatePostEvoSparkleSet1 149794 68 64
CreatePostEvoSparkleSet2 1498cc 88 64
CreatePreEvoSparkleSet1 149614 5c 64
CreatePreEvoSparkleSet2 1496e4 68 64
CreatePressStartBanner 7bf2c 5c 222
CreateRainSprite 7e7b4 134
CreateRandomEggShardSprite 435fc 58 59
CreateRecordMixingSprite c71d8 68
CreateReflectionEffectSprites 5aab4 a4 63
CreateRegionMapCursor fbb3c 164
CreateRegionMapPlayerIcon fbcf0 108
CreateRoamerMonInstance 134450 7c
CreateSandstormSprites_1 80178 c0
CreateSandstormSprites_2 80238 100
CreateScriptedWildMon c54d0 60
CreateScrollingPokemonSprite 8e398 f2 158
CreateSearchParameterScrollArrows 9308c 84 158
CreateSecretBaseEnemyParty 3db8c 11c
CreateShedinja 1122b4 158 65
CreateShopMenu b2d54 a8 193
CreateSizeScreenTrainerPic 91a4c ac
CreateSliderHeartSprites afe30 48
CreateSnowflakeSprite 7eba0 6c
CreateSpecialAreaFlyTargetIcons fc484 d8 167
CreateSprite bdc 54
CreateSpriteAndAnimate e3c 94
CreateSpriteAt ce4 158 204
CreateSpriteAtEnd c30 6a
CreateStartMenuTask 71288 30
CreateStarterPokemonLabel 10a42c 150 206
CreateTask 7aa8c 52
CreateTasksForSendRecvLinkBuffers bf28 c8 14
CreateTeleportFieldEffectTask 87ba8 14
CreateTrainerSprite 859bc a0
CreateUnusedBlendTask b0518 30
CreateUnusedBrokenBlendTask b06e0 68
CreateVerticalScrollIndicators f953c 260
CreateWarpArrowSprite 126b54 50
CreateWaterDrop 13d584 204 114
CreateWildMon 84e78 38 239
CreatedHatchedMon 428a4 148 59
CryScreenPlayButton 11a050 50
CurrentMapDrawMetatileAt 57db4 3c
CurrentMapIsSecretBase bbca8 22
CurrentOpponentTrainerFlag 82264 18 21
CursorColToKeyboardCol b67ec 20 141
CursorInit b6774 78 141
CutGrassSpriteCallback1 a2a48 14 87
CutGrassSpriteCallback2 a2a5c 5c 87
CutGrassSpriteCallbackEnd a2ab8 48 87
CycleSceneryPalette 149020 ec
DaycareMonReceivedMail 42b4c 1c
DaycareMonReceivedMail_ 42abc 8e 59
DaycareStorageMenuCallback_Exit 1230f4 44 37
DaycareStorageMenuCallback_Store 122f70 20 37
DaycareStorageMenuCallback_Summary 1230bc 38 37
Daycare_FindEmptySpot 41394 32 52
DebugCB_GoBack 111314 4c 159
DebugCB_GoNext 111360 4c 159
DebugCB_WaitButton 1112bc 58 159
DebugCB_WaitFade 111288 34 159
Debug_AddDaycareSteps 41790 28
Debug_FillEReaderTrainerWithPlayerData 135ee8 d4
DecompressPicFromTable_2 d308 2c
DecompressTrainerBackPic 31af4 7c
DecorationPC fe23c 28
DecrementAffineAnimDelayCounter 1dcc 30 204
DecrementAnimDelayCounter 1da4 28 204
DecrementFeederStepCounters c8508 34 176
DecryptBoxMon 3c614 24
DeleteFirstMoveAndGiveMoveToBoxMon 3b980 ac
DeleteFirstMoveAndGiveMoveToMon 3b8d4 ac
DeleteMail a2e58 20
DeleteMonMove fa0dc 6c
DeleteTextCharacter b6fbc 48 141
DequeueRecvCmds 8ad8 114 120
DestroyAnimSoundTask 75928 1c
DestroyAnimSprite 758ec 20
DestroyAnimSpriteAfterTimer da6f0 640 97
DestroyAnimVisualTask 7590c 1c
DestroyAreaSprites 111738 74 159
DestroyAshSprites 7fa54 54
DestroyBallOpenAnimationParticle 141294 80 9
DestroyContestantBoxBlinkSprites b0b5c 3c
DestroyCryMeterNeedleSprite 11a4f8 3c
DestroyFieldMessageBoxTask 64b50 1c 72
DestroyFog1Sprites 7f7a4 54 79
DestroyFog2Sprites 7fde8 54
DestroyMenuCursor 14a7fc 84
DestroyPokemonIconSprite 9d7e8 3c
DestroyRainSprites 7e974 54
DestroyRecordMixingSprite c7240 3c
DestroySprite ed0 68
DestroySpriteAndFreeResources 140c 20
DestroySpriteAndFreeResources_ 7a0f8 a
DestroySpriteAndMatrix 78578 14
DestroyTask 7ab78 70
DestroyVerticalScrollIndicator f97e0 38
DetermineBattleTowerPrize 135d84 68
DetermineCyclingRoadResults 10d74c 110 76
DetermineEggSpeciesAndParentSlots 41eec d8 52
DetermineFinalStandings af6a0 188
DeterminePokemonToShow 1458dc 19c 47
DidContestantPlaceHigher af828 38
DisableGpioPortRead 1e075c 14 194
DisableMysteryEvent 69170 10
DisableNationalPokedex 690cc 28
DisableResetRTC 691a4 1c
DisableSerial 871c 60 120
DisableWildEncounters 84978 c
DisplayCannotBeHeldMessage a607c 4c 116
DisplayCannotUseItemMessage a7718 4e 116
DisplayCantGetOffBikeItemMessage c9104 18
DisplayCurrentElevatorFloor 10e944 40
DisplayDadsAdviceCannotUseItemMessage c90ec 18
DisplayDiplomaText 145fb8 5c 54
DisplayGiveHeldItemMessage 6ebf4 54
DisplayItemMessageOnField f90b8 3c
DisplayItemRespondingMessageAndExitItemfinder c99ec 4c
DisplayMessageAndContinueTask 49cf0 54 223
DisplayMoveTutorMenu 132670 2c
DisplayPartyMenuMessage 6e838 50
DisplaySafariBallsWindow 710e0 38 205
DisplaySaveMessageWithCallback 71688 38 205
DisplaySentToPCMessage b74fc 40 141
DisplayTakeHeldItemMessage 6edb8 54
DisplayTeachMonTMHMYesNoChoice c9f80 40 117
DisplayYesNoMenu 72978 54
DiveBallOpenParticleAnimation 140b3c d8
DoAreaGlow 111110 178 159
DoBalloonSoundEffect c696c 4e 88
DoBerryBlending 4e538 34
DoBgAffineSet 40f34 4a
DoBrailleDigEffect 147408 70
DoBrailleFlyEffect 1475c4 1c
DoBrailleStrengthEffect 147514 74
DoBrailleWait 14768c 24
DoCB1_Overworld 542fc 56 148
DoCableClubWarp 8102c 24
DoContestPaintingImageProcessing 106f6c 124 44
DoCoordEventWeather 6940c 34
DoCurrentWeather 8073c 12
DoEscapeRopeFieldEffect 878c4 30 69
DoEvolutionStoneItemEffect 70dc0 8a
DoFallWarp 80f14 18
DoFieldEndTurnEffects 15dfc 75c
DoForcedMovement 589f0 76 73
DoForcedMovementInCurrentDirection 58a68 34 73
DoGlobalWildEncounterDiceRoll 850e0 22 239
DoGroundEffects_OnBeginStep 64300 54 63
DoGroundEffects_OnFinishStep 64354 54 63
DoGroundEffects_OnSpawn 642b4 4c 63
DoHandshake 8d04 fa 120
DoHitAnimBlinkSpriteEffect 137820 7c 13
DoHitAnimHealthboxEffect 47858 44
DoHorizontalLunge a8530 74 8
DoInGameTradeScene 4e174 2c
DoJudgeSpeechBubble b1710 218
DoLoadSpritePalette 2678 16 204
DoLotteryCornerComputerEffect 10e638 44
DoMassOutbreakEncounterTest 84fc4 64 239
DoMoveAnim 75704 38
DoNamingScreen b59cc 30
DoNothing 7ceb8 2 78
DoOpenPartyMenu 6af90 20
DoPCTurnOffEffect 10e59c a
DoPCTurnOnEffect 10e424 44
DoPPRecoveryItemEffect 703f4 c0
DoPPUpItemEffect 70628 5c
DoPlayerAvatarSecretBaseMatJump 59fb8 4c 73
DoPlayerAvatarTransition 59078 54 73
DoPlayerMatJump 59f98 20 73
DoPlayerMatSpin 5a070 20 73
DoPlayerPCDecoration fe28c 28
DoPoisonFieldEffect c583c 82
DoPokeNews bece8 bc
DoPokeballSendOutAnimation 46400 64
DoPokedexSearch 91af8 328
DoPokemonMenu_Switch 8a004 28
DoRareCandyItemEffect 70684 120
DoReadFlashWholeSection 125bf8 18 177
DoRecoverPP 70574 b4
DoRecv 8e00 118 120
DoRippleFieldEffect 64a3c 3c 63
DoSacredAshItemEffect 7004c 40
DoSafariBattle 81aa4 38 21
DoSaveFailedScreen 146e10 2c
DoScroll_TextMode0 40ac 7e 214
DoScroll_TextMode2 4208 110 214
DoScroll_TextModeMonospace 4160 74 214
DoSealedChamberShakingEffect1 1477b4 3c
DoSealedChamberShakingEffect2 1477f0 3c
DoSecretBaseGlitterMatSparkle c6c90 ac
DoSecretBasePCTurnOffEffect c683c 68
DoSend 8f18 b4 120
DoShadowFieldEffect 64a20 1c
DoSoftReset 6b4 70
DoStandardWildBattle 81a18 44 21
DoSwitchOutAnimation 13789c 6c 13
DoTVShow c07c4 138
DoTVShowBravoTrainerBattleTowerProfile c0b9c 264
DoTVShowBravoTrainerPokemonProfile c091c 280
DoTVShowInSearchOfTrainers c1c5c 1dc
DoTVShowPokemonAngler c1e38 d0
DoTVShowPokemonFanClubLetter c1754 224
DoTVShowPokemonFanClubOpinions c1b08 ec
DoTVShowPokemonNewsMassOutbreak c1bf8 64
DoTVShowPokemonTodayFailedCapture c15f4 160
DoTVShowPokemonTodaySuccessfulCapture c13ac 248
DoTVShowRecentHappenings c1978 190
DoTVShowTheNameRaterShow c1030 37c
DoTVShowTheWorldOfMasters c1f08 d4
DoTVShowTodaysSmartShopper c0e00 230
DoTakeMail 6ee0c 54
DoTimeBasedEvents 6a364 30
DoTracksGroundEffect_BikeTireTracks 64050 50 63
DoTracksGroundEffect_Footprints 64000 50 63
DoVerticalDip a85c8 4c 8
DoWallyTutorialBagMenu a719c 94
DoWateringBerryTreeAnim c71c4 14
DoWhiteOut 52f5c 34 148
DoWildEncounterRateDiceRoll 85028 2c 239
DoWildEncounterTest 85054 8c 239
DoYesNoFuncWithChoice f914c 2c
DoesContestCategoryHaveMuseumPainting c4c78 74
DoesCurrentMapHaveFishingMons 853e4 36
DoesObjectCollideWithObjectAt 601bc 7a 63
DoesSomeoneWantRematchIn 82c0c 20
DoesSomeoneWantRematchIn_ 829a8 40
Draw10000Sprite b7b34 b8
DrawAreaGlow 110838 d0 159
DrawBattleEntryBackground e23c 1d8
DrawBattleMoveInfoHeaders 133030 b8 137
DrawBerryPic a7ca0 58 116
DrawClosedDoor 585a0 e 68
DrawClosedDoorTiles 58410 1a 68
DrawConditionStars aef50 98
DrawContestMoveInfoHeaders 133140 108 137
DrawContestantWindowText ae514 84
DrawContestantWindows b1118 34
DrawCurrentDoorAnimFrame 583d0 3e 68
DrawDialogueFrame 65284 b0 215
DrawDoor 5842c 3a 68
DrawDoorMetatileAt 57df0 34
DrawDownArrow 4458 16c 214
DrawExperienceProgressBar a0c80 14e 163
DrawFirstMartScrollIndicators b3270 34 193
DrawGlyphTile_ShadowedFont 5680 148 214
DrawGlyphTile_UnshadowedFont 50ac 158 214
DrawGlyphTiles 6874 de 214
DrawGlyph_TextMode0 3818 2a 214
DrawGlyph_TextMode2 392c 26 214
DrawInitialDownArrow 4610 e 214
DrawLearnMoveMenuWindow 132fec 44 137
DrawLetterMapTiles 14524c 84
DrawMainBattleBackground d7b8 300
DrawMapNamePopup a30e0 38 129
DrawMetatile 57e8c 19c 66
DrawMetatileAt 57e24 68 66
DrawMonDescriptorStatus 6bc40 7c
DrawMonRibbonIcons f1238 1c4
DrawMoveEffectSymbol aed7c a4
DrawMoveEffectSymbols aee20 2c
DrawMoveInfoWindow 133aec 1b8 137
DrawMoveSelectArrow ac0ac 18
DrawMoveSelectionWindow 133800 140 137
DrawMultichoiceMenu b5138 f8 184
DrawOpenedDoor 585b0 40 68
DrawOptionMenuChoice 8bc60 54 145
DrawOrEraseSearchParameterBox 92c8c ec 158
DrawPartyMenuMonText 142c d0
DrawPartyMonBackground 6b590 37c
DrawPocketIndicatorDots a3ac0 44 116
DrawPokerusSurvivorDot a0ea4 44 163
DrawSearchMenuItemBgHighlight 9286c f8 158
DrawSelectIcon a4030 2c 116
DrawSpace 32a8 9c 214
DrawSpindaSpots 3fa54 112
DrawStandardFrame 6503c 190 215
DrawStatusSymbol af038 e8
DrawStatusSymbols af120 18
DrawSummaryScreenNavigationDots a0ee8 160
DrawTheEnd 1452d0 a8 47
DrawUnnervedSymbols b20c4 88
DrawWaveformFlatline 11a124 38
DrawWaveformSegment 11a1c8 15c
DrawWaveformWindow 11a324 2c
DrawWholeMapView 57b44 2c
DrawWholeMapViewInternal 57b70 84 66
DrawWindowRect_DefaultPalette 4724 34
Drought_Finish 7e258 4
Drought_InitAll 7e144 30
Drought_InitVars 7e110 34
Drought_Main 7e174 e4
DummyFunc 1df3c8 2
DummyPerStepCallback 695e0 2
EasyChat_GetWordText eb3fc b8
EggGroupsOverlap 423a8 30 52
EggHatch 42c80 2c
EggHatchCreateMonSprite 42b68 104 59
EggHatchPrintMessage1 436d4 28 59
EggHatchPrintMessage2 436fc 28 59
EggHatchSetMonNickname 42f88 30 59
EggHatchUpdateWindowText 43724 18 59
EmptyFunc 2d50 2
EnableGpioPortRead 1e0748 14 194
EnableMysteryEvent 69180 10
EnableNationalPokedex 690f4 3c
EnableResetRTC 691c0 20
EnableSerial 877c bc 120
EncryptBoxMon 3c5f0 24
EndBattleIntroTask e443c 50 16
EndLotteryCornerComputerEffect 10e724 28
EndMassOutbreak be858 6c
EndTrainerApproach 847c8 10
EndTruckSequence c7700 54
EnqueueSendCmd 89f0 e8 120
EnterSafariMode c81b8 2c
EraseAndPrintSearchTextBox 91e20 1c
EraseAtCursor 3d30 40 214
EraseFlashChip_MX 1dfbf4 74
EraseFlashSector_MX 1dfc68 d0
EraseMoveSelectArrow ac0c4 2
EraseSelectIcon a40ac 24 116
EscapeRopeFieldEffect_Step0 878f4 1e 69
EscapeRopeFieldEffect_Step1 87914 114 69
EvoDummyFunc 114fd0 2 65
EvoDummyFunc2 1150f8 2 65
EvoSparkle_DummySpriteCb 14951c 2 64
EvoTask_BeginPostSparklesSet1 149b5c 34 64
EvoTask_BeginPostSparklesSet2_AndFlash 149c50 60 64
EvoTask_BeginPostSparklesSet2_AndFlash_Trade 149d8c 60 64
EvoTask_BeginPreSet1_FadeAndPlaySE 1499a0 50 64
EvoTask_BeginPreSparklesSet2 149aa8 34 64
EvoTask_CreatePostEvoSparklesSet1 149b90 80 64
EvoTask_CreatePostEvoSparklesSet2_AndFlash 149cb0 8c 64
EvoTask_CreatePostEvoSparklesSet2_AndFlash_Trade 149dec 8c 64
EvoTask_CreatePreEvoSparkleSet1 1499f0 70 64
EvoTask_CreatePreEvoSparklesSet2 149adc 58 64
EvoTask_DestroyPostSet1Task 149c10 e 64
EvoTask_DestroyPostSet2AndFlashTask 149d3c 20 64
EvoTask_DestroyPreSet2Task 149b34 e 64
EvoTask_WaitForPre1SparklesToGoUp 149a60 30 64
EvolutionRenameMon 3fb68 54
EvolutionScene 111984 30c
ExecuteItemUseFromBlackPalette a5cc4 18
ExecuteSwitchToOverworldFromItemUse c8fac 68
ExecuteTableBasedItemEffect_ 3e18c 24
ExecuteTableBasedItemEffect__ 6fdc8 68
ExecuteTeleportFieldEffectTask 87bbc 30 69
ExecuteTruckSequence c76a0 60
ExecuteWhiteOut c5824 18
ExitItemfinder c9520 28
ExitSafariMode c81e4 24
ExpandBattleTextBuffPlaceholders 121a68 2b2
ExpandBoxMon 3b4b4 50
ExpandPlaceholder_EvilLeader 6fac 8 208
ExpandPlaceholder_EvilLegendary 6fbc 8 208
ExpandPlaceholder_EvilTeam 6f9c 8 208
ExpandPlaceholder_GoodLeader 6fb4 8 208
ExpandPlaceholder_GoodLegendary 6fc4 8 208
ExpandPlaceholder_GoodTeam 6fa4 8 208
ExpandPlaceholder_KunChan 6f4c 24 208
ExpandPlaceholder_PlayerName 6f2c 8 208
ExpandPlaceholder_RivalName 6f70 24 208
ExpandPlaceholder_StringVar1 6f34 8 208
ExpandPlaceholder_StringVar2 6f3c 8 208
ExpandPlaceholder_StringVar3 6f44 8 208
ExpandPlaceholder_UnknownStringVar 6f24 8 208
ExpandPlaceholder_Version 6f94 8 208
ExtCtrlCode_AllColors 3104 4e 214
ExtCtrlCode_BackgroundColor 30cc 1c 214
ExtCtrlCode_ClearWindowTextLines 326c c 214
ExtCtrlCode_DefaultFont 3184 a 214
ExtCtrlCode_Escape 3210 2c 214
ExtCtrlCode_Font 316c 16 214
ExtCtrlCode_ForegroundColor 30b0 1c 214
ExtCtrlCode_Japanese 3408 8 214
ExtCtrlCode_Latin 3410 8 214
ExtCtrlCode_Nop 30ac 4 214
ExtCtrlCode_Nop2 323c 4 214
ExtCtrlCode_Palette 3154 16 214
ExtCtrlCode_Pause 3190 26 214
ExtCtrlCode_PlayBGM 31e0 30 214
ExtCtrlCode_PlaySE 3278 30 214
ExtCtrlCode_SetCursorX 33ac 26 214
ExtCtrlCode_SetCursorY 3240 2a 214
ExtCtrlCode_ShadowColor 30e8 1c 214
ExtCtrlCode_Skip 3388 24 214
ExtCtrlCode_SkipTo 33d4 1c 214
ExtCtrlCode_Spacing 33f0 16 214
ExtCtrlCode_WaitButton 31b8 14 214
ExtCtrlCode_WaitSound 31cc 14 214
FaceDirection 60ca0 42 63
FadeFootprintsTireTracks_Step0 1275a0 22 70
FadeFootprintsTireTracks_Step1 1275c4 4a 70
FadeInBGM 74ffc 18
FadeInNewBGM 74f70 4c
FadeInNewMapMusic 74ddc 3c
FadeInScreenWithWeather 7ccac 118 78
FadeInScreen_Drought 7ce24 58 78
FadeInScreen_Fog1 7ce7c 3a 78
FadeInScreen_RainShowShade 7cdc4 60 78
FadeOutAndFadeInNewMapMusic 74d98 44
FadeOutAndPlayNewMapMusic 74d64 34
FadeOutBGM 75014 18
FadeOutBGMTemporarily 74fbc 18
FadeOutBody 1de710 c8
FadeOutMapMusic 74d2c 38
FadeScreen 7d644 12c
FailSweetScentEncounter 12c118 2c 95
FaintFromFieldPoison c56dc 4c 74
FanOutBallOpenParticles_Step1 140ecc 56 9
FeebasRandom 84b54 20
FeebasSeedRng 84b74 10
FieldAnimateDoorClose 58710 36
FieldAnimateDoorOpen 58748 36
FieldCB_ContestReturnToField ae010 e
FieldCB_ReturnToOverworld 96130 38
FieldCallback_AfterFadeInFromMenu 8aba8 4c 160
FieldCallback_CutGrass a25e8 1c 87
FieldCallback_CutTree a2634 20 87
FieldCallback_PrepareFadeInFromMenu 8ab90 18
FieldCallback_SecretBaseCave c639c 20 92
FieldCallback_SecretBaseShrub c660c 20 92
FieldCallback_SecretBaseTree c64a8 20 92
FieldCallback_SweetScent 12bfd4 1c 95
FieldCallback_Teleport 14a3b4 20 96
FieldClearVBlankHBlankCallbacks 547ac 3c
FieldEffectActiveListAdd 85934 2c
FieldEffectActiveListClear 85910 24
FieldEffectActiveListContains 85990 2c
FieldEffectActiveListRemove 85960 30
FieldEffectCmd_callnative 856ec 12
FieldEffectCmd_end 85700 4
FieldEffectCmd_loadfadedpal 856c4 12
FieldEffectCmd_loadfadedpal_callnative 85750 22
FieldEffectCmd_loadgfx_callnative 85704 28
FieldEffectCmd_loadpal 856d8 12
FieldEffectCmd_loadtiles 856b0 12
FieldEffectCmd_loadtiles_callnative 8572c 22
FieldEffectFreeGraphicsResources 85818 22
FieldEffectFreePaletteIfUnused 858b8 58
FieldEffectFreeTilesIfUnused 85854 64
FieldEffectScript_CallNative 857fc 1c
FieldEffectScript_LoadFadedPalette 857bc 28
FieldEffectScript_LoadPalette 857e4 18
FieldEffectScript_LoadTiles 8578c 30
FieldEffectScript_ReadWord 85774 18
FieldEffectStart 85668 48
FieldEffectStop 8583c 16
FieldInitRegionMap 13eeb4 30
FieldIsDoorAnimationRunning 58780 14
FieldSetDoorClosed 586e4 2c
FieldSetDoorOpened 586b8 2c
FieldShowRegionMap 10e414 10
FillBattleTowerTrainerParty 134dd4 2c8
FillConnection 56138 64 80
FillContestantWindowBgs afa5c 5c
FillEastConnection 562c4 64 80
FillNorthConnection 56204 60 80
FillPalette 73a94 50
FillSouthConnection 5619c 68 80
FillWestConnection 56264 60 80
FilterOutDisabledCoveringGroundEffects 64260 38
FilterOutStepOnPuddleGroundEffectIfJumping 64298 1c
FindAnyTVNewsOnTheAir beca0 46
FindCameraObject 5c398 46 63
FindFirstActiveTask 7ac18 3c 212
FindFreeDecorationInventorySlot 133f9c 46
FindFreePCItemSlot a96ac 38 115
FindLinkBattleRecord 10ffec 50 19
FindMapsWithMon 110908 190 159
FindMonThatAbsorbsOpponentsMove 361e8 228 5
FindMonWithFlagsAndSuperEffective 366a4 260 5
FindNonMassOutbreakActiveTVShow bda30 46
FindObjectEventPaletteIndexByTag 5bee8 48 63
FindObjectEventTemplateByLocalId 5c6cc 36 63
FindTallGrassFieldEffectSpriteId 126ff0 8e
FindTaskIdByFunc 7acf8 2e
FinishCyclingRoadChallenge 10d85c 30
FirstBattleTrainerIdToRematchTableId 82894 24
Fishing1 5a3b8 20 73
Fishing10 5a6b8 28 73
Fishing11 5a6e0 e0 73
Fishing12 5a7c0 4c 73
Fishing13 5a80c 50 73
Fishing14 5a85c 1a 73
Fishing15 5a878 a0 73
Fishing16 5a918 40 73
Fishing2 5a3d8 98 73
Fishing3 5a470 24 73
Fishing4 5a494 48 73
Fishing5 5a4dc 94 73
Fishing6 5a570 60 73
Fishing7 5a5d0 28 73
Fishing8 5a5f8 58 73
Fishing9 5a650 68 73
FishingWildEncounter 8541c 6c
FlagClear 6931c 28
FlagGet 69344 2c
FlagSet 692f4 28
FlashTimerIntr 1df674 28
FldEff_Ash 127cf8 8c
FldEff_BerryTreeGrowthSparkle 128450 74
FldEff_BikeTireTracks 127510 74
FldEff_Bubbles 1283ac 64
FldEff_CutGrass a2698 110
FldEff_DeepSandFootprints 12749c 74
FldEff_Dust 1281b4 70
FldEff_ExclamationMarkIcon 847ec 38
FldEff_FeetInFlowingWater 127820 b8
FldEff_FieldMoveShowMon 88068 5c
FldEff_FieldMoveShowMonInit 880c4 5c
FldEff_FlyIn 8925c 14
FldEff_HallOfFameRecord 85ed4 3c
FldEff_HeartIcon 8485c 38
FldEff_HotSpringsWater 1279d8 a4
FldEff_JumpBigSplash 1277b0 70
FldEff_JumpLongGrass 127220 70
FldEff_JumpSmallSplash 127740 70
FldEff_JumpTallGrass 126f80 70
FldEff_LavaridgeGymWarp 875d4 64
FldEff_LongGrass 127080 a8
FldEff_MountainDisguise 1284d4 10
FldEff_NPCFlyOut 88b68 5c
FldEff_Nop47 c69bc 4
FldEff_Nop48 c69c0 4
FldEff_Pokeball 11b6b4 6c
FldEff_PokecenterHeal 85d80 44
FldEff_PopOutOfAsh 87828 64
FldEff_QuestionMarkIcon 84824 38
FldEff_Ripple 127978 60
FldEff_RockSmash 10b55c 30
FldEff_SandDisguise 1284e4 10
FldEff_SandFootprints 127428 74
FldEff_SandPile 128224 bc
FldEff_SandPillar c6d3c 128
FldEff_SecretBasePCTurnOn c6718 48
FldEff_SecretPowerCave c63fc 50
FldEff_SecretPowerShrub c666c 50
FldEff_SecretPowerTree c6508 90
FldEff_Shadow 126c6c a4
FldEff_ShortGrass 127290 a4
FldEff_Sparkle 128700 74
FldEff_Splash 127610 a4
FldEff_SurfBlob 127e58 78
FldEff_SweetScent 12bff0 2c
FldEff_TallGrass 126dd8 a4
FldEff_TreeDisguise 1284c4 10
FldEff_Unknown19 127b14 6c
FldEff_Unknown20 127b80 6c
FldEff_Unknown21 127bec 6c
FldEff_Unknown22 127c58 6c
FldEff_UseCutOnGrass a2604 30
FldEff_UseCutOnTree a2654 30
FldEff_UseDig 10b5f8 3c
FldEff_UseDive 870b0 3c
FldEff_UseFly 88c40 30
FldEff_UseFlyAncientTomb 1475e0 2c
FldEff_UseSecretPowerCave c63bc 2c
FldEff_UseSecretPowerShrub c662c 2c
FldEff_UseSecretPowerTree c64c8 2c
FldEff_UseStrength 11aa54 48
FldEff_UseSurf 88914 40
FldEff_UseTeleport 14a3d4 30
FldEff_UseWaterfall 86f2c 38
FldeffPoison_IsActive c708c 14
FldeffPoison_Start c7074 18
Fog1SpriteCallback 7f688 60 79
Fog1_Finish 7f5ec 9a
Fog1_InitAll 7f4fc 30
Fog1_InitVars 7f49c 60
Fog1_Main 7f52c c0
Fog2SpriteCallback 7fe3c 60
Fog2_Finish 7fc3c 5e
Fog2_InitAll 7fba8 30
Fog2_InitVars 7fb24 84
Fog2_Main 7fbd8 64
ForcedMovement_MuddySlope 58c20 58 73
ForcedMovement_None 589a4 4c 73
ForcedMovement_RideCurrentEast 58b58 18 73
ForcedMovement_RideCurrentNorth 58b28 18 73
ForcedMovement_RideCurrentSouth 58b10 18 73
ForcedMovement_RideCurrentWest 58b40 18 73
ForcedMovement_SecretBaseJumpMat 58c08 c 73
ForcedMovement_SecretBaseSpinMat 58c14 c 73
ForcedMovement_Slide 58b70 38 73
ForcedMovement_SlideEast 58bf0 18 73
ForcedMovement_SlideNorth 58bc0 18 73
ForcedMovement_SlideSouth 58ba8 18 73
ForcedMovement_SlideWest 58bd8 18 73
ForcedMovement_Slip 58a9c 14 73
ForcedMovement_WalkEast 58af8 18 73
ForcedMovement_WalkNorth 58ac8 18 73
ForcedMovement_WalkSouth 58ab0 18 73
ForcedMovement_WalkWest 58ae0 18 73
FormatDecimalDate 94c4 36
FormatDecimalTime 943c 36
FormatHexDate 94fc 36
FormatHexRtcTime 94ac 18
FormatHexTime 9474 36
FormatMonSizeRecord c5a08 84 161
FormatPlayTime 948e4 44
FoundAbandonedShipRoom1Key 10f488 26
FoundAbandonedShipRoom2Key 10f4b0 22
FoundAbandonedShipRoom4Key 10f4d4 26
FoundAbandonedShipRoom6Key 10f4fc 26
FoundBlackGlasses 10f828 12
FrameType_DrawChoices 8becc c6 145
FrameType_ProcessInput 8be74 58 145
FreeAllSpritePalettes 25c8 38
FreeAndReserveObjectSpritePalettes 5bde8 14
FreeBallGraphics 4794c 2c
FreeMonIconPalettes 9d5b4 24
FreeOamMatrix 2198 40
FreePokeSpriteMatrix 148618 14 157
FreeRegionMapIconResources fab10 50
FreeResetData_ReturnToOvOrDoEvolutions 13da8 50 17
FreeResourcesAndDestroySprite 85c44 36
FreeSpriteOamMatrix 13e0 2c
FreeSpritePalette 13d0 e
FreeSpritePaletteByTag 2708 28
FreeSpriteTileRanges 2440 40
FreeSpriteTiles 13b4 1c
FreeSpriteTilesByTag 23c8 78
FreezeObjectEvent 643a8 90
FreezeObjectEvents 64438 3c
FreezeObjectEventsExceptOne 64474 44
FuncIsActiveTask 7acc0 36
GabbyAndTyAfterInterview bdc14 6c
GabbyAndTyBeforeInterview bdb14 100
GabbyAndTyGetBattleNum bdc9c 28
GabbyAndTyGetLastBattleTrivia bdd18 4a
GabbyAndTyGetLastQuote bdcdc 3c
GameClear 10d180 ec
GameCubeMultiBoot_ExecuteProgram 1dcbdc 14
GameCubeMultiBoot_HandleSerialInterrupt 1dcc3a 130
GameCubeMultiBoot_Hash 1dcac8 14
GameCubeMultiBoot_Init 1dcbf0 4a
GameCubeMultiBoot_Main 1dcadc f4
GameCubeMultiBoot_Quit 1dcd6a 22
GenderMenuProcessInput b760 e 128
GenerateFishingWildMon 84f18 36 239
GenerateWave 898fc 48 180
GenerateWildMon 84eb0 68 239
GetAI_ItemType 37030 5c 5
GetAbilityBySpecies 3db14 44
GetAcroEndWheelieDirectionAnimNum 5fdbc 10
GetAcroEndWheelieFaceDirectionMovementAction 60a34 2c
GetAcroEndWheelieMoveDirectionMovementAction 60b68 2c
GetAcroPopWheelieFaceDirectionMovementAction 60a08 2c
GetAcroPopWheelieMoveDirectionMovementAction 60b10 2c
GetAcroUnusedActionDirectionAnimNum 5fdcc 10
GetAcroWheelieDirectionAnimNum 5fd9c 10
GetAcroWheelieFaceDirectionMovementAction 609dc 2c
GetAcroWheelieHopDirectionMovementAction 60a8c 2c
GetAcroWheelieHopFaceDirectionMovementAction 60a60 2c
GetAcroWheelieInPlaceDirectionMovementAction 60ae4 2c
GetAcroWheelieJumpDirectionMovementAction 60ab8 2c
GetAcroWheelieMoveDirectionMovementAction 60b3c 2c
GetAcroWheeliePedalDirectionAnimNum 5fddc 10
GetAdjustedInitialDirection 53b60 c2 148
GetAdjustedInitialTransitionFlags 53b00 5e 148
GetAffineAnimFrame 1eac 6c 204
GetAllChosenMoves af1b8 2c
GetAllGroundEffectFlags_OnBeginStep 6363c 58 63
GetAllGroundEffectFlags_OnFinishStep 63694 50 63
GetAllGroundEffectFlags_OnSpawn 635f4 48 63
GetAnimBattlerSpriteId 7806c 94
GetAppealHeartTileOffset afb40 34
GetAvailableObjectEventId 5ae54 a0 63
GetBackgroundEventAtPosition 68e50 4e 67
GetBadgeCount 94890 34
GetBarboachSizeRecordInfo c5bf0 1c
GetBaseTemplateForObjectEvent 5c704 52 63
GetBattleOutcome 10e300 c
GetBattleTransitionTypeByMap 81e90 62 21
GetBattlerAtPosition 7883c 3c
GetBattlerBall 47978 54 155
GetBattlerForBattleScript 15150 84
GetBattlerPosition 7882c 10
GetBattlerPosition_permutated 79f18 2e
GetBattlerSide 78818 14
GetBattlerSpriteBGPriority 79ed8 40
GetBattlerSpriteCoord 77ac0 13e
GetBattlerSpriteCoordAttr 7a104 2fc
GetBattlerSpriteDefault_Y 77f6c 14
GetBattlerSpriteFinal_Y 77e48 a0
GetBattlerSpriteSubpriority 79e94 42
GetBattlerTurnOrderNum 1e3b4 38
GetBerryCountByBerryTreeId b4e20 18 24
GetBerryInfo b498c 3c
GetBerryNameByBerryType b4d14 20
GetBerryTreeInfo b49c8 10 24
GetBerryTypeByBerryTreeId b4c90 18
GetBestBattleTowerStreak 10f404 10
GetBlankTileNum 487c 5a 214
GetBlockReceivedStatus 7ee4 20
GetBoxMonData 3cbfc 5fe
GetBoxMonGender 3c4c8 5c
GetBoxMonNick 412d0 1e
GetCameraCoords 56c8c 10
GetCameraFocusCoords 56c6c 14
GetCenterScreenMetatileBehavior 53c24 20
GetCharAtKeyboardPos b7768 2c 141
GetChosenMove af15c 5c
GetCoins 11a82c 14
GetCollisionAtCoords 5ff64 c4
GetCollisionFlagsAtCoords 60028 cc
GetCollisionInDirection 5ff24 40 63
GetContestWinnerSaveIdx b2c4c d0
GetContestantNamesAtRank c4d80 180
GetContestantRound2Points af688 18
GetCoolColorFromPersonality fd40c d0
GetCoordEventScriptAtMapPosition 68e28 28
GetCoordEventScriptAtPosition 68dc0 66 67
GetCurSecretBaseRegistrationValidity bc56c 50
GetCurrLocationDefaultMusic 53de4 62
GetCurrentBattleTowerWinStreak 135d3c 48
GetCurrentMapMusic 74ce0 c
GetCurrentMapRotatingGatePuzzleType c799c 2e 174
GetCurrentMapWildMonHeader 84d6c 58 239
GetCurrentMauvilleOldMan f7b08 c
GetCurrentWeather 7dd4c 10
GetCursorPos b6858 20 141
GetCursorTileNum 69d8 4c 214
GetCursorTilemapPointer 3af8 38 214
GetDaycareCompatibilityScore 423d8 11c 52
GetDaycareCompatibilityScoreFromSave 424f4 14
GetDaycareCost 41770 20
GetDaycareCostForSelectedMon 41728 48 52
GetDaycareLevelMenuLevelText 426b0 7c 52
GetDaycareLevelMenuText 42630 80 52
GetDaycareMonNicknames 42360 10
GetDaycareState 42370 36
GetDaysUntilPacifidlogTMAvailable 10f908 46
GetDestinationWarpMapHeader 53328 24
GetDewfordHallPaintingNameIndex fa648 28
GetDialogueFrameTilemapEntry 65218 6c 215
GetDirectionToFace 5fe94 34 63
GetDoorGraphics 58518 22 68
GetDoorSoundEffect 58794 22
GetDummy2 8320 c
GetEReaderTrainerClassNameIndex 135fd8 1c
GetEReaderTrainerPicIndex 135fbc 1c
GetEggMoves 41b1c a8 52
GetEggSpecies 41870 80
GetEnigmaBerryChecksum b48f8 48 24
GetEqualEasyChatPairIndex fa828 44 53
GetEventLoadMessage 1469ac 38 139
GetEvolutionTargetSpecies 3f48c 328
GetExpandedPlaceholder 6fcc 24
GetExtCtrlCodeLength 496c 1c
GetFaceDirectionAnimNum 5fd3c 10
GetFaceDirectionMovementAction 606c4 2c
GetFieldMessageBoxMode 64c7c c
GetFirstFreePokeblockSlot 10ca00 32
GetFirstInactiveObjectEventId 5ab58 30
GetFishingBiteDirectionAnimNum 5fe0c 10
GetFishingDirectionAnimNum 5fdec 10
GetFishingNoCatchDirectionAnimNum 5fdfc 10
GetFlagPointer 692b0 44
GetForcedMovementByMetatileBehavior 58948 5a 73
GetFreeStorySlot f849c 2c 131
GetGabbyAndTyLocalIds bdd64 e4
GetGameStat 53108 26
GetGenderFromSpeciesAndPersonality 3c524 46
GetGlyphTilePointers 3a1c dc 214
GetGlyphWidth 48e8 84 214
GetGroundEffectFlags_HotSprings 6397c 4e 63
GetGroundEffectFlags_JumpLanding 639ec 5c 63
GetGroundEffectFlags_LongGrassOnBeginStep 637c8 1e 63
GetGroundEffectFlags_LongGrassOnSpawn 637a8 1e 63
GetGroundEffectFlags_Puddle 638dc 2e 63
GetGroundEffectFlags_Reflection 6370c 5a 63
GetGroundEffectFlags_Ripple 6390c 20 63
GetGroundEffectFlags_SandPile 63828 4e 63
GetGroundEffectFlags_Seaweed 639cc 20 63
GetGroundEffectFlags_ShallowFlowingWater 63878 64 63
GetGroundEffectFlags_ShortGrass 6392c 4e 63
GetGroundEffectFlags_TallGrassOnBeginStep 63788 1e 63
GetGroundEffectFlags_TallGrassOnSpawn 63768 1e 63
GetGroundEffectFlags_Tracks 637e8 40 63
GetHPBarLevel 46200 32
GetHealLocation fa8cc 1e
GetHealLocationByMap fa8a4 26
GetHealLocationIndexByMap fa86c 38
GetHealthboxElementGfxPtr 43cdc 10 15
GetHoennPokedexCount 90f68 58
GetImageEffectForContestWinner 106ee0 6a 44
GetInFrontOfPlayerPosition 6818c 3c 67
GetInGameTradeSpeciesInfo 4d89c 48
GetIncomingConnection 56a68 56 80
GetIndexOfFirstEmptySpaceInBoxN 95b24 48
GetInitialPlayerAvatarState 53aa8 58 148
GetInputEvent b61ec 24 141
GetInteractedBackgroundEventScript 68424 e0 67
GetInteractedLinkPlayerScript 682ac bc
GetInteractedMetatileScript 68504 1f4 67
GetInteractedObjectEventScript 68368 bc 67
GetInteractedWaterScript 686f8 7c 67
GetInteractionScript 68254 56 67
GetItemEffectParamOffset 3f1dc 146
GetItemEffectType 70e4c 148
GetJump2MovementAction 60824 2c
GetJumpInPlaceMovementAction 60850 2c
GetJumpInPlaceTurnAroundMovementAction 6087c 2c
GetJumpMovementAction 608a8 2c
GetJumpSpecialDirectionAnimNum 5fd8c 10
GetJumpSpecialMovementAction 608d4 2c
GetKeyRoleAtCursorPos b6958 3e 141
GetLandmarkName 11a8cc 54
GetLandmarks 11a920 7c 118
GetLastDoorFrame 58504 14 68
GetLastUsedWarpMapType 541f0 14
GetLastWinStreak 11056c 28 19
GetLeadMonFriendshipScore 10e384 80
GetLeadMonIndex 10f87c 56
GetLedgeJumpDirection 63bc8 5c
GetLetterMapTile 145208 42
GetLevelAfterDaycareSteps 41664 3a 52
GetLevelFromBoxMonExp 3b570 6c
GetLevelFromMonExp 3b504 6c
GetLevelUpMovesBySpecies 4051c 58
GetLimitedVectorDirection_EastNorth 5cb60 5c
GetLimitedVectorDirection_EastSouth 5cc18 5c
GetLimitedVectorDirection_NorthWestEast 5ccec 3c
GetLimitedVectorDirection_SouthNorth 5cae0 10
GetLimitedVectorDirection_SouthNorthEast 5ccb0 3c
GetLimitedVectorDirection_SouthNorthWest 5cc74 3c
GetLimitedVectorDirection_SouthWestEast 5cd28 3c
GetLimitedVectorDirection_WestEast 5caf0 12
GetLimitedVectorDirection_WestNorth 5cb04 5c
GetLimitedVectorDirection_WestSouth 5cbbc 5c
GetLinkBattleRecordTotalBattles 10ffdc e 19
GetLinkPartnerNames 10dac8 60
GetLinkPlayerCount 7b78 10
GetLinkPlayerCount_2 8300 10
GetLinkPlayerDataExchangeStatusTimed 7ba4 a4
GetLinkPlayerIdAt 55ba0 5e 148
GetLinkPlayerTrainerId 7cb0 18
GetLocalWaterMon 85514 44
GetLocalWildMon 85488 8c
GetLocationMusic 53d9c 48 148
GetLotteryNumber 145d3c 28
GetMUS_ForBattle 40728 194
GetMachBikeTransition e5110 56 28
GetMailboxMailCount 13af3c 3c 153
GetMapBorderIdAt 567c4 ec
GetMapConnection 53818 38
GetMapConnectionAtPos 56ba4 ae
GetMapHeaderFromConnection 55f94 10
GetMapLayout 53248 28 148
GetMapMusicFadeoutSpeed 53fdc 1e
GetMapPairFadeFromType 10ce00 48
GetMapPairFadeToType 10cdb8 48
GetMapSectionName fbfb4 42
GetMapTypeByGroupAndId 541ac 18
GetMapTypeByWarpData 541c4 18
GetMatchFromSymbolsInRow 1029d4 4e 199
GetMatchingDigits 145c8c 88 122
GetMedicineItemEffectMessage 6fbd4 1c0
GetMetatileAttributesById 56554 54
GetMirageRnd 10d280 2c 221
GetMomOrDadStringForTVMessage bfc10 110
GetMonAbility 3db58 32
GetMonData 3cb60 9a
GetMonEVCount 40020 28
GetMonGender 3c4b8 e
GetMonHeldItemIconSpriteId 6df38 2c
GetMonIconPtr 9d4f4 1c
GetMonIconSpriteId 6dda4 b0 150
GetMonMove 9f760 36 163
GetMonMovePP 9f798 36 163
GetMonNick 412b0 1e
GetMonNickname 6e0f0 18
GetMonSize c5994 74 161
GetMonSizeHash c58c0 a4 161
GetMonSizeRecordInfo c5b1c 68 161
GetMonSpritePal 40904 38
GetMonSpritePalFromOtIdPersonality 4093c 54
GetMonSpritePalStruct 40990 38
GetMonSpritePalStructFromOtIdPersonality 409c8 38
GetMonStatusAndPokerus a1cd8 40
GetMoneyAmountText b79f8 9c
GetMonsStateToDoubles 3daa0 74
GetMostSuitableMonToSwitchInto 36cd4 35c
GetMoveDirectionAnimNum 5fd4c 10
GetMoveDirectionFastAnimNum 5fd5c 10
GetMoveDirectionFasterAnimNum 5fd6c 10
GetMoveDirectionFastestAnimNum 5fd7c 10
GetMoveEffectSymbolTileOffset aeb68 84
GetMoveTarget 1b5c0 368
GetMoveTutorMoves 403cc 150
GetMultiplayerId 7e5c 10
GetMultiplayerId_ b9a58 e
GetNameOfEnigmaBerryInPlayerParty c54a0 30
GetNamingScreenParameters b5b7c 68 141
GetNationalPokedexCount 90f18 4e
GetNature 3f464 18
GetNatureFromPersonality 3f47c 10
GetNextPosition 91818 5a 158
GetNonMassOutbreakActiveTVShow bda78 3a
GetNpcContestantLocalId c4c28 3c
GetNumDecorationsInInventory 1341d4 24
GetNumDecorationsInInventoryCategory 134194 40
GetNumHeartsFromAppealPoints afb74 2c
GetNumLevelsGainedForDaycareSlot 416e8 40 52
GetNumLevelsGainedFromDaycare 417b8 3a
GetNumLevelsGainedFromSteps 416a0 46 52
GetNumMovedLilycoveFanClubMembers 10fcb0 38
GetNumRibbons a0a90 f8
GetNumStagesWateredByBerryTreeId b4d88 16 24
GetNumValidDaycarePartyMons 95b6c 48
GetObjectEventFlagIdByLocalIdAndMap 5c594 18 63
GetObjectEventFlagIdByObjectEventId 5c5ac 28 63
GetObjectEventGraphicsInfo 5bc14 30
GetObjectEventIdByLocalId 5ac6c 3a 63
GetObjectEventIdByLocalIdAndMap 5ab88 24
GetObjectEventIdByLocalIdAndMapInternal 5ac1c 4e 63
GetObjectEventIdByXY 5abd8 44
GetObjectEventIdByXYZ 5c1cc 66
GetObjectEventMovingCameraOffset 604c0 40 63
GetObjectEventScriptPointerByLocalIdAndMap 5c558 18 63
GetObjectEventScriptPointerByObjectEventId 5c570 24
GetObjectEventScriptPointerPlayerFacing 68fb4 3a
GetObjectEventTemplateByLocalIdAndMap 5c67c 4e
GetObjectPaletteTag 5c808 80
GetObjectTrainerTypeByLocalIdAndMap 5c5d4 3c
GetObjectTrainerTypeByObjectEventId 5c610 18
GetOnOffBike e5f7c 50
GetOppositeDirection 60b94 32
GetOverworldMapFromUnderwaterMap fba04 12
GetOverworldMapFromUnderwaterMap_ fb9c0 44 167
GetPaletteNumByUid 741c8 34 149
GetPlayerAvatarBike 10d724 28
GetPlayerAvatarGenderByGraphicsId 598b8 2c
GetPlayerAvatarGraphicsIdByCurrentState 59a50 42
GetPlayerAvatarGraphicsIdByStateId 59870 1c
GetPlayerAvatarGraphicsIdByStateIdAndGender 59858 18 73
GetPlayerAvatarObjectId 597e0 c
GetPlayerAvatarStateTransitionByGraphicsId 59a10 3e 73
GetPlayerBigGuyGirlString 10e298 34
GetPlayerCurMetatileBehavior 681c8 2a 67
GetPlayerDirectionTowardsHiddenItem c9908 74
GetPlayerFacingDirection 5973c 20
GetPlayerFieldInput 67f1c 10a
GetPlayerMovementDirection 5975c 1c
GetPlayerPosition 68174 16 67
GetPlayerRecvBuffer b9a68 10
GetPlayerRunMovementAction 607f8 2c
GetPlayerSpeed e6034 50
GetPlayerTrainerId bfb94 1c
GetPlayerTrainerIdOnesDigit 10e278 20
GetPocketByItemId a9670 12
GetPokeFlavourRelation 40a7c 28
GetPokeblockData 10ca9c 46
GetPokeblockFeederWithinRange c837c 9c 176
GetPokeblockNameByMonNature 10f3ac 30
GetPokedexHeightWeight 90d54 3c
GetPokedexRatingText 10d488 178
GetPokedexSeenCount 948c4 20
GetPokemonCategory 90d3c 18
GetPokemonSpriteToDisplay 8e888 3e 158
GetPostCameraMoveMapBorderId 568b0 28
GetPreviousTextCaretPosition b6f84 36 141
GetPriceReduction beda4 5a
GetPrimaryStatus a1c90 46
GetRamScript 65810 60
GetRecordMixingGift 126338 3c
GetRecordedCyclingRoadResults 10d8ec 48
GetReflectionTypeByMetatileBehavior 63b98 2e 63
GetReflectionVerticalOffset 1268d0 14 70
GetRegionMapLocationPosition fc04c 28 167
GetRegionMapSectionAt fb2ec 40 167
GetRegionMapSectionAt_ fb9a8 16
GetRematchTrainerId 82c4c 1c
GetRematchTrainerIdFromTable 82a90 54
GetRideWaterCurrentMovementAction 60774 2c
GetRivalAvatarGraphicsIdByStateIdAndGender 59840 18
GetRivalSonDaughterString 10e2cc 34
GetRoamerLocation 134538 10
GetRoute119WaterTileNum 84984 c0 239
GetRunningDirectionAnimNum 5fe1c 10
GetSSTidalLocation 10d9ec dc
GetSafariZoneFlag c8184 14
GetSav1Weather 806d8 c
GetSaveValidStatus 125974 214 177
GetScaledExpFraction 46188 4a 15
GetScaledHPFraction 461d4 2a
GetSearchModeSelection 92e10 a0 158
GetSecretBase2Field_9 479f8 c
GetSecretBaseMapName bc1d0 54
GetSecretBaseNearbyMapName 10f3dc 28
GetSecretBaseOwnerType bcca4 44 187
GetSecretBaseTrainerLoseText bcce8 94
GetSecretBaseTrainerNameIndex 3dce4 3c
GetSecretBaseTrainerPicIndex 3dca8 3c
GetSelectedDaycareMonNickname 42328 38
GetSetPokedexFlag 90d90 188
GetShieldToyTVDecorationInfo c6f38 d0
GetShroomishSizeRecordInfo c5b98 1c
GetSioMultiSI 86bc 10
GetSlideMovementAction 607cc 2c
GetSlotMachineId 10f424 64
GetSpeciesName 3dda0 4a
GetSpriteMatrixNum 1c80 20 204
GetSpritePaletteTagByPaletteNum 26f8 10
GetSpriteTileStartByTag 2480 2c
GetSpriteTileTagByTileStart 24d8 4c
GetStageByBerryTreeId b4ca8 1c
GetStageDurationByBerryType b4e38 18 24
GetStarTileOffset aee4c 8
GetStarterPokemon 109e50 1c
GetStatusSymbolTileOffset aefe8 50
GetStoryActionByStat f8490 c 131
GetStoryByStat f844c 2c 131
GetStoryByStattellerPlayerName f8534 2c 131
GetStoryTextByStat f8484 c 131
GetStoryTitleByStat f8478 c 131
GetStringLanguage c86a0 92
GetStringWidth 4bcc 138
GetStringWidthInMenuWindow 72ca8 18
GetStringWidthInTilesForScriptMenu b511c 1c 184
GetSubstruct 3c638 528
GetSumOfEnemyPartyLevel 81f54 e0 21
GetSumOfPlayerPartyLevel 81ef4 60 21
GetTVChannelByShowType bfb54 40
GetTVShowType bda0c 24
GetTagOfReelSymbolOnScreenAtPos 102ba4 54 199
GetTagOfReelSymbolOnScreenAtPos_AdjustForPixelOffset 102bf8 50 199
GetTaskCount 7ad28 30
GetTextCaretPosition b6f44 3e 141
GetTextDelay 3fa4 2a 214
GetTradeSpecies 4db2c 3c
GetTrainerApproachDistanceEast 841d4 42 225
GetTrainerApproachDistanceNorth 8414c 42 225
GetTrainerApproachDistanceSouth 84108 42 225
GetTrainerApproachDistanceWest 84190 42 225
GetTrainerBattleTransition 82080 b8 21
GetTrainerEyeRematchFlag 82a54 3a
GetTrainerFacingDirectionMovementType 5ff14 10
GetTrainerFlag 82564 16
GetTrainerFlagFromScriptPointer 82504 1e
GetTrainerIntroSpeech 8281c 14 21
GetTrainerLoseText 82830 3c
GetTrainerNonBattlingSpeech 82880 14 21
GetTruckBoxMovement c72a8 1a
GetTruckCameraBobbingY c727c 2c
GetTurnOrderNumberGfx b208c 38
GetUnownLetterByPersonality 9d474 34
GetVarPointer 69214 44
GetVectorDirection 5cab0 30
GetWalkFastMovementAction 60748 2c
GetWalkFastestMovementAction 607a0 2c
GetWalkInPlaceFastMovementAction 60958 2c
GetWalkInPlaceFastestMovementAction 60984 2c
GetWalkInPlaceNormalMovementAction 6092c 2c
GetWalkInPlaceSlowMovementAction 60900 2c
GetWalkNormalMovementAction 6071c 2c
GetWalkSlowMovementAction 606f0 2c
GetWarpDestinationMusic 53e48 3c
GetWarpEventAtMapPosition 68c10 22 67
GetWarpEventAtPosition 68d38 48 67
GetWeekCount 10e35c 28
GetWhoStrikesFirst 12ff0 3d8
GetWildBattleTransition 82034 4c 21
GetWord 12618c 18 140
GetWordPhonemes 14a2ec 88
GetWordSounds 14a2d0 1c
GetXYCoordsOneStepInFrontOfPlayer 596c8 44
GivLeadMonEffortRibbon 10f54c 3c
GiveBattleTowerPrize 135dec 64
GiveBoxMonInitialMoveset 3b720 a8
GiveEggFromDaycare 421a0 10
GiveGiftRibbonToParty c5c38 9c
GiveMailToMon a2bc4 17e
GiveMailToMon2 a2d88 6a
GiveMonArtistRibbon c4fbc 86
GiveMonInitialMoveset 3b714 a
GiveMonToPlayer 3d91c 7c
GiveMoveToBattleMon 3b660 44
GiveMoveToBoxMon 3b5f0 70
GiveMoveToMon 3b5dc 12
GivePokeblock 10ca34 38
GlassWorkshopUpdateScrollIndicators 10f2dc 5c
GreatBallOpenParticleAnimation 140dc4 108
GroundEffect_DeepSandTracks 63fd0 2c
GroundEffect_FlowingWater 63f94 e
GroundEffect_HotSprings 641ec e
GroundEffect_IceReflection 63f88 c
GroundEffect_JumpLandingDust 641ac 30
GroundEffect_JumpOnLongGrass 64124 28
GroundEffect_JumpOnShallowWater 6414c 30
GroundEffect_JumpOnTallGrass 640cc 58
GroundEffect_JumpOnWater 6417c 30
GroundEffect_MoveOnLongGrass 63f30 4c
GroundEffect_MoveOnTallGrass 63e98 4c
GroundEffect_Ripple 640a0 a
GroundEffect_SandPile 640bc e
GroundEffect_SandTracks 63fa4 2c
GroundEffect_Seaweed 641fc 20
GroundEffect_ShortGrass 641dc e
GroundEffect_SpawnOnLongGrass 63ee4 4c
GroundEffect_SpawnOnTallGrass 63e4c 4c
GroundEffect_StepOnPuddle 640ac e
GroundEffect_WaterReflection 63f7c c
HBlankCB_Phase2_Mugshots 11c77c 34 23
HBlankCB_Phase2_Transition_Ripple 11be74 2c 23
HBlankCB_Phase2_Transition_Shuffle 11b0c4 2c 23
HBlankCB_Phase2_Transition_Slice 11ccb0 2c 23
HBlankCB_Phase2_Transition_Swirl 11af18 2c 23
HBlankCB_Phase2_Transition_WhiteFade 11cfac 24 23
HBlankIntr 600 30 127
HBlankIntrOff c6204 60 151
HBlankIntrOn c61b0 54 151
HallOfFameRecordEffectHelper 864cc 84
HallOfFameRecordEffect_0 85f40 74
HallOfFameRecordEffect_1 85fb4 30
HallOfFameRecordEffect_2 85fe4 28
HallOfFameRecordEffect_3 8600c 40
HallOfFame_LoadPokemonPic 1436bc e8 107
HallOfFame_LoadTrainerPic 1437a4 c8 107
HallOfFame_PrintMonInfo 143088 278 107
HallOfFame_PrintPlayerInfo 143300 e0 107
HandleAction_Action11 15034 2c
HandleAction_Action9 14fbc 78
HandleAction_ActionFinished 15094 bc
HandleAction_ChooseMove 2c68c 3d4 12
HandleAction_GoNear 14ebc c4
HandleAction_NothingIsFainted 15060 34
HandleAction_Run 14bf4 15c
HandleAction_SafariZoneBallThrow 14d98 60
HandleAction_SafriZoneRun 14f80 3c
HandleAction_Switch 146f4 ac
HandleAction_ThrowPokeblock 14df8 c4
HandleAction_UseItem 147a0 318
HandleAction_UseMove 13fe8 70c
HandleAction_WatchesCarefully 14d50 48
HandleBattlePartyMenu 95118 164
HandleBattleTowerPartyMenu 1222b0 dc
HandleBattleTowerPartyMenuInput 6be3c c4
HandleCloseSaveWindow 946c8 72
HandleDaycareLevelMenuInput 4272c f8 52
HandleDaycarePartyMenu 122e0c a0
HandleDefaultPartyMenu 89cd4 c0
HandleDefaultPartyMenuInput 6bd84 b8
HandleDeniedItemUseMessage c9098 54 117
HandleDpadMovement b62cc 16a 141
HandleDrawSaveWindowInfo 945c0 108
HandleEndTurn_BattleLost 13b64 78
HandleEndTurn_BattleWon 13998 1cc
HandleEndTurn_FinishBattle 13c9c 10c
HandleEndTurn_MonFled 13c48 54
HandleEndTurn_RanFromBattle 13bdc 6c
HandleExtCtrlCode 3080 2c 214
HandleFaintedMonActions 173a4 324
HandleFloorShadowFadeIn b654 6c 128
HandleFloorShadowFadeOut b5a8 6c 128
HandleIntroSlide e43c0 7c
HandleItemMenuPaletteFade a5b00 40
HandleKeyboardEvent b60b8 50 141
HandleLinkBattleSetup b858 2c
HandleLinkMultiBattlePartyMenu 122a48 70
HandleLoadSpecialPokePic d334 44
HandleLowHpMusicChange 324f8 c0
HandleMoveTutorMenuInput 13362c 1d2 137
HandleMoveTutorPartyMenu f9e64 88
HandlePartyMenuSwitchPokemonInput 6cb78 b6
HandlePopupMenuAction_CheckTag a6178 30 116
HandlePopupMenuAction_Confirm a69e0 28 116
HandlePopupMenuAction_Give a60c8 ae 116
HandlePopupMenuAction_Register a5fac 54 116
HandlePopupMenuAction_Toss a5f14 6c 116
HandlePopupMenuAction_UseInBattle a70f4 30 116
HandlePopupMenuAction_UseOnField a5b78 80 116
HandleReadMail f890c 11c
HandleReceiveRemoteLinkPlayer 7668 48 120
HandleSelectPartyMenu f9c6c 7c
HandleWishPerishSongOnTurnEnd 170dc 2c8
HandleWriteSectorNBytes 1253c8 78 177
HasAtLeastFiveBadges 82b44 34
HasEnoughMoneyFor b7ce8 24
HasEnoughMonsForDoubleBattle c5428 28
HasLinkErrorOccurred 8710 c
HasPlayerInputTakenLongerThanList e5bc8 62 28
HasPlayerReceivedBlock c85ac 2c 42
HasSuperEffectiveMoveAgainstOpponents 36514 148 5
HasTrainerAlreadyBeenFought 825a4 18
HasTrainerStatIncreased f8508 2c 131
HaveAllPlayersReceivedBlock c85d8 2c 42
HealStatusConditions 3f16c 6e
HeavyRain_InitAll 7ef90 30
HeavyRain_InitVars 7ef24 6c
HiddenItemAtPos c962c 5c
HideApplauseMeterNoAnim b1d84 34
HideCoinsWindow 11a770 28
HideFieldMessageBox 64c5c 20
HideMapNamePopup a30a4 3c
HideSaveDialog 71714 12 205
HighlightCurrentMenuItem 9fdc e0 128
HighlightOptionMenuItem 8bc3c 24 145
HighlightScreenSelectBarItem 90584 c0 158
HighlightSelectedSearchMenuItem 92ad4 94 158
HighlightSelectedSearchTopBarItem 92ab0 24 158
HighlightSelectedWindow ba6b8 48
HoennPokedexNumToSpecies 3f7b4 4c
HoennToNationalOrder 3f8e0 22
HoldContestPainting 10682c d0 44
IdentifyFlash 1dfab4 a0
IncTrainerCardLosses 110228 2c 19
IncTrainerCardWins 1101fc 2c 19
IncrementGameStat 530d0 38
IncrementRematchStepCounter 82b78 2c
IndexOfSpritePaletteTag 26c0 38
IndexOfSpriteTileTag 24ac 2c 204
InheritIVs 419a8 172 52
InitAndLaunchSpecialAnimation 31660 6c
InitAnimArcTranslation 786f0 2a
InitAnimLinearTranslation 78aa0 98
InitAnimShadowBall ddf40 a8 102
InitAnimSpritePos 787b4 64
InitBackupMapLayoutConnections 560b0 86 80
InitBackupMapLayoutData 56058 58 80
InitBarboachSizeRecord c5bdc 14
InitBirchState 10d3fc 14
InitBlockSend 7d00 70 120
InitCameraUpdateCallback 580b0 40
InitClearSaveDataScreen 148970 1c2 38
InitClockWithRtc 10afe0 7a 236
InitContestMonPixels 106ac4 cc 44
InitContestPaintingBg 1069cc 44 44
InitContestPaintingVars 106a10 48 44
InitContestPaintingWindow 1068fc 1c 44
InitContestResources ab350 48
InitCurrentFlashLevelScanlineEffect 54818 28 148
InitDaycareMailRecordMixing 41324 6e
InitDewfordTrend fa17c a4
InitEasyChatPhrases e6764 c8
InitEventData 69034 3c
InitFieldMessageBox 64a78 2c
InitFlashTimer 5ec 14
InitIceBallAnim d8e4c 94 113
InitIceBallParticle d8f10 64 113
InitIntrHandlers 4c4 7c 127
InitIntroMudkipAttackAnim 13edbc 40 114
InitIntroTorchicAttackAnim 13eb4c 70 114
InitItemStorageMenu 139f58 5c 153
InitKeys 400 28
InitLink 7314 2c 120
InitLinkBattleRecord 10ff78 30 19
InitLinkBattleRecords 1101ec 10
InitLinkBattleRecords_ 10ffa8 32 19
InitLinkBattleVsScreen de30 40c
InitLinkBtlControllers ba78 2dc
InitLinkPlayerObjectEventPos 55a30 3e 148
InitLinkTestBG 7090 98 120
InitLinkTestBG_Unused 7128 7c
InitLocalLinkPlayer 7280 80 120
InitMainCallbacks 388 20 127
InitMainMenu 9708 170 128
InitMap 55fa4 20
InitMapFromSavedGame 55fc4 38
InitMapLayoutData 55ffc 5c 80
InitMapMusic 74bb0 14
InitMatsudaDebugMenu a9b28 50
InitMenu 72d44 68
InitMenuWindow 71c50 c
InitMenuWindowInternal 71d4c 5c 132
InitMirageRnd 10d2d4 20
InitMoriDebugMenu 83f6c 50
InitMoveTutorMenuSprites 133358 200 137
InitMoveTutorMenuStrings 133558 b4 137
InitMoveTutorMenuWaitFade 13269c 3c 137
InitMysteryEventScript 1260ec 30 140
InitObjectEventPalettes 5c7c8 40
InitObjectEventStateFromTemplate 5aca8 138 63
InitObjectPriorityByZCoord 63d18 4c 63
InitObjectReflectionSprite 12680c c4
InitOverworldGraphicsRegisters 54c58 f8 148
InitPaintingMonOamData 106e98 48 44
InitPartyMenu 6b128 33a
InitPlayerAvatar 59ac4 c8
InitPlayerPCMenu 139cf4 70 153
InitPlayerTrainerId 52d2c 28
InitPoisonGasCloudAnim d8700 174 113
InitRamScript 657ac 62
InitRegionMap fa8ec 18
InitRoamer 13430c 12
InitScriptContext 65398 3a
InitSecretBaseAppearance bbccc 104
InitShroomishSizeRecord c5b84 14
InitSinglePlayerBtlControllers b9a8 d0 14
InitSogabeDebugMenu 14a414 50
InitSpriteAffineAnim 21d8 4e
InitSpriteDataForLinearTranslation 78a60 3e
InitStartMenu 71234 24 205
InitStartMenuMultistep 71180 b2 205
InitSwirlingFogAnim d7f10 138 113
InitTimeBasedEvents 6a32c 38
InitTimer 89a0 50 120
InitUnusedBlendTaskData b0548 40
InitVariableWidthFontTileData 2ad8 54 214
InitWindowTileData 2a50 86
InitYesNoMenu 72930 48
InitializeCursorPosition fb32c 2d4 167
InputInit b61d8 14 141
InputState_Disabled b626c 6 141
InputState_Enabled b6274 58 141
InsertStringDigit ae020 32
InsertTask 7aae0 96 212
InstallCameraPanAheadCallback 58260 30
InterviewAfter bde48 62
InterviewAfter_BravoTrainerBattleTowerProfile be320 9c
InterviewAfter_BravoTrainerPokemonProfile be188 b4
InterviewAfter_DummyShow4 be774 2
InterviewAfter_FanClubLetter be5fc 60
InterviewAfter_PkmnFanClubOpinions be6a0 d4
InterviewAfter_RecentHappenings be65c 44
InterviewBefore bf2c4 70
InterviewBefore_BravoTrainerBTProfile bf4bc 38
InterviewBefore_BravoTrainerPkmnProfile bf484 38
InterviewBefore_Dummy bf46c c
InterviewBefore_FanClubLetter bf334 70
InterviewBefore_NameRater bf478 c
InterviewBefore_PkmnFanClubOpinions bf3dc 90
InterviewBefore_RecentHappenings bf3a4 38
IntrDummy 690 2 127
Intro_TryShinyAnimShowHealthbox 137538 180 13
Intro_WaitForShinyAnimAndHealthbox 1376b8 f8 13
InventoryContainsDecoration 133fe4 46
InvertPlttBuffer 7433c 48
IsAnimBankSpriteVisible 75fc0 78
IsArrowWarpMetatileBehavior 68bb8 56 67
IsBGMPausedOrStopped 74fd4 26
IsBGMPlaying 755d8 26
IsBGMStopped 7502c 1a
IsBagPocketNonEmpty a929c 38
IsBankSpritePresent 78878 90
IsBattleTransitionDone 11aae8 38
IsBerryTreeSparkling 60238 54
IsBikingDisallowedByPlayer e5ef4 4a
IsBlueYellowRedFlute 70030 1c
IsContest 76be4 26
IsContestantAllowedToCombo b214c 36
IsCoordInConnectingMap 56b50 14 80
IsCoordInIncomingConnectingMap 56b24 2a 80
IsCoordOutsideObjectEventMovementRange 600f4 70 63
IsCryFinished 75378 22
IsCryPlaying 753ec 1e
IsCryPlayingOrClearCrySongs 753c8 22
IsCursorAnimFinished b6938 20 141
IsDoorAnimationStopped 67d30 16 182
IsDoubleBattle 78908 10
IsDummyWarp 532d4 3a 148
IsEasyChatPairEqual fa7fc 2a 53
IsEggPending 422b4 10 52
IsEnigmaBerryValid b4940 4c
IsEnoughMoney b79a8 10
IsFanfareTaskInactive 74efc 1e
IsFieldMessageBoxHidden 64c88 1a
IsFirstTrainerIdReadyForRematch 82a18 3a
IsGrassTypeInParty 10f018 78
IsGridCursorMovementClamped 723d8 b0 132
IsHMMove 6f7bc 30
IsHMMove2 40a00 3a
IsHPRecoveryItem 6fb80 36
IsImprisoned 15d5c a0
IsInfiltratedWeatherInstitute 53d6c 30 148
IsInfoScreenScrolling 8f250 32 158
IsLeapYear 9148 38
IsLinkConnectionEstablished 86f4 10
IsLinkDoubleBattle 6b52c 1e
IsLinkMaster 8310 10
IsLinkPlayerDataExchangeComplete 7c48 68
IsLinkTaskFinished 7ecc 18
IsMedicineIneffective 6fd94 34
IsMetatileDirectionallyImpassable 60164 58 63
IsMirageIslandPresent 10d32c 4a
IsMonAllowedInBattleTower 122030 98 37
IsMonDisobedient 1b928 328
IsMonValidSpecies c5684 22 74
IsMoveUnchoosable 2838c 28 20
IsMoveUncopyable 27694 48 20
IsMoveWithoutAnimation 31720 4
IsMysteryEventEnabled 69190 14
IsNationalPokedexEnabled 69130 3e
IsNotWaitingForBGMStop 74e18 22
IsOtherTrainer 40ad0 4c
IsPageSwapAnimNotInProgress b6610 1e 141
IsPaletteNotActive 6624c 1e
IsPartyMemberAlreadySelected 1221cc 2c 37
IsPicboxClosed b59ac 1e 184
IsPlayerDefeated 8227c 3e 21
IsPlayerFacingSurfableFishableWater 59958 8a
IsPlayerFacingUnplantedSoil b4a34 36
IsPlayerLinkLeader ae074 22
IsPlayerSurfingNorth 59934 24
IsPokeSpriteNotFlipped 40a3c 18
IsPokemonCryPlaying 1df524 16
IsPokerusInParty 10f738 1e
IsPosInConnectingMap 56b64 40 80
IsPosInIncomingConnectingMap 56ac0 64 80
IsPriceDiscounted bee00 48
IsRecordMixingGiftValid 126288 38 140
IsRematchStepCounterMaxed 82ba4 2a
IsRematchTrainerIn 82c2c 20
IsRematchTrainerIn_ 829e8 30
IsResizeSaveWindowEnabled 9473c 4
IsRoamerAt 13441c 32
IsRunningDisallowed e5dec 26
IsRunningDisallowedByMetatile e5e14 36 28
IsSEPlaying 75594 42
IsScriptActive b54c8 1a
IsSectorNonEmpty 1472e4 40 178
IsSelectedMonEgg fa148 34
IsShiny 40cb4 2a
IsShinyOtIdPersonality 40ce0 28
IsSioMultiMaster 86cc 28 120
IsSoftwarePaletteFadeFinishing 74adc 64 149
IsSpecialSEPlaying 75600 26
IsSpeciesNotUnown aeb1c 14
IsStarterInParty 10f694 56
IsTVShowInSearchOfTrainersAiring bdcc4 18
IsTradedMon 40aa4 2a
IsTrainerReadyForRematch 82c9c 1c
IsTrendyPhraseBoring fa5e4 64
IsTwoTurnsMove 28350 3a 20
IsWarpMetatileBehavior 68b34 82 67
IsWeatherChangeComplete 7ddfc 14
IsWeatherNotFadingIn 7d770 1c
IsWildLevelAllowedByRepel 85598 66 239
IsZCoordMismatchAt 63c80 3a
ItemBattleEffects 1a02c 13e0
ItemIdToBattleMoveId 6f028 18
ItemIdToBerryType b4cc4 26
ItemId_CopyDescription a99a8 60
ItemId_GetBattleFunc a9ae0 24
ItemId_GetBattleUsage a9abc 24
ItemId_GetDescription a9984 24
ItemId_GetExitsBagOnUse a9a2c 24
ItemId_GetFieldFunc a9a98 24
ItemId_GetHoldEffect a993c 24
ItemId_GetHoldEffectParam a9960 24
ItemId_GetId a98f4 24
ItemId_GetImportance a9a08 24
ItemId_GetName a98d4 20
ItemId_GetPocket a9a50 24
ItemId_GetPrice a9918 24
ItemId_GetSecondaryId a9b04 24
ItemId_GetType a9a74 24
ItemIsMail a2f2c 18
ItemListMenu_ChangeDescription a49ac a8 116
ItemListMenu_InitDescription a490c a0 116
ItemListMenu_InitMenu a736c 54 116
ItemMenu_ConfirmComplexFade c9038 16
ItemMenu_ConfirmNormalFade c9014 22
ItemMenu_LoadSellMenu a6300 1c
ItemMenu_ReadMail c9154 40
ItemStorageMenuPrint 139fb4 20 153
ItemStorageMenuProcessInput 139fd4 a4 153
ItemStorage_Deposit 13a0a0 28 153
ItemStorage_DoItemAction 13a4b4 d0 153
ItemStorage_DoItemSwap 13aa30 94 153
ItemStorage_DoItemToss 13a794 a8 153
ItemStorage_DoItemWithdraw 13a6fc 98 153
ItemStorage_DrawBothListAndDescription 13ae0c 60 153
ItemStorage_DrawItemList 13abe8 16e 153
ItemStorage_DrawItemName 13ab28 3c 153
ItemStorage_DrawItemQuantity 13aac4 4c 153
ItemStorage_DrawItemVoidQuantity 13ab10 18 153
ItemStorage_DrawKeyItemEntry 13ab90 1a 153
ItemStorage_DrawNormalItemEntry 13ab64 2a 153
ItemStorage_DrawTMHMEntry 13abac 3a 153
ItemStorage_Exit 13a21c 24 153
ItemStorage_GoBackToItemPCMenu 13ae6c 98 153
ItemStorage_GoBackToPlayerPCMenu 13a468 4c 153
ItemStorage_HandleQuantityRolling 13a584 178 153
ItemStorage_HandleRemoveItem 13a8f0 94 153
ItemStorage_HandleResumeProcessInput 13a9ec 44 153
ItemStorage_HandleReturnToProcessInput 13a0c8 30 153
ItemStorage_LoadPalette 13af04 38 153
ItemStorage_PrintItemPcResponse 13ad58 b2 153
ItemStorage_ProcessInput 13a280 1e6 153
ItemStorage_ResumeInputFromNoToss 13a878 78 153
ItemStorage_ResumeInputFromYesToss 13a83c 3c 153
ItemStorage_ReturnToMenuAfterDeposit 13a0f8 20
ItemStorage_SetItemAndMailCount 13a240 40 153
ItemStorage_Toss 13a198 84 153
ItemStorage_WaitPressHandleResumeProcessInput 13a984 68 153
ItemStorage_Withdraw 13a118 80 153
ItemUseInBattle_EnigmaBerry ca64c a4
ItemUseInBattle_Escape ca4c8 58
ItemUseInBattle_Medicine ca3f4 1c
ItemUseInBattle_PPRecovery ca42c 1c
ItemUseInBattle_PokeBall ca244 50
ItemUseInBattle_StatIncrease ca310 84
ItemUseMoveMenu_HandleCancel 704f4 80 150
ItemUseMoveMenu_HandleMoveSelection 704b4 40 150
ItemUseOnFieldCB_Berry c9d00 30 117
ItemUseOnFieldCB_Bike c929c 48
ItemUseOnFieldCB_EscapeRope ca18c 3c 117
ItemUseOnFieldCB_Itemfinder c9408 50
ItemUseOnFieldCB_Rod c93b8 28
ItemUseOnFieldCB_WailmerPail c9d74 24 117
ItemUseOutOfBattle_Berry c9c7c 84
ItemUseOutOfBattle_Bike c91cc d0
ItemUseOutOfBattle_BlackWhiteFlute ca0dc 94
ItemUseOutOfBattle_CannotUse ca6f0 20
ItemUseOutOfBattle_CoinCase c9b38 80
ItemUseOutOfBattle_EnigmaBerry ca520 12c
ItemUseOutOfBattle_EscapeRope ca1e4 44
ItemUseOutOfBattle_EvolutionStone ca228 1c
ItemUseOutOfBattle_Itemfinder c93e0 28
ItemUseOutOfBattle_Mail c9194 38
ItemUseOutOfBattle_Medicine c9db0 1c
ItemUseOutOfBattle_PPRecovery c9e3c 1c
ItemUseOutOfBattle_PPUp c9e58 1c
ItemUseOutOfBattle_PokeblockCase c9ac8 70
ItemUseOutOfBattle_RareCandy c9e74 1c
ItemUseOutOfBattle_Repel ca014 68
ItemUseOutOfBattle_Rod c9378 40
ItemUseOutOfBattle_SSTicket c9bf8 84
ItemUseOutOfBattle_SacredAsh c9dcc 70
ItemUseOutOfBattle_TMHM c9e90 54
ItemUseOutOfBattle_WailmerPail c9d30 44
ItemfinderCheckForHiddenItems c9548 e4
JamByMoveCategory b9038 88 41
JamContestant b9200 24 41
JumpIfMoveAffectedByProtect 1c108 6c 20
JumpIfMoveFailed 1c008 90 20
JumpToTopOfAffineAnimLoop 1b34 6c 204
JumpToTopOfAnimLoop 18d8 72 204
KeyboardKeyHandler_Backspace b6170 22 141
KeyboardKeyHandler_Character b6108 40 141
KeyboardKeyHandler_OK b6194 34 141
KeyboardKeyHandler_Page b6148 28 141
LZ77UnCompVram 1e0780 4
LZ77UnCompWram 1e0784 4
LZDecompressVram d244 a
LZDecompressWram d238 a
LaunchBattleAnimation 7573c 1b0
LaunchBattleTransitionTask 11ab20 30 23
LaunchPokeblockFeedTask 147ddc 34 157
LaunchTask_PostEvoSparklesSet1 149b44 18
LaunchTask_PostEvoSparklesSet2AndFlash 149c20 30
LaunchTask_PostEvoSparklesSet2AndFlash_Trade 149d5c 30
LaunchTask_PreEvoSparklesSet1 149970 30
LaunchTask_PreEvoSparklesSet2 149a90 18
LeadMonHasEffortRibbon 10f524 28
LeadMonNicknamed bf544 16
LightRain_Finish 7e460 8c
LightRain_InitAll 7e3d0 30
LightRain_InitVars 7e364 6c
LightRain_Main 7e400 60
LightenSpritePaletteInFog 7d574 46 78
LinkCB_BlockSend 7d94 64 120
LinkCB_BlockSendBegin 7d70 24 120
LinkCB_BlockSendEnd 7df8 c 120
LinkCB_RequestPlayerDataExchange 802c 2c 120
LinkContest_GetLeaderIndex c4b34 26
LinkMain1 8848 12a
LinkMain2 75f0 78
LinkOpponentBufferExecCompleted 38004 78
LinkOpponentHandleBallThrow 39a18 a
LinkOpponentHandleBattleAnimation 3a5d8 68
LinkOpponentHandleDMATransfer 39f70 a
LinkOpponentHandleEffectivenessSound 3a0d4 44
LinkOpponentHandleExpBarUpdate 39e70 a
LinkOpponentHandleFaintingCry 3a148 3c
LinkOpponentHandleGetAttributes 3807c 72
LinkOpponentHandleHealthBarUpdate 39d80 f0
LinkOpponentHandleHitAnimation 3a058 70
LinkOpponentHandleIntroSlide 3a184 34
LinkOpponentHandleLinkStandbyMsg 3a640 a
LinkOpponentHandleLoadPokeSprite 39294 150
LinkOpponentHandleMoveAnimation 39a30 134
LinkOpponentHandleOpenBag 39d5c a
LinkOpponentHandlePrintString 39cc8 64
LinkOpponentHandlePrintStringPlayerOnly 39d2c a
LinkOpponentHandlePuase 39a24 a
LinkOpponentHandleResetActionMoveSelection 3a64c a
LinkOpponentHandleReturnPokeToBall 395b4 94
LinkOpponentHandleSendOutPoke 393e4 4c
LinkOpponentHandleSetAttributes 388a8 58
LinkOpponentHandleSpriteInvisibility 3a578 60
LinkOpponentHandleStatusAnimation 39ef0 68
LinkOpponentHandleStatusIconUpdate 39e7c 74
LinkOpponentHandleStatusXor 39f58 a
LinkOpponentHandleTrainerBallThrow 3a1b8 10c
LinkOpponentHandleTrainerSlide 398a4 a
LinkOpponentHandleTrainerSlideBack 398b0 ac
LinkOpponentHandleTrainerThrow 396d0 1d4
LinkOpponentHandlecmd1 3889c a
LinkOpponentHandlecmd10 3995c a4
LinkOpponentHandlecmd11 39a00 a
LinkOpponentHandlecmd12 39a0c a
LinkOpponentHandlecmd18 39d38 a
LinkOpponentHandlecmd19 39d44 a
LinkOpponentHandlecmd20 39d50 a
LinkOpponentHandlecmd22 39d68 a
LinkOpponentHandlecmd23 39d74 a
LinkOpponentHandlecmd29 39f64 a
LinkOpponentHandlecmd3 39220 74
LinkOpponentHandlecmd31 39f7c a
LinkOpponentHandlecmd32 39f88 a
LinkOpponentHandlecmd33 39f94 a
LinkOpponentHandlecmd34 39fa0 a
LinkOpponentHandlecmd35 39fac a
LinkOpponentHandlecmd36 39fb8 a
LinkOpponentHandlecmd37 39fc4 1c
LinkOpponentHandlecmd38 39fe0 38
LinkOpponentHandlecmd39 3a018 18
LinkOpponentHandlecmd40 3a030 28
LinkOpponentHandlecmd42 3a0c8 a
LinkOpponentHandlecmd44 3a118 30
LinkOpponentHandlecmd48 3a3dc 104
LinkOpponentHandlecmd49 3a520 4c
LinkOpponentHandlecmd50 3a56c a
LinkOpponentHandlecmd55 3a658 64
LinkOpponentHandlecmd56 3a6bc 2
LinkPartnerBufferExecCompleted 11e314 78
LinkPartnerBufferRunCommand 11da94 50
LinkPartnerHandleBallThrow 11fde4 a
LinkPartnerHandleBattleAnimation 1209d8 68
LinkPartnerHandleDMATransfer 12033c a
LinkPartnerHandleEffectivenessSound 1204a0 44
LinkPartnerHandleExpBarUpdate 12023c a
LinkPartnerHandleFaintingCry 120514 40
LinkPartnerHandleGetAttributes 11e3e4 72
LinkPartnerHandleHealthBarUpdate 12014c f0
LinkPartnerHandleHitAnimation 120424 70
LinkPartnerHandleIntroSlide 120554 34
LinkPartnerHandleLinkStandbyMsg 120a40 a
LinkPartnerHandleLoadPokeSprite 11f6d8 11c
LinkPartnerHandleMoveAnimation 11fdfc 134
LinkPartnerHandleOpenBag 120128 a
LinkPartnerHandlePrintString 120094 64
LinkPartnerHandlePrintStringPlayerOnly 1200f8 a
LinkPartnerHandlePuase 11fdf0 a
LinkPartnerHandleResetActionMoveSelection 120a4c a
LinkPartnerHandleReturnPokeToBall 11f9d0 8c
LinkPartnerHandleSendOutPoke 11f7f4 70
LinkPartnerHandleSetAttributes 11ec10 58
LinkPartnerHandleSpriteInvisibility 120978 60
LinkPartnerHandleStatusAnimation 1202bc 68
LinkPartnerHandleStatusIconUpdate 120248 74
LinkPartnerHandleStatusXor 120324 a
LinkPartnerHandleTrainerBallThrow 120588 194
LinkPartnerHandleTrainerSlide 11fc30 a
LinkPartnerHandleTrainerSlideBack 11fc3c ac
LinkPartnerHandleTrainerThrow 11fae4 14c
LinkPartnerHandlecmd1 11ec04 a
LinkPartnerHandlecmd10 11fce8 e4
LinkPartnerHandlecmd11 11fdcc a
LinkPartnerHandlecmd12 11fdd8 a
LinkPartnerHandlecmd18 120104 a
LinkPartnerHandlecmd19 120110 a
LinkPartnerHandlecmd20 12011c a
LinkPartnerHandlecmd22 120134 a
LinkPartnerHandlecmd23 120140 a
LinkPartnerHandlecmd29 120330 a
LinkPartnerHandlecmd3 11f664 74
LinkPartnerHandlecmd31 120348 a
LinkPartnerHandlecmd32 120354 a
LinkPartnerHandlecmd33 120360 a
LinkPartnerHandlecmd34 12036c a
LinkPartnerHandlecmd35 120378 a
LinkPartnerHandlecmd36 120384 a
LinkPartnerHandlecmd37 120390 1c
LinkPartnerHandlecmd38 1203ac 38
LinkPartnerHandlecmd39 1203e4 18
LinkPartnerHandlecmd40 1203fc 28
LinkPartnerHandlecmd42 120494 a
LinkPartnerHandlecmd44 1204e4 30
LinkPartnerHandlecmd48 120828 b8
LinkPartnerHandlecmd49 120920 4c
LinkPartnerHandlecmd50 12096c a
LinkPartnerHandlecmd55 120a58 4c
LinkPartnerHandlecmd56 120aa4 2
LinkPlayerDetectCollision 55dd4 8c 148
LinkTestCalcBlockChecksum 7f74 2e 120
LinkTestProcessKeyInput 7510 bc 120
LinkTestScreen 71a4 cc
LinkVSync 8bec 70
LoadAllContestMonIcons c30d4 38 43
LoadAppropiateBankSprite 7b098 f0 168
LoadAreaUnknownGraphics 1117ac 38 159
LoadAshSpriteSheet 7f99c 10
LoadBagGraphicsMultistep a3520 10a 116
LoadBallGraphics 478dc 70
LoadBattleBarGfx 31d5c 14
LoadBattleTextboxAndBackground dab8 40
LoadBerryPic a7cf8 94 116
LoadBikeScene 144ecc 1de 47
LoadChosenBattleElement e414 3b0
LoadCompressedObjectPalette d2a4 34
LoadCompressedObjectPaletteOverrideBuffer d2d8 30
LoadCompressedObjectPic d250 2c
LoadCompressedObjectPicOverrideBuffer d27c 28
LoadCompressedPalette 73a18 44
LoadContestBgAfterMoveAnim ab2ac 74
LoadContestPaintingFrame 106c40 258 44
LoadCopyrightGraphics 13b808 4c 114
LoadCryWaveformWindow 119e3c 14c
LoadCurrentMapData 5334c 40 148
LoadCustomWeatherSpritePalette 7d8c0 30
LoadDefaultBg 76eb4 1a 6
LoadDroughtWeatherPalette 7d8f0 b8 78
LoadDroughtWeatherPalettes 7d9c8 3c
LoadEasyChatStrings eb040 70
LoadEvoSparkleSpriteAndPal 149954 1c
LoadFixedWidthFont 2b2c 2a 214
LoadFixedWidthFont_Braille 2bc8 34 214
LoadFixedWidthFont_Font1Latin 2b58 34 214
LoadFixedWidthFont_Font4Latin 2b8c 3c 214
LoadFixedWidthGlyph 3954 96 214
LoadFontDefaultPalette 2a1c 18
LoadHeldItemIconGraphics 6da9c 1c
LoadInfoScreen 8f210 40 158
LoadMapFromCameraTransition 538f0 a4
LoadMapTilesetPalettes 56d88 18
LoadMoveBg 76dbc f8 6
LoadOam f70 30
LoadObjEventTemplatesFromHeader 53154 44
LoadObjectEvents 47b04 38 121
LoadObjectHighBridgeReflectionPalette 1269b0 30 70
LoadObjectReflectionPalette 1268e4 6e 70
LoadObjectRegularReflectionPalette 126954 5a 70
LoadPalette 73a5c 38
LoadPartyMenuGraphics 6d71c e0
LoadPlayArrowPalette 90040 30 158
LoadPlayerBag 47b5c bc
LoadPlayerObjectReflectionPalette 5bf30 6e
LoadPlayerParty 47a84 48
LoadPokedexBgPalette 8d640 50 158
LoadPokedexListPage 8d344 2fa 158
LoadPokemonSummaryScreenGraphics 9df00 144 163
LoadPrimaryTilesetPalette 56d50 10 80
LoadPtrFromTaskData b9a44 c
LoadRainSpriteSheet 7e7a4 10
LoadRotatingGatePics c7db0 10 174
LoadSaveblockMapHeader 5338c 40 148
LoadSaveblockObjEventScripts 53198 28 148
LoadSavedMapView 56674 80 80
LoadScreenSelectBarMain 904fc 44 158
LoadScreenSelectBarSubmenu 90540 44 158
LoadScrollIndicatorPalette f9818 10
LoadSearchMenu 91e3c 18 158
LoadSecondaryTilesetPalette 56d60 10
LoadSerializedGame 47b4c e
LoadSlotMachineWheelOverlay 1064d8 d0 199
LoadSpecialObjectReflectionPalette 5bfa0 76
LoadSpecialPokePic d378 a8
LoadSpritePalette 2600 4c
LoadSpritePalettes 264c 2c
LoadSpriteSheet 22a8 44
LoadSpriteSheetDeferred 2594 32
LoadSpriteSheets 22ec 2a
LoadSprites 124118 354 35
LoadTextWindowPalette 65018 22 215
LoadTextWindowTiles 64ffc 1c 215
LoadTheEndScreen 145128 e0 47
LoadTilesForSpriteSheet 2370 2c
LoadTilesForSpriteSheets 239c 2a
LoadTilesetPalette 56cc0 6a 80
LoadTrainerEyesDescriptionLines f0cd8 84
LoadTrainerGfx_TrainerCard 85a5c 38
LoadWallClockGraphics 10a718 14c 236
LoadWordFromTwoHalfwords 40ef8 e
LockPlayerFieldControls 65534 c
LockSelectedObjectEvent 64ddc 54
LotteryCornerComputerEffect 10e6a4 80 76
MEScrCmd_addrareword 1265b0 2c
MEScrCmd_addtrainer 126714 40
MEScrCmd_checkcompat 126380 50
MEScrCmd_checksum 126778 46
MEScrCmd_crc 1267c0 4a
MEScrCmd_enableresetrtc 126754 24
MEScrCmd_end 126374 c
MEScrCmd_givenationaldex 12658c 24
MEScrCmd_givepokemon 126608 10c
MEScrCmd_giveribbon 1264f0 34
MEScrCmd_initramscript 126524 66
MEScrCmd_nop 1263d0 4
MEScrCmd_runscript 12641c 1c
MEScrCmd_setenigmaberry 126438 b8
MEScrCmd_setmsg 1263e4 38
MEScrCmd_setrecordmixinggift 1265dc 2a
MEScrCmd_setstatus 1263d4 e
MPlayContinue 1ddd8c 1c
MPlayExtender 1de0f0 118
MPlayFadeOut 1ddda8 20
MPlayJumpTableCopy 1dd5a4 16
MPlayMain 1dd7b4 268
MPlayOpen 1de574 78
MPlayStart 1de5ec e4
MachBikeTransition_FaceDirection e5168 12 28
MachBikeTransition_TrySlowDown e5270 6c 28
MachBikeTransition_TrySpeedUp e51c4 ac 28
MachBikeTransition_TurnDirection e517c 48 28
MailSpeciesToSpecies a2d64 22
Mailbox_Cancel 13b734 24 153
Mailbox_CloseScrollIndicators 13b27c 16 153
Mailbox_DoGiveMailPokeMenu 13b66c 38 153
Mailbox_DoMailMoveToBag 13b578 98 153
Mailbox_DoMailRead 13b428 2c 153
Mailbox_DoRedrawMailboxMenuAfterReturn 13b4d0 20 153
Mailbox_DrawMailList 13b01c ec 153
Mailbox_DrawMailMenuAndDoProcessInput 13b758 2c 153
Mailbox_DrawMailboxMenu 13b108 6c 153
Mailbox_DrawYesNoBeforeMove 13b554 24 153
Mailbox_FadeAndReadMail 13b454 4c 153
Mailbox_Give 13b630 3c 153
Mailbox_HandleReturnToProcessInput 13b4a0 30 153
Mailbox_MailOptionsProcessInput 13b3a0 86 153
Mailbox_MoveToBag 13b510 44 153
Mailbox_NoPokemonForMail 13b718 1c 153
Mailbox_PrintMailOptions 13b348 58 153
Mailbox_PrintWhatToDoWithPlayerMailText 13b294 6c 153
Mailbox_ProcessInput 13b174 106 153
Mailbox_ReturnToFieldFromReadMail 13b4f0 20 153
Mailbox_ReturnToInputAfterNo 13b610 20 153
Mailbox_ReturnToMailListAfterDeposit 13b6f8 20
Mailbox_ReturnToPlayerPC 13b300 20 153
Mailbox_TurnOff 13b320 28 153
Mailbox_UpdateMailList 13af78 a4 153
Mailbox_UpdateMailListAfterDeposit 13b6a4 54 153
MainCB 8b610 16 145
MainCB 8c5f0 16 158
MainCB2 7c458 16 222
MainCB2 b3094 16 193
MainCB2 145efc 16 54
MainCB2_EndIntro 13b7ec 1c 114
MainCB2_Intro 13b798 54 114
MainCB_AreaScren 1107f0 24 159
MainCallback2 10a11c 16 206
MainMenuProcessKeyInput 9d6c 112 128
MainState_6 b5fec 60 141
MainState_BeginFadeIn b5ea8 28 141
MainState_BeginFadeInOut b606c 28 141
MainState_HandleInput b5f00 e 141
MainState_MoveToOKButton b5f10 28 141
MainState_StartPageSwap b5f38 38 141
MainState_UpdateSentToPCMessage b604c 20 141
MainState_WaitFadeIn b5ed0 30 141
MainState_WaitFadeOutAndExit b6094 24 141
MainState_WaitPageSwap b5f70 7c 141
MakeContestantNervous b157c 20
MakeObjectTemplateFromObjectEventGraphicsInfo 5b328 34
MakeObjectTemplateFromObjectEventGraphicsInfoWithCallbackIndex 5b35c 20 63
MakeObjectTemplateFromObjectEventTemplate 5b37c 18 63
MapGridGetCollisionAt 56394 74
MapGridGetElevationAt 56328 6c
MapGridGetMetatileBehaviorAt 564a0 18
MapGridGetMetatileIdAt 56408 98
MapGridGetMetatileLayerTypeAt 564b8 1c
MapGridSetMetatileEntryAt 5651c 38
MapGridSetMetatileIdAt 564d4 48
MapHasMon 110ba4 56 159
MapHeaderCheckScriptTable 656a4 60 183
MapHeaderGetScriptTable 6564c 3e 183
MapHeaderRunScriptType 6568c 16 183
MapMusicMain 74bc4 f8
MapPosToBgTilemapOffset 58028 48 66
MarkAllBattlersForControllerExec 154e4 70
MarkBattlerForControllerExec 15554 50
MarkFogSpritePalToLighten 7d540 34 78
MasterBallOpenParticleAnimation 141058 10c
MatsudaDebugMenu_CommTest a9c40 58
MatsudaDebugMenu_Contest a9c1c 18
MatsudaDebugMenu_ContestComm a9c34 c
MatsudaDebugMenu_ContestResults a9bbc 28
MatsudaDebugMenu_ResetHighScore aafec 40
MatsudaDebugMenu_SetArtMuseumItems ab02c 58
MatsudaDebugMenu_SetHighScore aafdc 10
MauvilleGymSpecial1 10dc7c 50
MauvilleGymSpecial2 10dccc 210
MauvilleGymSpecial3 10dedc 194
MedRain_InitAll 7eef4 30
MedRain_InitVars 7ee80 74
MenuCursor_Create814A5C0 14a5c0 198
MenuCursor_Destroy814AD44 14ad44 38
MenuCursor_SetPos814A880 14a880 84
MenuCursor_SetPos814AD7C 14ad7c 4c
MenuPrintMessage 72014 34
MenuPrintMessageDefaultCoords 72048 28
MenuPrint_AlignedToRightOfReferenceString 72b84 58
MenuPrint_Centered 72bdc 3c
MenuPrint_RightAligned 72b50 34
Menu_BlankWindowRect 71ec0 38
Menu_ClearWindowText 720b4 14
Menu_DestroyCursor 72df0 a
Menu_DisplayDialogueFrame 72000 14
Menu_DrawStdWindowFrame 71f0c 38
Menu_EraseScreen 71ef8 12
Menu_EraseWindowRect 71e88 38
Menu_GetColumnXCoord 72890 14
Menu_GetCursorPos 72168 c
Menu_GetTextColors 72cd8 20
Menu_GetTextWindowPaletteNum 72cc0 18
Menu_LoadStdFrameGraphics 71e1c 14
Menu_LoadStdFrameGraphicsOverrideStyle 71e04 18
Menu_MoveCursor 720c8 4e
Menu_MoveCursorNoWrap 72118 4e
Menu_PrintItems 728a4 42
Menu_PrintItemsReordered 728e8 48
Menu_PrintText 71e54 34
Menu_PrintTextPixelCoords 729dc 40
Menu_ProcessInput 72174 82
Menu_ProcessInputGridLayout 727d0 c0
Menu_ProcessInputNoWrap 721f8 9a
Menu_ProcessInputNoWrap_ 729cc e
Menu_SetText 72070 14
Menu_UpdateWindowText 72084 18
Menu_UpdateWindowTextOverrideLineLength 72cf8 18
MetatileBehavior_GetBridgeType 57454 16
MetatileBehavior_HasRipples 573a4 1c
MetatileBehavior_IsATile 56da0 4
MetatileBehavior_IsAquaHideoutWarp 577c4 14
MetatileBehavior_IsAshGrass 57410 14
MetatileBehavior_IsBerryTreeSoil 573fc 14
MetatileBehavior_IsBlockDecoration 57278 14
MetatileBehavior_IsBlueprint 579ac 14
MetatileBehavior_IsBookShelf 57948 14
MetatileBehavior_IsBridge 57438 1a
MetatileBehavior_IsBumpySlope 57858 14
MetatileBehavior_IsClosedSootopolisDoor 57738 14
MetatileBehavior_IsCounter 5716c 14
MetatileBehavior_IsCrackedFloor 57830 14
MetatileBehavior_IsCrackedFloorHole 5781c 14
MetatileBehavior_IsCrackedIce 57558 14
MetatileBehavior_IsCuttableGrass 578fc 24
MetatileBehavior_IsDeepSand 56e4c 14
MetatileBehavior_IsDeepSouthWarp 56f28 14
MetatileBehavior_IsDiveable 574f0 20
MetatileBehavior_IsDoor 56eb0 18
MetatileBehavior_IsEastArrowWarp 56f60 14
MetatileBehavior_IsEastBlocked 575cc 24
MetatileBehavior_IsEastwardCurrent 57108 14
MetatileBehavior_IsEncounterTile 56da4 22
MetatileBehavior_IsEscalator 56ec8 1a
MetatileBehavior_IsFeebasEncounterable 575a0 2a
MetatileBehavior_IsFootprints 57424 14
MetatileBehavior_IsForcedMovementTile 57000 40
MetatileBehavior_IsFortreeBridge 57690 14
MetatileBehavior_IsHorizontalRail 578a8 14
MetatileBehavior_IsHotSprings 57668 14
MetatileBehavior_IsIce 56e88 14
MetatileBehavior_IsIce_2 57040 14
MetatileBehavior_IsIndoorEncounter 574c8 14
MetatileBehavior_IsIsolatedHorizontalRail 57880 14
MetatileBehavior_IsIsolatedVerticalRail 5786c 14
MetatileBehavior_IsJumpEast 56dc8 14
MetatileBehavior_IsJumpNorth 56df0 14
MetatileBehavior_IsJumpSouth 56e04 14
MetatileBehavior_IsJumpWest 56ddc 14
MetatileBehavior_IsLadder 56ef8 14
MetatileBehavior_IsLandWildEncounter 5746c 2c
MetatileBehavior_IsLargeMatCenter 572f0 14
MetatileBehavior_IsLavaridge1FWarp 577b0 14
MetatileBehavior_IsLavaridgeB1FWarp 5779c 14
MetatileBehavior_IsLinkBattleRecords 571b0 14
MetatileBehavior_IsLongGrass 573e8 14
MetatileBehavior_IsMountainTop 574dc 14
MetatileBehavior_IsMtPyreHole 57808 14
MetatileBehavior_IsMuddySlope 57844 14
MetatileBehavior_IsNonAnimDoor 56f0c 1c
MetatileBehavior_IsNormal 572a0 12
MetatileBehavior_IsNorthArrowWarp 56f88 18
MetatileBehavior_IsNorthBlocked 57614 20
MetatileBehavior_IsNorthwardCurrent 570cc 14
MetatileBehavior_IsNotSurfacable 57510 18
MetatileBehavior_IsOceanWater 5756c 1c
MetatileBehavior_IsOpenSecretBaseDoor 571c4 2c
MetatileBehavior_IsPC 5719c 14
MetatileBehavior_IsPacifidlogHorizontalLog1 576cc 14
MetatileBehavior_IsPacifidlogHorizontalLog2 576e0 14
MetatileBehavior_IsPacifidlogLog 576f4 1a
MetatileBehavior_IsPacifidlogVerticalLog1 576a4 14
MetatileBehavior_IsPacifidlogVerticalLog2 576b8 14
MetatileBehavior_IsPictureBookShelf 57934 14
MetatileBehavior_IsPlayerFacingTVScreen 57180 1c
MetatileBehavior_IsPlayerRoomPCOn 57390 14
MetatileBehavior_IsPokeCenterBookShelf 5795c 14
MetatileBehavior_IsPokeGrass 56e18 1a
MetatileBehavior_IsPokeblockFeeder 57760 14
MetatileBehavior_IsPuddle 573c0 14
MetatileBehavior_IsRecordMixingSecretBasePC 57250 14
MetatileBehavior_IsReflective 56e60 28
MetatileBehavior_IsRegionMap 57724 14
MetatileBehavior_IsRoulette 5774c 14
MetatileBehavior_IsRunningDisallowed 578d4 26
MetatileBehavior_IsRunningShoesManual 57920 14
MetatileBehavior_IsSandOrDeepSand 56e34 18
MetatileBehavior_IsSeaweed 578bc 18
MetatileBehavior_IsSecretBaseBalloon 57318 14
MetatileBehavior_IsSecretBaseBreakableDoor 5732c 14
MetatileBehavior_IsSecretBaseCave 571f0 20
MetatileBehavior_IsSecretBaseGlitterMat 57354 14
MetatileBehavior_IsSecretBaseHole 57304 14
MetatileBehavior_IsSecretBaseImpassable 5728c 14
MetatileBehavior_IsSecretBaseJumpMat 57774 14
MetatileBehavior_IsSecretBaseLargeMatEdge 572dc 14
MetatileBehavior_IsSecretBaseMusicNoteMat 57340 14
MetatileBehavior_IsSecretBaseNorthWall 572b4 14
MetatileBehavior_IsSecretBasePC 5723c 14
MetatileBehavior_IsSecretBaseSandOrnament 57368 14
MetatileBehavior_IsSecretBaseShieldOrToyTV 5737c 14
MetatileBehavior_IsSecretBaseShrub 57228 14
MetatileBehavior_IsSecretBaseSpinMat 57788 14
MetatileBehavior_IsSecretBaseTree 57210 18
MetatileBehavior_IsShallowFlowingWater 57528 1c
MetatileBehavior_IsShopShelf 57998 14
MetatileBehavior_IsShortGrass 57654 14
MetatileBehavior_IsSlideEast 57158 14
MetatileBehavior_IsSlideNorth 5711c 14
MetatileBehavior_IsSlideSouth 57130 14
MetatileBehavior_IsSlideWest 57144 14
MetatileBehavior_IsSouthArrowWarp 56fa0 1c
MetatileBehavior_IsSouthBlocked 57634 20
MetatileBehavior_IsSouthwardCurrent 570e0 14
MetatileBehavior_IsSurfableFishableWater 577d8 2e
MetatileBehavior_IsSurfableWaterOrUnderwater 56f3c 22
MetatileBehavior_IsTallGrass 573d4 14
MetatileBehavior_IsThinIce 57544 14
MetatileBehavior_IsTrashCan 57984 14
MetatileBehavior_IsTrickHousePuzzleDoor 57710 14
MetatileBehavior_IsTrickHouseSlipperyFloor 57054 14
MetatileBehavior_IsVase 57970 14
MetatileBehavior_IsVerticalRail 57894 14
MetatileBehavior_IsWalkEast 570b8 14
MetatileBehavior_IsWalkNorth 5707c 14
MetatileBehavior_IsWalkSouth 57090 14
MetatileBehavior_IsWalkWest 570a4 14
MetatileBehavior_IsWarpDoor 56e9c 14
MetatileBehavior_IsWaterWildEncounter 57498 2e
MetatileBehavior_IsWaterfall 5767c 14
MetatileBehavior_IsWestArrowWarp 56f74 14
MetatileBehavior_IsWestBlocked 575f0 24
MetatileBehavior_IsWestwardCurrent 570f4 14
MidiKeyToCgbFreq 1de88c a8
MidiKeyToFreq 1ddd24 64
ModulateByTypeEffectiveness 36c4c 88 5
ModulateDmgByType 1cbec d8 20
ModulateDmgByType2 1d1c8 b8 20
MonFaintedFromPoison c5728 48 74
MonGainEVs 3fe70 1b0
MonHasMail a2b94 30
MonKnowsMultipleMoves 9e508 2a 163
MonListHasMon 110bfc 36 159
MonOTNameMatchesPlayer 10f96c 40
MonRestorePP 40b1c a
MonTryLearningNewMove 3b7c8 10c
MoriDebugMenuProcessInput 83f2c 3e
MoriDebugMenu_10000Steps 83e68 18
MoriDebugMenu_1000Steps 83e54 14
MoriDebugMenu_BreedEgg 83e90 5c
MoriDebugMenu_Egg 83dfc 2c
MoriDebugMenu_LongName 83eec 20
MoriDebugMenu_MaleEgg 83e28 2c
MoriDebugMenu_MoveTutor 83e80 10
MoriDebugMenu_PokeblockCase 83f0c 1e
MoriDebugMenu_SearchChild 83d70 8c
MoveAnimRaindrop d3190 36 166
MoveBattleBar 45c78 e0
MoveBattlerSpriteToBG 76038 34c
MoveCameraAndRedrawMap 58200 3c
MoveCoords 602d8 24
MoveCoordsInDirection 60324 68 63
MoveCursorPos 13360c 20 137
MoveCursorToOKButton b6878 e 141
MoveMapViewToBackup 566f4 d0 80
MoveMenuCursor3 72294 76
MoveMenuCursorGridLayout 7230c cc 132
MoveNextDirectionInSequence 5e504 b2
MoveOutOfSecretBase bc464 10
MovePlayerAvatarUsingKeypadInput 588d0 36 73
MovePlayerNotOnBike 58c78 30 73
MovePlayerOnAcroBike e52dc 38 28
MovePlayerOnBike e50a8 36
MovePlayerOnMachBike e50e0 30 28
MoveSecretBase bc50c 2c
MoveSelectIcon a405c 50 116
MoveTutorMain 132908 6e4 137
MoveValuesCleanUp 20b54 48 20
MovementAction_AcroEndWheelieFaceDown_Step0 62a70 24
MovementAction_AcroEndWheelieFaceLeft_Step0 62ab8 24
MovementAction_AcroEndWheelieFaceRight_Step0 62adc 24
MovementAction_AcroEndWheelieFaceUp_Step0 62a94 24
MovementAction_AcroEndWheelieMoveDown_Step0 63374 20
MovementAction_AcroEndWheelieMoveDown_Step1 63394 1e
MovementAction_AcroEndWheelieMoveLeft_Step0 633f4 20
MovementAction_AcroEndWheelieMoveLeft_Step1 63414 1e
MovementAction_AcroEndWheelieMoveRight_Step0 63434 20
MovementAction_AcroEndWheelieMoveRight_Step1 63454 1e
MovementAction_AcroEndWheelieMoveUp_Step0 633b4 20
MovementAction_AcroEndWheelieMoveUp_Step1 633d4 1e
MovementAction_AcroPopWheelieDown_Step0 629e0 24
MovementAction_AcroPopWheelieLeft_Step0 62a28 24
MovementAction_AcroPopWheelieMoveDown_Step0 6310c 20
MovementAction_AcroPopWheelieMoveDown_Step1 6312c 1e
MovementAction_AcroPopWheelieMoveLeft_Step0 6318c 20
MovementAction_AcroPopWheelieMoveLeft_Step1 631ac 1e
MovementAction_AcroPopWheelieMoveRight_Step0 631cc 20
MovementAction_AcroPopWheelieMoveRight_Step1 631ec 1e
MovementAction_AcroPopWheelieMoveUp_Step0 6314c 20
MovementAction_AcroPopWheelieMoveUp_Step1 6316c 1e
MovementAction_AcroPopWheelieRight_Step0 62a4c 24
MovementAction_AcroPopWheelieUp_Step0 62a04 24
MovementAction_AcroWheelieFaceDown_Step0 629a0 e
MovementAction_AcroWheelieFaceLeft_Step0 629c0 e
MovementAction_AcroWheelieFaceRight_Step0 629d0 e
MovementAction_AcroWheelieFaceUp_Step0 629b0 e
MovementAction_AcroWheelieHopDown_Step0 62d34 2a
MovementAction_AcroWheelieHopDown_Step1 62d60 2a
MovementAction_AcroWheelieHopFaceDown_Step0 62bd4 2a
MovementAction_AcroWheelieHopFaceDown_Step1 62c00 2a
MovementAction_AcroWheelieHopFaceLeft_Step0 62c84 2a
MovementAction_AcroWheelieHopFaceLeft_Step1 62cb0 2a
MovementAction_AcroWheelieHopFaceRight_Step0 62cdc 2a
MovementAction_AcroWheelieHopFaceRight_Step1 62d08 2a
MovementAction_AcroWheelieHopFaceUp_Step0 62c2c 2a
MovementAction_AcroWheelieHopFaceUp_Step1 62c58 2a
MovementAction_AcroWheelieHopLeft_Step0 62de4 2a
MovementAction_AcroWheelieHopLeft_Step1 62e10 2a
MovementAction_AcroWheelieHopRight_Step0 62e3c 2a
MovementAction_AcroWheelieHopRight_Step1 62e68 2a
MovementAction_AcroWheelieHopUp_Step0 62d8c 2a
MovementAction_AcroWheelieHopUp_Step1 62db8 2a
MovementAction_AcroWheelieInPlaceDown_Step0 62ff4 36
MovementAction_AcroWheelieInPlaceLeft_Step0 63064 36
MovementAction_AcroWheelieInPlaceRight_Step0 6309c 36
MovementAction_AcroWheelieInPlaceUp_Step0 6302c 36
MovementAction_AcroWheelieJumpDown_Step0 62e94 2a
MovementAction_AcroWheelieJumpDown_Step1 62ec0 2a
MovementAction_AcroWheelieJumpLeft_Step0 62f44 2a
MovementAction_AcroWheelieJumpLeft_Step1 62f70 2a
MovementAction_AcroWheelieJumpRight_Step0 62f9c 2a
MovementAction_AcroWheelieJumpRight_Step1 62fc8 2a
MovementAction_AcroWheelieJumpUp_Step0 62eec 2a
MovementAction_AcroWheelieJumpUp_Step1 62f18 2a
MovementAction_AcroWheelieMoveDown_Step0 6323c 20
MovementAction_AcroWheelieMoveDown_Step1 6325c 1e
MovementAction_AcroWheelieMoveLeft_Step0 632bc 20
MovementAction_AcroWheelieMoveLeft_Step1 632dc 1e
MovementAction_AcroWheelieMoveRight_Step0 632fc 20
MovementAction_AcroWheelieMoveRight_Step1 6331c 1e
MovementAction_AcroWheelieMoveUp_Step0 6327c 20
MovementAction_AcroWheelieMoveUp_Step1 6329c 1e
MovementAction_ClearAffineAnim_Step0 62870 2e
MovementAction_ClearFixedPriority_Step0 62830 10
MovementAction_CutTree_Step0 627a4 1a
MovementAction_CutTree_Step1 627c0 24
MovementAction_CutTree_Step2 627e4 3a
MovementAction_Delay16_Step0 615b0 20
MovementAction_Delay1_Step0 61530 20
MovementAction_Delay2_Step0 61550 20
MovementAction_Delay4_Step0 61570 20
MovementAction_Delay8_Step0 61590 20
MovementAction_Delay_Step1 61514 1c
MovementAction_DisableAnimation_Step0 625fc e
MovementAction_DisableJumpLandingGroundEffect_Step0 625ec e
MovementAction_EmoteExclamationMark_Step0 62658 24
MovementAction_EmoteHeart_Step0 626a0 24
MovementAction_EmoteQuestionMark_Step0 6267c 24
MovementAction_EnableJumpLandingGroundEffect_Step0 625dc 10
MovementAction_FaceAwayPlayer_Step0 62110 64
MovementAction_FaceDown_Step0 60ce4 e
MovementAction_FaceLeft_Step0 60d04 e
MovementAction_FaceOriginalDirection_Step0 625b4 18
MovementAction_FacePlayer_Step0 620b4 5c
MovementAction_FaceRight_Step0 60d14 e
MovementAction_FaceUp_Step0 60cf4 e
MovementAction_Finish 63474 4
MovementAction_InitAffineAnim_Step0 62840 30
MovementAction_Jump2Down_Step0 613ac 2a
MovementAction_Jump2Down_Step1 613d8 2a
MovementAction_Jump2Left_Step0 6145c 2a
MovementAction_Jump2Left_Step1 61488 2a
MovementAction_Jump2Right_Step0 614b4 2a
MovementAction_Jump2Right_Step1 614e0 2a
MovementAction_Jump2Up_Step0 61404 2a
MovementAction_Jump2Up_Step1 61430 2a
MovementAction_JumpDown_Step0 62194 2a
MovementAction_JumpDown_Step1 621c0 2a
MovementAction_JumpInPlaceDownUp_Step0 62454 2a
MovementAction_JumpInPlaceDownUp_Step1 62480 2a
MovementAction_JumpInPlaceDown_Step0 622f4 2a
MovementAction_JumpInPlaceDown_Step1 62320 2a
MovementAction_JumpInPlaceLeftRight_Step0 62504 2a
MovementAction_JumpInPlaceLeftRight_Step1 62530 2a
MovementAction_JumpInPlaceLeft_Step0 623a4 2a
MovementAction_JumpInPlaceLeft_Step1 623d0 2a
MovementAction_JumpInPlaceRightLeft_Step0 6255c 2a
MovementAction_JumpInPlaceRightLeft_Step1 62588 2a
MovementAction_JumpInPlaceRight_Step0 623fc 2a
MovementAction_JumpInPlaceRight_Step1 62428 2a
MovementAction_JumpInPlaceUpDown_Step0 624ac 2a
MovementAction_JumpInPlaceUpDown_Step1 624d8 2a
MovementAction_JumpInPlaceUp_Step0 6234c 2a
MovementAction_JumpInPlaceUp_Step1 62378 2a
MovementAction_JumpLeft_Step0 62244 2a
MovementAction_JumpLeft_Step1 62270 2a
MovementAction_JumpRight_Step0 6229c 2a
MovementAction_JumpRight_Step1 622c8 2a
MovementAction_JumpSpecialDown_Step0 61f94 1e
MovementAction_JumpSpecialDown_Step1 61fb4 28
MovementAction_JumpSpecialLeft_Step0 62024 1e
MovementAction_JumpSpecialLeft_Step1 62044 28
MovementAction_JumpSpecialRight_Step0 6206c 1e
MovementAction_JumpSpecialRight_Step1 6208c 28
MovementAction_JumpSpecialUp_Step0 61fdc 1e
MovementAction_JumpSpecialUp_Step1 61ffc 28
MovementAction_JumpUp_Step0 621ec 2a
MovementAction_JumpUp_Step1 62218 2a
MovementAction_LockFacingDirection_Step0 62174 e
MovementAction_NurseJoyBowDown_Step0 625cc 10
MovementAction_PauseSpriteAnim 63478 e
MovementAction_PlayerRunDown_Step0 61dfc 1e
MovementAction_PlayerRunDown_Step1 61e1c 1e
MovementAction_PlayerRunLeft_Step0 61e7c 1e
MovementAction_PlayerRunLeft_Step1 61e9c 1e
MovementAction_PlayerRunRight_Step0 61ebc 1e
MovementAction_PlayerRunRight_Step1 61edc 1e
MovementAction_PlayerRunUp_Step0 61e3c 1e
MovementAction_PlayerRunUp_Step1 61e5c 1e
MovementAction_RestoreAnimation_Step0 6260c 2a
MovementAction_RevealTrainer_Step0 626c4 44
MovementAction_RevealTrainer_Step1 62708 1e
MovementAction_RideWaterCurrentDown_Step0 61afc 20
MovementAction_RideWaterCurrentDown_Step1 61b1c 1e
MovementAction_RideWaterCurrentLeft_Step0 61b7c 20
MovementAction_RideWaterCurrentLeft_Step1 61b9c 1e
MovementAction_RideWaterCurrentRight_Step0 61bbc 20
MovementAction_RideWaterCurrentRight_Step1 61bdc 1e
MovementAction_RideWaterCurrentUp_Step0 61b3c 20
MovementAction_RideWaterCurrentUp_Step1 61b5c 1e
MovementAction_RockSmashBreak_Step0 62728 1a
MovementAction_RockSmashBreak_Step1 62744 24
MovementAction_RockSmashBreak_Step2 62768 3a
MovementAction_SetFixedPriority_Step0 62820 e
MovementAction_SetInvisible_Step0 62638 e
MovementAction_SetVisible_Step0 62648 10
MovementAction_SlideDown_Step0 61cfc 20
MovementAction_SlideDown_Step1 61d1c 1e
MovementAction_SlideLeft_Step0 61d7c 20
MovementAction_SlideLeft_Step1 61d9c 1e
MovementAction_SlideRight_Step0 61dbc 20
MovementAction_SlideRight_Step1 61ddc 1e
MovementAction_SlideUp_Step0 61d3c 20
MovementAction_SlideUp_Step1 61d5c 1e
MovementAction_StartAnimInDirection_Step0 61f28 16
MovementAction_UnlockFacingDirection_Step0 62184 10
MovementAction_UnusedAcroActionDown_Step0 62b00 24
MovementAction_UnusedAcroActionLeft_Step0 62b48 24
MovementAction_UnusedAcroActionRight_Step0 62b6c 24
MovementAction_UnusedAcroActionUp_Step0 62b24 24
MovementAction_WaitSpriteAnim 61f40 20
MovementAction_WalkDownAffine_Step0 62900 32
MovementAction_WalkDownAffine_Step1 62934 2a
MovementAction_WalkDownStartAffine_Step0 628a0 32
MovementAction_WalkDownStartAffine_Step1 628d4 2a
MovementAction_WalkFastDown_Step0 615d0 20
MovementAction_WalkFastDown_Step1 615f0 1e
MovementAction_WalkFastLeft_Step0 61650 20
MovementAction_WalkFastLeft_Step1 61670 1e
MovementAction_WalkFastRight_Step0 61690 20
MovementAction_WalkFastRight_Step1 616b0 1e
MovementAction_WalkFastUp_Step0 61610 20
MovementAction_WalkFastUp_Step1 61630 1e
MovementAction_WalkFastestDown_Step0 61bfc 20
MovementAction_WalkFastestDown_Step1 61c1c 1e
MovementAction_WalkFastestLeft_Step0 61c7c 20
MovementAction_WalkFastestLeft_Step1 61c9c 1e
MovementAction_WalkFastestRight_Step0 61cbc 20
MovementAction_WalkFastestRight_Step1 61cdc 1e
MovementAction_WalkFastestUp_Step0 61c3c 20
MovementAction_WalkFastestUp_Step1 61c5c 1e
MovementAction_WalkInPlaceFastDown_Step0 6193c 36
MovementAction_WalkInPlaceFastLeft_Step0 619ac 36
MovementAction_WalkInPlaceFastRight_Step0 619e4 36
MovementAction_WalkInPlaceFastUp_Step0 61974 36
MovementAction_WalkInPlaceFastestDown_Step0 61a1c 36
MovementAction_WalkInPlaceFastestLeft_Step0 61a8c 36
MovementAction_WalkInPlaceFastestRight_Step0 61ac4 36
MovementAction_WalkInPlaceFastestUp_Step0 61a54 36
MovementAction_WalkInPlaceNormalDown_Step0 6185c 36
MovementAction_WalkInPlaceNormalLeft_Step0 618cc 36
MovementAction_WalkInPlaceNormalRight_Step0 61904 36
MovementAction_WalkInPlaceNormalUp_Step0 61894 36
MovementAction_WalkInPlaceSlowDown_Step0 6177c 36
MovementAction_WalkInPlaceSlowLeft_Step0 617ec 36
MovementAction_WalkInPlaceSlowRight_Step0 61824 36
MovementAction_WalkInPlaceSlowUp_Step0 617b4 36
MovementAction_WalkInPlaceSlow_Step1 61740 3c
MovementAction_WalkInPlace_Step1 61718 28
MovementAction_WalkNormalDown_Step0 61040 20
MovementAction_WalkNormalDown_Step1 61060 1e
MovementAction_WalkNormalLeft_Step0 610c0 20
MovementAction_WalkNormalLeft_Step1 610e0 1e
MovementAction_WalkNormalRight_Step0 61100 20
MovementAction_WalkNormalRight_Step1 61120 1e
MovementAction_WalkNormalUp_Step0 61080 20
MovementAction_WalkNormalUp_Step1 610a0 1e
MovementAction_WalkSlowDown_Step0 60f40 1e
MovementAction_WalkSlowDown_Step1 60f60 1e
MovementAction_WalkSlowLeft_Step0 60fc0 1e
MovementAction_WalkSlowLeft_Step1 60fe0 1e
MovementAction_WalkSlowRight_Step0 61000 1e
MovementAction_WalkSlowRight_Step1 61020 1e
MovementAction_WalkSlowUp_Step0 60f80 1e
MovementAction_WalkSlowUp_Step1 60fa0 1e
MovementType_BerryTreeGrowth 5d2d4 44
MovementType_BerryTreeGrowth_Callback 5d318 20 63
MovementType_BerryTreeGrowth_Step0 5d338 b8
MovementType_BerryTreeGrowth_Step1 5d3f0 1e
MovementType_BerryTreeGrowth_Step2 5d410 4c
MovementType_BerryTreeGrowth_Step3 5d45c 50
MovementType_BerryTreeGrowth_Step4 5d4ac 4a
MovementType_CopyPlayer 5f300 24
MovementType_CopyPlayerInGrass 5f8e4 24
MovementType_CopyPlayerInGrass_Step1 5f928 64
MovementType_CopyPlayerInGrass_callback 5f908 20 63
MovementType_CopyPlayer_Step0 5f344 22
MovementType_CopyPlayer_Step1 5f368 60
MovementType_CopyPlayer_Step2 5f3c8 26
MovementType_CopyPlayer_callback 5f324 20 63
MovementType_Disguise_Callback 5f9fc c 63
MovementType_FaceDirection 5d234 24
MovementType_FaceDirection_Step0 5d278 2c
MovementType_FaceDirection_Step1 5d2a4 1e
MovementType_FaceDirection_Step2 5d2c4 e
MovementType_FaceDirection_callback 5d258 20 63
MovementType_FaceDownAndLeft 5d9f8 24
MovementType_FaceDownAndLeft_Step0 5da3c 12
MovementType_FaceDownAndLeft_Step1 5da50 2a
MovementType_FaceDownAndLeft_Step2 5da7c 44
MovementType_FaceDownAndLeft_Step3 5dac0 2e
MovementType_FaceDownAndLeft_Step4 5daf0 48
MovementType_FaceDownAndLeft_callback 5da1c 20 63
MovementType_FaceDownAndRight 5db38 24
MovementType_FaceDownAndRight_Step0 5db7c 12
MovementType_FaceDownAndRight_Step1 5db90 2a
MovementType_FaceDownAndRight_Step2 5dbbc 44
MovementType_FaceDownAndRight_Step3 5dc00 2e
MovementType_FaceDownAndRight_Step4 5dc30 48
MovementType_FaceDownAndRight_callback 5db5c 20 63
MovementType_FaceDownAndUp 5d4f8 24
MovementType_FaceDownAndUp_Step0 5d53c 12
MovementType_FaceDownAndUp_Step1 5d550 2a
MovementType_FaceDownAndUp_Step2 5d57c 44
MovementType_FaceDownAndUp_Step3 5d5c0 2e
MovementType_FaceDownAndUp_Step4 5d5f0 48
MovementType_FaceDownAndUp_callback 5d51c 20 63
MovementType_FaceDownLeftAndRight 5e038 24
MovementType_FaceDownLeftAndRight_Step0 5e07c 12
MovementType_FaceDownLeftAndRight_Step1 5e090 2a
MovementType_FaceDownLeftAndRight_Step2 5e0bc 44
MovementType_FaceDownLeftAndRight_Step3 5e100 2e
MovementType_FaceDownLeftAndRight_Step4 5e130 48
MovementType_FaceDownLeftAndRight_callback 5e05c 20 63
MovementType_FaceDownUpAndLeft 5dc78 24
MovementType_FaceDownUpAndLeft_Step0 5dcbc 12
MovementType_FaceDownUpAndLeft_Step1 5dcd0 2a
MovementType_FaceDownUpAndLeft_Step2 5dcfc 44
MovementType_FaceDownUpAndLeft_Step3 5dd40 2e
MovementType_FaceDownUpAndLeft_Step4 5dd70 48
MovementType_FaceDownUpAndLeft_callback 5dc9c 20 63
MovementType_FaceDownUpAndRight 5ddb8 24
MovementType_FaceDownUpAndRight_Step0 5ddfc 12
MovementType_FaceDownUpAndRight_Step1 5de10 2a
MovementType_FaceDownUpAndRight_Step2 5de3c 44
MovementType_FaceDownUpAndRight_Step3 5de80 2e
MovementType_FaceDownUpAndRight_Step4 5deb0 48
MovementType_FaceDownUpAndRight_callback 5dddc 20 63
MovementType_FaceLeftAndRight 5d638 24
MovementType_FaceLeftAndRight_Step0 5d67c 12
MovementType_FaceLeftAndRight_Step1 5d690 2a
MovementType_FaceLeftAndRight_Step2 5d6bc 44
MovementType_FaceLeftAndRight_Step3 5d700 2e
MovementType_FaceLeftAndRight_Step4 5d730 48
MovementType_FaceLeftAndRight_callback 5d65c 20 63
MovementType_FaceUpAndLeft 5d778 24
MovementType_FaceUpAndLeft_Step0 5d7bc 12
MovementType_FaceUpAndLeft_Step1 5d7d0 2a
MovementType_FaceUpAndLeft_Step2 5d7fc 44
MovementType_FaceUpAndLeft_Step3 5d840 2e
MovementType_FaceUpAndLeft_Step4 5d870 48
MovementType_FaceUpAndLeft_callback 5d79c 20 63
MovementType_FaceUpAndRight 5d8b8 24
MovementType_FaceUpAndRight_Step0 5d8fc 12
MovementType_FaceUpAndRight_Step1 5d910 2a
MovementType_FaceUpAndRight_Step2 5d93c 44
MovementType_FaceUpAndRight_Step3 5d980 2e
MovementType_FaceUpAndRight_Step4 5d9b0 48
MovementType_FaceUpAndRight_callback 5d8dc 20 63
MovementType_FaceUpLeftAndRight 5def8 24
MovementType_FaceUpLeftAndRight_Step0 5df3c 12
MovementType_FaceUpLeftAndRight_Step1 5df50 2a
MovementType_FaceUpLeftAndRight_Step2 5df7c 44
MovementType_FaceUpLeftAndRight_Step3 5dfc0 2e
MovementType_FaceUpLeftAndRight_Step4 5dff0 48
MovementType_FaceUpLeftAndRight_callback 5df1c 20 63
MovementType_Hidden 5fa78 64
MovementType_Hidden_Callback 5fadc 20 63
MovementType_Hidden_Step0 5fafc c
MovementType_Invisible 5fc74 24
MovementType_Invisible_Step0 5fcb8 34
MovementType_Invisible_Step1 5fcec 1e
MovementType_Invisible_Step2 5fd0c e
MovementType_Invisible_callback 5fc98 20 63
MovementType_JogInPlace 5fb94 24
MovementType_JogInPlace_Step0 5fbd8 2c
MovementType_JogInPlace_callback 5fbb8 20 63
MovementType_LookAround 5cdec 24
MovementType_LookAround_Step0 5ce30 12
MovementType_LookAround_Step1 5ce44 2a
MovementType_LookAround_Step2 5ce70 44
MovementType_LookAround_Step3 5ceb4 2e
MovementType_LookAround_Step4 5cee4 48
MovementType_LookAround_callback 5ce10 20 63
MovementType_MountainDisguise 5fa08 70
MovementType_MoveInPlace_Step1 5fb08 1a
MovementType_None 5c888 24
MovementType_None_callback 5c8ac 4 63
MovementType_Player 587b8 24
MovementType_Player_callback 587dc 4 73
MovementType_RotateClockwise 5e27c 24
MovementType_RotateClockwise_Step0 5e2c0 2c
MovementType_RotateClockwise_Step1 5e2ec 22
MovementType_RotateClockwise_Step2 5e310 2a
MovementType_RotateClockwise_Step3 5e33c 44
MovementType_RotateClockwise_callback 5e2a0 20 63
MovementType_RotateCounterclockwise 5e178 24
MovementType_RotateCounterclockwise_Step0 5e1bc 2c
MovementType_RotateCounterclockwise_Step1 5e1e8 22
MovementType_RotateCounterclockwise_Step2 5e20c 2a
MovementType_RotateCounterclockwise_Step3 5e238 44
MovementType_RotateCounterclockwise_callback 5e19c 20 63
MovementType_RunInPlace 5fc04 24
MovementType_RunInPlace_Step0 5fc48 2c
MovementType_RunInPlace_callback 5fc28 20 63
MovementType_TreeDisguise 5f98c 70
MovementType_WalkBackAndForth 5e380 24
MovementType_WalkBackAndForth_Step0 5e3c4 12
MovementType_WalkBackAndForth_Step1 5e3d8 38
MovementType_WalkBackAndForth_Step2 5e410 b6
MovementType_WalkBackAndForth_Step3 5e4c8 26
MovementType_WalkBackAndForth_callback 5e3a4 20 63
MovementType_WalkInPlace 5fb24 24
MovementType_WalkInPlace_Step0 5fb68 2c
MovementType_WalkInPlace_callback 5fb48 20 63
MovementType_WalkSequenceDownLeftRightUp 5ee14 24
MovementType_WalkSequenceDownLeftRightUp_Step1 5ee58 48
MovementType_WalkSequenceDownLeftRightUp_callback 5ee38 20 63
MovementType_WalkSequenceDownLeftUpRight 5f15c 24
MovementType_WalkSequenceDownLeftUpRight_Step1 5f1a0 48
MovementType_WalkSequenceDownLeftUpRight_callback 5f180 20 63
MovementType_WalkSequenceDownRightLeftUp 5ebe4 24
MovementType_WalkSequenceDownRightLeftUp_Step1 5ec28 48
MovementType_WalkSequenceDownRightLeftUp_callback 5ec08 20 63
MovementType_WalkSequenceDownRightUpLeft 5ef2c 24
MovementType_WalkSequenceDownRightUpLeft_Step1 5ef70 48
MovementType_WalkSequenceDownRightUpLeft_callback 5ef50 20 63
MovementType_WalkSequenceDownUpLeftRight 5e928 24
MovementType_WalkSequenceDownUpLeftRight_Step1 5e96c 48
MovementType_WalkSequenceDownUpLeftRight_callback 5e94c 20 63
MovementType_WalkSequenceDownUpRightLeft 5e6f8 24
MovementType_WalkSequenceDownUpRightLeft_Step1 5e73c 48
MovementType_WalkSequenceDownUpRightLeft_callback 5e71c 20 63
MovementType_WalkSequenceLeftDownRightUp 5efb8 24
MovementType_WalkSequenceLeftDownRightUp_Step1 5effc 48
MovementType_WalkSequenceLeftDownRightUp_callback 5efdc 20 63
MovementType_WalkSequenceLeftDownUpRight 5e784 24
MovementType_WalkSequenceLeftDownUpRight_Step1 5e7c8 48
MovementType_WalkSequenceLeftDownUpRight_callback 5e7a8 20 63
MovementType_WalkSequenceLeftRightDownUp 5e89c 24
MovementType_WalkSequenceLeftRightDownUp_Step1 5e8e0 48
MovementType_WalkSequenceLeftRightDownUp_callback 5e8c0 20 63
MovementType_WalkSequenceLeftRightUpDown 5ed88 24
MovementType_WalkSequenceLeftRightUpDown_Step1 5edcc 48
MovementType_WalkSequenceLeftRightUpDown_callback 5edac 20 63
MovementType_WalkSequenceLeftUpDownRight 5ea40 24
MovementType_WalkSequenceLeftUpDownRight_Step1 5ea84 48
MovementType_WalkSequenceLeftUpDownRight_callback 5ea64 20 63
MovementType_WalkSequenceLeftUpRightDown 5f1e8 24
MovementType_WalkSequenceLeftUpRightDown_Step1 5f22c 48
MovementType_WalkSequenceLeftUpRightDown_callback 5f20c 20 63
MovementType_WalkSequenceRightDownLeftUp 5f274 24
MovementType_WalkSequenceRightDownLeftUp_Step1 5f2b8 48
MovementType_WalkSequenceRightDownLeftUp_callback 5f298 20 63
MovementType_WalkSequenceRightDownUpLeft 5e9b4 24
MovementType_WalkSequenceRightDownUpLeft_Step1 5e9f8 48
MovementType_WalkSequenceRightDownUpLeft_callback 5e9d8 20 63
MovementType_WalkSequenceRightLeftDownUp 5e66c 24
MovementType_WalkSequenceRightLeftDownUp_Step1 5e6b0 48
MovementType_WalkSequenceRightLeftDownUp_callback 5e690 20 63
MovementType_WalkSequenceRightLeftUpDown 5eb58 24
MovementType_WalkSequenceRightLeftUpDown_Step1 5eb9c 48
MovementType_WalkSequenceRightLeftUpDown_callback 5eb7c 20 63
MovementType_WalkSequenceRightUpDownLeft 5ec70 24
MovementType_WalkSequenceRightUpDownLeft_Step1 5ecb4 48
MovementType_WalkSequenceRightUpDownLeft_callback 5ec94 20 63
MovementType_WalkSequenceRightUpLeftDown 5f044 24
MovementType_WalkSequenceRightUpLeftDown_Step1 5f088 48
MovementType_WalkSequenceRightUpLeftDown_callback 5f068 20 63
MovementType_WalkSequenceUpDownLeftRight 5ecfc 24
MovementType_WalkSequenceUpDownLeftRight_Step1 5ed40 48
MovementType_WalkSequenceUpDownLeftRight_callback 5ed20 20 63
MovementType_WalkSequenceUpDownRightLeft 5eacc 24
MovementType_WalkSequenceUpDownRightLeft_Step1 5eb10 48
MovementType_WalkSequenceUpDownRightLeft_callback 5eaf0 20 63
MovementType_WalkSequenceUpLeftDownRight 5eea0 24
MovementType_WalkSequenceUpLeftDownRight_Step1 5eee4 48
MovementType_WalkSequenceUpLeftDownRight_callback 5eec4 20 63
MovementType_WalkSequenceUpLeftRightDown 5e810 24
MovementType_WalkSequenceUpLeftRightDown_Step1 5e854 48
MovementType_WalkSequenceUpLeftRightDown_callback 5e834 20 63
MovementType_WalkSequenceUpRightDownLeft 5f0d0 24
MovementType_WalkSequenceUpRightDownLeft_Step1 5f114 48
MovementType_WalkSequenceUpRightDownLeft_callback 5f0f4 20 63
MovementType_WalkSequenceUpRightLeftDown 5e5e0 24
MovementType_WalkSequenceUpRightLeftDown_Step1 5e624 48
MovementType_WalkSequenceUpRightLeftDown_callback 5e604 20 63
MovementType_WalkSequence_Step0 5e4f0 12
MovementType_WalkSequence_Step2 5e5b8 26
MovementType_WanderAround 5c8b0 24
MovementType_WanderAround_Step0 5c8f4 12
MovementType_WanderAround_Step1 5c908 2a
MovementType_WanderAround_Step2 5c934 3c
MovementType_WanderAround_Step3 5c970 20
MovementType_WanderAround_Step4 5c990 4c
MovementType_WanderAround_Step5 5c9dc 30
MovementType_WanderAround_Step6 5ca0c 26
MovementType_WanderAround_callback 5c8d4 20 63
MovementType_WanderLeftAndRight 5d0b0 24
MovementType_WanderLeftAndRight_Step0 5d0f4 12
MovementType_WanderLeftAndRight_Step1 5d108 2a
MovementType_WanderLeftAndRight_Step2 5d134 3c
MovementType_WanderLeftAndRight_Step3 5d170 20
MovementType_WanderLeftAndRight_Step4 5d190 4c
MovementType_WanderLeftAndRight_Step5 5d1dc 30
MovementType_WanderLeftAndRight_Step6 5d20c 26
MovementType_WanderLeftAndRight_callback 5d0d4 20 63
MovementType_WanderUpAndDown 5cf2c 24
MovementType_WanderUpAndDown_Step0 5cf70 12
MovementType_WanderUpAndDown_Step1 5cf84 2a
MovementType_WanderUpAndDown_Step2 5cfb0 3c
MovementType_WanderUpAndDown_Step3 5cfec 20
MovementType_WanderUpAndDown_Step4 5d00c 4c
MovementType_WanderUpAndDown_Step5 5d058 30
MovementType_WanderUpAndDown_Step6 5d088 26
MovementType_WanderUpAndDown_callback 5cf50 20 63
Mugshots_CreateOpponentPlayerSprites 11c7b0 15c 23
Multichoice b535c 56
MultiplyInvertedPaletteRGBComponents 85c7c 8c
MultiplyPaletteRGBComponents 85d08 78
MultistepInitMenuWindowBegin 71c5c c
MultistepInitMenuWindowContinue 71c98 b4
MultistepInitMenuWindowInternal 71c68 30 132
MultistepInitWindowTileData 2bfc 56
MultistepLoadFont 2c54 64
MultistepLoadFont_LoadGlyph 2cb8 98 214
MusicPlayerJumpTableCopy 1de208 4
NameHasGenderSymbol 42548 7a
NameMenuProcessInput b7f8 e 128
NamingScreen_ClearOam b5ca0 24 141
NamingScreen_ClearVram b5c4c 54 141
NamingScreen_Init b5d54 74 141
NamingScreen_InitDisplayMode b5c04 48 141
NamingScreen_ResetObjects b5de4 16 141
NamingScreen_SetUpVideoRegs b5cc4 90 141
NamingScreen_SetUpWindow b5dc8 1c 141
NamingScreen_TurnOffScreen b5be8 1a 141
NationalPokedexNumToSpecies 3f800 4c
NationalToHoennOrder 3f84c 4c
NewGameInitData 52e6c f0
NewGameInitPCItems 139c18 5c
NicknameDiffersFromSpeciesName bf4f4 50
None_Finish 7cb0c 4
None_Init 7cae8 20
None_Main 7cb08 2
ObjAffineSet 1e0788 4
ObjectCB_CameraObject 5c2cc 28 63
ObjectEventCheckForReflectiveSurface 63a48 14e 63
ObjectEventCheckHeldMovementStatus 60604 14
ObjectEventClearHeldMovement 605d0 34
ObjectEventClearHeldMovementIfActive 605b8 16
ObjectEventClearHeldMovementIfFinished 60618 22
ObjectEventDoesZCoordMatch 5c234 26 63
ObjectEventExecHeldMovementAction 60c20 38 63
ObjectEventExecSingleMovementAction 60c58 40 63
ObjectEventFaceOppositeDirection 609b0 2a
ObjectEventForceSetHeldMovement 6059c 1a
ObjectEventGetBerryTreeId 5c664 18
ObjectEventGetHeldMovementActionId 6063c 16
ObjectEventGetLocalIdAndMap 5bcb0 14
ObjectEventInteractionGetBerryTreeData b4e50 94
ObjectEventInteractionPickBerryTree b4f2c 4c
ObjectEventInteractionPlantBerryTree b4ef4 38
ObjectEventInteractionRemoveBerryTree b4f78 30
ObjectEventInteractionWaterBerryTree b49d8 5c
ObjectEventIsHeldMovementActive 60538 1c
ObjectEventIsMovementOverridden 60520 16
ObjectEventIsTrainerAndCloseToPlayer 5ca34 7a
ObjectEventMoveDestCoords 60500 1e
ObjectEventSetGraphicsId 5b984 100
ObjectEventSetGraphicsIdByLocalIdAndMap 5ba84 40
ObjectEventSetHeldMovement 60554 48
ObjectEventSetSingleMovement 60c98 8 63
ObjectEventTurn 5bac4 50
ObjectEventTurnByLocalIdAndMap 5bb14 40
ObjectEventUpdateMetatileBehaviors 636e4 26 63
ObjectEventUpdateSubpriority 63e10 1a 63
ObjectEventUpdateZCoord 63d74 54
OnBagClose_Battle a70d8 1a 116
OnBagClose_Field0 a599c 34 116
OnBagClose_Field4 a68f0 28 116
OnBagClose_Field5 a69b8 28 116
OnBagClose_PC a6a4c 38 116
OnBagClose_PkmnList a61ec 28 116
OnBagClose_Shop a631c 38 116
OnItemSelect_Battle a7024 70 116
OnItemSelect_Field05 a59d0 dc 116
OnItemSelect_Field4 a6918 28 116
OnItemSelect_PC a6c6c b0 116
OnItemSelect_PkmnList a6214 c4 116
OnItemSelect_Shop a6354 b8 116
OpenBagAfterPaletteFade 1374c4 38 13
OpenLink 7378 94
OpenLinkTimed 7b88 1c
OpenMoneyWindow b7c14 84
OpenPartyMenu 6afb0 24
OpenPartyMenuFromScriptContext f9a8c 40
OpenPokeblockCaseOnFeeder 10baf4 18
OpponentBufferExecCompleted 334ec 38
OpponentBufferRunCommand 32afc 50
OpponentHandleBallThrow 350ec a
OpponentHandleBattleAnimation 35f24 68
OpponentHandleDMATransfer 358bc a
OpponentHandleEffectivenessSound 35a20 44
OpponentHandleExpBarUpdate 357bc a
OpponentHandleFaintingCry 35a94 3c
OpponentHandleGetAttributes 33524 72
OpponentHandleHealthBarUpdate 356cc f0
OpponentHandleHitAnimation 359a4 70
OpponentHandleIntroSlide 35ad0 34
OpponentHandleLinkStandbyMsg 35f8c a
OpponentHandleLoadPokeSprite 347b8 158
OpponentHandleMoveAnimation 35104 134
OpponentHandleOpenBag 35590 30
OpponentHandlePrintString 3539c 64
OpponentHandlePrintStringPlayerOnly 35400 a
OpponentHandlePuase 350f8 a
OpponentHandleResetActionMoveSelection 35f98 a
OpponentHandleReturnPokeToBall 34ae0 94
OpponentHandleSendOutPoke 34910 4c
OpponentHandleSetAttributes 33dcc 58
OpponentHandleSpriteInvisibility 35ec4 60
OpponentHandleStatusAnimation 3583c 68
OpponentHandleStatusIconUpdate 357c8 74
OpponentHandleStatusXor 358a4 a
OpponentHandleTrainerBallThrow 35b04 10c
OpponentHandleTrainerSlide 34dc0 1c4
OpponentHandleTrainerSlideBack 34f84 ac
OpponentHandleTrainerThrow 34bfc 1c4
OpponentHandlecmd1 33d44 88
OpponentHandlecmd10 35030 a4
OpponentHandlecmd11 350d4 a
OpponentHandlecmd12 350e0 a
OpponentHandlecmd18 3540c e
OpponentHandlecmd19 3541c a
OpponentHandlecmd20 35428 168
OpponentHandlecmd22 355c0 100
OpponentHandlecmd23 356c0 a
OpponentHandlecmd29 358b0 a
OpponentHandlecmd3 34744 74
OpponentHandlecmd31 358c8 a
OpponentHandlecmd32 358d4 a
OpponentHandlecmd33 358e0 a
OpponentHandlecmd34 358ec a
OpponentHandlecmd35 358f8 a
OpponentHandlecmd36 35904 a
OpponentHandlecmd37 35910 1c
OpponentHandlecmd38 3592c 38
OpponentHandlecmd39 35964 18
OpponentHandlecmd40 3597c 28
OpponentHandlecmd42 35a14 a
OpponentHandlecmd44 35a64 30
OpponentHandlecmd48 35d28 104
OpponentHandlecmd49 35e6c 4c
OpponentHandlecmd50 35eb8 a
OpponentHandlecmd55 35fa4 44
OpponentHandlecmd56 35fe8 2
OverrideMovementTypeForObjectEvent 5c778 16
OverrideTemplateCoordsForObjectEvent 5c758 20
OverworldBasic 54374 26 148
Overworld_ChangeMusicTo 53fb0 2c
Overworld_ChangeMusicToDefault 53f84 2c
Overworld_ClearSavedMusic 53f00 c
Overworld_FadeOutMapMusic 54048 c
Overworld_GetFlashLevel 53d08 c
Overworld_GetMapHeaderByGroupAndId 53310 18
Overworld_GetMapTypeOfSaveblockLocation 541dc 14
Overworld_IsBikingAllowed 53c44 52
Overworld_MapTypeAllowsTeleportAndFly 54228 20
Overworld_MapTypeIsIndoors 54248 1a
Overworld_PlaySpecialMapMusic 53e90 64
Overworld_ResetMapMusic 53e84 a
Overworld_ResetStateAfterDigEscRope 53014 3c
Overworld_ResetStateAfterFly 52f90 3c
Overworld_ResetStateAfterTeleport 52fcc 48
Overworld_ResetStateAfterWhiteOut 53050 3c 148
Overworld_SetFlashLevel 53ce4 24
Overworld_SetHealLocationWarp 53588 3c
Overworld_SetObjEventTemplateCoords 531c0 32
Overworld_SetObjEventTemplateMovementType 531f4 2a
Overworld_SetSavedMusic 53ef4 c
Overworld_SetWarpDestToLastHealLoc 53570 18
Overworld_SetWarpDestination 53454 3c
PCTurnOffEffect 10e5a8 90 76
PCTurnOffEffect_0 10e490 78 76
PCTurnOffEffect_1 10e508 94 76
PSS_DestroyMonIconSprite 99be0 16 162
PSS_ForgetSpeciesIcon 99aac 50 162
PSS_LoadSpeciesIconGfx 999e8 c4 162
PSS_SpawnMonIconSprite 99afc e4 162
PadNameString 14a518 4e
PageSwapAnimState_1 b6680 6c 141
PageSwapAnimState_2 b66ec 6c 141
PageSwapAnimState_Done b6758 1c 141
PageSwapAnimState_Init b6668 18 141
PaletteFadeActive 80e64 c 71
PartyHasMonWithSurf 598e4 50
PartyMenuClearLevelStatusTilemap 6e16c 68 150
PartyMenuDoDrawHPBar 6e578 bc
PartyMenuDoPrintGenderIcon 6e360 64
PartyMenuDoPrintHP 6e424 84
PartyMenuDoPrintLevel 6e1f8 a0
PartyMenuDoPrintMonNickname 6e004 50
PartyMenuDrawHPBar 6e634 44
PartyMenuDrawHPBars 6e6cc 28
PartyMenuEraseMsgBoxAndFrame 6d5a8 12
PartyMenuGetPopupMenuFunc 6e820 18
PartyMenuPrintGenderIcon 6e3c4 60
PartyMenuPrintHP 6e4a8 44
PartyMenuPrintLevel 6e298 2a
PartyMenuPrintMonLevelOrStatus 6e2c4 74
PartyMenuPrintMonsLevelOrStatus 6e338 28
PartyMenuPutStatusTilemap 6e108 64
PartyMenuTryDrawHPBar 6e678 52
PartyMenuTryGiveMonHeldItem 6e968 128
PartyMenuTryGiveMonHeldItem_806EACC 6ead0 ec
PartyMenuTryGiveMonHeldItem_806ECE8 6ecec cc
PartyMenuTryGiveMonMail 6ec48 a4
PartyMenuTryPrintHP 6e4ec 52 150
PartyMenuTryPrintMonsHP 6e540 28
PartyMenuUpdateLevelOrStatus 6fbb8 1c
PartyMenuUpdateMonHeldItem 6e908 60
PartyMenuWriteTilemap 6e1d4 24 150
PartySpreadPokerus 40250 ae
PatchObjectPalette 5be84 38
PatchObjectPalettes 5bebc 2a 63
PauseVerticalScrollIndicator f996c 1a
PayMoneyFor b7d0c 18
PerStepCallback_8069864 69868 172
PerStepCallback_8069AA0 69aa4 216
PerStepCallback_8069DD4 69dd8 190
PerStepCallback_8069F64 69f68 dc
PerStepCallback_806A07C 6a080 10e
PetalburgGymOpenDoorsInstantly 10e230 1c
PetalburgGymSlideOpenDoors 10e070 2c
Phase1Task_TransitionAll 11ac64 50 23
Phase1_Task_RunFuncs 11d54c 38 23
Phase1_TransitionAll_Func1 11d584 5c 23
Phase1_TransitionAll_Func2 11d5e0 76 23
Phase2Task_MugShotTransition 11c12c 38 23
Phase2Task_Transition_BigPokeball 11b0f0 38 23
Phase2Task_Transition_Blur 11acb4 38 23
Phase2Task_Transition_Clockwise_BlackFade 11b7e8 38 23
Phase2Task_Transition_Drake 11c0ec 20 23
Phase2Task_Transition_Glacia 11c0cc 20 23
Phase2Task_Transition_GridSquares 11d0b8 38 23
Phase2Task_Transition_Phoebe 11c0ac 20 23
Phase2Task_Transition_PokeballsTrail 11b578 38 23
Phase2Task_Transition_Ripple 11bcbc 38 23
Phase2Task_Transition_Shards 11d1c8 38 23
Phase2Task_Transition_Shuffle 11af44 38 23
Phase2Task_Transition_Slice 11ca5c 38 23
Phase2Task_Transition_Steven 11c10c 20 23
Phase2Task_Transition_Swirl 11adac 38 23
Phase2Task_Transition_Sydney 11c08c 20 23
Phase2Task_Transition_Wave 11bea0 38 23
Phase2Task_Transition_WhiteFade 11ccdc 38 23
Phase2_Mugshot_Func1 11c164 68 23
Phase2_Mugshot_Func10 11c630 40 23
Phase2_Mugshot_Func2 11c1cc d8 23
Phase2_Mugshot_Func3 11c2a4 e8 23
Phase2_Mugshot_Func4 11c38c 74 23
Phase2_Mugshot_Func5 11c400 3c 23
Phase2_Mugshot_Func6 11c43c b4 23
Phase2_Mugshot_Func7 11c4f0 c4 23
Phase2_Mugshot_Func8 11c5b4 34 23
Phase2_Mugshot_Func9 11c5e8 48 23
Phase2_Transition_BigPokeball_Func1 11b128 b0 23
Phase2_Transition_BigPokeball_Func2 11b1d8 90 23
Phase2_Transition_BigPokeball_Func3 11b268 8c 23
Phase2_Transition_BigPokeball_Func4 11b2f4 8c 23
Phase2_Transition_BigPokeball_Func5 11b380 6c 23
Phase2_Transition_BigPokeball_Func6 11b3ec bc 23
Phase2_Transition_Blur_Func1 11acec 30 23
Phase2_Transition_Blur_Func2 11ad1c 64 23
Phase2_Transition_Blur_Func3 11ad80 2c 23
Phase2_Transition_Clockwise_BlackFade_Func1 11b820 64 23
Phase2_Transition_Clockwise_BlackFade_Func2 11b884 88 23
Phase2_Transition_Clockwise_BlackFade_Func3 11b90c e4 23
Phase2_Transition_Clockwise_BlackFade_Func4 11b9f0 80 23
Phase2_Transition_Clockwise_BlackFade_Func5 11ba70 f0 23
Phase2_Transition_Clockwise_BlackFade_Func6 11bb60 8c 23
Phase2_Transition_Clockwise_BlackFade_Func7 11bbec 40 23
Phase2_Transition_GridSquares_Func1 11d0f0 54 23
Phase2_Transition_GridSquares_Func2 11d144 58 23
Phase2_Transition_GridSquares_Func3 11d19c 2c 23
Phase2_Transition_PokeballsTrail_Func1 11b5b0 4c 23
Phase2_Transition_PokeballsTrail_Func2 11b5fc 8c 23
Phase2_Transition_PokeballsTrail_Func3 11b688 2c 23
Phase2_Transition_Ripple_Func1 11bcf4 6c 23
Phase2_Transition_Ripple_Func2 11bd60 dc 23
Phase2_Transition_Shards_Func1 11d200 60 23
Phase2_Transition_Shards_Func2 11d260 78 23
Phase2_Transition_Shards_Func3 11d2d8 d8 23
Phase2_Transition_Shards_Func4 11d3b0 6c 23
Phase2_Transition_Shards_Func5 11d41c 1c 23
Phase2_Transition_Shuffle_Func1 11af7c 84 23
Phase2_Transition_Shuffle_Func2 11b000 8c 23
Phase2_Transition_Slice_Func1 11ca94 8c 23
Phase2_Transition_Slice_Func2 11cb20 c6 23
Phase2_Transition_Slice_Func3 11cbe8 40 23
Phase2_Transition_Swirl_Func1 11ade4 8c 23
Phase2_Transition_Swirl_Func2 11ae70 70 23
Phase2_Transition_Wave_Func1 11bed8 54 23
Phase2_Transition_Wave_Func2 11bf2c 98 23
Phase2_Transition_Wave_Func3 11bfc4 40 23
Phase2_Transition_WhiteFade_Func1 11cd14 8c 23
Phase2_Transition_WhiteFade_Func2 11cda0 74 23
Phase2_Transition_WhiteFade_Func3 11ce14 38 23
Phase2_Transition_WhiteFade_Func4 11ce4c 64 23
Phase2_Transition_WhiteFade_Func5 11ceb0 34 23
PickLotteryCornerTicket 145b00 18c
PickWildMonNature 84dc4 b4 239
PlantBerryTree b4c04 68
PlayAmbientCry 54054 80 148
PlayBGM 75478 20
PlayBlackWhiteFluteSound ca098 44 117
PlayCollisionSoundIfNotFacingWarp 5964c 7c 73
PlayCry2 75094 24
PlayCry3 750b8 60
PlayCry4 75118 64
PlayCry5 7517c 48
PlayCryInternal 751c4 1b4 201
PlayCryScreenCry 11a0a0 20
PlayCry_Normal 75048 4c
PlayFanfare 74ec0 3a
PlayFanfareByFanfareNum 74e3c 34
PlayNewMapMusic 74cec 20
PlayRainSoundEffect 7ddb8 42
PlayRoulette 1177fc 3c
PlaySE 75498 e
PlaySE12WithPanning 754a8 54
PlaySE1WithPanning 754fc 34
PlaySE2WithPanning 75530 34
PlaySecretBaseMusicNoteMatSound c6c30 34
PlaySlotMachine 1018a0 18
PlaySlotMachine_Internal 1019b0 3c 199
PlayTimeCounter_Reset 52c28 20
PlayTimeCounter_SetToMax 52cdc 24
PlayTimeCounter_Start 52c48 28
PlayTimeCounter_Stop 52c70 c
PlayTimeCounter_Update 52c7c 60
PlayTrainerEncounterMusic 82728 e4
PlayerAcroTurnJump 595bc 24
PlayerAllowForcedMovementIfMovingSameDirection 58908 1c 73
PlayerAvatarTransition_AcroBike 59130 38 73
PlayerAvatarTransition_MachBike 590fc 34 73
PlayerAvatarTransition_Normal 590d0 2c 73
PlayerAvatarTransition_ReturnToField 591f8 10 73
PlayerAvatarTransition_Surfing 59168 5c 73
PlayerAvatarTransition_Underwater 591c4 34 73
PlayerAvatar_DoSecretBaseMatJump 5a004 6c 73
PlayerAvatar_DoSecretBaseMatSpin 5a090 4c 73
PlayerAvatar_SecretBaseMatSpinStep0 5a0dc 28 73
PlayerAvatar_SecretBaseMatSpinStep1 5a104 78 73
PlayerAvatar_SecretBaseMatSpinStep2 5a17c 40 73
PlayerAvatar_SecretBaseMatSpinStep3 5a1bc 54 73
PlayerBufferExecCompleted 2bf9c 78
PlayerBufferRunCommand 2c014 50
PlayerCanInterruptDelay 3fd0 4c 214
PlayerCheckIfAnimFinishedOrInactive 592f0 24 73
PlayerEndWheelie 59538 18
PlayerFaceDirection 59470 18
PlayerGetCopyableMovement 59330 1c
PlayerGetDestCoords 5970c 30
PlayerGetZCoord 59778 1c
PlayerGoSpeed1 593b0 18
PlayerGoSpeed2 593c8 18
PlayerGoSpeed4 593f8 18
PlayerHandleBallThrow 2ffd0 5c
PlayerHandleBattleAnimation 31174 68
PlayerHandleDMATransfer 30988 b4
PlayerHandleEffectivenessSound 30bd8 44
PlayerHandleExpBarUpdate 30798 9c
PlayerHandleFaintingCry 30c4c 40
PlayerHandleGetAttributes 2e4d0 72
PlayerHandleGetRawMonData 2ecf0 88
PlayerHandleHealthBarUpdate 30698 100
PlayerHandleHitAnimation 30b5c 70
PlayerHandleIntroSlide 30c8c 34
PlayerHandleLinkStandbyMsg 311dc 5a
PlayerHandleLoadPokeSprite 2f840 68
PlayerHandleMoveAnimation 3005c 134
PlayerHandleOpenBag 30530 64
PlayerHandlePrintString 302f4 64
PlayerHandlePrintStringPlayerOnly 30358 24
PlayerHandlePuase 3002c 30
PlayerHandleResetActionMoveSelection 31238 68
PlayerHandleReturnPokeToBall 2faa0 8c
PlayerHandleSendOutPoke 2f8a8 8c
PlayerHandleSetAttributes 2ed78 58
PlayerHandleSpriteInvisibility 31114 60
PlayerHandleStatusAnimation 308a8 68
PlayerHandleStatusIconUpdate 30834 74
PlayerHandleStatusXor 30910 6c
PlayerHandleTrainerBallThrow 30cc0 178
PlayerHandleTrainerSlide 2fce0 dc
PlayerHandleTrainerSlideBack 2fdbc c0
PlayerHandleTrainerThrow 2fbb4 12c
PlayerHandlecmd10 2fe7c e4
PlayerHandlecmd11 2ff60 20
PlayerHandlecmd12 2ff80 50
PlayerHandlecmd18 3037c e8
PlayerHandlecmd19 30464 2
PlayerHandlecmd20 30468 40
PlayerHandlecmd22 30594 e0
PlayerHandlecmd23 30674 24
PlayerHandlecmd29 3097c a
PlayerHandlecmd3 2f7cc 74
PlayerHandlecmd31 30a3c 30
PlayerHandlecmd32 30a6c a
PlayerHandlecmd33 30a78 14
PlayerHandlecmd34 30a8c 14
PlayerHandlecmd35 30aa0 12
PlayerHandlecmd36 30ab4 12
PlayerHandlecmd37 30ac8 1c
PlayerHandlecmd38 30ae4 38
PlayerHandlecmd39 30b1c 18
PlayerHandlecmd40 30b34 28
PlayerHandlecmd42 30bcc a
PlayerHandlecmd44 30c1c 30
PlayerHandlecmd48 30fac b8
PlayerHandlecmd49 310a4 4c
PlayerHandlecmd50 310f0 24
PlayerHandlecmd55 312a0 4c
PlayerHandlecmd56 312ec 2
PlayerHasBerries b4fa8 10
PlayerIdleWheelie 59508 18
PlayerIsAnimActive 592cc 24 73
PlayerJumpLedge 594a0 24
PlayerLedgeHoppingWheelie 59598 24
PlayerMovingHoppingWheelie 59574 24
PlayerNotOnBikeCollide 5944c 24 73
PlayerNotOnBikeNotMoving 58cec 12 73
PlayerNotOnBikeTurningInPlace 58d00 e 73
PlayerObjectTurn 5bb54 20
PlayerOnBikeCollide 59428 24
PlayerPC 139cb4 40
PlayerPCProcessMenuInput 139d64 c0 153
PlayerPC_Decoration 139ed8 20 153
PlayerPC_ItemStorage 139e40 2c 153
PlayerPC_Mailbox 139e6c 6c 153
PlayerPC_TurnOff 139ef8 60 153
PlayerPartyAndPokemonStorageFull 3dd20 34
PlayerRideWaterCurrent 593e0 18
PlayerRun 59410 18 73
PlayerSetAnimId 59374 3c
PlayerSetCopyableMovement 59314 1c 73
PlayerStandingHoppingWheelie 59550 24
PlayerStartWheelie 59520 18
PlayerTurnInPlace 59488 18
PokeBallOpenParticleAnimation 140930 d8
PokeBallOpenParticleAnimation_Step1 140a08 20 9
PokeBallOpenParticleAnimation_Step2 140a28 3a 9
PokeEvoSprite_DummySpriteCB 149e78 2 64
PokeballGlowEffect_0 860bc 98
PokeballGlowEffect_1 86154 34
PokeballGlowEffect_2 86188 140
PokeballGlowEffect_3 862c8 f4
PokeballGlowEffect_4 863bc 1a
PokeballGlowEffect_5 863d8 8
PokeballGlowEffect_6 863e0 22
PokeballGlowEffect_7 86404 2
PokeblockClearIfExists 10ca6c 2e
PokeblockCopyName 10cb44 24
PokeblockFeed_CreatePokeSprite 147f84 c0 157
PokeblockGetGain 10cae4 60
Pokeblock_BufferEnhancedStatText 136dc0 50 235
Pokeblock_GetMonContestStats 136e10 30 235
Pokeblock_MenuWindowTextPrint 136da0 20 235
PokecenterHealEffectHelper 86430 5c
PokecenterHealEffect_0 85df4 3a
PokecenterHealEffect_1 85e30 3c
PokecenterHealEffect_2 85e6c 28
PokecenterHealEffect_3 85e94 40
PokemonMenu_Cancel 8a918 1e 160
PokemonMenu_CancelSubmenu 8a938 4c 160
PokemonMenu_FieldMove 8a984 16c 160
PokemonMenu_GiveItem 8a630 48 160
PokemonMenu_Item 8a140 40 160
PokemonMenu_Mail 8a6e8 54 160
PokemonMenu_ReadMail 8a810 38 160
PokemonMenu_Summary 89fcc 38 160
PokemonMenu_Switch 8a02c 34 160
PokemonMenu_TakeItem 8a688 30 160
PokemonMenu_TakeMail 8a6b8 30 160
PokemonStorageFull 3dd54 4a
PokemonSummaryScreen_CheckOT a0664 a4
PokemonSummaryScreen_CopyPokemonLevel a203c 3c
PokemonSummaryScreen_PrintEggTrainerMemo a0708 90 163
PokemonSummaryScreen_PrintTrainerMemo a0798 1c0 163
PokemonUseItemEffects 3e1b0 fbc
PopSecretBaseBalloon c68a4 48
PreEvoInVisible_PostEvoVisible_KillTask 14a158 b0 64
PreEvoVisible_PostEvoInvisible_KillTask 14a208 b0 64
PremierBallOpenParticleAnimation 141164 cc
PremierBallOpenParticleAnimation_Step1 141230 62 9
PrepareAffineAnimInTaskData 798f8 38
PrepareBattlerSpriteForRotScale 78e74 d0
PrepareBufferDataTransfer be9c 8c 14
PrepareBufferDataTransferLink bff0 1b8
PrepareItemUseMessage c9fdc 38 117
PrepareOwnMultiPartnerBuffer f02c d8
PrepareSongText f7ba0 b4
PrepareStringBattle 156b8 24
PreservePaletteInWeather 7de38 30
PressurePPLose 151d4 c8
PressurePPLoseOnUsingImprision 1529c 134
PressurePPLoseOnUsingPerishSong 153d0 114
PrintAppealMoveResultText b146c 110
PrintBadgeCount a1c0 34 128
PrintBattleTowerTrainerGreeting 135474 58
PrintBattleTowerTrainerMessage 13545c 18
PrintCoins 11a798 94
PrintContestMoveDescription aebec 16c
PrintContestPaintingCaption 106918 b4 44
PrintContestantMonName ae6cc 18
PrintContestantMonNameWithColor ae6e4 8c
PrintContestantTrainerName ae5bc 18
PrintContestantTrainerNameWithColor ae5d4 f8
PrintCryNumber bb494 18
PrintCryScreenSpeciesName 91260 a4 158
PrintDriverTestMenuText bad5c b4
PrintEReaderTrainerFarewellMessage 1360d0 3c 22
PrintEReaderTrainerGreeting 1360c0 10
PrintEntryScreenDexNum 91154 72 158
PrintEntryScreenSpeciesName 911c8 98 158
PrintFieldMessage 64bf8 38 72
PrintFieldMessageFromStringVar4 64c30 2c 72
PrintFlyTargetName fc254 c8 167
PrintFootprint 91738 94
PrintGlyph_TextMode0 37f0 26 214
PrintGlyph_TextMode1 3844 24 214
PrintGlyph_TextMode2 38f8 32 214
PrintHeldItemName a0bf4 8c 163
PrintHex 7fd8 54
PrintHexDigit 7fa4 34 120
PrintKeyboardCharacters b785c 4c 141
PrintLastWinStreak 110594 50 19
PrintLinkBattleRecord 110348 f4 19
PrintLinkBattleWinLossTie dc24 20c 11
PrintLinkBattleWinsLossesDraws 1102e8 60 19
PrintMainMenuItem a0bc 4a 128
PrintMainMoveTutorMenuText 1328e8 20 137
PrintMessage f9058 38 133
PrintMoneyAmount b7a94 58
PrintMoveInfo 133940 1aa
PrintNewStatsInLevelUpWindow 7096c b8
PrintNextChar 2fe0 a0 214
PrintNumRibbons a0b88 6c 163
PrintNumberWithPalette f91ec 60
PrintPartyMenuMonNickname 6e054 2a
PrintPartyMenuMonNicknames 6e0c8 28
PrintPartyMenuPromptText 6d53c 6c
PrintPlayTime a144 44 128
PrintPlayerName a120 24 128
PrintPokedexCount a188 38 128
PrintRecordWinStreak 110538 34 19
PrintSafariMonInfo 44338 214
PrintSaveBadges 947b0 48
PrintSaveFileInfo a108 16 128
PrintSaveMapName 94778 38
PrintSavePlayTime 94844 4c
PrintSavePlayerName 94740 38
PrintSavePokedexCount 947f8 4c
PrintSearchParameterText 92d78 96 158
PrintSelectedSearchParameters 92b68 124 158
PrintSelectorArrow 925b4 18 158
PrintSignedNumber bae78 10c
PrintSoundNumber ba700 9a
PrintStartMenuItemsMultistep 71118 66 205
PrintStatGrowthsInLevelUpWindow 7084c 120
PrintStorageActionText 98898 1a0
PrintStoryList f8758 6c 131
PrintStringWithPalette f9178 74 133
PrintSummaryWindowHeaderText a0dd0 d4 163
PrintTriangleCursorWithPalette f924c 38
PrintWinStreak 1104e8 50 19
ProcessPlayerFieldInput 68028 14a
ProcessRecvCmds 76b0 2f6 120
ProcessSpriteCopyRequests 1214 5c
ProgramByte 1dfdcc 38 1
ProgramFlashByte_MX 1dfd38 94
ProgramFlashSectorAndVerify 1dfa28 44
ProgramFlashSectorAndVerifyNBytes 1dfa6c 48
ProgramFlashSector_MX 1dfe04 a2
PutPokemonTodayCaughtOnAir bdec8 160
PutZigzagoonInPlayerParty 10f628 6c
QuantizePalette_BlackAndWhite fdd70 b8
QuantizePalette_Grayscale fded8 b0
QuantizePalette_GrayscaleSmall fde28 b0
QuantizePalette_PrimaryColors fdf88 b0
QuantizePalette_Standard fdc18 158
QuantizePixel_BlackAndWhite fd4dc 30
QuantizePixel_BlackOutline fd50c 30
QuantizePixel_Blur fd68c 120
QuantizePixel_BlurHard fd7ac 11e
QuantizePixel_Grayscale fe1b0 2c
QuantizePixel_GrayscaleSmall fe17c 32
QuantizePixel_Invert fd53c 2c
QuantizePixel_MotionBlur fd568 124
QuantizePixel_PrimaryColors fe0ac ce
QuantizePixel_Standard fe038 74
QueueTilesetAnimDma 72e28 50 220
RLUnCompVram 1e078c 4
RLUnCompWram 1e0790 4
Rain_Finish 7f34c ac
Rain_Main 7efc0 38c
Random 40e84 20
RandomlyGivePartyPokerus 40048 c8
RankContestants af2fc c4
ReDrawPartyMonBackgrounds 6b54c 44 150
ReadData 1e06bc 8c 194
ReadFlash 1df82c 9c
ReadFlash1 1df7c4 4
ReadFlashId 1df5d8 9a
ReadFlash_Core 1df808 22
ReadKeys 428 9c 127
ReadPlttIntoBuffers 73bb8 40
ReadSomeUnknownSectorAndVerify 125b88 70 177
RealClearChain 1dd554 20
ReceiveBattleTowerData b9b70 4c
ReceiveDaycareMailData b9c6c 2d0
ReceiveDewfordTrendData fa4e4 d8
ReceiveGiftItem b9f3c d0
ReceiveOldManData b9b1c 54
ReceivePokeNewsData c0514 b0
ReceiveSecretBasesData bd674 134
ReceiveTvShowsData bfd44 e0
RecordAbilityBattle 1074c4 34
RecordCyclingRoadResults 10d88c 60 76
RecordItemEffectBattle 1074f8 34
RecordMixingPlayerSpotTriggered b929c 10
RecordMixing_PrepareExchangePacket b92ac 104
RecordMixing_ReceiveExchangePacket b93b0 a0
RedrawMapSliceEast 57cf8 54 66
RedrawMapSliceNorth 57c40 68 66
RedrawMapSliceSouth 57ca8 50 66
RedrawMapSliceWest 57d4c 68 66
RedrawMapSlicesForCameraUpdate 57bf4 4c 66
RedrawMenuCursor 72dac 18 132
RedrawMoveInfoWindow 133ca4 28 137
RedrawPokemonInfoInMenu 70a24 a8
ReducePlayerPartyToThree c5604 80
RegionMapDefaultZoomOffsetPlayerSprite fb2a4 48
RegisterRamReset 1e0794 4
RejectEggFromDayCare 41e7c 10
RemoveAllObjectEventsExceptPlayer 5af9c 34
RemoveBagItem a9538 136
RemoveBattleMonPPBonus 3de70 18
RemoveBerryTree b4c6c 24
RemoveCameraDummy 10f388 24
RemoveCoins 11a898 34
RemoveDecorationFromInventory 1340a8 5c
RemoveEggFromDayCare 41e64 18 52
RemoveEmptyItemSlots a3bd0 62 116
RemoveIVIndexFromList 41960 46 52
RemoveMonPPBonus 3de34 3c
RemoveMoney b79e0 16
RemoveObjectEvent 5aef4 14 63
RemoveObjectEventByLocalIdAndMap 5af08 48
RemoveObjectEventIfOutsideView 5b698 7c 63
RemoveObjectEventInternal 5af50 4c 63
RemoveObjectEventsOutsideView 5b638 60
RemovePCItem a97f4 38
RemoveSelectIconFromRegisteredItem a40d0 6c 116
RemoveSnowflakeSprite 7ec0c 34
RenderTextHandleBold 34d4 18
RepeatBallOpenParticleAnimation 140f24 d4
RepeatBallOpenParticleAnimation_Step1 140ff8 5e 9
RequestSpriteCopy 12d4 50
RequestSpriteFrameImageCopy 1270 64 204
RequestSpriteSheetCopy 256c 28
ResetAffineAnimData 212c 34 204
ResetAllSprites 1374 40 204
ResetBagScrollPositions a3684 34
ResetBattleTowerStreak 13461c 34 22
ResetBerryTreeSparkleFlag b4d34 16
ResetBerryTreeSparkleFlags b4fb8 9c
ResetBlendForContestantBoxBlink b0bb4 10
ResetBlockReceivedFlag 7f30 1c
ResetBlockReceivedFlags 7f18 18
ResetBlockSend 7cec 14 120
ResetCameraUpdateInfo 58098 18
ResetContestAndMuseumWinners 52da8 3c
ResetContestGpuRegs ab1bc f0
ResetCreditsTasks 1450ac 7c 47
ResetCyclingRoadChallengeData 10d6dc 20
ResetDrawAreaGlowState 110824 14 159
ResetDroughtWeatherPaletteLoading 7d9a8 20
ResetFanClub 10fa54 20
ResetFieldTasksArgs 695a4 3c
ResetGabbyAndTy bdab4 60
ResetGameStats 530ac 24
ResetGpuAndVram 144130 88 47
ResetInitialPlayerAvatarState 53a3c 10
ResetLinkContestBoolean ab1b0 c
ResetLinkPlayers 7cc8 24
ResetLotteryCorner 145a78 2c
ResetMapMusic 74cbc 24
ResetMoveTutorMenu 1332a0 60 137
ResetOamMatrices fe0 2c 204
ResetOamRange f38 38
ResetObjectEvents 5aa9c 16
ResetOtherVideoRegisters 91060 f4 158
ResetPSSMonIconSprites 98b48 a8
ResetPaletteFade 73b98 1e
ResetPaletteFadeControl 740f4 78
ResetPaletteStruct 74098 5c
ResetPaletteStructByUid 7407c 1a
ResetPokedex 8c02c 74
ResetPokedexScrollPositions 8c0a0 18
ResetPokemonStorageSystem 961d8 8c
ResetPreservedPalettesInWeather 7de68 10
ResetRecvBuffer 9084 70
ResetRtcScreen_CreateCursor 6a6a0 88
ResetRtcScreen_FreeCursorPalette 6a728 14
ResetRtcScreen_HideChooseTimeWindow 6a73c 12
ResetRtcScreen_MoveTimeUpDown 6a8b0 66
ResetRtcScreen_PrintTime 6a750 104
ResetRtcScreen_ShowChooseTimeWindow 6a854 5c
ResetRtcScreen_ShowMessage 6abe0 18
ResetSSTidalFlag 10d9a0 10
ResetSafariZoneFlag c81a8 10
ResetSafariZoneFlag_ 542d0 a
ResetSecretBase bb594 20
ResetSecretBases bb5b4 1c
ResetSendBuffer 9030 54
ResetSentPokesToOpponentValue 156dc 64
ResetSerial 8838 e
ResetSprite 102c 14 204
ResetSpriteData 748 4c
ResetTVShowState c2014 c
ResetTasks 7aa2c 60
ResetTrainerOpponentIds 822bc 50 21
ResetTrickHouseEndRoomFlag 10ef24 18
ResetVerticalScrollIndicators f9914 58 133
ReshowBattleScreenAfterMenu 7ad5c 50
ReshowBattleScreenDummy 7ad58 2
ReshowPCMenuAfterHallOfFamePC 10d64c 38 110
ReshowPlayerPC 139e24 1c
RestartWildEncounterImmunitySteps 689a8 c
RestoreBGMVolumeAfterPokemonCry 75454 24 201
RestoreSaveBackupVars 1254c8 44 177
RestoreSaveBackupVarsAndIncrement 12546c 5c 177
RetrieveLotteryNumber 145aec 14
ReturnFromBattleToOverworld 13eb0 a4 17
ReturnFromHallOfFamePC 10d62c 20
ReturnFromStartWallClock 6a450 14 39
ReturnToShopMenuAfterExitingSellMenu b2fdc 20 193
ReverseHorizontalLungeDirection a85a4 24 8
ReverseVerticalDipDirection a8614 24 8
RoamerMove 134394 88
RoamerMoveToOtherLocationSet 134348 4c
RotatePlayerAndExitItemfinder c9a38 90
RotatingGatePuzzleCameraUpdate c8058 28
RotatingGate_CanRotate c7e8c d8
RotatingGate_CreateGate c7bac e6 174
RotatingGate_CreateGatesWithinViewport c7adc d0 174
RotatingGate_DestroyGatesOutsideViewport c7dc0 cc 174
RotatingGate_GetGateOrientation c7a08 1a 174
RotatingGate_GetRotationInfo c7fec 54 174
RotatingGate_HasArm c7f64 54 174
RotatingGate_HideGatesOutsideViewport c7d14 9c 174
RotatingGate_InitPuzzle c8040 16
RotatingGate_InitPuzzleAndGraphics c8080 1e
RotatingGate_LoadPuzzleConfig c7a80 5c 174
RotatingGate_ResetAllGateOrientations c79cc 3c 174
RotatingGate_RotateInDirection c7a44 3c 174
RotatingGate_SetGateOrientation c7a24 20 174
RotatingGate_TriggerRotationAnimation c7fb8 34 174
RoundTowardsZero b9224 42 41
RoundUp b9268 32 41
RtcCalcLocalTime 95b8 28
RtcCalcLocalTimeOffset 95f4 30
RtcCalcTimeDifference 9534 84
RtcCheckInfo 9328 100
RtcDisableInterrupts 90f4 18
RtcGetDateTime 92e4 18
RtcGetDayCount 920c 3a
RtcGetErrorStatus 92a8 c
RtcGetInfo 92b4 30
RtcGetMinuteCount 968c 38
RtcGetRawInfo 9314 14
RtcGetStatus 92fc 18
RtcInit 9248 60
RtcInitLocalTimeOffset 95e0 14
RtcReset 9428 12
RtcRestoreInterrupts 910c 14
RunAffineAnimFromTaskData 79930 136
RunAnimScriptCommand 759d4 40 6
RunBattleScriptCommands 13fbc 2c
RunBattleScriptCommands_PopCallbacksStack 13f54 68
RunFieldCallback 543ec 28 148
RunItemfinderResults c9458 c8
RunMysteryEventScript 12613c 24
RunMysteryEventScriptCommand 12611c 20 140
RunOnDiveWarpMapScript 65728 c
RunOnLoadMapScript 65704 c
RunOnResumeMapScript 6571c c
RunOnTransitionMapScript 65710 c
RunPauseTimer 662c0 1e
RunSaveDialogCallback 71634 3c 205
RunScriptCommand 653f0 86
RunScriptImmediately 65614 38
RunTasks 7abe8 30
RunTimeBasedEvents 6946c 50 77
RunTrainerSeeFuncList 8433c 58 225
RunTurnActionsFunctions 138f0 a8 17
SB1ContainsWords fa7c8 32 53
SE12PanpotControl 75564 30
SSTicketWaitForAButtonPress c9bb8 20 117
SSTicketWaitForAButtonPress2 c9bd8 20 117
SafariBallOpenParticleAnimation 140c14 d4
SafariBufferExecCompleted 12b7c0 78
SafariBufferRunCommand 12b484 50
SafariHandleBallThrow 12ba14 5c
SafariHandleBattleAnimation 12bee0 5c
SafariHandleDMATransfer 12bce4 a
SafariHandleEffectivenessSound 12bd80 44
SafariHandleExpBarUpdate 12bc78 a
SafariHandleFaintingCry 12bdf4 3c
SafariHandleGetAttributes 12b864 a
SafariHandleHealthBarUpdate 12bc6c a
SafariHandleHitAnimation 12bd68 a
SafariHandleIntroSlide 12be30 34
SafariHandleLinkStandbyMsg 12bf3c a
SafariHandleLoadPokeSprite 12b894 a
SafariHandleMoveAnimation 12ba7c a
SafariHandleOpenBag 12bc14 40
SafariHandlePrintString 12ba88 64
SafariHandlePrintStringPlayerOnly 12baec 24
SafariHandlePuase 12ba70 a
SafariHandleResetActionMoveSelection 12bf48 a
SafariHandleReturnPokeToBall 12b8ac a
SafariHandleSendOutPoke 12b8a0 a
SafariHandleSetAttributes 12b87c a
SafariHandleSpriteInvisibility 12bed4 a
SafariHandleStatusAnimation 12bcc0 a
SafariHandleStatusIconUpdate 12bc84 3c
SafariHandleStatusXor 12bccc a
SafariHandleTrainerBallThrow 12be64 4c
SafariHandleTrainerSlide 12b994 a
SafariHandleTrainerSlideBack 12b9a0 a
SafariHandleTrainerThrow 12b8b8 dc
SafariHandlecmd1 12b870 a
SafariHandlecmd10 12b9ac a
SafariHandlecmd11 12b9b8 a
SafariHandlecmd12 12b9c4 50
SafariHandlecmd18 12bb10 ec
SafariHandlecmd19 12bbfc a
SafariHandlecmd20 12bc08 a
SafariHandlecmd22 12bc54 a
SafariHandlecmd23 12bc60 a
SafariHandlecmd29 12bcd8 a
SafariHandlecmd3 12b888 a
SafariHandlecmd31 12bcf0 a
SafariHandlecmd32 12bcfc a
SafariHandlecmd33 12bd08 a
SafariHandlecmd34 12bd14 a
SafariHandlecmd35 12bd20 a
SafariHandlecmd36 12bd2c a
SafariHandlecmd37 12bd38 a
SafariHandlecmd38 12bd44 a
SafariHandlecmd39 12bd50 a
SafariHandlecmd40 12bd5c a
SafariHandlecmd42 12bd74 a
SafariHandlecmd44 12bdc4 30
SafariHandlecmd48 12beb0 a
SafariHandlecmd49 12bebc a
SafariHandlecmd50 12bec8 a
SafariHandlecmd55 12bf54 5c
SafariHandlecmd56 12bfb0 2
SafariZoneActivatePokeblockFeeder c8478 90
SafariZoneGetActivePokeblock c8448 2e
SafariZoneGetPokeblockNameInFeeder c82ec 90
SafariZoneRetirePrompt c823c 10
SafariZoneTakeStep c8208 34
SafeFreeMonIconPalette 9d5d8 30
SafeLoadMonIconPalette 9d540 40
SampleFreqSet 1de32c a4
SandstormSpriteCallback1 80338 60
SandstormSpriteCallback2 80398 24
SandstormSpriteCallback3 803bc 74
Sandstorm_Finish 7ffc8 62
Sandstorm_InitAll 7ff1c 30
Sandstorm_InitVars 7fe9c 80
Sandstorm_Main 7ff4c 7c
SanitizeItemId a98bc 18 115
SanitizeMove b2760 16
SanitizeNameString 14a568 26
SanitizeSpecies b2778 18
SanitizeString 8280c 10 21
SaveBattleTowerProgress 135ba0 98
SaveCallback1 715a8 1c 205
SaveCallback2 715c4 4a 205
SaveCurrentWinStreak 135a3c 88 22
SaveDialogCB_DisplayConfirmMessage 71798 24 205
SaveDialogCB_DisplayConfirmYesNoMenu 717bc 20 205
SaveDialogCB_DisplayOverwriteYesNoMenu 71880 20 205
SaveDialogCB_DisplaySavingMessage 718ec 18 205
SaveDialogCB_DoSave 71904 60 205
SaveDialogCB_ProcessConfirmYesNoMenu 717dc 76 205
SaveDialogCB_ProcessOverwriteYesNoMenu 718a0 4a 205
SaveDialogCB_ReturnError 719d8 1a 205
SaveDialogCB_ReturnSuccess 7198c 24 205
SaveDialogCB_SaveError 719b0 28 205
SaveDialogCB_SaveFileExists 71854 2c 205
SaveDialogCB_SaveSuccess 71964 28 205
SaveDialogCheckForTimeoutAndKeypress 71768 2e 205
SaveDialogCheckForTimeoutOrKeypress 71734 34 205
SaveDialogStartTimeout 71728 c 205
SaveGame 71670 18
SaveMapView 565a8 74
SaveMuseumContestPainting c4cec c
SaveObjectEvents 47acc 38 121
SavePlayerBag 47c18 c0
SavePlayerParty 47a40 44
SaveSerializedGame 47b3c e
Save_EraseAllData 125194 24
Save_LoadGameData 125ec8 84
Save_ResetSaveCounters 1251b8 1c
Save_WriteData 125d44 3c
Save_WriteDataInternal 125c3c 108
SavedMapViewIsEmpty 5661c 34 80
ScanlineEffect_Clear 895b8 40
ScanlineEffect_InitHBlankDmaTransfer 89668 8c
ScanlineEffect_InitWave 89944 12c
ScanlineEffect_SetParams 895f8 70
ScanlineEffect_Stop 89578 40
ScrCmd_addcoins 67e80 38
ScrCmd_adddecoration 66108 2c
ScrCmd_addelevmenuitem 67de4 6c
ScrCmd_additem 65f44 44
ScrCmd_addmoney 67760 2c
ScrCmd_addobject 66c34 28
ScrCmd_addobject_at 66c5c 2e
ScrCmd_addpcitem 66080 44
ScrCmd_addvar 65eb8 26
ScrCmd_animateflash 66214 1a
ScrCmd_applymovement 66a88 40
ScrCmd_applymovement_at 66ac8 44
ScrCmd_braillemessage 67310 58
ScrCmd_bufferdecorationname 6748c 3c
ScrCmd_bufferitemname 67458 34
ScrCmd_bufferleadmonspeciesname 673c4 4c
ScrCmd_buffermovename 674c8 40
ScrCmd_buffernumberstring 67508 44
ScrCmd_bufferpartymonnick 67410 48
ScrCmd_bufferspeciesname 67384 40
ScrCmd_bufferstdstring 6754c 40
ScrCmd_bufferstring 6758c 28
ScrCmd_call 65930 18
ScrCmd_call_if 65984 3c
ScrCmd_callnative 658f0 10
ScrCmd_callstd 65adc 30
ScrCmd_callstd_if 65b58 4c
ScrCmd_checkcoins 67e60 1e
ScrCmd_checkdecor 6618c 2c
ScrCmd_checkdecorspace 66160 2c
ScrCmd_checkflag 661e0 1a
ScrCmd_checkitem 66010 44
ScrCmd_checkitemspace 65fcc 44
ScrCmd_checkitemtype 66054 2c
ScrCmd_checkmoney 677b8 40
ScrCmd_checkpartymove 676e4 7c
ScrCmd_checkpcitem 660c4 44
ScrCmd_checkplayergender 67bb4 14
ScrCmd_checktrainerflag 67940 22
ScrCmd_choosecontestmon 67aac 10
ScrCmd_clearflag 661cc 14
ScrCmd_cleartrainerflag 67980 1c
ScrCmd_closedoor 67cec 44
ScrCmd_closemessage 670b8 c
ScrCmd_compare_addr_to_addr 65e30 22
ScrCmd_compare_addr_to_local 65de4 2a
ScrCmd_compare_addr_to_value 65e10 20
ScrCmd_compare_local_to_addr 65db8 2c
ScrCmd_compare_local_to_local 65d60 30
ScrCmd_compare_local_to_value 65d90 28
ScrCmd_compare_var_to_value 65e54 2e
ScrCmd_compare_var_to_var 65e84 34
ScrCmd_contestlinktransfer 67adc 18
ScrCmd_copybyte 65ca8 1c
ScrCmd_copylocal 65c88 20
ScrCmd_copyvar 65ce8 2c
ScrCmd_createvobject 66ed0 70
ScrCmd_delay 662e0 24
ScrCmd_dofieldeffect 67af4 28
ScrCmd_dotimebasedevents 6633c c
ScrCmd_doweather 663a8 c
ScrCmd_dowildbattle 679d0 10
ScrCmd_drawbox 671b8 2a
ScrCmd_drawboxtext 67260 3a
ScrCmd_end 65878 c
ScrCmd_erasebox 67234 2a
ScrCmd_faceplayer 66e3c 38
ScrCmd_fadedefaultbgm 66a10 c
ScrCmd_fadeinbgm 66a64 24
ScrCmd_fadenewbgm 66a1c 14
ScrCmd_fadeoutbgm 66a30 34
ScrCmd_fadescreen 6626c 28
ScrCmd_fadescreenspeed 66294 2c
ScrCmd_getpartysize 66938 1c
ScrCmd_getplayerxy 66900 38
ScrCmd_getpricereduction 67a80 2c
ScrCmd_gettime 66348 38
ScrCmd_giveegg 6768c 2c
ScrCmd_givemon 6760c 80
ScrCmd_goto 6590c 18
ScrCmd_goto_if 65948 3c
ScrCmd_gotobeatenscript 6792c 12
ScrCmd_gotonative 65884 18
ScrCmd_gotopostbattlescript 67918 12
ScrCmd_gotoram 65ba4 14
ScrCmd_gotostd 65aac 30
ScrCmd_gotostd_if 65b0c 4c
ScrCmd_hidecoinsbox 678b0 1c
ScrCmd_hidemoneybox 67830 1c
ScrCmd_hidemonpic 672cc 20
ScrCmd_hideobjectat 66da0 30
ScrCmd_incrementgamestat 661fc 16
ScrCmd_initclock 66304 38
ScrCmd_killscript 65bb8 16
ScrCmd_loadbyte 65c48 1c
ScrCmd_loadbytefromaddr 65c0c 24
ScrCmd_loadword 65be8 22
ScrCmd_lock 66f84 58
ScrCmd_lockall 66f5c 28
ScrCmd_message 6706c 1a
ScrCmd_messageautoscroll 67088 1a
ScrCmd_moveobjectoffscreen 66d48 28
ScrCmd_multichoice 6712c 3a
ScrCmd_multichoicedefault 67168 50
ScrCmd_multichoicegrid 671e4 50
ScrCmd_nop 65870 4
ScrCmd_nop1 65874 4
ScrCmd_opendoor 67c94 56
ScrCmd_playbgm 669cc 2e
ScrCmd_playfanfare 66994 14
ScrCmd_playmoncry 67bc8 38
ScrCmd_playse 66954 14
ScrCmd_playslotmachine 67a1c 28
ScrCmd_pokemart 679e0 14
ScrCmd_pokemartdecoration 679f4 14
ScrCmd_pokemartdecoration2 67a08 14
ScrCmd_random 65f10 34
ScrCmd_release 67014 58
ScrCmd_releaseall 66fdc 38
ScrCmd_removecoins 67eb8 38
ScrCmd_removedecoration 66134 2c
ScrCmd_removeitem 65f88 44
ScrCmd_removemoney 6778c 2c
ScrCmd_removeobject 66bdc 28
ScrCmd_removeobject_at 66c04 2e
ScrCmd_resetobjectpriority 66e0c 2e
ScrCmd_resetweather 6639c c
ScrCmd_return 65924 c
ScrCmd_savebgm 669fc 14
ScrCmd_setberrytree 67a44 3c
ScrCmd_setdivewarp 66780 7e
ScrCmd_setdoorclosed 67da0 44
ScrCmd_setdooropen 67d5c 44
ScrCmd_setdynamicwarp 666fc 82
ScrCmd_setescapewarp 66880 7e
ScrCmd_setfieldeffectargument 67b1c 30
ScrCmd_setflag 661b8 14
ScrCmd_setflashradius 66230 1c
ScrCmd_setholewarp 66800 7e
ScrCmd_setmaplayoutindex 663cc 1c
ScrCmd_setmetatile 67c14 7e
ScrCmd_setmonmove 676b8 2a
ScrCmd_setmysteryeventstatus 65bd0 16
ScrCmd_setobjectmovementtype 66ea8 28
ScrCmd_setobjectpriority 66dd0 3a
ScrCmd_setobjectxy 66c8c 64
ScrCmd_setobjectxyperm 66cf0 56
ScrCmd_setorcopyvar 65d14 2a
ScrCmd_setptrbyte 65c64 24
ScrCmd_setrespawn 67b98 1c
ScrCmd_setstepcallback 663b4 16
ScrCmd_settrainerflag 67964 1c
ScrCmd_setvaddress 659c0 1c
ScrCmd_setvar 65cc4 22
ScrCmd_setwarp 6667c 7e
ScrCmd_setweather 66380 1c
ScrCmd_setwildbattle 6799c 32
ScrCmd_showcoinsbox 67884 2c
ScrCmd_showcontestresults 67acc 10
ScrCmd_showcontestwinner 672ec 22
ScrCmd_showelevmenu 67e50 10
ScrCmd_showmoneybox 677f8 38
ScrCmd_showmonpic 6729c 2e
ScrCmd_showobjectat 66d70 30
ScrCmd_special 6589c 20
ScrCmd_specialvar 658bc 34
ScrCmd_startcontest 67abc 10
ScrCmd_subvar 65ee0 2e
ScrCmd_trainerbattle 678f8 14
ScrCmd_trainerbattlebegin 6790c c
ScrCmd_turnobject 66e74 34
ScrCmd_turnvobject 66f40 1c
ScrCmd_updatecoinsbox 678cc 2c
ScrCmd_updatemoneybox 6784c 38
ScrCmd_vbufferstring 675d8 34
ScrCmd_vcall 65a00 24
ScrCmd_vcall_if 65a68 44
ScrCmd_vgoto 659dc 24
ScrCmd_vgoto_if 65a24 44
ScrCmd_vloadptr 675b4 24
ScrCmd_vmessage 67368 1c
ScrCmd_waitbuttonpress 670ec 14
ScrCmd_waitdooranim 67d48 14
ScrCmd_waitfanfare 669b8 14
ScrCmd_waitfieldeffect 67b6c 2c
ScrCmd_waitmessage 670a4 14
ScrCmd_waitmoncry 67c00 14
ScrCmd_waitmovement 66b34 54
ScrCmd_waitmovement_at 66b88 54
ScrCmd_waitse 66980 14
ScrCmd_waitstate 65900 c
ScrCmd_warp 663e8 86
ScrCmd_warpdoor 664f8 86
ScrCmd_warphole 66580 74
ScrCmd_warpsilent 66470 86
ScrCmd_warpteleport 665f4 86
ScrCmd_writebytetoaddr 65c30 18
ScrCmd_yesnobox 67100 2c
ScrSpecial_AreLeadMonEVsMaxedOut 10f588 32
ScrSpecial_BeginCyclingRoadChallenge 10d6fc 28
ScrSpecial_CanMonParticipateInSelectedLinkContest c4440 80
ScrSpecial_CheckSelectedMonAndInitContest c43f4 4c
ScrSpecial_ChooseStarter 82168 20
ScrSpecial_CountContestMonsWithBetterCondition c4758 48
ScrSpecial_CountPokemonMoves f9f3c 48
ScrSpecial_DoesPlayerHaveNoDecorations 109c58 38
ScrSpecial_GenerateGiddyLine f7cf4 cc
ScrSpecial_GetContestPlayerMonIdx c496c 14
ScrSpecial_GetContestWinnerIdx c47c0 30
ScrSpecial_GetContestWinnerNick c4858 34
ScrSpecial_GetContestWinnerTrainerName c47f0 68
ScrSpecial_GetCurrentMauvilleMan f7b14 18
ScrSpecial_GetHipsterSpokenFlag f7c70 14
ScrSpecial_GetMonCondition c47a0 20
ScrSpecial_GetPokemonNicknameAndMoveName f9f84 58
ScrSpecial_GetTraderTradedFlag 109c44 14
ScrSpecial_GetTrainerBattleMode 82558 c
ScrSpecial_GiddyShouldTellAnotherTale f7cc8 2c
ScrSpecial_GiveContestRibbon c44c0 1b4
ScrSpecial_HasBardSongBeenChanged f7b2c 14
ScrSpecial_HasStorytellerAlreadyRecorded f88e0 1a
ScrSpecial_HealPlayerParty c52b0 c4
ScrSpecial_HipsterTeachWord f7c90 38
ScrSpecial_IsDecorationFull 109c90 60
ScrSpecial_PlayBardSong f7c54 1c
ScrSpecial_RockSmashWildEncounter 85290 6c
ScrSpecial_SaveBardSongLyrics f7b40 60
ScrSpecial_SetHipsterSpokenFlag f7c84 c
ScrSpecial_SetLinkContestTrainerGfxIdx c4f70 4c
ScrSpecial_ShowDiploma 10d6a4 14
ScrSpecial_ShowTrainerNonBattlingSpeech 82718 e
ScrSpecial_StartGroudonKyogreBattle 81bf8 58
ScrSpecial_StartRayquazaBattle 81bb8 40
ScrSpecial_StartRegiBattle 81c50 3c
ScrSpecial_StartSouthernIslandBattle 81b78 40
ScrSpecial_StartWallyTutorialBattle 81afc 40
ScrSpecial_StorytellerDisplayStory f8888 14
ScrSpecial_StorytellerGetFreeStorySlot f889c e
ScrSpecial_StorytellerInitializeRandomStat f88fc e
ScrSpecial_StorytellerStoryListMenu f8874 14
ScrSpecial_StorytellerUpdateStat f88ac 34
ScrSpecial_TraderDoDecorationTrade 109de0 54
ScrSpecial_TraderMenuGetDecoration 109e34 1c
ScrSpecial_TraderMenuGiveDecoration 109cf0 14
ScrSpecial_ViewWallClock 10d6b8 24
ScrambleStatList f85fc 52 131
ScriptAddElevatorMenuItem 10e7ac 78
ScriptCall 654c8 14
ScriptCmd_blendoff 76aa4 1c 6
ScriptCmd_call 76ac0 34 6
ScriptCmd_changebg 76f7c 20 6
ScriptCmd_choosetwoturnanim 76b3c 40 6
ScriptCmd_clearmonbg 76660 d0 6
ScriptCmd_clearmonbg_23 768d4 d4 6
ScriptCmd_createsoundtask 77614 74 6
ScriptCmd_createsprite 75ac8 f4 6
ScriptCmd_createvisualtask 75bbc 7c 6
ScriptCmd_delay 75c38 40 6
ScriptCmd_doublebattle_2D 77950 b0 6
ScriptCmd_doublebattle_2E 77a00 98 6
ScriptCmd_end 75cb4 108 6
ScriptCmd_fadetobg 76c0c 44 6
ScriptCmd_fadetobgfromset 76c50 98 6
ScriptCmd_hang1 75cac 2 6
ScriptCmd_hang2 75cb0 2 6
ScriptCmd_invisible 778d4 3c 6
ScriptCmd_jump 76bc0 24 6
ScriptCmd_jumpargeq 7770c 54 6
ScriptCmd_jumpifcontest 77760 40 6
ScriptCmd_jumpifmoveturn 76b7c 42 6
ScriptCmd_loadspritegfx 75a14 68 6
ScriptCmd_loopsewithpan 77478 88 6
ScriptCmd_monbg 75de4 1dc 6
ScriptCmd_monbg_22 767c8 10c 6
ScriptCmd_monbgprio_28 777a0 6c 6
ScriptCmd_monbgprio_29 7780c 44 6
ScriptCmd_monbgprio_2A 77850 84 6
ScriptCmd_panse_1B 771d4 c0 6
ScriptCmd_panse_26 77324 94 6
ScriptCmd_panse_27 773b8 c0 6
ScriptCmd_playse 75dbc 28 6
ScriptCmd_playsewithpan 77170 38 6
ScriptCmd_restorebg 76ed0 44 6
ScriptCmd_return 76af4 14 6
ScriptCmd_setalpha 76a40 3c 6
ScriptCmd_setarg 76b08 34 6
ScriptCmd_setbldcnt 76a7c 28 6
ScriptCmd_setpan 771a8 2c 6
ScriptCmd_stopsound 77a98 28 6
ScriptCmd_unloadspritegfx 75a7c 4c 6
ScriptCmd_visible 77910 40 6
ScriptCmd_waitbgfadein 76f48 34 6
ScriptCmd_waitbgfadeout 76f14 34 6
ScriptCmd_waitforvisualfinish 75c78 34 6
ScriptCmd_waitplaysewithpan 7755c 74 6
ScriptCmd_waitsound 77688 84 6
ScriptContext_Enable 65600 14
ScriptContext_Init 65558 28
ScriptContext_RunScript 65580 3c
ScriptContext_SetupScript 655bc 38
ScriptContext_Stop 655f4 c
ScriptFreezeObjectEvents 64d24 18
ScriptGetMultiplayerId c5228 34
ScriptGetPartyMonSpecies 10f8d4 28
ScriptGetPokedexInfo 10d43c 4c
ScriptGiveEgg c53f8 30
ScriptGiveMon c5374 82
ScriptHatchMon 42aa8 14
ScriptJump 654c4 4
ScriptMenu_CreatePCMenu b5734 104
ScriptMenu_CreatePCMultichoice b5704 2e
ScriptMenu_DisplayPCStartupPrompt b5838 18
ScriptMenu_GetPicboxWaitFunc b5974 36
ScriptMenu_Multichoice b5054 5a
ScriptMenu_MultichoiceGrid b5578 10c
ScriptMenu_MultichoiceWithDefault b50b0 6a
ScriptMenu_ShowPokemonPic b58c4 b0
ScriptMenu_YesNo b546c 5c
ScriptMovement_IsObjectMovementFinished a212c 4c
ScriptMovement_StartObjectMovementScript a20d4 58
ScriptPop 654a0 22 183
ScriptPush 65478 28 183
ScriptRandom c525c 54
ScriptReadHalfword 654ec 16
ScriptReadWord 65504 30
ScriptReturn 654dc 10
ScriptSetMonMoveSlot c5530 38
ScriptShowElevatorMenu 10e824 50
ScriptUnfreezeObjectEvents 64e30 30
ScrollWindowTextLines 401c 2c 214
ScrollWindowTextLines_TextMode0 4048 64 214
ScrollWindowTextLines_TextMode2 41d4 34 214
ScrollWindowTextLines_TextModeMonospace 412c 34 214
SealedChamberShakingEffect 14782c 64
SearchParamCantScrollDown 92f8c 4a 158
SearchParamCantScrollUp 92f44 46 158
SecretBasePC_Decoration bc604 14
SecretBasePC_Registry bc618 14
SeedRng 40ea4 10
SeedRngWithRtc 3e4 1c 127
SeekSpriteAnim 1f8c 7a
SelectBattleTowerOKButton 6c894 9c
SelectContestMoveBankTarget b29b4 c8
SelectMonForNPCTrade f9a0c 40
SelectMove f9eec 50
SelectMoveTutorMon f9a4c 40
SellMenu_QuantityRoller a52c4 8a
SendBlock 7e88 14
SendBlockToAllOpponents c857c 30 42
SendMonToPC 3d998 80
SendOutMonAnimation 46464 1d0 155
SendOutMonAnimation_Delay 47230 24 155
SendOutOpponentMonAnimation_Step0 47254 5c 155
SendOutPlayerMonAnimation_Step0 47074 50 155
SendOutPlayerMonAnimation_Step1 470c4 16c 155
SendRecvDone 9000 30 120
SerialCB 8c6c 88
SerialCB_CopyrightScreen 13b854 10 114
SerialIntr 660 30 127
SetActionsAndBanksTurnOrder 133c8 294
SetAllPlayersBerryData eb08 13c
SetAndStartSpriteAnim 64840 26
SetAnimRaindropCallback d3184 c
SetAreaHasMon 110a98 4c 159
SetAttentionLevels af3c0 42
SetAverageBattlerPositions 7a400 a2
SetBankFuncToLinkOpponentBufferRunCommand 37510 1c
SetBankFuncToLinkPartnerBufferRunCommand 11da78 1c
SetBankFuncToOpponentBufferRunCommand 32ae0 1c
SetBankFuncToPlayerBufferRunCommand 2bf74 28
SetBankFuncToSafariBufferRunCommand 12b468 1c
SetBattleBarStruct 43d84 2c
SetBattleMonMoveSlot 3b6e4 30
SetBattlePartyIds bd54 148 14
SetBattleTargetSpritePosition b2968 4c
SetBattleTowerParty 135a14 28
SetBattleTowerPlayerParty c55c8 3c
SetBattleTowerProperty 135668 23c
SetBattleTowerRecordChecksum 135cc4 22 22
SetBattleTowerTrainerGfxId 1349fc b8
SetBattlerSpriteAffineMode 326ec e0
SetBgAffineStruct 40f08 2a
SetBgForCurtainDrop b2184 fc
SetBikeScene 144a68 464 47
SetBlendForContestantBoxBlink b0b98 1c
SetBlockReceivedFlag 7f04 14 120
SetBottomSliderHeartsInvisibility affe0 52
SetBoxMonData 3d2ec 624
SetCableClubWarp 68ff0 44
SetCallback 110814 10 159
SetCallbackToStoredInData 78108 e
SetCameraCoords 56c80 c 80
SetCameraFocusCoords 56c54 18
SetCameraPanning 58248 18
SetCameraPanningCallback 5823c c
SetCloseLinkCallback 832c 24
SetContestCategoryStringVarForInterview bf060 28
SetContestTrainerGfxIds c4bf0 38
SetContestWinnerForPainting 106630 38
SetContestantEffectStringID b13ec 18
SetContestantEffectStringID2 b1404 18
SetContestantStatusesForNextRound af438 164
SetControllerToWally 137224 48
SetCryMeterNeedleTarget 11a6d8 2c
SetCurrentSecretBase c6264 1c 92
SetCurrentSecretBaseFromPosition bbfd8 5e
SetCurrentSecretBaseVar bb5e4 58
SetCurrentTrainerBattledFlag 8257c 12
SetCursorPos b680c 4c 141
SetCursorX 3ca0 28 214
SetCutGrassMetatile a27a8 f6 87
SetCutGrassMetatiles a28f4 154 87
SetDaycareCompatibilityString 42508 40
SetDebugMonForContest aa69c b8
SetDefaultFlashLevel 53c98 4c
SetDefaultOptions 52d54 24
SetDefaultSearchModeAndOrder 92eb0 94 158
SetDepartmentStoreFloorVar 10e74c 60
SetDiveWarp 53850 5e 148
SetDiveWarpDive 538d0 1e
SetDiveWarpEmerge 538b0 1e
SetEReaderTrainerChecksum 136088 22
SetEReaderTrainerGfxId 134ab4 c
SetEReaderTrainerName 135ff4 28
SetEnigmaBerry b48a8 50
SetEvoSparklesMatrices 149520 38 64
SetFieldVBlankCallback 547e8 10 148
SetFixedDiveWarp 53690 3c
SetFixedDiveWarpAsDestination 536cc 18 148
SetFixedHoleWarp 536e4 3c
SetFixedHoleWarpAsDestination 53720 56
SetFlashScanlineEffectWindowBoundaries 81398 8c 75
SetFlashScanlineEffectWindowBoundary 8136c 2c 75
SetFlashTimerIntr 1df69c 3a
SetGameStat 53130 24
SetHBlankCallback 54c c
SetHealthboxSpriteInvisible 43db0 4c
SetHealthboxSpriteVisible 43dfc 54
SetHeldItemIconVisibility 6df64 a0
SetHiddenItemFlag 10e348 14
SetIncompatible 1260d0 1c 140
SetInitialEggData 420fc a4 52
SetInitialSearchMenuBgHighlights 92964 14c 158
SetInputState b6210 2c 141
SetLinkDebugValues 8184 14
SetLotteryNumber 145d14 28
SetLotteryNumber16_Unused 145d64 e
SetMainCallback1 543d4 c
SetMainCallback2 3cc 18
SetMapVarsToTrainer 82394 34 21
SetMauvilleOldManObjEventGfx f83d0 28
SetMirageRnd 10d2ac 28 221
SetMonData 3d1fc ee
SetMonIconAnim 6d850 34
SetMonIconAnimByHP 6d7fc 54
SetMonIconSpriteId 6de54 e4
SetMonMarkings f4548 58
SetMonMoveSlot 3b6a4 40
SetMonPreventsSwitchingString 40b8c ac
SetMoveAnimAttackerData b28f0 3c
SetMoveEffect 1e3ec 1228
SetMoveSpecificAnimData b2790 13c
SetMovementDelay 64824 4 63
SetMuddySlopeAnimatedMetatile 6a190 5c 77
SetMultiuseSpriteTemplateToPokemon 3c56c 34
SetMultiuseSpriteTemplateToTrainerBack 3c5a0 50
SetMysteryEventScriptStatus 126160 c
SetOamMatrix 100c 20
SetOamMatrixRotationScaling 2228 80
SetObjectEventCoords 5c048 12 63
SetObjectEventDirection 5c514 42
SetObjectEventDynamicGraphicsId 5bc44 1c 63
SetObjectEventSpriteOamTableForLongGrass 63c24 5a 63
SetObjectSubpriorityByZCoord 63dc8 48
SetOccupiedSecretBaseEntranceMetatiles bb970 a2
SetOpenedSecretBaseMetatile bb800 a8
SetPSSCallback 96be0 10
SetPacifidlogTMReceivedDay 10f950 1c
SetPartyHPBarSprite 9d824 1e
SetPartyMenuSettings 6af50 40
SetPartyPopupMenuOffsets 6e724 2e
SetPetalburgGymDoorTiles 10e104 12c 76
SetPlacedMonData 9b4d4 74
SetPlayerAvatarExtraStateTransition 59a94 30
SetPlayerAvatarObjectEventIdAndObjectId 5b950 34 63
SetPlayerAvatarStateMask 599f8 18
SetPlayerAvatarTransitionFlags 5905c 1c
SetPlayerBerryDataInBattleStruct eaac 5c 17
SetPlayerCoordsFromWarp 533cc 74 148
SetPlayerDirectionTowardsItem c997c 70
SetPlayerSecretBaseRecordMixingParty bc300 140
SetPokeblockFeedSpritePal 147c90 38 157
SetPokemonCryChorus 1df53c 2c
SetPokemonCryLength 1df500 c
SetPokemonCryPanpot 1df4b0 18
SetPokemonCryPitch 1df4c8 38
SetPokemonCryPriority 1df5a8 c
SetPokemonCryProgress 1df518 c
SetPokemonCryRelease 1df50c c
SetPokemonCryStereo 1df568 40
SetPokemonCryTone 1df3cc d0
SetPokemonCryVolume 1df49c 14
SetPokemonItemUseAndFadeOut c9d98 18 117
SetPositionFromConnection 5691c 7c 80
SetPresetPalette_BlackAndWhite fdb8c 1c
SetPresetPalette_Grayscale fdbe4 34
SetPresetPalette_GrayscaleSmall fdba8 3c
SetPresetPalette_PrimaryColors fdae4 a8
SetPresetPlayerName b808 50 128
SetRainStrengthFromSoundEffect 7dd5c 5c
SetRandomLotteryNumber 145aa4 48
SetReadFlash1 1df7c8 3e
SetRecordMixingGift 1262e4 54 140
SetRoamerInactive 13452c c
SetRoute119Weather 10f83c 20
SetRoute123Weather 10f85c 20
SetSSTidalFlag 10d980 20
SetSafariZoneFlag c8198 10
SetSav1Weather 806b4 24
SetSav1WeatherFromCurrMapHeader 806e4 28
SetSearchRectHighlight 92810 5c
SetSecretBase2Field_9 47a10 c
SetSecretBase2Field_9_AndHideBG 47a1c 18
SetSecretBaseOwnerGfxId bbfa4 34
SetSectorDamagedStatus 1251d4 64 177
SetSerialCallback 564 c
SetShiftedMonData 9b58c a0
SetShoalItemFlag 10f618 10
SetShopItemsForSale b2e08 30 193
SetShopMenuCallback b2dfc c 193
SetSootopolisGymCrackedIceMetatiles 69d7c 5c
SetSpecialMapHasMon 110ae4 c0 159
SetSpriteInvisible 126ba4 20
SetSpriteOamFlipBits 1ca0 72 204
SetSpritePrimaryCoordsFromSecondaryCoords 78750 18
SetSpriteSheetFrameTileNum 20d4 58
SetSpriteTemplateForPokemonPic 91878 38 158
SetSpriteTemplateForSizeComparisonTrainerPic 918b0 3c 158
SetStartledString b141c 4e
SetSubspriteTables 2730 a
SetSuppressLinkErrorMessage 8704 c
SetTVMetatilesOnMap bd98c 62
SetTaskFuncWithFollowupFunc 7ac58 34
SetThunderCounter 7f3f8 3c
SetTradeSceneStrings 4c1a8 f4 223
SetTrainerFlag 825bc 14
SetTrainerFlagsAfterTrainerEyeRematch 82cb8 1c 21
SetTrainerMovementType 5fec8 4c
SetTrickHouseEndRoomFlag 10ef0c 18
SetUpBattlePartyMenu 94e58 1f8
SetUpBattleVarsAndBirchPoochyena b884 cc
SetUpContestWindow ab320 30
SetUpCopyrightScreen 13b864 1de 114
SetUpFieldMove_Cut a2504 e4
SetUpFieldMove_Dig 10b5a4 34
SetUpFieldMove_Dive 8adc8 40 160
SetUpFieldMove_Flash 10cbb4 46
SetUpFieldMove_Fly 8aca8 64 160
SetUpFieldMove_RockSmash 10b504 38
SetUpFieldMove_SecretPower c62c4 d8
SetUpFieldMove_SoftBoiled 133ccc 5c
SetUpFieldMove_Strength 11a99c 7c
SetUpFieldMove_Surf 8ac48 42 160
SetUpFieldMove_SweetScent 12bfb4 20
SetUpFieldMove_Teleport 14a374 40
SetUpFieldMove_Waterfall 8ae24 66 160
SetUpFieldTasks 694f0 6c
SetUpItemUseOnFieldCallback c9050 48
SetUpMassOutbreakEncounter 84f50 74 239
SetUpPlacingDecorationPlayerAvatar ff89c c4
SetUpPuttingAwayDecorationPlayerAvatar 100d84 ec
SetUpTrainerMovement 82524 34
SetVBlankCallback 540 c
SetVCountCallback 558 c
SetVerticalScrollIndicatorPriority f9988 44
SetVerticalScrollIndicators f979c 44
SetWallyMonData 138294 9fc 13
SetWarpData 532b4 1e 148
SetWeather 8070c 16
SetWeatherScreenFadeOut 7de10 14
SetWeather_Unused 80724 16
SetWildMonHeldItem 40c38 7a
SetWindowBackgroundColor 3f60 20 214
SetWindowDefaultColors 3f3c 24 214
SetWindowForegroundColor 3f90 14 214
SetWindowShadowColor 3f80 10 214
SetWord 1261a4 10 140
SetupBagMultistep a317c 336 116
SetupBard f7a34 38 131
SetupBattleTowerPartyMenu 121e78 1b6
SetupBytecodeScript 653d4 a
SetupContestGraphics ab70c 254
SetupContestPartyMenu f9acc 132
SetupDefaultPartyMenu 6afd4 152 150
SetupDefaultPartyMenuSwitchPokemon 6ca64 9c
SetupGiddy f7a88 10 131
SetupHipster f7a6c 10 131
SetupLinkMultiBattlePartyMenu 122854 94
SetupMauvilleOldMan f7aa4 64
SetupMoveTutorPartyMenu f9ce8 132
SetupNativeScript 653e0 8
SetupStoryteller f7a7c a 131
SetupTrader f7a98 a 131
Shade_Finish 80470 4
Shade_InitAll 80460 a
Shade_InitVars 80430 30
Shade_Main 8046c 2
ShakeCamera 10f758 50
ShakeScreenInElevator 10ebec 48
ShatterSecretBaseBreakableDoor c6a54 58
ShiftDaycareSlots 414c0 5c 52
ShiftGlyphTile_ShadowedFont_Width0 57c8 2 214
ShiftGlyphTile_ShadowedFont_Width1 57cc 5c 214
ShiftGlyphTile_ShadowedFont_Width2 5828 68 214
ShiftGlyphTile_ShadowedFont_Width3 5890 80 214
ShiftGlyphTile_ShadowedFont_Width4 5910 90 214
ShiftGlyphTile_ShadowedFont_Width5 59a0 310 214
ShiftGlyphTile_ShadowedFont_Width6 5cb0 380 214
ShiftGlyphTile_ShadowedFont_Width7 6030 3f2 214
ShiftGlyphTile_ShadowedFont_Width8 6424 450 214
ShiftGlyphTile_UnshadowedFont_Width0 5204 2 214
ShiftGlyphTile_UnshadowedFont_Width1 5208 4c 214
ShiftGlyphTile_UnshadowedFont_Width2 5254 6c 214
ShiftGlyphTile_UnshadowedFont_Width3 52c0 88 214
ShiftGlyphTile_UnshadowedFont_Width4 5348 88 214
ShiftGlyphTile_UnshadowedFont_Width5 53d0 94 214
ShiftGlyphTile_UnshadowedFont_Width6 5464 a4 214
ShiftGlyphTile_UnshadowedFont_Width7 5508 b0 214
ShiftGlyphTile_UnshadowedFont_Width8 55b8 c8 214
ShiftObjectEventCoords 5c038 e
ShiftStillObjectEventCoords 5c150 12
ShiftWaveformOver 11a350 7c
Shop_AnimViewportObjects b368c 94 193
Shop_CreateDecorationShop1Menu b4574 20
Shop_CreateDecorationShop2Menu b4594 20
Shop_CreatePokemartMenu b4550 24
Shop_DisplayDecorationPriceInList b3930 a0 193
Shop_DisplayNormalPriceInList b389c 94 193
Shop_DisplayPriceInCheckoutWindow b37f8 a4 193
Shop_DisplayPriceInList b39d0 a0 193
Shop_DoCursorAction b40e8 28e 193
Shop_DoItemTransaction b3b80 50 193
Shop_DoPremierBallCheck b3aec 94 193
Shop_DoPricePrintAndReturnToBuyMenu b3bd0 24 193
Shop_DoYesNoPurchase b3d38 44 193
Shop_DrawViewport b3554 16 193
Shop_DrawViewportTiles b3420 134 193
Shop_FadeAndRunBuySellCallback b2fa0 3c 193
Shop_FadeReturnToMartMenu b3050 18
Shop_InitMenus b3764 38 193
Shop_LoadExitSellMenuTask b3078 1c
Shop_LoadViewportObjects b356c 120 193
Shop_MoveItemListDown b403c ac 193
Shop_MoveItemListUp b3f88 b4 193
Shop_PrintItemDesc b37ec a 193
Shop_PrintItemDescText b3a70 7c 193
Shop_PrintPrice b3dc8 134 193
Shop_RunExitSellMenuTask b3068 e
Shop_TryDrawVerticalScrollIndicators b32a4 48 193
Shop_UpdateCurItemCountToMax b3efc 8c 193
ShouldBattleEReaderTrainer 134650 a4
ShouldDoBrailleDigEffect 1473b8 4e
ShouldDoBrailleFlyEffect 147588 3a
ShouldDoBrailleStrengthEffect 1474c8 4a
ShouldEggHatch 422a0 14
ShouldHideGenderIcon 40d8c 20
ShouldHideGenderIconForLanguage 40d3c 50
ShouldJumpLedge 58f4c 22 73
ShouldLegendaryMusicPlayAtLocation 53d30 3c 148
ShouldMoveLilycoveFanClubMember 10fd60 20
ShouldReadyContestArtist c4cf8 58
ShouldSwitch 36904 206 5
ShouldSwitchIfNaturalCure 36410 104 5
ShouldSwitchIfPerishSong 35fec 66 5
ShouldSwitchIfWonderGuard 36054 194 5
ShouldTryRematchBattle 82c68 34
ShouldUseItem 3708c 47e 5
ShowAndUpdateApplauseMeter b1cbc 40
ShowApplauseMeterNoAnim b1db8 24
ShowBattleTowerRecords 1105e4 80
ShowBerryBlenderRecordWindow 52b14 bc
ShowCoinsWindow 11a72c 42
ShowContestEntryMonPic c5050 114
ShowContestPainting 106674 194 44
ShowContestWinner c4f10 60
ShowContestWinnerCleanup c4f00 10
ShowDaycareLevelMenu 42824 64
ShowDisguiseFieldEffect 1284f4 b8 70
ShowEasyChatScreen e60d8 1c8
ShowFieldAutoScrollMessage 64b94 26
ShowFieldMessage 64b6c 28
ShowFieldMessageStringVar4 10e24c 10
ShowGlassWorkshopMenu 10f090 88
ShowHideNextTurnGfx b1fd0 bc
ShowLinkBattleRecords 11043c 58
ShowMapNamePopUpWindow f0798 84
ShowMapNamePopup a2f54 a0
ShowPartyPopupMenu 6e754 7e
ShowPokedexAreaScreen 1113ac 40
ShowPokedexCryScreen 11a3cc 12c
ShowPokedexRatingMessage 10d600 18
ShowPokemonStorageSystem 96100 30
ShowPokemonSummaryScreen 9d8bc 134
ShowSelectMovePokemonSummaryScreen 9d9f0 2c
ShowTrainerIntroSpeech 826d8 e
ShowWarpArrowSprite 126bc4 a8
ShrinkPlayerSprite b240 1a 128
ShrubEntranceSpriteCallback1 c66bc 1c 92
ShrubEntranceSpriteCallback2 c66d8 30 92
ShrubEntranceSpriteCallbackEnd c6708 10 92
SiiRtcGetDateTime 1e01a8 b0
SiiRtcGetStatus 1e0034 cc
SiiRtcGetTime 1e02f4 b4
SiiRtcProbe 1dfed8 d6
SiiRtcProtect 1dfec0 18
SiiRtcReset 1dffb0 84
SiiRtcSetAlarm 1e0444 134
SiiRtcSetDateTime 1e0258 9c
SiiRtcSetStatus 1e0100 a8
SiiRtcSetTime 1e03a8 9c
SiiRtcUnprotect 1dfea8 18
Sin 40dec 1c
Sin2 40e28 44
SkipExtCtrlCode 4f60 22 214
SlideApplauseMeterIn b1b14 54
SlideApplauseMeterOut b1bdc 58
SlideMonToOffset a8764 b4 8
SlideMonToOriginalPos a8638 bc 8
SlideMonToOriginalPosStep a86f4 70 8
SlidersDoneUpdating aff28 38
SlotMachineDummyTask 101a24 2 199
SlotMachineSetup_0_0 101a28 1a 199
SlotMachineSetup_0_1 101ba4 e0 199
SlotMachineSetup_1_0 101a8c 54 199
SlotMachineSetup_2_0 101ae0 24 199
SlotMachineSetup_2_1 101b04 a0 199
SlotMachineSetup_3_0 101c84 1c 199
SlotMachineSetup_4_0 101ca0 20 199
SlotMachineSetup_5_0 101cc0 12 199
SlotMachineSetup_6_0 101cd4 16 199
SlotMachineSetup_6_1 101cec 16 199
SlotMachineSetup_6_2 101a44 48 199
SlotMachine_VBlankCallback 10196c 44 199
Snow_Finish 7eac0 64
Snow_InitAll 7ea18 6c
Snow_InitVars 7e9c8 50
Snow_Main 7ea84 3c
SoftReset 1e0798 18
SortContestants b0f28 1f0
SortDecorationInventory 134104 90
SortItemSlots a3c34 74 116
SortLinkBattleRecords 11003c 7c 19
SortPokedex 8d690 558 158
SortSprites 930 1c0 204
SoundClear 1de468 54
SoundInit 1de234 f8
SoundMain 1dcdb4 84
SoundMainBTM 1dd53c 16
SoundMainRAM 1dce38 3bc
Sound_DrawChoices 8be34 40 145
Sound_ProcessInput 8be0c 28 145
SpawnBerryBlenderLinkPlayerSprites 10db28 154
SpawnBoxIconSprites 98c48 d8
SpawnCameraDummy 10f338 50
SpawnLinkPlayerObjectEvent 55984 ac 148
SpawnSpecialObjectEvent 5b234 3c
SpawnSpecialObjectEventParametrized 5b270 68
SpecialStatusesClear 1377c 50
SpeciesToCryId 3f904 32
SpeciesToHoennPokedexNum 3f8bc 22
SpeciesToMailSpecies a2d44 20
SpeciesToNationalPokedexNum 3f898 22
SpeciesToPokedexNum 406d8 38
SpriteAnimEnded 64868 18
SpriteCB_AMIndicator 10b18c a4 236
SpriteCB_BerrySprite a7dc4 10 116
SpriteCB_BlinkContestantBox b0c5c 54
SpriteCB_CreditsMon 1454e0 1d4
SpriteCB_CreditsMonBg 14580c ce
SpriteCB_CryMeterNeedle 11a534 1a4
SpriteCB_Cursor fbaf0 48 167
SpriteCB_DexListInterfaceText 8f08c 28 158
SpriteCB_DexListStartMenuCursor 8f168 a6 158
SpriteCB_EggShard 435a4 58 59
SpriteCB_Egg_0 432e4 56 59
SpriteCB_Egg_1 4333c 62 59
SpriteCB_Egg_2 433a0 c0 59
SpriteCB_Egg_3 43460 24 59
SpriteCB_Egg_4 43484 80 59
SpriteCB_Egg_5 43504 a0 59
SpriteCB_EndBlinkContestantBox b0cb0 2c
SpriteCB_EndMoveMonForInfoScreen 8ed90 2 158
SpriteCB_FlyTargetIcons fc55c 56 167
SpriteCB_FreePlayerSpriteLoadMonSprite 30e38 68
SpriteCB_GlitterMatSparkle c6c64 2c
SpriteCB_HallOfFameMonitor 86550 6c
SpriteCB_HallOfFame_Dummy 143644 2 107
SpriteCB_HeldItemIcon 6dab8 58
SpriteCB_HourHand 10b0f4 98 236
SpriteCB_JudgeSpeechBubble b16d0 40
SpriteCB_LinkPlayer 55edc b6 148
SpriteCB_MinuteHand 10b05c 98 236
SpriteCB_MonSlideIn ad8fc 30
SpriteCB_MonSlideOut ad92c 34
SpriteCB_MoveMonForInfoScreen 8edb8 70 158
SpriteCB_Null7 137220 2 13
SpriteCB_PMIndicator 10b230 a4 236
SpriteCB_Player 145378 a6 47
SpriteCB_PlayerIconZoomedIn fbea4 8e 167
SpriteCB_PlayerIconZoomedOut fbf34 a 167
SpriteCB_PokeballGlow 86408 28
SpriteCB_PokeballGlowEffect 860a0 1c
SpriteCB_PokecenterMonitor 8648c 3e
SpriteCB_PokedexListMonSprite 8ee28 110 158
SpriteCB_PokemonIcon 9d62c a
SpriteCB_PostEvoSparkleSet1 14974c 48 64
SpriteCB_PostEvoSparkleSet2 1497fc d0 64
SpriteCB_PreEvoSparkleSet1 149558 ba 64
SpriteCB_PreEvoSparkleSet2 149670 72 64
SpriteCB_ResetRtcCusor0 6a484 11a
SpriteCB_ResetRtcCusor1 6a5a0 fe
SpriteCB_Rival 145420 be 47
SpriteCB_RotatingPokeBall 8f0b4 b4 158
SpriteCB_SandPillar_0 c6e64 80
SpriteCB_SandPillar_1 c6ee4 44
SpriteCB_SandPillar_2 c6f28 10
SpriteCB_ScrollArrow 8ef8c fe 158
SpriteCB_Scrollbar 8ef38 54 158
SpriteCB_SearchParameterScrollArrow 92fd8 b2 158
SpriteCB_SeenOwnInfo 8ed94 24 158
SpriteCB_ThrownPokeblock 1481b0 2a 157
SpriteCB_TrainerSlideIn 313a0 30
SpriteCB_UpdateHeldItemIconPosition 6dd80 24
SpriteCB_WaitForBattlerBallReleaseAnim 312f0 74
SpriteCB_WaterDropFall 13d484 80 114
SpriteCB_WaterDropFall_2 13d504 80 114
SpriteCB_sub_806D37C 6d380 38 150
SpriteCallbackDummy 1210 2
SpriteCallback_PokemonLogoShine 7bfe4 a8
SpriteCallback_PressStartCopyrightBanner 7bef4 38
SpriteCallback_RotatingGate c7c94 7e 174
SpriteCallback_VersionBannerLeft 7be04 90
SpriteCallback_VersionBannerRight 7be94 60
SpriteTileAllocBitmapOp 11a0 70
Sqrt 1e07b0 4
StandardWildEncounter 85104 18c
StartAnimLinearTranslation 78b38 28
StartApplauseOverflowAnimation b1a2c 40
StartAreaGlow 111084 8c 159
StartAshFieldEffect 127cc4 34
StartBackgroundFadeIn b6c0 40 128
StartBackgroundFadeOut b614 40 128
StartBardSong f7f80 30 131
StartCutGrassFieldEffect a2684 12 87
StartCutTreeFieldEffect a2b00 16 87
StartDoorAnimationTask 5853c 62 68
StartDoorCloseAnimation 58630 3e 68
StartDoorOpenAnimation 585f0 3e 68
StartEscapeRopeFieldEffect 878a8 1c
StartFieldEffectForObjectEvent 649f8 28
StartFishing 5a34c 34
StartFlashTimer 1df6d8 a8
StartHealthboxSlideIn 4777c 90
StartMassOutbreak be570 8c
StartMenu_BagCallback 7147c 2c 205
StartMenu_ExitCallback 71558 c 205
StartMenu_InputProcessCallback 7133c e0 205
StartMenu_OptionCallback 7151c 3c 205
StartMenu_PlayerCallback 714d4 2c 205
StartMenu_PlayerLinkCallback 71574 34 205
StartMenu_PokedexCallback 7141c 34 205
StartMenu_PokemonCallback 71450 2c 205
StartMenu_PokenavCallback 714a8 2c 205
StartMenu_RetireCallback 71564 10 205
StartMenu_SaveCallback 71500 1c 205
StartPageSwapAnim b65f0 20 141
StartPokemonLogoShine 7c08c 40 222
StartRunningAnim 60e04 2e
StartScriptMenuTask b5230 82 184
StartSecretBaseCaveFieldEffect c63e8 12 92
StartSecretBaseShrubFieldEffect c6658 12 92
StartSecretBaseTreeFieldEffect c64f4 12 92
StartSendOutAnim 1398bc 170 13
StartSpecialBattle 13556c fc
StartSpriteAffineAnim 2008 2c
StartSpriteAffineAnimIfDifferent 2034 34
StartSpriteAnim 1f58 18
StartSpriteAnimIfDifferent 1f70 1a
StartSpriteAnimInDirection 61efc 2c
StartSpriteFadeIn b534 74 128
StartSpriteFadeOut b458 70 128
StartStopFlashJudgeAttentionEye b09b0 32
StartStrengthAnim 59df4 3c 73
StartSweetScentFieldEffect 12c01c 68 95
StartTeachMonTMHMMove c9fc0 1c 117
StartTeleportFieldEffect 14a404 10 96
StartTheBattle 81adc 20 21
StartTileset1Animation 72f50 3c 220
StartTileset2Animation 72f8c 3c 220
StartTransfer 8cf4 10 120
StartTriggeredGroundEffects 6421c 44 63
StartVerticalScrollIndicators f98dc 38
StartWallClock 6a464 20
StartWeather 7c828 f4
StarterPokemonSpriteAnimCallback 10a6c4 40 206
Step1 64550 20 63
Step2 64570 24 63
Step3 64594 28 63
Step4 645bc 24 63
Step8 645e0 24 63
StopCry 753b4 14
StopCryAndClearCrySongs 7539c 18
StopFanfareByFanfareNum 74ea8 18
StopFlashTimer 1df780 44
StopMapMusic 74d0c 20
StopScript 653e8 8
StopTimer 8fcc 34 120
StopTryingToTeachMove_806F588 6f58c 8c
StopTryingToTeachMove_806F614 6f618 68
StopTryingToTeachMove_806F67C 6f680 38
StopTryingToTeachMove_806F6B4 6f6b8 104
StopVerticalScrollIndicators f98a4 38
StorageSystemClearMessageWindow 95ea0 12
StorageSystemCreatePrimaryMenu 96168 40
StorageSystemGetNextMonIndex 95dcc d2
StorageSystemGetPartySize 95c28 38
StoreInitialPlayerAvatarState 53a4c 5a
StoreNamingScreenParameters b5b10 6c 141
StorePlayerCoordsInVars 10e25c 1c
StorePokemonInDaycare 413c8 d4 52
StorePtrInTaskData b9a50 8
StoreSelectedPokemonInDaycare 4149c 24
StoreSpriteCallbackInData 78100 8
StoreWordInTwoHalfwords 40ef0 8
StorytellerDisplayStory f8700 58 131
StorytellerGetGameStat f8438 14 131
StorytellerGetRecordedTrainerStat f84c8 24 131
StorytellerInitializeRandomStat f8650 ae 131
StorytellerRecordNewStat f8598 64 131
StorytellerSetPlayerName f8560 38 131
StorytellerSetRecordedTrainerStat f84ec 1c 131
StorytellerSetup f83f8 30 131
StringAppend 6ad0 18
StringAppendN 6b18 1c
StringBraille 6ec4 5e
StringCompare 6b74 24
StringCompareN 6b98 2c
StringCompareWithoutExtCtrlCodes 4f84 4a
StringCopy 6ab0 1e
StringCopy10 6a24 32
StringCopy8 6a84 2c
StringCopyN 6ae8 2e
StringCopyPadded 701c 54
StringExpandPlaceholders 6e44 7e
StringFill 6ff0 2a
StringFillWithTerminator 7070 10
StringGetEnd10 6a58 2a
StringLength 6b34 3e
SummaryScreenExit 9e0fc 40 163
SummaryScreenHandleAButton 9ea50 78 163
SummaryScreenHandleKeyInput 9e19c c4 163
SummaryScreenHandleLeftRightInput 9f134 84 163
SummaryScreenHandleUpDownInput 9f1b8 cc
SummaryScreen_CanForgetSelectedMove 9f7d0 42 163
SummaryScreen_CopyColoredString a1e9c 5a 163
SummaryScreen_CreatePokemonSprite a1808 7e
SummaryScreen_DestroyTask 9e13c 60 163
SummaryScreen_DrawTypeIcon a198c a4 163
SummaryScreen_GetPokemon 9f678 3a 163
SummaryScreen_LoadPalettes 9e044 b8 163
SummaryScreen_LoadPokemonSprite 9f6b4 aa 163
SummaryScreen_MoveSelect_Cancel 9eac8 78 163
SummaryScreen_MoveSelect_HandleInput 9e3fc 10c 163
SummaryScreen_PlaceTextTile 9fa3c 38 163
SummaryScreen_PlaceTextTile_White 9fa74 20 163
SummaryScreen_PrintColoredIntPixelCoords a1f98 60 163
SummaryScreen_PrintColoredText a1ff8 44 163
SummaryScreen_PrintColoredTextCentered a1f48 50 163
SummaryScreen_PrintColoredTextPixelCoords a1ef8 50 163
SummaryScreen_PrintPokemonInfo 9fc34 238 163
SummaryScreen_PrintPokemonInfoLabels 9fc0c 28 163
SummaryScreen_PrintPokemonSkills 9ff64 12c 163
SummaryScreen_PrintPokemonSkillsLabels 9feb8 ac 163
SummaryScreen_SetTextColor a1e58 42 163
SummaryScreen_SpritePlayCry a1888 3c 163
SummaryScreen_SwapMoves_Box 9e6d8 118 163
SummaryScreen_SwapMoves_Party 9e5c4 114 163
SwapItemSlots a3bc4 a 116
SwapMoveDescAndContestTilemaps aeb30 1c
SwapMoveSlots f9fdc 100 186
SwapPokemon 6e6f4 2e
SwapRegisteredBike a9884 36
SwapTurnOrder 12fbc 34
SwapValues_s16 6cefc a
SweetScentWildEncounter 852fc e8
SwitchFlashBank 1df5b4 24
SwitchInClearSetData 10b88 3c0
SwitchTaskToFollowupFunc 7ac8c 34
TMMoveUpdateMoveSlot 6f540 4c
TVShowConvertInternationalString c08fc 1e
TVShowDone c1fdc 38
TV_CheckMonOTIDEqualsPlayerID bfb10 44
TV_CopyNicknameToStringVar1AndEnsureTerminated bfae0 30
TV_IsScriptShowKindAlreadyInQueue bf974 3e
TV_PutNameRaterShowOnTheAirIfNicnkameChanged bf9b4 44
TakeMailFromMon a2df8 60
TakeMailFromMon2 a2e78 b2
TakePokemonFromDaycare 41648 1c
TakeSelectedPokemonFromDaycare 41570 d8 52
TakeTVShowInSearchOfTrainersOffTheAir bdc80 1c
TaskDummy 7ac54 2
TaskDummy1 ab1ac 2
TaskFunc_UpdateWavePerFrame 89734 1c8 180
Task_8071B64 71b68 bc 205
Task_809527C 9527c 38 18
Task_80952B4 952b4 30 18
Task_80952E4 952e4 4c 18
Task_8095330 95330 2c 18
Task_809535C 9535c 30 18
Task_809538C 9538c 7a 18
Task_80954C0 954c0 1c 18
Task_80A244C a244c 42 185
Task_80B64D4 b64d4 78 141
Task_AnimateAudience b1dfc ac
Task_AnimateDoor 584cc 38 68
Task_AppealSetup ac284 48
Task_ApplauseOverflowAnimation b1a6c a8
Task_AreaScreenProcessInput 8f9c8 38 158
Task_BardSong f8184 24c 131
Task_BattlePartyMenuCancel 958c4 40 18
Task_BattlePartyMenuShift 95584 340 18
Task_BattlePartyMenuSummary 95544 40 18
Task_BattleStart 81960 64 21
Task_BattleTransitionMain 11ab50 38 23
Task_BeginEvolutionScene 1118a4 80 65
Task_BikeScene 144664 2ce
Task_BlendAudienceBackground b1f4c 84
Task_BrailleWait 1476b0 c4
Task_BumpBoulder 59e30 58 73
Task_BuyHowManyDialogueHandleInput a6670 f0 116
Task_CallItemUseOnFieldCallback a5cdc 28 116
Task_CallYesOrNoCallback f90f4 58 133
Task_CancelItemPurchase b3d7c 4c 193
Task_ChooseNewMonForSoftboiled 133e74 44 93
Task_ClearSaveData 148930 24 38
Task_ClosePageScreen 8f8b8 20 158
Task_ClosePokedex 8cc50 74 158
Task_CommunicateFinalStandings adf4c 4c
Task_CommunicateMonIdxs ab678 1c
Task_ConfirmGiveHeldItem 6ebbc 38
Task_ConfirmLoseMailMessage 6ef04 38
Task_ConfirmTakeHeldMail 6eff0 38
Task_ContestReturnToField adfd8 38
Task_CreditsMain 143b68 94 47
Task_CreditsSoftReset 144114 1c 47
Task_CreditsTheEnd1 143ebc 48 47
Task_CreditsTheEnd2 143f04 38 47
Task_CreditsTheEnd3 143f3c a0 47
Task_CreditsTheEnd4 143fdc 48 47
Task_CreditsTheEnd5 144024 5c 47
Task_CreditsTheEnd6 144080 94 47
Task_CryScreenProcessInput 8fdf8 1c4 158
Task_CycleSceneryPalette 144934 134
Task_DaycareStorageMenu8122EAC 122eac c4 37
Task_DecorationPCProcessMenuInput fe2ec a6
Task_DestroySelf 7080 e
Task_DestroyTrainerApproachTask 847d8 12 225
Task_DiplomaFadeIn 145f14 30 54
Task_DiplomaFadeOut 145f8c 2c 54
Task_DiplomaWaitForKeyPress 145f44 48 54
Task_DisplayAppealNumberText abb70 cc
Task_Dive 870ec 38 69
Task_DoAppeals ac2cc 160e
Task_DoBuySellMenu b2e38 c2 193
Task_DoItemPurchase b3bf4 144 193
Task_DoNothing b5be4 2 141
Task_DrawDriverTestMenu ba800 248
Task_DropCurtainAtAppealsEnd adeac 40
Task_DropCurtainAtRoundEnd adcb4 28
Task_DuckBGMForPokemonCry 7540c 48 201
Task_EggHatch 42cac 3c 59
Task_EggHatchPlayBGM 42fb8 54 59
Task_EndAppeals adda4 b0
Task_EndCommunicateFinalStandings adf98 40
Task_EndCommunicateMonIdxs ab694 20
Task_EndCommunicateMoveSelections ac15c 2c
Task_EndWaitForLink ad8dc 20
Task_EvolutionScene 11240c bdc 65
Task_ExitBuyMenu b43f0 48 193
Task_ExitBuyMenuDoFade b4438 38 193
Task_ExitSearch 927b8 38 158
Task_ExitSearchWaitForFade 927f0 20 158
Task_FadeToBg 76ce8 d4 6
Task_Fanfare 74f1c 30 201
Task_FieldMessageBox 64aa4 98 72
Task_FieldPoisonEffect c7008 6c 90
Task_FinishRoundOfAppeals ad960 bc
Task_Fishing 5a380 38 73
Task_HallOfFameRecord 85f10 30
Task_HandleCopyReceivedLinkBuffersData c47c 19c 14
Task_HandleGetDecorationMenuInput 109b7c c8
Task_HandleInput b623c 30 141
Task_HandleItemUseMoveMenuInput 70378 7c
Task_HandleMoveSelectInput abea0 20c
Task_HandleMultichoiceGridInput b5684 80 184
Task_HandleMultichoiceInput b52b4 a8 184
Task_HandlePageSwapAnim b6630 38 141
Task_HandlePopupMenuInput 95408 b6 18
Task_HandlePorthole c77a0 100
Task_HandleSearchMenuInput 921b0 24c 158
Task_HandleSearchParameterInput 92644 174 158
Task_HandleSearchTopBarInput 9207c 100 158
Task_HandleSendLinkBuffersData c1a8 1b2 14
Task_HandleShopMenuBuy b2efc 34 193
Task_HandleShopMenuQuit b2f64 3c 193
Task_HandleShopMenuSell b2f30 34 193
Task_HandleTruckSequence c752c 172
Task_HandleYesNoInput b54e4 94 184
Task_HideApplauseMeterForAppealStart ac204 4c
Task_HideMoveSelectScreen ac188 7c
Task_Hof_InitTeamSaveData 14217c f8 107
Task_InitAreaScreenMultistep 8f8d8 f0 158
Task_InitCryScreenMultistep 8fa64 394 158
Task_InitCryTest bb25c 158
Task_InitMenu 148830 8c 38
Task_InitPageScreenMultistep 8f2b0 41c 158
Task_InitSizeScreenMultistep 90070 360 158
Task_InitSoundCheckMenu ba258 12c
Task_IntroFadeIn 13bc8c 64 114
Task_IntroHandleBikeAndEonMovement 13c080 174 114
Task_IntroLoadPart1Graphics 13ba94 1f8
Task_IntroLoadPart2Graphics 13bf20 50 114
Task_IntroLoadPart3Graphics 13c230 bc 114
Task_IntroLoadPart3Streaks 13c3b0 19c 114
Task_IntroPokemonBattle 13c668 474 114
Task_IntroScrollDownAndShowEon 13bdec 100 114
Task_IntroSpinAndZoomPokeball 13c2ec 98 114
Task_IntroStartBikeRide 13bf70 110 114
Task_IntroWaitToSetupPart2 13beec 34 114
Task_IntroWaitToSetupPart3 13c1f4 3c 114
Task_IntroWaitToSetupPart3DoubleFight 13c384 2c 114
Task_IntroWaterDrops 13bcf0 fc 114
Task_ItemStorage_Deposit 13a078 28 153
Task_LinkContest_CalculateTurnOrder c4b0c 28
Task_LinkContest_CommunicateAppealsState c8c80 19c
Task_LinkContest_CommunicateCategory c8938 a4
Task_LinkContest_CommunicateFinalStandings c8ad0 1b0
Task_LinkContest_CommunicateLeaderIds c8e1c a0
Task_LinkContest_CommunicateMonIdxs c89dc 5a
Task_LinkContest_CommunicateRng c88ac 8c
Task_LinkContest_CommunicateRound1Points c8ebc 78
Task_LinkContest_CommunicateTurnOrder c8f34 78
Task_LinkContest_Disconnect c4ba4 28
Task_LinkContest_FinalizeConnection c4b5c 48
Task_LinkContest_Init c8604 40
Task_LinkContest_SetUpContest c4a44 c8
Task_LinkContest_WaitDisconnect c4bcc 24
Task_LoadInfoScreenWaitForFade 8f888 30 158
Task_LoadSearchMenu 91e54 1f8 158
Task_LoadShowMons 143d04 1b8 47
Task_LoopAndPlaySE 77500 5c 6
Task_LoseMailMessage 6ee60 a4
Task_LotteryCornerComputerEffect 10e67c 28 76
Task_MainMenuCheckRtc 9a64 c8 128
Task_MainMenuCheckSave 9878 1a4 128
Task_MainMenuDraw 9b74 1cc 128
Task_MainMenuHighlight 9d40 2c 128
Task_MainMenuPressedA 9eb0 100 128
Task_MainMenuPressedB 9fb0 2c 128
Task_MainMenuProcessKeyInput 9e80 30 128
Task_MainMenuWaitForRtcErrorAck 9b2c 48 128
Task_MainMenuWaitForSaveErrorAck 9a1c 48 128
Task_MapNamePopup a2ff4 b0 129
Task_MuddySlope 6a1ec 140
Task_NamingScreenMain b5e70 38 141
Task_NewGameSpeech1 a1f4 ec 128
Task_NewGameSpeech10 a5ac 78 128
Task_NewGameSpeech11 a624 44 128
Task_NewGameSpeech12 a668 b0 128
Task_NewGameSpeech13 a718 44 128
Task_NewGameSpeech14 a75c 40 128
Task_NewGameSpeech15 a79c 38 128
Task_NewGameSpeech16 a7d4 a0 128
Task_NewGameSpeech17 a874 a8 128
Task_NewGameSpeech18 a91c 58 128
Task_NewGameSpeech19 a974 40 128
Task_NewGameSpeech2 a2e0 78 128
Task_NewGameSpeech20 a9b4 38 128
Task_NewGameSpeech21 a9ec c0 128
Task_NewGameSpeech22 aaac 40 128
Task_NewGameSpeech23 aaec 4c 128
Task_NewGameSpeech24 ab38 38 128
Task_NewGameSpeech25 ab70 b0 128
Task_NewGameSpeech26 ac20 38 128
Task_NewGameSpeech27 ac58 f0 128
Task_NewGameSpeech28 ad48 ac 128
Task_NewGameSpeech29 adf4 e0 128
Task_NewGameSpeech3 a358 70 128
Task_NewGameSpeech30 aed4 b0 128
Task_NewGameSpeech31 af84 3c 128
Task_NewGameSpeech32 afc0 74 128
Task_NewGameSpeech33 b034 2c 128
Task_NewGameSpeech4 a3c8 4c 128
Task_NewGameSpeech5 a414 30 128
Task_NewGameSpeech6 a444 74 128
Task_NewGameSpeech7 a4b8 70 128
Task_NewGameSpeech8 a528 3c 128
Task_NewGameSpeech9 a564 48 128
Task_OpenInfoScreenAfterMonMovement 8ca64 80 158
Task_OpenSearchResults 8ccc4 48 158
Task_OpenSearchResultsInfoScreenAfterMonMovement 8d118 80 158
Task_OptionMenuFadeIn 8b9c4 30 145
Task_OptionMenuFadeOut 8bc10 2c 145
Task_OptionMenuProcessInput 8b9f4 18c 145
Task_OptionMenuSave 8bb80 90 145
Task_PCTurnOnEffect 10e468 28 76
Task_PageScreenProcessInput 8f6cc 1bc 158
Task_PaletteFadeToReturn 147f4c 38 157
Task_PanFromInitialToTarget 77294 90 6
Task_PartyMenuPrintRun 6e888 4c 150
Task_PlayerController_RestoreBgmAfterCry 2d86c 30
Task_PokecenterHeal 85dc4 30
Task_PokedexAreaScreen_0 1113ec 170 159
Task_PokedexAreaScreen_1 11155c fc 159
Task_PokedexMainScreen 8c650 248 158
Task_PokedexMainScreenMenu 8c8e8 17c 158
Task_PokedexResultsScreen 8cd0c 1ec 158
Task_PokedexResultsScreenExitPokedex 8d2ac 98 158
Task_PokedexResultsScreenMenu 8cf48 1d0 158
Task_PokedexResultsScreenReturnToMainScreen 8d214 98 158
Task_PokedexShowMainScreen 8c608 48 158
Task_PokemonPicWindow b5850 74 184
Task_PokemonStorageSystem 95eb4 24c
Task_PrintAtePokeblockText 147e40 c8 157
Task_PrintRoundResultText adb88 88
Task_PrintTestData 8058 12c 120
Task_ProcessCryTestInput bb3b4 e0
Task_ProcessDriverTestInput baa48 294
Task_ProcessMenuInput 1488bc 74 38
Task_ProcessSoundCheckMenuInput ba400 25c
Task_RaiseCurtainAtStart ab9a0 10c
Task_RareCandy1 707a4 60
Task_RareCandy2 70804 48
Task_RareCandy3 70acc 18c
Task_ReUpdateHeartSliders adc4c 38
Task_ReadyBikeScene 143bfc 44 47
Task_ReadyShowMons 143cc0 44 47
Task_ReadyStartLinkContest ab6b4 58
Task_ReadyUpdateHeartSliders ada1c 30
Task_RecordMixing_CopyReceiveBuffer b9890 124
Task_RecordMixing_Main b9484 16c
Task_RecordMixing_ReceivePacket b99e8 34
Task_RecordMixing_SendPacket b97dc b4
Task_RecordMixing_SendPacket_SwitchToReceive b9a1c 28
Task_RecordMixing_SoundEffect b9450 34
Task_ResetForNextRound b2400 108
Task_ResetRtcScreen 6acd0 210
Task_ResetRtc_0 6aa68 74
Task_ResetRtc_1 6a95c 10c
Task_ResetRtc_2 6a930 2c
Task_ResetRtc_3 6a918 18
Task_ReturnAfterPaletteFade 147f08 44 157
Task_ReturnToBuyMenu b4378 78 193
Task_ReturnToMartMenu b2ffc 54 193
Task_Roulette_0 1176a8 154
Task_RunPerStepCallback 69440 2c
Task_RunTimeBasedEvents 694bc 34
Task_SaveDialog 716c0 44 205
Task_SearchCompleteWaitForInput 92508 ac 158
Task_SecretBaseMusicNoteMatSound c6aac 184 88
Task_SecretBasePCTurnOn c6760 da 91
Task_SecretBasePC_Decoration fe264 28
Task_SecretBasePC_Registry bc62c 84 187
Task_SelectSearchMenuItem 925cc 78 158
Task_SelectedMove ac0c8 94
Task_SetBikeScene 143c40 80 47
Task_SetClock1 10ab54 30 236
Task_SetClock2 10ab84 dc 236
Task_SetClock3 10ac60 74 236
Task_SetClock4 10acd4 84 236
Task_SetClock5 10ad58 44 236
Task_SetClock6 10ad9c 24 236
Task_ShowAndUpdateApplauseMeter b1cfc 88
Task_ShowMons 144514 150 47
Task_ShowMoveSelectScreen abcdc 1c4
Task_ShowResetRtcPrompt 6abf8 d8
Task_ShowSummaryScreen 954dc 68 18
Task_SizeScreenProcessInput 903d0 c8 158
Task_SlideApplauseMeterIn b1b68 74
Task_SlideApplauseMeterOut b1c34 88
Task_SlideOpenPetalburgGymDoors 10e09c 66 76
Task_SpriteFadeIn b4c8 6c 128
Task_SpriteFadeOut b3ec 6c 128
Task_StartCommunicateCategory c4a28 1c
Task_StartCommunicateLeaderIds c4a0c 1c
Task_StartCommunicateRng c49f0 1c
Task_StartCommunication c49c4 2c
Task_StartContestWaitFade ab5d4 30
Task_StartDropCurtainAtRoundEnd b237c 40
Task_StartMenu 71258 30 205
Task_StartNewRoundOfAppeals add74 30
Task_StartPokedexSearch 923fc a8 158
Task_StartRaiseCurtainAtRoundEnd b25a4 40
Task_StartSendOutAnim 139a2c 74 13
Task_StarterChoose1 10a134 44 206
Task_StarterChoose2 10a178 110 206
Task_StarterChoose3 10a288 50 206
Task_StarterChoose4 10a2d8 58 206
Task_StarterChoose5 10a330 c4 206
Task_StarterChoose6 10a3f4 1c 206
Task_StoryListMenu f87c4 b0 131
Task_SwitchScreensFromCryScreen 8ffbc 84 158
Task_SwitchScreensFromSizeScreen 90498 64 158
Task_SwitchToSearchMenu 9217c 34 158
Task_SwitchToSearchMenuTopBar 9204c 30 158
Task_TakeHeldMail 6ef3c b4
Task_TeamMonTMMove 6f0b8 11c
Task_TeamMonTMMove2 6f1d4 84
Task_TeamMonTMMove3 6f258 38
Task_TeamMonTMMove4 6f290 70
Task_TitleScreenPhase1 7c470 114 222
Task_TitleScreenPhase2 7c584 c4 222
Task_TitleScreenPhase3 7c648 130 222
Task_TradeEvolutionScene 112fe8 b68 65
Task_TriggerHandshake 7340 38 120
Task_Truck1 c72c4 b0
Task_Truck2 c7374 110
Task_Truck3 c7484 a8
Task_TryCommunicateFinalStandings adeec 60
Task_TryShowMoveSelectScreen abc70 6c
Task_TryStartLinkContest ab604 74
Task_TryStartNextRoundOfAppeals add04 70
Task_UnusedBlend b05fc e4
Task_UnusedBrokenBlend b0748 24c
Task_UpdateAppealHearts afc74 1bc
Task_UpdateContestantBoxOrder adcdc 28
Task_UpdateCurtainDropAtRoundEnd b23bc 44
Task_UpdateHeartSliders ada4c 8c
Task_UpdatePage 1441b8 29a 47
Task_UpdatePurchaseHistory b4470 c4 193
Task_UpdateRaiseCurtainAtRoundEnd b2508 34
Task_ViewClock1 10adc0 30 236
Task_ViewClock2 10adf0 38 236
Task_ViewClock3 10ae28 38 236
Task_ViewClock4 10ae60 24 236
Task_WaitAndCompleteSearch 924a4 64 158
Task_WaitAndPlaySE 775d0 44 6
Task_WaitBeforePrintRoundResult adb48 40
Task_WaitForAtePokeblockText 147e10 30 157
Task_WaitForExitInfoScreen 8cae4 a8 158
Task_WaitForExitSearch 8cb8c c4 158
Task_WaitForExitSearchResultsInfoScreen 8d198 7c 158
Task_WaitForHeartSliders adad8 2c
Task_WaitForHeartSlidersAgain adc84 30
Task_WaitForOutOfTimeMsg ade54 58
Task_WaitForPaletteFade 10d684 20 110
Task_WaitForScroll 8c898 50 158
Task_WaitForSearchResultsScroll 8cef8 50 158
Task_WaitForSliderHeartAnim b26c8 98
Task_WaitHideApplauseMeterForAppealStart ac250 34
Task_WaitPaletteFade 143b38 30 47
Task_WaitPrintRoundResultText adc10 3c
Task_WaitRaiseCurtainAtRoundEnd b253c 66
Task_WaitToRaiseCurtainAtStart ab960 40
Task_WaitWeather 10d3c8 20 221
Task_WateringBerryTreeAnim_0 c70a0 1c 86
Task_WateringBerryTreeAnim_1 c70bc 74 86
Task_WateringBerryTreeAnim_2 c7130 70 86
Task_WateringBerryTreeAnim_3 c71a0 24 86
Task_WeatherInit 7c9e4 50
Task_WeatherMain 7ca34 b4
Task_WhiteOut c5770 b4 74
Task_unused_80AF94C af94c 110
TaughtMove 6f494 ac
TeachMonMoveInPartyMenu 70c58 13c
TeachMonTMMove 6f070 48
TeleportFieldEffectTask1 87bec 26 69
TeleportFieldEffectTask2 87c14 90 69
TeleportFieldEffectTask3 87ca4 d4 69
TeleportFieldEffectTask4 87d78 54 69
TestBlockTransfer 7428 e8 120
TestPlayerAvatarFlags 597c4 10
TextSpeed_DrawChoices 8bcf8 54 145
TextSpeed_ProcessInput 8bcb4 44 145
TextWindow_DisplayDialogueFrame 65204 14
TextWindow_DrawDialogueFrame 65334 18
TextWindow_DrawStdFrame 64f9c 3c
TextWindow_EraseDialogueFrame 65370 28
TextWindow_GetFrameGraphics 64fd8 24
TextWindow_LoadDialogueFrameTiles 6534c 24
TextWindow_LoadStdFrameGraphics 64f0c 30
TextWindow_LoadStdFrameGraphicsOverridePal 64f3c 34
TextWindow_LoadStdFrameGraphicsOverrideStyle 64f70 2c
TextWindow_SetBaseTileNum 64ef8 14
TextWindow_SetDlgFrameBaseTileNum 651cc 14
Text_BlankWindowRect 482c 50
Text_ClearWindow 4318 54
Text_EraseWindowRect 47fc 30
Text_FillWindowBorder 4690 94
Text_FillWindowRect 4758 6e
Text_FillWindowRectDefPalette 47c8 34
Text_GetStringWidthFromWindowTemplate 4e6c 30
Text_GetTextColors 4e28 14
Text_GetWindowPaletteNum 4e24 4
Text_GetWindowTilemapEntry 467c 14
Text_InitWindow 2dc0 8c
Text_InitWindow8002E4C 2e4c 44
Text_InitWindow8004D04 4d04 32
Text_InitWindow8004E3C 4e3c 30
Text_InitWindowAndPrintText 3460 2e
Text_InitWindowWithTemplate 2d54 6c
Text_InitWindow_Centered 4db0 74
Text_InitWindow_RightAligned 4d38 78
Text_LoadWindowTemplate 2a34 1a
Text_PrintWindow8002F44 2f44 5c
Text_PrintWindowSimple 3418 48
Text_SetWindowText 2e90 1e
Text_StripExtCtrlCodes 4f04 5c
Text_UpdateWindow 35ac 18
Text_UpdateWindowAutoscroll 3778 28
Text_UpdateWindowInBattle 374c 2c
Text_UpdateWindowOverrideLineLength 37c8 28
TilesetCB_BikeShop 733fc 2c
TilesetCB_Building 72ff0 28
TilesetCB_Cave 73380 2c
TilesetCB_Dewford 73168 28
TilesetCB_EliteFour 733ac 24
TilesetCB_EverGrande 732b4 2c
TilesetCB_Fallarbor 73214 28
TilesetCB_Fortree 7323c 28
TilesetCB_General 72fc8 28
TilesetCB_Lavaridge 731e8 2c
TilesetCB_Lilycove 73264 28
TilesetCB_Mauville 731b8 30
TilesetCB_MauvilleGym 733d0 2c
TilesetCB_Mossdeep 7328c 28
TilesetCB_Pacifidlog 732e0 30
TilesetCB_Petalburg 73114 28
TilesetCB_Rustboro 7313c 2c
TilesetCB_Slateport 73190 28
TilesetCB_Sootopolis 73310 28
TilesetCB_SootopolisGym 7335c 24
TilesetCB_Underwater 73338 24
Timer3Intr 8c5c e
TimerBallOpenParticleAnimation 140a64 d8
TintPlttBuffer 74384 d4
ToggleCurSecretBaseRegistry bc5bc 48
TrackStop 1dda1c 44
TradeEvolutionScene 1120e4 18c
TradeMenuMoveCursor 49560 c0 223
Trade_Memcpy 48d24 20 223
TraderSetup 1099cc 54
TrainerBattleLoadArg16 82254 c 21
TrainerBattleLoadArg32 8223c 18 21
TrainerBattleLoadArg8 82260 4 21
TrainerBattleLoadArgs 8230c 86 21
TrainerCanApproachPlayer 84058 b0 225
TrainerCard_Back_PrintBattleTower 94448 50 224
TrainerCard_Back_PrintBattleTower_Label 94428 20 224
TrainerCard_Back_PrintHallOfFameTime 94354 70 224
TrainerCard_Back_PrintHallOfFameTime_Label 94334 20 224
TrainerCard_Back_PrintLinkBattles 943e4 44 224
TrainerCard_Back_PrintLinkBattlesLabel 943c4 20 224
TrainerCard_Back_PrintLinkContests 944b8 30 224
TrainerCard_Back_PrintLinkContests_Label 94498 20 224
TrainerCard_Back_PrintLinkPokeblocks 94508 30 224
TrainerCard_Back_PrintLinkPokeblocks_Label 944e8 20 224
TrainerCard_Back_PrintName 942f8 3c 224
TrainerCard_Back_PrintPokemonTrades 94558 30 224
TrainerCard_Back_PrintPokemonTrades_Label 94538 20 224
TrainerCard_Back_PrintTexts 94188 50 224
TrainerCard_ClearPokedexLabel 94110 30 224
TrainerCard_ClearTrainerGraphics 940e4 2c 224
TrainerCard_CopyGraphics 93e28 78 224
TrainerCard_CreateFlipAnimationTask 93a28 20 224
TrainerCard_CreatePrintPlayTimeTask 939a4 1c 224
TrainerCard_CreateStateMachine 9380c 20 224
TrainerCard_DestoryPlayTimeTask 939c0 1c 224
TrainerCard_DisplayBadges 94038 ac 224
TrainerCard_DrawCard 93dac 1c 224
TrainerCard_DrawCardBack 93dec 16 224
TrainerCard_DrawCardFront 93dc8 22 224
TrainerCard_DrawStars 93fd0 68 224
TrainerCard_FadeOut 93954 2c
TrainerCard_FillFlags 936d4 d0 224
TrainerCard_FillTrainerCardStruct 93324 66
TrainerCard_FinishFlipAnimation 93d50 2c
TrainerCard_FlipAnimationHBlankCallback 93d7c 30 224
TrainerCard_Front_GetPlayTimeString 94250 4c 224
TrainerCard_Front_PrintMoney 94200 18 224
TrainerCard_Front_PrintPlayTime 939dc 4c 224
TrainerCard_Front_PrintPokedexCount 94218 38 224
TrainerCard_Front_PrintTexts 94140 48 224
TrainerCard_Front_PrintTrainerID 941d8 28 224
TrainerCard_GenerateCardForPlayer 93390 134
TrainerCard_GetStarCount 934f4 3e 224
TrainerCard_HasFlipAnimationFinished 93a48 1e 224
TrainerCard_Init 93864 44
TrainerCard_InitFlipAnimation 93aa0 50
TrainerCard_InitScreenForLinkPlayer 932e4 40 224
TrainerCard_InitScreenForPlayer 932ac 38 224
TrainerCard_LoadCardTileMap 93f14 34 224
TrainerCard_LoadPalettes 93ea0 58 224
TrainerCard_LoadTrainerGraphics 93ef8 1c 224
TrainerCard_LoadTrainerTilemap 93f80 50 224
TrainerCard_PrintEasyChatPhrase 9429c 5c 224
TrainerCard_ResetOffsetRegisters 93e04 24 224
TrainerCard_RunFlipAnimationStateMachine 93a68 38 224
TrainerCard_RunStateMachine 9382c 38 224
TrainerCard_ScaleDownFlipAnimation 93af0 11c
TrainerCard_ScaleUpFlipAnimation 93c38 118
TrainerCard_ShowLinkCard 93130 44
TrainerCard_ShowPlayerCard 93110 20
TrainerCard_StartFlipAntimation 93918 20
TrainerCard_SwitchToNewSide 93c0c 2c
TrainerCard_WaitForFadeInToFinish 938a8 24
TrainerCard_WaitForFadeOutToFinishAndQuit 93980 24
TrainerCard_WaitForFlipToFinish 93938 1c
TrainerCard_WaitForKeys 938cc 4c
TrainerIdToRematchTableId 828b8 42
TrainerWantsBattle 824c0 44
TransferPlttBuffer 73ae4 5c
TransitionToPokeblockFeedScene 1478bc 21e 157
Transition_BigPokeball_Vblank 11b4a8 78 23
Transition_Phase1 11ab88 50 23
Transition_Phase2 11ac0c 28 23
Transition_WaitForPhase1 11abd8 32 23
Transition_WaitForPhase2 11ac34 30 23
TranslateAnimArc 7871c 34
TranslateAnimLinear 78b60 5a
TranslateAnimLinearUntil 78bbc 1a
TranslateAnimSpriteToTargetMonLocation 79420 8c
TranslateBigMonSizeTableIndex c5964 30 161
TranslateMonBGSubPixelUntil 784ac 5c
TranslateMonBGUntil 7845c 50
TranslateSpriteOverDuration 78368 2e
TranslateWeatherNum 80764 ce 79
TreeEntranceSpriteCallback1 c6598 2c 92
TreeEntranceSpriteCallback2 c65c4 38 92
TreeEntranceSpriteCallbackEnd c65fc 10 92
TriggerPendingDaycareEgg 41940 10
TriggerPendingDaycareMaleEgg 41950 10
TrkVolPitSet 1de7d8 b4
TryClearRageStatuses 176c8 50
TryCorrectShedinjaLanguage ec44 58
TryCreatePartyMenuMonIcon 6d910 58
TryDoInfoScreenScroll 8e71c 110 158
TryDoMetatileBehaviorForcedMovement 58924 24 73
TryDoPokedexScroll 8e48c 230 158
TryEnableBravoTrainerBattleTower 13610c 24
TryEnableObjectEventAnim 634a4 2e 63
TryEraseDownArrow 4658 22 214
TryEvolvePokemon 13df8 90
TryFadeOutOldMapMusic 53ffc 3c
TryGetObjectEventIdByLocalIdAndMap 5abac 2a
TryGetStatusString 120f98 62
TryGetTrainerEncounterDirection 5cd64 88
TryHandleLaunchBattleTableAnimation 314c8 120
TryIncrementMonLevel 40300 74
TryInitBattleTowerAwardManObjectEvent 10f8fc c
TryInitLocalObjectEvent 5ade0 74
TryOverrideTemplateCoordsForObjectEvent 5c790 38
TryPrintPartyMenuMonNickname 6e080 46 150
TryPutPlayerLast ae054 20
TryRunCoordEventScript 68d80 3e 67
TryRunFromBattle 14ab8 13c
TryRunOnFrameMapScript 65734 1a
TryRunOnWarpIntoMapScript 65750 14
TrySetBehindSubstituteSpriteBit 324bc 24
TrySetCantSelectMoveBattleScript 15894 204
TrySetDestinyBondToHappen 28588 60 20
TrySetDiveWarp 68f1c 96
TrySetupDiveDownScript 68774 32 67
TrySetupDiveEmergeScript 687a8 3e 67
TrySetupObjectEventSprite 5afd0 19c 63
TryShinyAnimation 141828 f4
TrySpawnObjectEvent 5b16c c8 63
TrySpawnObjectEvents 5b560 d8
TryStartCoordEventScript 68840 34 67
TryStartCrackedFloorHoleScript 68874 24 67
TryStartInteractionScript 681f4 60 67
TryStartRoamerEncounter 1344cc 36
TryStartStepBasedScript 687e8 58 67
TryStartStepCountScript 68898 64 67
TryStartWarpEventScript 68a68 cc 67
TrySweetScentEncounter 12c084 94 95
TryToWaterBerryTree b4a6c 22
TryUpdateRandomTrainerRematches 82bd0 3c
TryUpdateRusturfTunnelState 10f5bc 5a
TryWriteSector 125440 2c 177
TurnBasedEffects 16558 b84
TurnObjectEvent 64994 64
TurnOffTVScreen bd9f0 1c
TurnValuesCleanUp 1365c 120 17
TypeCalc 1d280 1dc
UltraBallOpenParticleAnimation 140ce8 dc
UndoEffectsAfterFainting 10f48 378
UnfadePlttBuffer 74458 5c
UnfreezeObjectEvent 644b8 68
UnfreezeObjectEvents 64520 30
UnfreezeObjects a2408 44 185
UnlockPlayerFieldControls 65540 c
UnlockTrendySaying eb890 30
UnpackSelectedBattleAnimPalettes e1dc4 48 143
Unref_ClearHappinessStepCounter 688fc 14
Unref_GetAnimNums_08375633 5fdac 10
Unref_MetatileBehavior_IsArrowWarp 56fbc 42
Unref_MetatileBehavior_IsSecretBaseUnused_B2 57264 14
Unref_MetatileBehavior_IsSecretBaseUnused_B2_2 572c8 14
Unref_MetatileBehavior_IsUnused04 56ee4 14
Unref_MetatileBehavior_IsUnused05 57068 14
Unref_MetatileBehavior_IsUnusedSootopolisWater 57588 18
Unref_MovePixelCoords 602fc 28
UnusedDummyFunc 1ddd88 2
UnusedPokedexAreaScreen 110664 1c
UnusedPrintDecimalNum 913a4 b2
UnusedPrintMonName 91304 a0 158
Unused_ApplyRandomDmgMultiplier 1d574 3c
Unused_EndBlinkingState b0cdc 18
Unused_LZDecompressWramIndirect d420 c
UpdateAllBagPockets a3d08 1a 116
UpdateAmbientCry 540d4 94
UpdateAppealHearts afba0 d4
UpdateApplauseMeter b1928 a8
UpdateAshFieldEffect 127d84 1c
UpdateAshFieldEffect_Step0 127da0 2e 70
UpdateAshFieldEffect_Step1 127dd0 60 70
UpdateAshFieldEffect_Step2 127e30 26 70
UpdateBGRegs 29ac 3c 214
UpdateBagPocket a3ca8 60 116
UpdateBattlerSpritePriorities 79e28 6c
UpdateBirchState 10d410 2c
UpdateBlendRegisters 74a8c 50 149
UpdateBlendTaskContestantData b05a4 54
UpdateBlendTaskContestantsData b0588 1a
UpdateBubblesFieldEffect 128410 40
UpdateCameraPanning 58290 4c
UpdateClockPeriod 10af98 46 236
UpdateCoinsWindow 11a704 28
UpdateConditionStars aee54 fc
UpdateContestantBoxOrder b2280 fc
UpdateCryWaveformWindow 119f88 c8
UpdateCyclingRoadState 10d934 4c
UpdateDewfordTrendPerDay fa220 144
UpdateDexListScroll 8e208 190 158
UpdateDisguiseFieldEffect 1285ac f0
UpdateDownArrowAnimation 4620 38 214
UpdateFastPaletteFade 7455c 378 149
UpdateFeetInFlowingWaterFieldEffect 1278d8 a0 70
UpdateFireRingCircleOffset d5348 2c 84
UpdateFlashLevelEffect 81424 c4 75
UpdateFootprintsTireTracksFieldEffect 127584 1c
UpdateFuryCutterAnimCount d30d0 20
UpdateFuryCutterAnimDirection d30ac 24
UpdateHappinessStep 68910 3c 67
UpdateHardwarePaletteFade 74970 11c 149
UpdateHealthboxAttribute 45a5c 21a
UpdateHeartSliders aff10 18
UpdateHotSpringsWaterFieldEffect 127a7c 98
UpdateHpTextInHealthbox 440ec 124
UpdateIconBlink fbf40 54 167
UpdateJumpLandingFieldEffect 1287c4 3a
UpdateLegendaryMarkingColor 7c7e8 3e 222
UpdateLinkAndCallCallbacks 340 48 127
UpdateLinkBattleGameStats 11011c 3c 19
UpdateLinkBattleRecord 1100b8 64 19
UpdateLinkBattleRecords 110290 58
UpdateLinkBattleRecords_ 110158 92 19
UpdateLocationHistoryForRoamer 134320 28
UpdateLongGrassFieldEffect 127128 f8
UpdateMassOutbreakTimeLeft be954 28
UpdateMirageRnd 10d2f4 38
UpdateMonIconFrame 9d638 d6
UpdateMonIconFrame_806DA0C 6da10 2c 150
UpdateMonIconFrame_806DA38 6da3c a 150
UpdateMonIconFrame_806DA44 6da48 54 150
UpdateMoneyWindow b7bec 28
UpdateMoveTutorMenuCursorPosition 133300 56 137
UpdateMovedLilycoveFanClubMembers 10fce8 76
UpdateNormalPaletteFade 741fc 140 149
UpdateOamCoords 82c c2 204
UpdateOamPriorityInAllHealthboxes 43eb4 90
UpdateObjEventSpriteVisibility 635cc 26 63
UpdateObjectEventCoordsForCameraUpdate 5c164 68
UpdateObjectEventCurrentMovement 60654 6e
UpdateObjectEventIsOffscreen 634ec de 63
UpdateObjectEventSpriteAnimPause 63488 1a 63
UpdateObjectEventSpriteSubpriorityAndVisibility 64974 20 63
UpdateObjectEventSpriteVisibility 64880 f4
UpdateObjectEventVisibility 634d4 18 63
UpdateObjectEventZCoordAndPriority 63cbc 5c
UpdateObjectEventsForCameraUpdate 5c25c 2c
UpdateObjectReflectionSprite 1269e0 174 70
UpdatePaletteFade 73b40 58
UpdatePartyPokerusTime 401d8 78
UpdatePerDay 6a394 64 39
UpdatePerMinute 6a3f8 58 39
UpdatePoisonStepCounter 68960 46 67
UpdateRainCounter 80854 1e 79
UpdateRandomTrainerEyeRematches 828fc ac
UpdateRegionMapVideoRegs fb260 44
UpdateRepelCounter 85558 40
UpdateRoamerHPStatus 134504 28
UpdateSandPileFieldEffect 1282e0 cc
UpdateSelectedMonSpriteId 8e6bc 60 158
UpdateShadowFieldEffect 126d10 c8
UpdateShoalTideFlag 10d378 50
UpdateShortGrassFieldEffect 127334 f4
UpdateSliderHeartSpriteYPositions affa0 40
UpdateSparkleFieldEffect 128774 4e
UpdateSplashFieldEffect 1276b4 8c
UpdateSpritePaletteWithWeather 7d78c e8
UpdateSurfBlobFieldEffect 127f7c 58
UpdateTVScreensOnMap bd908 84
UpdateTVShowsPerDay be8c4 26
UpdateTallGrassFieldEffect 126e7c 104
UpdateThunderSound 7f434 66
UpdateTilemap 6954 84 214
UpdateTrainerCardWinsLosses 110254 3a 19
UpdateTrainerFanClubGameClear 10faa0 70
UpdateWeatherGammaShift 7cc24 86 78
UpdateWeatherPerDay 80834 20
UpdateWindowText 35c4 188 214
UproarWakeUpCheck 25a44 9c
UseFlyAncientTomb_Callback 14760c 10
UseFlyAncientTomb_Finish 14761c 70
UseMedicine 6fe30 200
UseRegisteredKeyItem a6d1c 7c
VBlankCB 7c0cc 28 222
VBlankCB 8b628 12 145
VBlankCB b30ac 5c 193
VBlankCB 10cc6c 12 89
VBlankCB 145d74 12 54
VBlankCB 146900 12 139
VBlankCB 146e3c 12 178
VBlankCB0_BerryBlender 4e2bc 1a 25
VBlankCB0_Phase2_Mugshots 11c670 90 23
VBlankCB0_Phase2_Transition_BigPokeball 11b520 2c 23
VBlankCB0_Phase2_Transition_WhiteFade 11cee4 90 23
VBlankCB1_BerryBlender 4e2d8 12 25
VBlankCB1_Phase2_Mugshots 11c700 7c 23
VBlankCB1_Phase2_Transition_BigPokeball 11b54c 2c 23
VBlankCB1_Phase2_Transition_WhiteFade 11cf74 38 23
VBlankCB_AreaScren 1107dc 12 159
VBlankCB_BattleTransition 11d67c 12 23
VBlankCB_ClearSaveDataScreen 14881c 12 38
VBlankCB_ContestPainting 106aac 16 44
VBlankCB_Credits 143948 12 47
VBlankCB_EggHatch 42c6c 12 59
VBlankCB_EvolutionScene 114fd4 88 65
VBlankCB_Field 547f8 1e 148
VBlankCB_FieldRegionMap 13efb0 12
VBlankCB_FlyRegionMap fc214 12 167
VBlankCB_HallOfFame 141e38 12 107
VBlankCB_InitClearSaveDataScreen 148964 a 38
VBlankCB_Intro 13b784 12 114
VBlankCB_LinkTest 7300 12 120
VBlankCB_MainMenu 96dc 12 128
VBlankCB_MoveTutorMenu 13265c 12 137
VBlankCB_NamingScreen b5ab8 58 141
VBlankCB_PartyMenu 6af38 16
VBlankCB_Phase2_Transition_Clockwise_BlackFade 11bc2c 90 23
VBlankCB_Phase2_Transition_Ripple 11be3c 38 23
VBlankCB_Phase2_Transition_Shards 11d438 90 23
VBlankCB_Phase2_Transition_Shuffle 11b08c 38 23
VBlankCB_Phase2_Transition_Slice 11cc28 88 23
VBlankCB_Phase2_Transition_Swirl 11aee0 38 23
VBlankCB_Phase2_Transition_Wave 11c004 88 23
VBlankCB_PokeblockFeed 1478a8 12 157
VBlankCB_Pokedex 8c0b8 12 158
VBlankCB_ResetRtcScreen 6abcc 12
VBlankCB_SoundCheckMenu ba0c0 2c
VBlankCB_TradeEvolutionScene 11505c 7c 65
VBlankCB_UpdateClockGraphics 147218 cc 178
VBlankIntr 570 7c 127
VBlankIntrWait 1e07b4 6
VCountIntr 630 30 127
ValidateBattleTowerRecordChecksums 135c44 80 22
ValidateEReaderTrainer 13601c 6c
VarGet 69258 1c
VarGetObjectEventGraphicsId 69294 1c
VarSet 69274 20
VblankCallback 109e6c 12 206
VerifyFlashSector 1df8f8 98
VerifyFlashSectorNBytes 1df990 98
VerifyFlashSector_Core 1df8c8 2e
WaitAnimForDuration 782dc 1e
WaitAnimFrameCount 759a8 2c 6
WaitButtonPressAndDisplayTMHMInfo c9f10 70 117
WaitCableClubWarp 80fc4 68 71
WaitFanfare 74e70 38
WaitFieldEffectSpriteAnim 128800 2a
WaitForAorBPress 670c4 26 182
WaitForEvoSceneToFinish 13e88 28 17
WaitForFanfareFinish 669a8 e 182
WaitForFlashWrite_Common 1dfb54 9e
WaitForMovementDelay 64828 18 63
WaitForMovementFinish 66b0c 28 182
WaitForSoundEffectFinish 66968 16 182
WaitForVBlank 694 20 127
WaitWeather 10d3e8 14
WaitWithDownArrow 45c4 4c 214
WallClockInit 10a864 90 236
WallClockMainCallback 10ab3c 16 236
WallClockVblankCallback 10a704 12 236
WallyBufferExecCompleted 13796c 78 13
WallyBufferRunCommand 13726c 50 13
WallyCmdEnd 139c14 2 13
WallyDoMoveAnimation 1390d0 136 13
WallyHandleActions 1372bc 160 13
WallyHandleBallThrowAnim 138f44 5c 13
WallyHandleBattleAnimation 139b44 5c 13
WallyHandleCantSwitch 139674 a 13
WallyHandleChooseAction 139298 e0 13
WallyHandleChooseItem 1393ec 40 13
WallyHandleChooseMove 139384 68 13
WallyHandleChoosePokemon 13942c a 13
WallyHandleChosenMonReturnValue 1395b0 a 13
WallyHandleClearUnkFlag 1395ec a 13
WallyHandleClearUnkVar 1395d4 a 13
WallyHandleCmd23 139438 a 13
WallyHandleCmd32 139598 a 13
WallyHandleDMA3Transfer 139580 a 13
WallyHandleDataTransfer 139574 a 13
WallyHandleDrawPartyStatusSummary 139aa0 80 13
WallyHandleDrawTrainerPic 138d38 cc 13
WallyHandleEndBounceEffect 139b2c a 13
WallyHandleEndLinkBattle 139bb8 5c 13
WallyHandleExpUpdate 139544 a 13
WallyHandleFaintAnimation 138edc a 13
WallyHandleFaintingCry 1396e0 3c 13
WallyHandleGetMonData 137a10 72 13
WallyHandleGetRawMonData 138230 a 13
WallyHandleHealthBarUpdate 139444 100 13
WallyHandleHidePartyStatusSummary 139b20 a 13
WallyHandleHitAnimation 139604 70 13
WallyHandleIntroSlide 13971c 34 13
WallyHandleIntroTrainerBallThrow 139750 16c 13
WallyHandleLinkStandbyMsg 139ba0 a 13
WallyHandleLoadMonSprite 138c9c a 13
WallyHandleMoveAnimation 138fac 124 13
WallyHandleOneReturnValue 1395bc a 13
WallyHandleOneReturnValue_Duplicate 1395c8 a 13
WallyHandlePaletteFade 138ee8 a 13
WallyHandlePause 138fa0 a 13
WallyHandlePlayBGM 13958c a 13
WallyHandlePlayFanfareOrBGM 1396b0 30 13
WallyHandlePlaySE 139680 30 13
WallyHandlePrintSelectionString 139274 24 13
WallyHandlePrintString 139208 6c 13
WallyHandleResetActionMoveSelection 139bac a 13
WallyHandleReturnMonToBall 138cb4 84 13
WallyHandleSetMonData 13823c 58 13
WallyHandleSetRawMonData 138c90 a 13
WallyHandleSetUnkVar 1395e0 a 13
WallyHandleSpriteInvisibility 139b38 a 13
WallyHandleStatusAnimation 13955c a 13
WallyHandleStatusIconUpdate 139550 a 13
WallyHandleStatusXor 139568 a 13
WallyHandleSuccessBallThrowAnim 138ef4 50 13
WallyHandleSwitchInAnim 138ca8 a 13
WallyHandleToggleUnkFlag 1395f8 a 13
WallyHandleTrainerSlide 138e04 cc 13
WallyHandleTrainerSlideBack 138ed0 a 13
WallyHandleTwoReturnValues 1395a4 a 13
WallyHandleYesNoBox 139378 a 13
WallySetBattleEndCallbacks 13746c 40
WarpFadeScreen 80918 3e
WarpIntoMap 53440 12
WarpToTruck 52e04 1e
WasAtLeastOneOpponentJammed b9120 de 41
WasSecondRematchWon 82b10 32
WasUnableToUseMove 15660 56
Weather2_Finish 7dfd0 4
Weather2_InitAll 7dfc0 a
Weather2_InitVars 7df9c 24
Weather2_Main 7dfcc 2
Weather_SetBlendCoeffs 7db64 40
Weather_SetTargetBlendCoeffs 7dba4 44
Weather_UpdateBlend 7dbe8 cc
WillPlayerCollideWithCollision e5ec0 32 28
Window_MoveCursor 48d8 10 214
WipeSector 147324 58 178
WipeSectors 14737c 3a 178
WriteCommand 1e0578 a4 194
WriteData 1e061c a0 194
WriteFlashScanlineEffectBuffer 815e0 3c
WriteGlyphTilemap 39ec 30 214
WriteGlyphTilemap_Font0_Font3 3868 1c 214
WriteGlyphTilemap_Font1_Font4 3884 2c 214
WriteGlyphTilemap_Font2_Font5 38b0 1c 214
WriteGlyphTilemap_Font6 38cc 2c 214
WriteSaveBlockChunks 125238 a0 177
WriteSingleChunk 1252d8 f0 177
WriteSomeFlashByte0x25ToPrevSector 1257f0 8c 177
WriteSomeFlashByteToPrevSector 125758 98 177
ZCoordToPriority 63d64 10
ZeroBattleTowerData 52de4 20
ZeroBoxMonData 3a6c0 16
ZeroEnemyPartyMons 3a778 20
ZeroMonData 3a6d8 7e
ZeroPlayerPartyMons 3a758 20
_CreateInGameTradePokemon 4d948 18c 223
_GetDaycareMonNicknames 422c4 64 52
_GiveEggFromDaycare 41fc4 80 52
_InitContestMonPixels 106b90 b0 44
_ShouldEggHatch 421b0 f0 52
_SpriteCB_Dummy 91874 2 158
_TriggerPendingDaycareEgg 418f0 2c 52
_TriggerPendingDaycareMaleEgg 4191c 24 52
__adddf3 1e13e4 30
__addsf3 1e1fa4 2c
__cmpdf2 1e197c 2a
__cmpsf2 1e2338 26
__copy_tilemap aeb4c 1c
__div0 1e088c 2
__divdf3 1e16f4 188
__divsf3 1e2168 ea
__divsi3 1e07f8 92
__eqdf2 1e19a8 4a
__eqsf2 1e2360 46
__extendsfdf2 1e2614 2c
__fixdfsi 1e1bec 72
__fixsfsi 1e2570 68
__fixunsdfsi 1e0890 44
__fixunssfsi 1e08d4 34
__floatsidf 1e1b70 7c
__floatsisf 1e2510 60
__fpcmp_parts_d 1e187c fe
__fpcmp_parts_f 1e2254 e4
__gedf2 1e1a8c 4c
__gesf2 1e2438 48
__gtdf2 1e1a40 4c
__gtsf2 1e23f0 48
__ledf2 1e1b24 4a
__lesf2 1e24c8 46
__lshrdi3 1e2640 32
__ltdf2 1e1ad8 4a
__ltsf2 1e2480 46
__make_dp 1e1c88 26
__make_fp 1e25fc 16
__modsi3 1e0908 ce
__muldf3 1e144c 2a8
__muldi3 1e09d8 70
__mulsf3 1e2004 164
__nedf2 1e19f4 4a
__negdf2 1e1c60 26
__negdi2 1e2674 16
__negsf2 1e25d8 24
__nesf2 1e23a8 46
__pack_d 1e0f58 148
__pack_f 1e1cf4 b8
__subdf3 1e1414 38
__subsf3 1e1fd0 34
__truncdfsf2 1e1cb0 44
__udivdi3 1e0a48 3d8
__udivsi3 1e0e20 78
__umodsi3 1e0e98 c0
__unpack_d 1e10a0 d8
__unpack_f 1e1dac 7a
_call_via_fp 1e07e8 4
_call_via_ip 1e07ec 4
_call_via_lr 1e07f4 4
_call_via_r0 1e07bc 4
_call_via_r1 1e07c0 4
_call_via_r2 1e07c4 4
_call_via_r3 1e07c8 4
_call_via_r4 1e07cc 4
_call_via_r5 1e07d0 4
_call_via_r6 1e07d4 4
_call_via_r7 1e07d8 4
_call_via_r8 1e07dc 4
_call_via_r9 1e07e0 4
_call_via_sl 1e07e4 4
_call_via_sp 1e07f0 4
_fpadd_parts 1e1178 26c 55
_fpadd_parts 1e1e28 17a 101
_swiopen fac44 c0 167
add_to_c3_somehow 985a0 2c
an_walk_any_2 60f08 38
atk00_attackcanceler 1bc50 3b8 20
atk01_accuracycheck 1c2bc 38c 20
atk02_attackstring 1c648 54 20
atk03_ppreduce 1c69c 1dc 20
atk04_critcalc 1c878 174 20
atk05_damagecalc 1c9ec 10c 20
atk06_typecalc 1ccc4 278 20
atk07_adjustnormaldamage 1d5b0 1b0 20
atk08_adjustnormaldamage2 1d760 18c 20
atk09_attackanimation 1d8ec 174 20
atk0A_waitanimation 1da60 20 20
atk0B_healthbarupdate 1da80 cc 20
atk0C_datahpupdate 1db4c 3fc 20
atk0D_critmessage 1df48 54 20
atk0E_effectivenesssound 1df9c d0 20
atk0F_resultmessage 1e06c 1b0 20
atk10_printstring 1e21c 40 20
atk11_printselectionstring 1e25c 44 20
atk12_waitmessage 1e2a0 5c 20
atk13_printfromtable 1e2fc 54 20
atk14_printselectionstringfromtable 1e350 64 20
atk15_seteffectwithchance 1f614 f4 20
atk16_seteffectprimary 1f708 e 20
atk17_seteffectsecondary 1f718 e 20
atk18_clearstatusfromeffect 1f728 84 20
atk19_tryfaintmon 1f7ac 386 20
atk1A_dofaintanimation 1fb34 3c 20
atk1B_cleareffectsonfaint 1fb70 64 20
atk1C_jumpifstatus 1fbd4 78 20
atk1D_jumpifstatus2 1fc4c 78 20
atk1E_jumpifability 1fcc4 ee 20
atk1F_jumpifsideaffecting 1fdb4 78 20
atk20_jumpifstat 1fe2c f8 20
atk21_jumpifstatus3condition 1ff24 84 20
atk22_jumpiftype 1ffa8 5a 20
atk23_getexp 20004 9b0 20
atk24 209b4 1a0 20
atk25_movevaluescleanup 20b9c 18 20
atk26_setmultihit 20bb4 18 20
atk27_decrementmultihit 20bcc 48 20
atk28_goto 20c14 20 20
atk29_jumpifbyte 20c34 9e 20
atk2A_jumpifhalfword 20cd4 a6 20
atk2B_jumpifword 20d7c b2 20
atk2C_jumpifarrayequal 20e30 86 20
atk2D_jumpifarraynotequal 20eb8 84 20
atk2E_setbyte 20f3c 28 20
atk2F_addbyte 20f64 2c 20
atk30_subbyte 20f90 2c 20
atk31_copyarray 20fbc 54 20
atk32_copyarraywithindex 21010 6c 20
atk33_orbyte 2107c 2c 20
atk34_orhalfword 210a8 38 20
atk35_orword 210e0 44 20
atk36_bicbyte 21124 2c 20
atk37_bichalfword 21150 38 20
atk38_bicword 21188 44 20
atk39_pause 211cc 40 20
atk3A_waitstate 2120c 20 20
atk3B_healthbar_update 2122c 58 20
atk3C_return 21284 a 20
atk3D_end 21290 20 20
atk3E_end2 212b0 18 20
atk3F_end3 212c8 30 20
atk40_jumpifaffectedbyprotect 1c098 70 20
atk41_call 212f8 30 20
atk42_jumpiftype2 21328 5a 20
atk43_jumpifabilitypresent 21384 4a 20
atk44_endselectionscript 213d0 20 20
atk45_playanimation 213f0 c4 20
atk46_playanimation2 214b4 cc 20
atk47_setgraphicalstatchangevalues 21580 7c 20
atk48_playstatchangeanimation 215fc 1fc 20
atk49_moveend 217f8 ae4
atk4A_typecalc2 222dc 250 20
atk4B_returnatktoball 2252c 50 20
atk4C_getswitchedmondata 2257c 74 20
atk4D_switchindataupdate 225f0 194 20
atk4E_switchinanim 22784 ac 20
atk4F_jumpifcantswitch 22830 20c 20
atk50_openpartyscreen 22a98 884 20
atk51_switchhandleorder 2331c 208 20
atk52_switchineffects 23524 2a8 20
atk53_trainerslidein 237cc 40 20
atk54_playse 2380c 3c 20
atk55_fanfare 23848 3c 20
atk56_playfaintcry 23884 30 20
atk57 238b4 38 20
atk58_returntoball 238ec 34 20
atk59_handlelearnnewmove 23920 160
atk5A_yesnoboxlearnmove 23af8 37c 20
atk5B_yesnoboxstoplearningmove 23e74 110 20
atk5C_hitanimation 23f84 90 20
atk5D_getmoneyreward 24014 180 20
atk5E 24194 b4 20
atk5F_swapattackerwithtarget 24248 50 20
atk60_incrementgamestat 24298 30 20
atk61_drawpartystatussummary 242c8 c8 20
atk62_hidepartystatussummary 24390 30 20
atk63_jumptorandomattack 243c0 64 20
atk64_statusanimation 24424 90 20
atk65_status2animation 244b4 a8 20
atk66_chosenstatusanimation 2455c 94 20
atk67_yesnobox 245f0 b0 20
atk68_cancelallactions 246a0 38 20
atk69_adjustsetdamage 246d8 17c 20
atk6A_removeitem 24854 6c
atk6B_atknameinbuff1 248c0 3c 20
atk6C_drawlvlupbox 248fc 350 20
atk6D_resetsentmonsvalue 24c4c 18 20
atk6E_setatktoplayer0 24c64 20 20
atk6F_makevisible 24c84 34 20
atk70_recordlastability 24cb8 34 20
atk71_buffermovetolearn 24d14 18 20
atk72_jumpifplayerran 24d2c 44 20
atk73_hpthresholds 24d70 bc 20
atk74_hpthresholds2 24e2c bc 20
atk75_useitemonopponent 24ee8 58 20
atk76_various 24f40 1f0 20
atk77_setprotectlike 25130 13c 20
atk78_faintifabilitynotdamp 2526c 11c 20
atk79_setatkhptozero 25388 60 20
atk7A_jumpifnexttargetvalid 253e8 a2 20
atk7B_tryhealhalfhealth 2548c 7c 20
atk7C_trymirrormove 25508 1c8 20
atk7D_setrain 256d0 54 20
atk7E_setreflect 25724 b8 20
atk7F_setseeded 257dc c0 20
atk80_manipulatedamage 2589c 80 20
atk81_trysetrest 2591c d0 20
atk82_jumpifnotfirstturn 259ec 48 20
atk83_nop 25a34 10 20
atk84_jumpifcantmakeasleep 25ae0 7c 20
atk85_stockpile 25b5c 7c 20
atk86_stockpiletobasedamage 25bd8 128 20
atk87_stockpiletohpheal 25d00 ec 20
atk88_negativedamage 25dec 34 20
atk89_statbuffchange 262c4 54 20
atk8A_normalisebuffs 26318 54 20
atk8B_setbide 2636c 70 20
atk8C_confuseifrepeatingattackends 263dc 40 20
atk8D_setmultihitcounter 2641c 4c 20
atk8E_initmultihitstring 26468 58 20
atk8F_forcerandomswitch 26590 2fa 20
atk90_tryconversiontypechange 2688c 1a4 20
atk91_givepaydaymoney 26a30 90 20
atk92_setlightscreen 26ac0 b8 20
atk93_tryKO 26b78 2e0 20
atk94_damagetohalftargethp 26e58 3c 20
atk95_setsandstorm 26e94 58 20
atk96_weatherdamage 26eec 178 20
atk97_tryinfatuating 27064 1d4 20
atk98_updatestatusicon 27238 110 20
atk99_setmist 27348 94 20
atk9A_setfocusenergy 273dc 5c 20
atk9B_transformdataexecution 27438 1a0 20
atk9C_setsubstitute 275d8 bc 20
atk9D_mimicattackcopy 276dc 1da 20
atk9E_metronome 278b8 a8 20
atk9F_dmgtolevel 27960 30 20
atkA0_psywavedamageeffect 27990 54 20
atkA1_counterdamagecalculator 279e4 f8 20
atkA2_mirrorcoatdamagecalculator 27adc f8 20
atkA3_disablelastusedattack 27bd4 144 20
atkA4_trysetencore 27d18 134 20
atkA5_painsplitdmgcalc 27e4c f8 20
atkA6_settypetorandomresistance 27f44 1f8 20
atkA7_setalwayshitflag 2813c 58 20
atkA8_copymovepermanently 28194 1bc 20
atkA9_trychoosesleeptalkmove 28420 138 20
atkAA_setdestinybond 28558 30 20
atkAB_trysetdestinybondtohappen 285e8 18 20
atkAC_remaininghptopower 28600 68 20
atkAD_tryspiteppreduce 28668 1f0 20
atkAE_healpartystatus 28858 27c 20
atkAF_cursetarget 28ad4 9c 20
atkB0_trysetspikes 28b70 8c 20
atkB1_setforesight 28bfc 30 20
atkB2_trysetperishsong 28c2c b8 20
atkB3_rolloutdamagecalculation 28ce4 17c 20
atkB4_jumpifconfusedandstatmaxed 28e60 68 20
atkB5_furycuttercalc 28ec8 b4 20
atkB6_happinesstodamagecalculation 28f7c 84 20
atkB7_presentdamagecalculation 29000 bc 20
atkB8_setsafeguard 290bc 90 20
atkB9_magnitudedamagecalculation 2914c 124 20
atkBA_jumpifnopursuitswitchdmg 29270 178 20
atkBB_setsunny 293e8 58 20
atkBC_maxattackhalvehp 29440 80 20
atkBD_copyfoestats 294c0 48 20
atkBE_rapidspinfree 29508 144 20
atkBF_setdefensecurlbit 2964c 30 20
atkC0_recoverbasedonsunlight 2967c 108 20
atkC1_hiddenpowercalc 29784 128 20
atkC2_selectfirstvalidtarget 298ac 74 20
atkC3_trysetfutureattack 29920 128 20
atkC4_trydobeatup 29a48 210 20
atkC5_setsemiinvulnerablebit 29c58 84 20
atkC6_clearsemiinvulnerablebit 29cdc 90 20
atkC7_setminimize 29d6c 40 20
atkC8_sethail 29dac 58 20
atkC9_jumpifattackandspecialattackcannotfall 29e04 9c 20
atkCA_setforcedtarget 29ea0 4c 20
atkCB_setcharge 29eec 64 20
atkCC_callenvironmentattack 29f50 74 20
atkCD_cureifburnedparalysedorpoisoned 29fc4 84 20
atkCE_settorment 2a048 58 20
atkCF_jumpifnodamage 2a0a0 5c 20
atkD0_settaunt 2a0fc 74 20
atkD1_trysethelpinghand 2a170 a8 20
atkD2_tryswapitems 2a218 298 20
atkD3_trycopyability 2a4b0 78 20
atkD4_trywish 2a528 d2 20
atkD5_trysetroots 2a5fc 58 20
atkD6_doubledamagedealtifdamaged 2a654 68 20
atkD7_setyawn 2a6bc 70 20
atkD8_setdamagetohealthdifference 2a72c 6c 20
atkD9_scaledamagebyhealthratio 2a798 64 20
atkDA_tryswapabilities 2a7fc 98 20
atkDB_tryimprison 2a894 100 20
atkDC_trysetgrudge 2a994 58 20
atkDD_weightdamagecalculation 2a9ec 98 20
atkDE_assistattackselect 2aa84 178 20
atkDF_trysetmagiccoat 2abfc 84 20
atkE0_trysetsnatch 2ac80 7c 20
atkE1_trygetintimidatetarget 2acfc dc 20
atkE2_switchoutabilities 2add8 84 20
atkE3_jumpifhasnohp 2ae5c 54 20
atkE4_getsecretpowereffect 2aeb0 b8 20
atkE5_pickup 2af68 ec 20
atkE6_docastformchangeanimation 2b054 6c 20
atkE7_trycastformdatachange 2b0c0 48 20
atkE8_settypebasedhalvers 2b108 b8 20
atkE9_setweatherballtype 2b1c0 cc 20
atkEA_tryrecycleitem 2b28c a4 20
atkEB_settypetoenvironment 2b330 b0 20
atkEC_pursuitrelated 2b3e0 d4 20
atkEE_removelightscreenreflect 2b51c 9c 20
atkEF_handleballthrow 2b5b8 3a8
atkEF_snatchsetbattlers 2b4b4 68 20
atkF0_givecaughtmon 2b960 80 20
atkF1_trysetcaughtmondexflags 2b9e0 b0 20
atkF2_displaydexinfo 2ba90 144 20
atkF3_trygivecaughtmonnick 2bc90 260 20
atkF4_subattackerhpbydmg 2bef0 30 20
atkF5_removeattackerstatus1 2bf20 28 20
atkF6_finishaction 2bf48 c 20
atkF7_finishturn 2bf54 1c 20
b_link_standby_message 2e48c 44
ball_number_to_ball_processing_index 13fa14 7e
battle_load_something 31d70 176
battle_make_oam_normal_battle 43914 328
battle_make_oam_safari_battle 43c3c a0
bc_8012FAC 112c0 74
bc_801333C 11600 1a0
bc_8013568 117d8 28
bc_801362C 118c4 8c
bc_8013B1C 11dc8 c4
bc_battle_begin_message 117a0 38
bitmask_all_link_players_but_self 7e6c 1c
bx_0802E404 2c064 34
bx_battle_menu_t6_2 12b4d4 188
bx_blink_t1 2e0b0 7c
bx_blink_t3 11dfb8 7c
bx_blink_t7 331e8 7c
bx_t1_healthbar_update 2d89c 70
bx_t3_healthbar_update 11de28 70
bx_wait_t1 2e078 38
bx_wait_t6 12b6ec 38
c1_overworld_prev_quest 1002bc 78
c2_081284E0 101d4 74
c2_8011A1C 10014 1a4
c2_80567AC 545b0 38 148
c2_exit_to_overworld_1_sub_8080DEC 546a0 1c
c3_080843F8 866ec 5c
c3_0808DC50 97350 40
c3_80DFBE4 12db18 40
check_acro_bike_metatile 5901c 40 73
chk_adr_r2 1dd5be 0 125
clear_modM 1ddcd4 1a
compare_012 65d40 20
coords8_add 579ec e 66
copy_saved_warp2_bank_and_enter_x_to_warp1 53520 18
copy_word_to_mem 52d10 1c
cph_IM_DIFFERENT 5f71c 48
cur_mapdata_get_door_x2_at 58670 2e 68
cur_mapheader_run_tileset_funcs_after_some_cpuset 72ec0 12
current_map_music_set__default_for_battle 408d8 2c
debug_sub_800D684 d684 40
debug_sub_80524BC 524bc 74
debug_sub_80C853C c853c 3e
debug_sub_81261B4 1261b4 58
debug_sub_812620C 12620c 5c
dive_2_unknown 87138 28
dive_3_unknown 87160 58
dive_warp 68ea0 7c
do_boulder_dust 59ea8 9c 73
do_boulder_dust dd078 118 0
do_go_anim 60da8 5c
do_load_map_stuff_loop 54b94 16
do_nothing 4373c 4 15
door_build_blockdef 58390 40 68
dp01_getattr_by_ch1_for_player_pokemon 11e458 7ac
dp01_getattr_by_ch1_for_player_pokemon_ 2e544 7ac
dp01_getattr_by_ch1_for_player_pokemon__ 380f0 7ac
dp01_setattr_by_ch1_for_player_pokemon 2edd0 9fc
dp01t_0F_4_move_anim 37c44 7c
dp01t_12_3_battle_menu 1169f4 bc
dp11b_obj_free 10714 9c
dp11b_obj_instanciate 10614 100
dp15_jump_random_unknown 102708 98 199
draw_status_ailment_maybe 45540 2a8
duplicate_obj_of_side_rel2move_in_transparent_mode 795e8 74
fishE 894fc 7c
get_berry_tree_graphics 5bb74 a0 63
get_preferred_box 98b3c c
get_some_collision e5d34 6c 28
get_trainer_class_name_index 134ce0 6c
get_trainer_class_pic_index 134c74 6c
get_trainer_name 134d4c 88
gpu_pal_decompress_alloc_tag_and_upload fe3c4 54
gpu_sync_bg_hide 53808 10
gpu_sync_bg_show f5244 20
intro_create_brendan_sprite 149310 58
intro_create_latias_sprite 1494a0 7c
intro_create_latios_sprite 149424 7c
intro_create_may_sprite 149368 58
intro_reset_and_hide_bgs 13ccb0 36 114
is_c1_link_related_active 542dc 1e
is_map_type_1_2_3_5_or_6 54204 24
j5_08111E84 1035ec 7c 199
launch_c3_walk_stairs_and_run_once 136280 14 235
ld_r3_tp_adr_i 1dd5d8 722
ld_r3_tp_adr_i_unchecked 1ddcf0 0 125
ldrb_r3_r2 1dd5bc 0 125
load_intro_part2_graphics 148b8c ec
m4aMPlayAllContinue 1de00c 44
m4aMPlayAllStop 1ddfbc 44
m4aMPlayContinue 1de000 a
m4aMPlayFadeIn 1de080 28
m4aMPlayFadeOut 1de050 e
m4aMPlayFadeOutTemporarily 1de060 20
m4aMPlayImmInit 1de0a8 48
m4aMPlayLFOSpeedSet 1df04c 74
m4aMPlayModDepthSet 1defd8 74
m4aMPlayPanpotControl 1def50 68
m4aMPlayPitchControl 1deedc 74
m4aMPlayStop 1de6d0 40
m4aMPlayTempoControl 1dee4c 28
m4aMPlayVolumeControl 1dee74 68
m4aSongNumContinue 1ddf88 34
m4aSongNumStart 1dde88 2c
m4aSongNumStartOrChange 1ddeb4 4c
m4aSongNumStartOrContinue 1ddf00 54
m4aSongNumStop 1ddf54 34
m4aSoundInit 1dddc8 b4
m4aSoundMain 1dde7c a
m4aSoundMode 1de3d0 98
m4aSoundVSync 1dd768 4c
m4aSoundVSyncOff 1de4bc 7c
m4aSoundVSyncOn 1de538 3c
map_warp_consider_2_to_inside 68cac 8c 67
mapdata_load_assets_to_gpu_and_full_redraw 53220 28 148
mapheader_run_first_tag2_script_list_match_conditionally 68a04 64 67
mapldr_080842E8 865dc 28
mapldr_08084390 86684 68
mapldr_080851BC 87448 28
mapldr_080859D4 87a28 4c
mapldr_08085D88 87dcc 50 69
mapldr_default 80b48 16
maybe_shadow_1 611fc 44
memcpy 1e268c 5e
memset 1e26ec 52
mli4_mapscripts_and_other 54dbc 68
mon_icon_convert_unown_species_id 9d434 3e
move_anim_execute f3da8 34
move_anim_start_t2 7bd60 50
move_anim_start_t2_for_situation 313d0 f8
move_tilemap_camera_to_upper_left_corner 579fc 60
move_tilemap_camera_to_upper_left_corner_ 579c0 10 66
mplay_80342A4 31724 70
nature_stat_mod 3fc74 60
npc_apply_direction 60d24 84
npc_by_local_id_and_map_set_field_1_bit_x20 5bc60 50
npc_clear_strange_bits 588ac 24 73
npc_obj_ministep_stop_on_arrival 60e34 38
npc_obj_offscreen_culling_and_flag_update a23a8 10 185
npc_something3 55d74 5e 148
nullsub 63ffc 2 63
nullsub_10 31b70 2
nullsub_11 43eb0 2
nullsub_12 6e570 2 150
nullsub_13 6e574 2
nullsub_15 937fc 2 224
nullsub_16 a3e6c 2 116
nullsub_18 b0118 2
nullsub_19 b05f8 2
nullsub_20 b7764 2 141
nullsub_22 c1bf4 2
nullsub_23 e9e94 2
nullsub_34 b23c 2 128
nullsub_36 fdac 2
nullsub_37 10308 2
nullsub_40 b6e64 2 141
nullsub_41 107fc 2
nullsub_45 32adc 2
nullsub_47 3750c 2
nullsub_49 590cc 2 73
nullsub_5 48d20 2 223
nullsub_6 2bc8c 2
nullsub_60 9338c 2 224
nullsub_61 b78f4 2 141
nullsub_62 b7920 2 141
nullsub_65 f78c8 2 134
nullsub_66 fbb38 2 167
nullsub_68 104118 2 199
nullsub_69 104ea4 2 199
nullsub_7 2e3e0 2
nullsub_70 106360 2 199
nullsub_72 10a57c 2 206
nullsub_74 11da74 2
nullsub_76 123cb4 2 35
nullsub_8 2e410 2
nullsub_82 14929c 2
nullsub_83 1493c0 2
nullsub_86 105e8 2
nullsub_9 31a68 2
oac_poke_ally_ 105ac 30
oac_poke_opponent 10248 30
oamc_804BEB4 4789c 40 155
oamt_npc_ministep_reset 64604 12 63
obj_delete_and_free_associated_resources_ 47770 a
obj_delete_but_dont_free_vram 7965c 16
obj_id_set_rotscale 78db8 84
obj_npc_ministep 64618 68
objc_0804ABD4 46634 b4 155
objc_dp11b_pingpong 107b0 4c
objc_exclamation_mark_probably 848e0 96 225
oei_task_add 10b328 24
pal_fill_black 80904 12
pal_fill_for_map_transition 808b8 4a
palette_bg_fill_black 80898 20
palette_bg_fill_white 80874 24
party_menu_link_mon_held_item_object 6ea90 40
player_is_anim_in_certain_ranges 5924c 5a 73
player_should_look_direction_be_enforced_upon_movement e5f40 3a
player_step 587e0 78
ply_bend 1dd6f0 14
ply_bendr 1dd704 12
ply_endtie 1ddc94 40
ply_fine 1dd574 2e
ply_goto 1dd5e4 20
ply_keysh 1dd684 12
ply_lfodl 1dd718 a
ply_lfos 1ddcfc 12
ply_memacc 1df0c0 158
ply_mod 1ddd10 12
ply_modt 1dd724 18
ply_note 1dda90 204
ply_pan 1dd6dc 14
ply_patt 1dd604 1a
ply_pend 1dd620 14
ply_port 1dd750 18
ply_prio 1dd664 a
ply_rept 1dd634 2e
ply_tempo 1dd670 14
ply_tune 1dd73c 14
ply_voice 1dd698 2e
ply_vol 1dd6c8 12
ply_xatta 1df2a8 12
ply_xcmd 1df218 20
ply_xcmd_0C 1df338 46
ply_xcmd_0D 1df380 48
ply_xdeca 1df2bc 12
ply_xiecl 1df304 c
ply_xiecv 1df2f8 c
ply_xleng 1df310 12
ply_xrele 1df2e4 12
ply_xsust 1df2d0 12
ply_xswee 1df324 12
ply_xtype 1df294 12
ply_xwave 1df24c 48
ply_xxx 1df238 14
pokemon_change_order 94d18 48
pokemon_has_move 6f040 2e
pokemon_order_func 94cd4 44
refresh_graphics_maybe 32464 56
sav12_xor_get_clamped_above 934dc 18 224
sav1_map_get_battletype 542ac 24
sav1_map_get_name 54288 24
saved_warp2_set 534b0 3c
saved_warp2_set_2 534ec 34
show_sprite 5b2d8 50
snowflakes_progress 7eb24 7c
sp0C8_whiteout_maybe 10d26c 14
sp13E_warp_to_last_warp 80ec0 30
special_0x44 bd800 b8
state_to_direction 60be0 40
strcmp 1e2740 5a
sub_080B08A0 d8ff0 3c
sub_8002FA0 2fa0 40 214
sub_8003344 3344 42 214
sub_8003490 3490 42
sub_80034EC 34ec 18
sub_8003504 3504 54
sub_8003558 3558 54
sub_8004FD0 4fd0 dc
sub_8007270 7270 10
sub_8007B14 7b14 10
sub_8007B24 7b24 1e
sub_8007B44 7b44 1c 120
sub_8007E04 7e04 20 120
sub_8007E24 7e24 1c
sub_8007E40 7e40 c
sub_8007E4C 7e4c 10
sub_8007E9C 7e9c 30
sub_8007F4C 7f4c 28
sub_8008198 8198 30
sub_80081C8 81c8 44
sub_800820C 820c c
sub_8008218 8218 c
sub_8008224 8224 48
sub_800826C 826c 80
sub_80082EC 82ec 14
sub_8008350 8350 2c 120
sub_800837C 837c 64 120
sub_80083E0 83e0 74 120
sub_8008454 8454 2c 120
sub_8008480 8480 24
sub_80084A4 84a4 24
sub_80084C8 84c8 2c 120
sub_80084F4 84f4 58 120
sub_800B950 b950 58
sub_800C35C c35c 120
sub_800D6C4 d6c4 e 11
sub_800D6D4 d6d4 78
sub_800DAF8 daf8 12c 11
sub_800F104 f104 194
sub_800F828 f828 10
sub_800F838 f838 b0
sub_800FCD4 fcd4 28
sub_800FCFC fcfc b0
sub_800FDB0 fdb0 70
sub_800FE20 fe20 20
sub_800FE40 fe40 1d4
sub_80101B8 101b8 1a
sub_8010278 10278 34
sub_80102AC 102ac 5c
sub_8010320 10320 64
sub_8010384 10384 110
sub_8010494 10494 8c
sub_8010520 10520 1c
sub_801053C 1053c 36
sub_8010574 10574 2c
sub_80105A0 105a0 c
sub_80105DC 105dc c
sub_80105EC 105ec 28
sub_8010800 10800 24
sub_8011384 11384 27c
sub_8011800 11800 34
sub_8011834 11834 90
sub_8011970 11970 44
sub_80119B4 119b4 b4
sub_8012258 12258 cc
sub_8012324 12324 c98
sub_80155A4 155a4 50
sub_8015740 15740 84
sub_80157C4 157c4 68
sub_8018018 18018 1a0
sub_801B594 1b594 2c
sub_8022A3C 22a3c 5c
sub_8023A80 23a80 58
sub_8023AD8 23ad8 1e
sub_8024CEC 24cec 28
sub_80264C0 264c0 d0 20
sub_802BBD4 2bbd4 98
sub_802BC6C 2bc6c 20
sub_802C098 2c098 21e
sub_802C2EC 2c2ec 3a0
sub_802CA60 2ca60 6e8
sub_802D148 2d148 44
sub_802D18C 2d18c 78
sub_802D204 2d204 38
sub_802D23C 2d23c 38
sub_802D274 2d274 6c
sub_802D2E0 2d2e0 3c
sub_802D31C 2d31c 1e4
sub_802D500 2d500 180
sub_802D680 2d680 b0
sub_802D730 2d730 68
sub_802D798 2d798 d4
sub_802D90C 2d90c 18
sub_802D924 2d924 178
sub_802DA9C 2da9c d0
sub_802DB6C 2db6c 144
sub_802DCB0 2dcb0 60
sub_802DD10 2dd10 b4
sub_802DDC4 2ddc4 4c
sub_802DE10 2de10 9c
sub_802DEAC 2deac 6c
sub_802DF18 2df18 18
sub_802DF30 2df30 58
sub_802DF88 2df88 7c
sub_802E004 2e004 38
sub_802E03C 2e03c 3c
sub_802E12C 2e12c 84
sub_802E1B0 2e1b0 70
sub_802E220 2e220 b4
sub_802E2D4 2e2d4 e0
sub_802E3B4 2e3b4 2c
sub_802E3E4 2e3e4 2c
sub_802E414 2e414 10
sub_802E424 2e424 10
sub_802E434 2e434 2c
sub_802E460 2e460 2c
sub_802F934 2f934 16c
sub_802FB2C 2fb2c 88
sub_8030190 30190 164
sub_80304A8 304a8 88
sub_8031064 31064 40
sub_80315E8 315e8 54
sub_803163C 3163c 22
sub_80316CC 316cc 54
sub_8031A6C 31a6c 88
sub_8031B74 31b74 2c
sub_8031C30 31c30 12a
sub_8031EE8 31ee8 24
sub_8031F0C 31f0c 18
sub_8031F88 31f88 3c
sub_8031FC4 31fc4 38c
sub_80324E0 324e0 18
sub_8032638 32638 b4
sub_80327CC 327cc d8
sub_80328A4 328a4 d4
sub_8032978 32978 c
sub_8032984 32984 84
sub_8032A08 32a08 30
sub_8032A38 32a38 70
sub_8032AA8 32aa8 34
sub_8032B4C 32b4c 38
sub_8032B84 32b84 38
sub_8032BBC 32bbc 90
sub_8032C4C 32c4c 3c
sub_8032C88 32c88 1a4
sub_8032E2C 32e2c 1ec
sub_8033018 33018 b0
sub_80330C8 330c8 52
sub_803311C 3311c 44
sub_8033160 33160 70
sub_80331D0 331d0 18
sub_8033264 33264 6c
sub_80332D0 332d0 38
sub_8033308 33308 cc
sub_80333D4 333d4 c0
sub_8033494 33494 2c
sub_80334C0 334c0 2c
sub_8033598 33598 7ac
sub_8033E24 33e24 920
sub_803495C 3495c 184
sub_8034B74 34b74 88
sub_8035238 35238 164
sub_8035C10 35c10 34
sub_8035C44 35c44 e4
sub_8035E2C 35e2c 40
sub_803752C 3752c 50
sub_803757C 3757c 38
sub_80375B4 375b4 90
sub_8037644 37644 3c
sub_8037680 37680 1c0
sub_8037840 37840 234
sub_8037A74 37a74 b0
sub_8037B24 37b24 52
sub_8037B78 37b78 44
sub_8037BBC 37bbc 70
sub_8037C2C 37c2c 18
sub_8037CC0 37cc0 6c
sub_8037D2C 37d2c 38
sub_8037D64 37d64 cc
sub_8037E30 37e30 c0
sub_8037EF0 37ef0 44
sub_8037F34 37f34 78
sub_8037FAC 37fac 2c
sub_8037FD8 37fd8 2c
sub_8038900 38900 920
sub_8039430 39430 184
sub_8039648 39648 88
sub_8039B64 39b64 164
sub_803A2C4 3a2c4 e4
sub_803A3A8 3a3a8 34
sub_803A4E0 3a4e0 40
sub_803ADE8 3ade8 190
sub_803AF78 3af78 1ac
sub_803C434 3c434 84
sub_803F324 3f324 54
sub_803F378 3f378 ec
sub_803FBBC 3fbbc 3e
sub_803FBFC 3fbfc 38
sub_803FC34 3fc34 24
sub_803FC58 3fc58 1c
sub_8040574 40574 164
sub_80408BC 408bc 1a
sub_8040A54 40a54 28
sub_8040D08 40d08 34
sub_8043740 43740 19e
sub_8043CEC 43cec 70 15
sub_8043D5C 43d5c 28 15
sub_8043E50 43e50 20 15
sub_8043F44 43f44 7c
sub_8043FC0 43fc0 12c
sub_8044210 44210 128 15
sub_804454C 4454c 2b8
sub_8044CA0 44ca0 1d4
sub_8044E74 44e74 58 15
sub_8044ECC 44ecc a4 15
sub_8044F70 44f70 c0 15
sub_8045030 45030 18 15
sub_8045048 45048 34 15
sub_804507C 4507c 94 15
sub_8045110 45110 70 15
sub_8045180 45180 20
sub_80451A0 451a0 2b8
sub_8045458 45458 e8 15
sub_80457E8 457e8 c6 15
sub_80458B0 458b0 e8
sub_8045998 45998 c4
sub_8045D58 45d58 200 15
sub_8045F58 45f58 d2 15
sub_80460C8 460c8 60
sub_8046128 46128 60 15
sub_8046234 46234 154
sub_8046388 46388 44 200
sub_80463CC 463cc 34
sub_80466E8 466e8 c 155
sub_80466F4 466f4 6c 155
sub_8046760 46760 96 155
sub_80467F8 467f8 54 155
sub_804684C 4684c f8 155
sub_8046944 46944 40 155
sub_8046984 46984 14c 155
sub_8046AD0 46ad0 1a8 155
sub_8046C78 46c78 204 155
sub_8046E7C 46e7c 20 155
sub_8046E9C 46e9c 120 155
sub_8046FBC 46fbc b8 155
sub_80472B0 472b0 28 155
sub_80472D8 472d8 18 155
sub_80473D0 473d0 ba 155
sub_804748C 4748c f2 155
sub_8047580 47580 b8
sub_8047638 47638 a6 155
sub_80476E0 476e0 72 155
sub_8047754 47754 1c 155
sub_804780C 4780c 24 155
sub_8047830 47830 28 155
sub_8047CD8 47cd8 10
sub_8047CE8 47ce8 70 223
sub_8047D58 47d58 ec 223
sub_8047E44 47e44 7c 223
sub_8047EC0 47ec0 634 223
sub_80484F4 484f4 500 223
sub_80489F4 489f4 20 223
sub_8048A14 48a14 3c
sub_8048A50 48a50 40
sub_8048A90 48a90 24
sub_8048AB4 48ab4 58 223
sub_8048B0C 48b0c 164 223
sub_8048C70 48c70 b0 223
sub_8048D44 48d44 342 223
sub_8049088 49088 34 223
sub_80490BC 490bc 128 223
sub_80491E4 491e4 f4 223
sub_80492D8 492d8 200 223
sub_80494D8 494d8 3a 223
sub_8049514 49514 4c 223
sub_8049620 49620 5e 223
sub_8049680 49680 184 223
sub_8049804 49804 5c 223
sub_8049860 49860 f2 223
sub_8049954 49954 28 223
sub_804997C 4997c 74 223
sub_80499F0 499f0 30 223
sub_8049A20 49a20 a0 223
sub_8049AC0 49ac0 100 223
sub_8049BC0 49bc0 ca 223
sub_8049C8C 49c8c 38 223
sub_8049CC4 49cc4 2c 223
sub_8049D44 49d44 58 223
sub_8049D9C 49d9c 28 223
sub_8049DC4 49dc4 1c 223
sub_8049DE0 49de0 bc 223
sub_8049E9C 49e9c 38 223
sub_8049ED4 49ed4 3e0 223
sub_804A2B4 4a2b4 88
sub_804A33C 4a33c e0
sub_804A41C 4a41c 100 223
sub_804A51C 4a51c 1c0
sub_804A6DC 4a6dc 64 223
sub_804A740 4a740 cc 223
sub_804A80C 4a80c 34 223
sub_804A840 4a840 f8 223
sub_804A938 4a938 6 223
sub_804A940 4a940 22 223
sub_804A964 4a964 8 223
sub_804A96C 4a96c 88 223
sub_804A96C_alt 4a96c 88 223
sub_804A9F4 4a9f4 a 223
sub_804AA00 4aa00 a 223
sub_804AA0C 4aa0c 7c 223
sub_804AA88 4aa88 54 223
sub_804AADC 4aadc 54 223
sub_804AB30 4ab30 c8 223
sub_804ABF8 4abf8 e0 223
sub_804ACD8 4acd8 1c 223
sub_804ACF4 4acf4 148 223
sub_804AE3C 4ae3c d4 223
sub_804AF10 4af10 74 223
sub_804AF84 4af84 34 223
sub_804AFB8 4afb8 a0 223
sub_804B058 4b058 22 223
sub_804B07C 4b07c 40 223
sub_804B0BC 4b0bc 22 223
sub_804B0E0 4b0e0 22 223
sub_804B104 4b104 22 223
sub_804B128 4b128 94 223
sub_804B1BC 4b1bc 54 223
sub_804B210 4b210 16 223
sub_804B228 4b228 24 223
sub_804B24C 4b24c 62
sub_804B2B0 4b2b0 20 223
sub_804B2D0 4b2d0 14c 223
sub_804B41C 4b41c 374
sub_804B790 4b790 288
sub_804BA18 4ba18 4c 223
sub_804BA64 4ba64 30 223
sub_804BA94 4ba94 e4 223
sub_804BB78 4bb78 54 223
sub_804BBCC 4bbcc 1a 223
sub_804BBE8 4bbe8 510 223
sub_804C0F8 4c0f8 6c 223
sub_804C164 4c164 44 223
sub_804C29C 4c29c 12ec 223
sub_804D588 4d588 b4 223
sub_804D63C 4d63c 80 223
sub_804D6BC 4d6bc 7c 223
sub_804D738 4d738 74 223
sub_804D7AC 4d7ac 60 223
sub_804D80C 4d80c 90 223
sub_804D8E4 4d8e4 64 223
sub_804DAD4 4dad4 58 223
sub_804DB84 4db84 94
sub_804DC18 4dc18 70 223
sub_804DC88 4dc88 4bc 223
sub_804E144 4e144 30 223
sub_804E1A0 4e1a0 3c 223
sub_804E1DC 4e1dc 50 223
sub_804E22C 4e22c 64
sub_804E2EC 4e2ec 210 25
sub_804E4FC 4e4fc 3c 25
sub_804E56C 4e56c 1cc 25
sub_804E738 4e738 5c
sub_804E794 4e794 2c
sub_804E7C0 4e7c0 84 25
sub_804E990 4e990 68
sub_804E9F8 4e9f8 6fc 25
sub_804F0F4 4f0f4 78 25
sub_804F16C 4f16c 4e 25
sub_804F1BC 4f1bc 7c 25
sub_804F238 4f238 70 25
sub_804F2A8 4f2a8 d0 25
sub_804F378 4f378 4a4 25
sub_804F81C 4f81c 28 25
sub_804F844 4f844 4c 25
sub_804F890 4f890 38 25
sub_804F8C8 4f8c8 12c 25
sub_804F9F4 4f9f4 128 25
sub_804FB1C 4fb1c 12c 25
sub_804FC48 4fc48 e8 25
sub_804FD30 4fd30 140 25
sub_804FE70 4fe70 238 25
sub_80500A8 500a8 154 25
sub_80501FC 501fc a8 25
sub_80502A4 502a4 54 25
sub_80504F0 504f0 c 25
sub_8050508 50508 c 25
sub_8050760 50760 174
sub_80508D4 508d4 28 25
sub_80508FC 508fc 58 25
sub_8050954 50954 394 25
sub_8050CE8 50ce8 148
sub_8050E30 50e30 2b8 25
sub_80510E8 510e8 154 25
sub_805123C 5123c 1d8 25
sub_8051414 51414 60 25
sub_8051474 51474 30 25
sub_80514A4 514a4 4c 25
sub_80514F0 514f0 34 25
sub_8051524 51524 48
sub_805156C 5156c e4 25
sub_8051650 51650 32 25
sub_8051684 51684 40
sub_805181C 5181c b0 25
sub_80518CC 518cc 80 25
sub_805194C 5194c 30 25
sub_805197C 5197c a0 25
sub_8051A1C 51a1c 20 25
sub_8051A3C 51a3c 8c 25
sub_8051AC8 51ac8 2a 25
sub_8051AF4 51af4 24 25
sub_8051B18 51b18 28 25
sub_8051B40 51b40 4a 25
sub_8051B8C 51b8c 76 25
sub_8051C04 51c04 20 25
sub_80527BC 527bc 15c 25
sub_8052918 52918 1e0 25
sub_8052AF8 52af8 1a 25
sub_8052BD0 52bd0 58 25
sub_8052E4C 52e4c 20
sub_805308C 5308c 20 148
sub_8053538 53538 36
sub_80535C4 535c4 78
sub_805363C 5363c 3c
sub_8053678 53678 18
sub_8053778 53778 18
sub_80537CC 537cc 3c
sub_8053994 53994 a8
sub_8053D14 53d14 1c
sub_8053F0C 53f0c 76
sub_80543DC 543e0 c
sub_8054534 54538 54
sub_8054588 5458c 24
sub_805465C 54660 40
sub_80546B8 546bc 1c
sub_80546F0 546f4 1c
sub_805470C 54710 28
sub_805483C 54840 100 148
sub_805493C 54940 110
sub_8054A4C 54a50 50
sub_8054A9C 54aa0 f2
sub_8054BA8 54bac 84
sub_8054C2C 54c30 28
sub_8054D4C 54d50 44
sub_8054D90 54d94 28
sub_8054E20 54e24 12
sub_8054E34 54e38 2c
sub_8054E60 54e64 1c
sub_8054E7C 54e80 1c
sub_8054E98 54e9c 30
sub_8054EC8 54ecc 80
sub_8054F48 54f4c 28
sub_8054F70 54f74 18
sub_8054F88 54f8c 36
sub_8054FC0 54fc4 36
sub_8054FF8 54ffc 220
sub_8055218 5521c 68
sub_8055280 55284 30
sub_80552B0 552b4 5c
sub_805530C 55310 34
sub_8055340 55344 12
sub_8055354 55358 3c
sub_8055390 55394 50
sub_80553E0 553e4 4
sub_80553E4 553e8 24
sub_8055408 5540c 30
sub_8055438 5543c 30
sub_8055468 5546c 4
sub_805546C 55470 36
sub_80554A4 554a8 14
sub_80554B8 554bc 4
sub_80554BC 554c0 28
sub_80554E4 554e8 14
sub_80554F8 554fc 6e
sub_8055574 55578 14
sub_8055588 5558c 14
sub_805559C 555a0 14
sub_80555B0 555b4 68
sub_8055618 5561c 16
sub_8055630 55634 16
sub_8055648 5564c 18
sub_8055660 55664 2c
sub_805568C 55690 ca
sub_8055758 5575c 8e 148
sub_80557E8 557ec a
sub_80557F4 557f8 14
sub_8055808 5580c 1a 148
sub_8055824 55828 1c
sub_8055840 55844 1a 148
sub_805585C 55860 14
sub_8055870 55874 3c
sub_80558AC 558b0 62
sub_8055910 55914 2e
sub_8055940 55944 14
sub_8055AE8 55aec 20
sub_8055B08 55b0c 28
sub_8055B30 55b34 20
sub_8055B50 55b54 24
sub_8055BFC 55c00 6c
sub_8055C68 55c6c 20 148
sub_8055C88 55c8c 4 148
sub_8055C8C 55c90 20 148
sub_8055CAC 55cb0 4 148
sub_8055CB0 55cb4 68 148
sub_8055D18 55d1c 18 148
sub_8055D30 55d34 6 148
sub_8055D38 55d3c 36 148
sub_8057A58 57a5c bc
sub_8057B14 57b18 2c
sub_8058464 58468 62 68
sub_8058854 58858 52 73
sub_8058D0C 58d10 a8 73
sub_8058EF0 58ef4 58 73
sub_8058F6C 58f70 aa 73
sub_8059204 59208 44
sub_80592A4 592a8 22 73
sub_8059348 5934c 28 73
sub_80594C0 594c4 44
sub_80595DC 595e0 24
sub_8059600 59604 18
sub_8059618 5961c 18
sub_8059630 59634 18
sub_80597D0 597d4 c
sub_80597E8 597ec a
sub_80597F4 597f8 48
sub_8059B88 59b8c 6c
sub_8059BF4 59bf8 48
sub_8059C3C 59c40 58 73
sub_8059C94 59c98 74
sub_8059D08 59d0c 58
sub_8059D60 59d64 90 73
sub_8059E84 59e88 20 73
sub_8059F40 59f44 54 73
sub_805A20C 5a210 58 73
sub_805A2D0 5a2d4 78 73
sub_805B410 5b414 14c
sub_805B710 5b714 4c
sub_805B75C 5b760 1b8
sub_805B914 5b918 38 63
sub_805BCC0 5bcc4 30
sub_805BCF0 5bcf4 58
sub_805BD48 5bd4c 48
sub_805BD90 5bd94 54
sub_805BDF8 5bdfc 2c
sub_805BE58 5be5c 26 63
sub_805C058 5c05c a0
sub_805C0F8 5c0fc 54
sub_805FE28 5fe2c 3c
sub_805FE64 5fe68 2c
sub_8060288 6028c 4c
sub_8060388 6038c 44
sub_80603CC 603d0 a4
sub_8060470 60474 4a
sub_8060E68 60e6c 70
sub_8060ED8 60edc 2c
sub_806113C 61140 bc
sub_806123C 61240 c2
sub_8061300 61304 14
sub_8061314 61318 14
sub_8061328 6132c 18
sub_8061340 61344 18
sub_8061358 6135c 4e
sub_8061508 6150c 8
sub_80616CC 616d0 48
sub_8061F5C 61f60 32
sub_806295C 62960 40
sub_8062B8C 62b90 42
sub_80630D0 630d4 36
sub_8063208 6320c 30
sub_8063338 6333c 36
sub_806467C 64680 e
sub_806468C 64690 3a
sub_80646C8 646cc 1c
sub_80646E4 646e8 1e
sub_8064704 64708 88
sub_806478C 64790 94
sub_8064CDC 64ce0 20
sub_8064CFC 64d00 22
sub_8064D38 64d3c 7c
sub_8064DB4 64db8 22
sub_8064EAC 64eb0 28
sub_8064ED4 64ed8 20
sub_8067B48 67b4c 1e 182
sub_8068C30 68c34 78 67
sub_80695E0 695e4 56
sub_8069638 6963c 88
sub_80696C0 696c4 24
sub_80696E4 696e8 24
sub_8069708 6970c 24
sub_806972C 69730 9a
sub_80697C8 697cc 9a
sub_80699D8 699dc 64
sub_8069A3C 69a40 64
sub_8069CB8 69cbc 42
sub_8069CFC 69d00 38
sub_8069D34 69d38 44
sub_806A040 6a044 3c
sub_806B4A8 6b4ac 80
sub_806B908 6b90c 9c
sub_806B9A4 6b9a8 90 150
sub_806BA34 6ba38 60
sub_806BA94 6ba98 a8 150
sub_806BB3C 6bb40 60
sub_806BB9C 6bba0 50 150
sub_806BBEC 6bbf0 50 150
sub_806BCE8 6bcec 70
sub_806BD58 6bd5c 28
sub_806BF24 6bf28 50 150
sub_806C92C 6c930 68
sub_806C994 6c998 30
sub_806C9C4 6c9c8 3c
sub_806CA00 6ca04 18 150
sub_806CA18 6ca1c 20 150
sub_806CA38 6ca3c 28
sub_806CC2C 6cc30 48
sub_806CC74 6cc78 70
sub_806CCE4 6cce8 60
sub_806CD44 6cd48 18
sub_806CD5C 6cd60 19c
sub_806CF04 6cf08 9c
sub_806CFA0 6cfa4 74
sub_806D014 6d018 48 150
sub_806D05C 6d060 3c 150
sub_806D098 6d09c 80
sub_806D118 6d11c 44 150
sub_806D15C 6d160 3c 150
sub_806D198 6d19c 1e4 150
sub_806D3B4 6d3b8 f8
sub_806D4AC 6d4b0 60
sub_806D50C 6d510 2c
sub_806D5B8 6d5bc b0 150
sub_806D668 6d66c b0
sub_806E8D0 6e8d4 34
sub_806F2FC 6f300 5c
sub_806F358 6f35c 38
sub_806F390 6f394 6a
sub_806F3FC 6f400 50
sub_806F44C 6f450 44
sub_806F7E8 6f7ec c4
sub_806F8AC 6f8b0 16c
sub_806FA18 6fa1c f4
sub_806FB0C 6fb10 38
sub_806FB44 6fb48 38
sub_8070088 7008c 154
sub_80701DC 701e0 108
sub_8070D90 70d94 2c 150
sub_80712B4 712b8 5c
sub_8071310 71314 28
sub_807160C 71610 24 205
sub_8071700 71704 e 205
sub_80719F0 719f4 a 205
sub_80719FC 71a00 12a 205
sub_8071B28 71b2c 2c
sub_8071B54 71b58 e 205
sub_8071F40 71f44 20
sub_8071F60 71f64 38
sub_8072484 72488 70 132
sub_80724F4 724f8 12a 132
sub_8072620 72624 12c 132
sub_807274C 72750 80
sub_8072A18 72a1c 44
sub_8072AB0 72ab4 9c
sub_8072D18 72d1c 28 132
sub_8072DCC 72dd0 e
sub_8072DDC 72de0 e
sub_8072E74 72e78 48
sub_8072ED0 72ed4 a
sub_8072EDC 72ee0 70
sub_8073014 73018 44 220
sub_8073058 7305c 18 220
sub_8073070 73074 28 220
sub_8073098 7309c 28 220
sub_80730C0 730c4 28 220
sub_80730E8 730ec 28 220
sub_8073424 73428 7a 220
sub_80734A0 734a4 72 220
sub_8073514 73518 2a 220
sub_8073540 73544 72 220
sub_80735B4 735b8 2e 220
sub_80735E4 735e8 1c 220
sub_8073600 73604 1a 220
sub_807361C 73620 28 220
sub_8073644 73648 48 220
sub_807368C 73690 28 220
sub_80736B4 736b8 28 220
sub_80736DC 736e0 28 220
sub_8073704 73708 a0 220
sub_80737A4 737a8 3c 220
sub_80737E0 737e4 28 220
sub_8073808 7380c 28 220
sub_8073830 73834 38 220
sub_8073868 7386c 28 220
sub_8073890 73894 18 220
sub_80738A8 738ac 18 220
sub_80738C0 738c4 2a 220
sub_80738EC 738f0 18 220
sub_8073904 73908 28 220
sub_807392C 73930 48 220
sub_8073974 73978 28 220
sub_807399C 739a0 28 220
sub_80739C4 739c8 28 220
sub_80739EC 739f0 28 220
sub_8076380 76384 7c 6
sub_80763FC 76400 68
sub_8076464 76468 120
sub_807672C 76730 98 6
sub_80769A4 769a8 98 6
sub_8077104 77108 28
sub_8077BFC 77c00 1dc
sub_8077DD8 77ddc 6c
sub_8077EE4 77ee8 84
sub_8077F7C 77f80 42
sub_8077FC0 77fc4 a8
sub_8078114 78118 60
sub_8078174 78178 7c
sub_8078278 7827c 60
sub_80782F8 782fc 1c
sub_8078314 78318 4e
sub_8078394 78398 3a
sub_80783D0 783d4 42
sub_8078504 78508 6e
sub_80785E4 785e8 1a
sub_8078600 78604 1a
sub_807861C 78620 18
sub_8078634 78638 1c
sub_8078650 78654 2c
sub_807867C 78680 6e
sub_8078764 78768 4c
sub_8078914 78918 40
sub_8078954 78958 68
sub_80789BC 789c0 16
sub_80789D4 789d8 60
sub_8078A34 78a38 28
sub_8078BD4 78bd8 2c
sub_8078C00 78c04 28
sub_8078C28 78c2c 98
sub_8078CC0 78cc4 28
sub_8078CE8 78cec 5a
sub_8078D44 78d48 1a
sub_8078D60 78d64 2c
sub_8078D8C 78d90 28
sub_8078E38 78e3c 38
sub_8078F40 78f44 5c
sub_8078F9C 78fa0 40
sub_8078FDC 78fe0 bc
sub_8079098 7909c 3e
sub_8079108 7910c a0
sub_80791A8 791ac 116
sub_80792C0 792c4 e8
sub_80793A8 793ac 6
sub_80793C4 793c8 58
sub_80794A8 794ac 70
sub_8079518 7951c 1a
sub_8079534 79538 b0
sub_8079670 79674 88
sub_80796F8 796fc 98
sub_80798AC 798b0 48
sub_8079A64 79a68 54
sub_8079AB8 79abc 58
sub_8079B10 79b14 e2
sub_8079BF4 79bf8 8
sub_8079BFC 79c00 a
sub_8079C08 79c0c 6a
sub_8079C74 79c78 78
sub_8079CEC 79cf0 34
sub_8079F44 79f48 1b0
sub_807A4A0 7a4a4 a4
sub_807A544 7a548 80
sub_807A5C4 7a5c8 78
sub_807A63C 7a640 60
sub_807A69C 7a6a0 e8
sub_807A784 7a788 cc
sub_807A850 7a854 84
sub_807A8D4 7a8d8 34
sub_807A908 7a90c 58
sub_807A960 7a964 5a
sub_807A9BC 7a9c0 6c
sub_807B06C 7b070 28 168
sub_807B184 7b188 384 168
sub_807B508 7b50c 194 168
sub_807B7E0 7b7e4 90 10
sub_807B870 7b874 34 10
sub_807B8A4 7b8a8 7a 10
sub_807B920 7b924 b8
sub_807B9D8 7b9dc 4c 10
sub_807BA24 7ba28 b0 10
sub_807BAD4 7bad8 50 10
sub_807BB24 7bb28 64 10
sub_807BB88 7bb8c 1d4
sub_807BDAC 7bdb0 54 10
sub_807C988 7c988 2c
sub_807C9B4 7c9b4 30
sub_807D5BC 7d5bc 34
sub_807D5F0 7d5f0 54
sub_807DA04 7da04 10
sub_807DA14 7da14 38
sub_807DA4C 7da4c 118
sub_807E0A0 7e0a0 54
sub_807E0F4 7e0f4 1c
sub_807E25C 7e25c 14
sub_807E4EC 7e4ec d4
sub_807E5C0 7e5c0 102
sub_807E6C4 7e6c4 2a
sub_807E6F0 7e6f0 b4
sub_807E8E8 7e8e8 8c
sub_807EC40 7ec40 ac
sub_807ECEC 7ecec 5c
sub_807ED48 7ed48 138
sub_807FAA8 7faa8 7c
sub_807FC9C 7fc9c 94
sub_808002C 8002c 38
sub_8080064 80064 80
sub_80800E4 800e4 94
sub_8080588 80588 88
sub_8080610 80610 44
sub_8080750 80750 12
sub_8080958 80958 16
sub_8080990 80990 20
sub_80809B0 809b0 1c
sub_8080A3C 80a3c 20
sub_8080A5C 80a5c 66
sub_8080AC4 80ac4 20
sub_8080AE4 80ae4 64
sub_8080B60 80b60 16
sub_8080B78 80b78 24
sub_8080B9C 80b9c 118
sub_8080DC4 80dc4 28
sub_8080DEC 80dec 18
sub_8080E28 80e28 1c
sub_8080E44 80e44 20
sub_8080E70 80e70 18
sub_8080E88 80e88 38
sub_8080EF0 80ef0 24
sub_8080F2C 80f2c 1a
sub_8080F48 80f48 10
sub_8080F58 80f58 10
sub_8080F68 80f68 34
sub_8080F9C 80f9c 28
sub_8081050 81050 8c
sub_80810DC 810dc 14
sub_808115C 8115c 16c
sub_80812C8 812c8 6c
sub_8081334 81334 38
sub_80814E8 814e8 28 75
sub_8081510 81510 24 75
sub_8081534 81534 5e 75
sub_8081594 81594 4c
sub_808161C 8161c 3c 75
sub_8081658 81658 4e 75
sub_80816A8 816a8 1fc 75
sub_80818A4 818a4 56
sub_80818FC 818fc 28
sub_8081924 81924 18
sub_8082CD4 82cd4 44 36
sub_8082D18 82d18 34 36
sub_8082D4C 82d4c 12 36
sub_8082D60 82d60 3a 36
sub_8082D9C 82d9c 58 36
sub_8082DF4 82df4 34 36
sub_8082E28 82e28 44 36
sub_8082E6C 82e6c 4c 36
sub_8082EB8 82eb8 34 36
sub_8082F20 82f20 48 36
sub_8082F68 82f68 84 36
sub_8082FEC 82fec 50 36
sub_808303C 8303c a8 36
sub_80830E4 830e4 a4 36
sub_8083188 83188 70 36
sub_80831F8 831f8 90 36
sub_8083288 83288 8c 36
sub_8083314 83314 b0 36
sub_80833C4 833c4 28 36
sub_80833EC 833ec 2c 36
sub_8083418 83418 2c 36
sub_8083444 83444 38 36
sub_808347C 8347c 68
sub_80834E4 834e4 28
sub_808350C 8350c 30
sub_808353C 8353c 9c 36
sub_80835D8 835d8 3c
sub_8083614 83614 28
sub_808363C 8363c 28
sub_8083664 83664 ac
sub_8083710 83710 50 36
sub_8083760 83760 54 36
sub_80837B4 837b4 38 36
sub_80837EC 837ec 34 36
sub_8083820 83820 a
sub_808382C 8382c 12c 36
sub_8083958 83958 4c 36
sub_80839A4 839a4 2c
sub_80839D0 839d0 a
sub_80839DC 839dc a8 36
sub_8083A84 83a84 28
sub_8083AAC 83aac 98 36
sub_8083B44 83b44 18 36
sub_8083B5C 83b5c 10
sub_8083B6C 83b6c 14 36
sub_8083B80 83b80 e
sub_8083B90 83b90 20
sub_8083BDC 83bdc 18
sub_8083BF4 83bf4 5c
sub_8083C50 83c50 54
sub_8083CA4 83ca4 24 36
sub_8083D4C 83d4c 22
sub_80842C8 842c8 34 225
sub_80842FC 842fc 40 225
sub_8084394 84394 4 225
sub_8084398 84398 44 225
sub_80843DC 843dc 3e 225
sub_808441C 8441c 5a 225
sub_8084478 84478 bc 225
sub_8084534 84534 44 225
sub_8084578 84578 34 225
sub_80845AC 845ac 1c 225
sub_80845C8 845c8 34 225
sub_80845FC 845fc 58 225
sub_8084654 84654 74 225
sub_80846C8 846c8 1c 225
sub_80846E4 846e4 ae
sub_8084794 84794 34
sub_8084894 84894 4c 225
sub_80865BC 865bc 20
sub_8086748 86748 2c
sub_8086774 86774 38
sub_80867AC 867ac a8
sub_8086854 86854 1c
sub_8086870 86870 74
sub_80868E4 868e4 b8
sub_808699C 8699c 1c
sub_80869B8 869b8 3e
sub_80869F8 869f8 34
sub_8086A2C 86a2c 3c
sub_8086A68 86a68 38
sub_8086AA0 86aa0 20
sub_8086AC0 86ac0 70
sub_8086B30 86b30 22
sub_8086B54 86b54 10
sub_8086B64 86b64 22
sub_8086B88 86b88 10
sub_8086B98 86b98 4c
sub_8086BE4 86be4 4c
sub_8086C30 86c30 e
sub_8086C40 86c40 54
sub_8086C94 86c94 28
sub_8086CBC 86cbc 38
sub_8086CF4 86cf4 7a
sub_8086D70 86d70 40
sub_8086DB0 86db0 60
sub_8086E10 86e10 40
sub_8086E50 86e50 60
sub_8086EB0 86eb0 24
sub_8086ED4 86ed4 58
sub_8086F64 86f64 4c
sub_8086FB0 86fb0 20
sub_8087030 87030 26
sub_8087058 87058 58
sub_8087124 87124 14
sub_80871B8 871b8 18
sub_80871D0 871d0 5c
sub_808722C 8722c 38
sub_8087264 87264 34
sub_8087298 87298 4c
sub_80872E4 872e4 f4
sub_80873D8 873d8 1a
sub_80873F4 873f4 54
sub_8087470 87470 5c
sub_80874CC 874cc 30
sub_80874FC 874fc 4c
sub_8087548 87548 54
sub_808759C 8759c 38
sub_8087638 87638 1c
sub_8087654 87654 18
sub_808766C 8766c 5c
sub_80876C8 876c8 30
sub_80876F8 876f8 7c
sub_8087774 87774 38
sub_80877AC 877ac 26
sub_80877D4 877d4 54
sub_808788C 8788c 1c
sub_8087A74 87a74 30
sub_8087AA4 87aa4 24
sub_8087AC8 87ac8 e0
sub_8087E1C 87e1c 30
sub_8087E4C 87e4c 8c
sub_8087ED8 87ed8 102
sub_8087FDC 87fdc 8c
sub_8088120 88120 30
sub_8088150 88150 70
sub_80881C0 881c0 68
sub_8088228 88228 8c
sub_80882B4 882b4 30
sub_80882E4 882e4 54
sub_8088338 88338 48
sub_8088380 88380 5c
sub_80883DC 883dc 60
sub_808843C 8843c 40
sub_808847C 8847c 30
sub_80884AC 884ac 3c
sub_80884E8 884e8 6c
sub_8088554 88554 54
sub_80885A8 885a8 30
sub_80885D8 885d8 34
sub_808860C 8860c 20
sub_808862C 8862c 84
sub_80886B0 886b0 48
sub_80886F8 886f8 e
sub_8088708 88708 b8
sub_80887C0 887c0 70
sub_8088830 88830 60
sub_8088890 88890 44
sub_80888D4 888d4 1c
sub_80888F0 888f0 22
sub_8088954 88954 30
sub_8088984 88984 60
sub_80889E4 889e4 4c
sub_8088A30 88a30 48
sub_8088A78 88a78 7c
sub_8088AF4 88af4 74
sub_8088BC4 88bc4 7c
sub_8088C70 88c70 30
sub_8088CA0 88ca0 58
sub_8088CF8 88cf8 44
sub_8088D3C 88d3c 58
sub_8088D94 88d94 44
sub_8088DD8 88dd8 54
sub_8088E2C 88e2c 88
sub_8088EB4 88eb4 5c
sub_8088F10 88f10 20
sub_8088F30 88f30 30
sub_8088F60 88f60 44
sub_8088FA4 88fa4 1c
sub_8088FC0 88fc0 3c
sub_8088FFC 88ffc 1c
sub_8089018 89018 c0
sub_80890D8 890d8 74
sub_808914C 8914c e4
sub_8089230 89230 2c
sub_8089270 89270 30
sub_80892A0 892a0 b4
sub_8089354 89354 6c
sub_80893C0 893c0 54
sub_8089414 89414 78
sub_808948C 8948c 38
sub_80894C4 894c4 38
sub_8089A70 89a70 1c
sub_8089A8C 89a8c 150 160
sub_8089BDC 89bdc 74 160
sub_8089C50 89c50 2c
sub_8089C7C 89c7c 58 160
sub_8089D94 89d94 b6 160
sub_8089E4C 89e4c 38 160
sub_8089E84 89e84 38 160
sub_8089EBC 89ebc 58 160
sub_8089F14 89f14 30 160
sub_8089F44 89f44 88 160
sub_808A060 8a060 a0 160
sub_808A100 8a100 40 160
sub_808A180 8a180 60 160
sub_808A1E0 8a1e0 48 160
sub_808A228 8a228 84 160
sub_808A2AC 8a2ac 30 160
sub_808A2DC 8a2dc 54 160
sub_808A330 8a330 1c 160
sub_808A34C 8a34c a 160
sub_808A358 8a358 4c 160
sub_808A3A4 8a3a4 52 160
sub_808A3F8 8a3f8 dc
sub_808A4D4 8a4d4 4c 160
sub_808A520 8a520 9c
sub_808A5BC 8a5bc 48 160
sub_808A604 8a604 2c 160
sub_808A678 8a678 e 160
sub_808A73C 8a73c d4 160
sub_808A848 8a848 60 160
sub_808A8A8 8a8a8 2c 160
sub_808A8D4 8a8d4 44 160
sub_808AAF0 8aaf0 44 160
sub_808AB34 8ab34 5c 160
sub_808ABF4 8abf4 38 160
sub_808AC2C 8ac2c 1c 160
sub_808AC8C 8ac8c 1c 160
sub_808AD0C 8ad0c 4c 160
sub_808AD58 8ad58 30
sub_808ADAC 8adac 1c 160
sub_808AE08 8ae08 1c 160
sub_808AE8C 8ae8c 94 160
sub_808AF20 8af20 60 160
sub_808AF80 8af80 9e 160
sub_808B020 8b020 a0
sub_808B0C0 8b0c0 12c
sub_808B1EC 8b1ec 38 160
sub_808B224 8b224 38 160
sub_808B25C 8b25c 2c 160
sub_808B288 8b288 2c 160
sub_808B2B4 8b2b4 38 160
sub_808B2EC 8b2ec 4a 160
sub_808B338 8b338 68 160
sub_808B3A0 8b3a0 4c 160
sub_808B3EC 8b3ec b8 160
sub_808B4A4 8b4a4 48 160
sub_808B4EC 8b4ec 1c 160
sub_808B508 8b508 e
sub_808B518 8b518 4c 160
sub_808B564 8b564 50
sub_808B5B4 8b5b4 30
sub_808B5E4 8b5e4 2c 160
sub_808F284 8f284 2c 158
sub_808FA00 8fa00 64 158
sub_8090644 90644 c8 158
sub_809070C 9070c 44
sub_8090750 90750 2ec 158
sub_8090A3C 90a3c 150 158
sub_8090B8C 90b8c 9c 158
sub_8090C28 90c28 40 158
sub_8090C68 90c68 d4 158
sub_8091458 91458 10c 158
sub_8091564 91564 1d2 158
sub_8093174 93174 c8 224
sub_809323C 9323c 16 224
sub_8093254 93254 58 224
sub_80934C4 934c4 18
sub_8093534 93534 1a 224
sub_8093550 93550 48 224
sub_8093598 93598 54 224
sub_80935EC 935ec 24 224
sub_8093610 93610 78 224
sub_8093688 93688 4c 224
sub_80937A4 937a4 16 224
sub_80937BC 937bc 1c 224
sub_80937D8 937d8 16 224
sub_80937F0 937f0 a 224
sub_8093800 93800 a 224
sub_8093F48 93f48 1c 224
sub_8093F64 93f64 1c 224
sub_8094958 94958 20
sub_8094978 94978 20
sub_8094998 94998 dc 18
sub_8094A74 94a74 f8 18
sub_8094B6C 94b6c b2
sub_8094C20 94c20 34
sub_8094C54 94c54 44
sub_8094C98 94c98 3a
sub_8094D60 94d60 50 18
sub_8094E20 94e20 2c
sub_8094E4C 94e4c c
sub_8095050 95050 c8 18
sub_8095904 95904 144
sub_8095C8C 95c8c 7c
sub_80961A8 961a8 30
sub_8096264 96264 ac
sub_8096310 96310 3c
sub_809634C 9634c e
sub_809635C 9635c a
sub_8096368 96368 68
sub_80963D0 963d0 1bc
sub_809658C 9658c 6c
sub_80965F8 965f8 34
sub_809662C 9662c 2e
sub_809665C 9665c 98
sub_80966F4 966f4 90
sub_8096784 96784 34
sub_80967DC 967dc 28
sub_8096804 96804 44
sub_8096848 96848 2c
sub_8096874 96874 e
sub_8096884 96884 11c
sub_80969A0 969a0 15c
sub_8096AFC 96afc 3c
sub_8096B38 96b38 24
sub_8096B5C 96b5c 84
sub_8096BF0 96bf0 78
sub_8096C68 96c68 1c
sub_8096C84 96c84 344
sub_8096FC8 96fc8 3c
sub_8097004 97004 74
sub_8097078 97078 230
sub_80972A8 972a8 54
sub_80972FC 972fc 54
sub_8097390 97390 dc
sub_809746C 9746c 128
sub_8097594 97594 1f4
sub_8097788 97788 5c
sub_80977E4 977e4 74
sub_8097858 97858 44
sub_809789C 9789c d8
sub_8097974 97974 f0
sub_8097A64 97a64 e0
sub_8097B44 97b44 5c
sub_8097BA0 97ba0 120
sub_8097CC0 97cc0 120
sub_8097DE0 97de0 64
sub_8097E44 97e44 2c
sub_8097E70 97e70 e8
sub_8097F58 97f58 60
sub_8097FB8 97fb8 64
sub_809801C 9801c 28
sub_8098090 98090 44
sub_80980D4 980d4 11c
sub_80981F0 981f0 c2
sub_80982B4 982b4 9c
sub_8098350 98350 b0
sub_8098400 98400 e8
sub_80984E8 984e8 38
sub_8098520 98520 80
sub_80985CC 985cc c4
sub_8098690 98690 58
sub_80986E8 986e8 28
sub_8098710 98710 24
sub_8098734 98734 4c
sub_8098780 98780 5c
sub_80987DC 987dc 30
sub_809880C 9880c 24
sub_8098830 98830 68
sub_8098A38 98a38 22
sub_8098A5C 98a5c 22
sub_8098A80 98a80 26
sub_8098AA8 98aa8 94
sub_8098BF0 98bf0 58
sub_8098D20 98d20 c0
sub_8098DE0 98de0 44 162
sub_8098E24 98e24 44 162
sub_8098E68 98e68 38 162
sub_8098EA0 98ea0 40 162
sub_8098EE0 98ee0 12c 162
sub_809900C 9900c a0
sub_80990AC 990ac 154
sub_8099200 99200 110
sub_8099310 99310 64
sub_8099374 99374 14
sub_8099388 99388 6c 162
sub_80993F4 993f4 8c 162
sub_8099480 99480 28
sub_80994A8 994a8 76
sub_8099520 99520 2c
sub_809954C 9954c 38
sub_8099584 99584 88
sub_809960C 9960c a4
sub_80996B0 996b0 6c
sub_809971C 9971c 100
sub_809981C 9981c bc
sub_80998D8 998d8 46
sub_8099920 99920 38
sub_8099958 99958 38
sub_8099990 99990 34
sub_80999C4 999c4 24 162
sub_8099BF8 99bf8 78
sub_8099C70 99c70 c4
sub_8099D34 99d34 5c
sub_8099D90 99d90 3a
sub_8099DCC 99dcc 3c
sub_8099E08 99e08 a8
sub_8099EB0 99eb0 a8
sub_809A1BC 9a1bc 80
sub_809A23C 9a23c 194
sub_809A3D0 9a3d0 1c8
sub_809A598 9a598 50
sub_809A5E8 9a5e8 34
sub_809A61C 9a61c 36
sub_809A654 9a654 7c
sub_809A6D0 9a6d0 c
sub_809A6DC 9a6dc 98
sub_809A774 9a774 9c
sub_809A810 9a810 50
sub_809A860 9a860 68
sub_809A8C8 9a8c8 d8
sub_809A9A0 9a9a0 84
sub_809AA24 9aa24 74
sub_809AA98 9aa98 34
sub_809AACC 9aacc be
sub_809AB8C 9ab8c 72
sub_809AC00 9ac00 13c
sub_809AD3C 9ad3c 58
sub_809AD94 9ad94 184
sub_809AF18 9af18 a0
sub_809AFB8 9afb8 b0
sub_809B068 9b068 58
sub_809B0C0 9b0c0 12
sub_809B0D4 9b0d4 c
sub_809B0E0 9b0e0 14
sub_809B0F4 9b0f4 c
sub_809B100 9b100 30
sub_809B130 9b130 20
sub_809B150 9b150 86
sub_809B1D8 9b1d8 74
sub_809B24C 9b24c d8
sub_809B324 9b324 32
sub_809B358 9b358 2a
sub_809B384 9b384 5c
sub_809B3E0 9b3e0 60
sub_809B440 9b440 a
sub_809B44C 9b44c 88
sub_809B548 9b548 44
sub_809B62C 9b62c 90
sub_809B6BC 9b6bc 20
sub_809B6DC 9b6dc 58
sub_809B734 9b734 2c
sub_809B760 9b760 4c
sub_809B7AC 9b7ac 28
sub_809B7D4 9b7d4 18c
sub_809B960 9b960 230
sub_809BB90 9bb90 30
sub_809BBC0 9bbc0 58
sub_809BC18 9bc18 fc
sub_809BD14 9bd14 28
sub_809BDD8 9bdd8 a8
sub_809BE80 9be80 3a
sub_809BEBC 9bebc 62
sub_809BF20 9bf20 c
sub_809BF2C 9bf2c 1c
sub_809BF48 9bf48 2c
sub_809BF74 9bf74 b4
sub_809C028 9c028 24
sub_809C04C 9c04c 418
sub_809C464 9c464 200
sub_809C664 9c664 1f6
sub_809C85C 9c85c e8
sub_809C944 9c944 fc
sub_809CA40 9ca40 4c
sub_809CA8C 9ca8c 22
sub_809CAB0 9cab0 c2
sub_809CB74 9cb74 20
sub_809CB94 9cb94 70
sub_809CC04 9cc04 184
sub_809CD88 9cd88 44
sub_809CDCC 9cdcc 20
sub_809CDEC 9cdec 60
sub_809CE4C 9ce4c 38
sub_809CE84 9ce84 ac
sub_809CF30 9cf30 ac
sub_809CFDC 9cfdc 14
sub_809CFF0 9cff0 44
sub_809D034 9d034 88
sub_809D0BC 9d0bc 48
sub_809D104 9d104 68
sub_809D16C 9d16c 58
sub_809D1C4 9d1c4 a8
sub_809D3A4 9d3a4 90
sub_809D4A8 9d4a8 4a
sub_809D510 9d510 a
sub_809D51C 9d51c 24
sub_809D580 9d580 34
sub_809D608 9d608 24
sub_809D844 9d844 16
sub_809D85C 9d85c 60
sub_809DA1C 9da1c 68
sub_809DA84 9da84 3be
sub_809DE44 9de44 1e 163
sub_809DE64 9de64 9c 163
sub_809E260 9e260 19c 163
sub_809E534 9e534 90 163
sub_809E7F0 9e7f0 4c
sub_809E83C 9e83c b4 163
sub_809E8F0 9e8f0 160 163
sub_809EB40 9eb40 84 163
sub_809EBC4 9ebc4 74 163
sub_809EC38 9ec38 23c
sub_809EE74 9ee74 25c
sub_809F0D0 9f0d0 64
sub_809F284 9f284 8a
sub_809F310 9f310 34
sub_809F344 9f344 42
sub_809F388 9f388 42
sub_809F3CC 9f3cc 70
sub_809F43C 9f43c 1bc
sub_809F5F8 9f5f8 42 163
sub_809F63C 9f63c 14 163
sub_809F650 9f650 14 163
sub_809F664 9f664 14 163
sub_809F814 9f814 1bc
sub_809F9D0 9f9d0 60 163
sub_809FA30 9fa30 c
sub_809FA94 9fa94 34
sub_809FAC8 9fac8 11c 163
sub_809FBE4 9fbe4 28 163
sub_809FE6C 9fe6c 14 163
sub_809FE80 9fe80 36 163
sub_80A0090 a0090 14 163
sub_80A00A4 a00a4 4e 163
sub_80A00F4 a00f4 68 163
sub_80A015C a015c 140 163
sub_80A029C a029c f4 163
sub_80A0390 a0390 2a 163
sub_80A03BC a03bc 34
sub_80A03F0 a03f0 36
sub_80A0428 a0428 44 163
sub_80A046C a046c 2c 163
sub_80A0498 a0498 34 163
sub_80A04CC a04cc b0 163
sub_80A057C a057c e8
sub_80A0958 a0958 d4 163
sub_80A0A2C a0a2c 64 163
sub_80A1048 a1048 288
sub_80A12D0 a12d0 64 163
sub_80A1334 a1334 154 163
sub_80A1488 a1488 76 163
sub_80A1500 a1500 154 163
sub_80A1654 a1654 76 163
sub_80A16CC a16cc 13c 163
sub_80A18C4 a18c4 20 163
sub_80A18E4 a18e4 34 163
sub_80A1918 a1918 38 163
sub_80A1950 a1950 3c 163
sub_80A1A30 a1a30 ec 163
sub_80A1B1C a1b1c 22 163
sub_80A1B40 a1b40 80 163
sub_80A1BC0 a1bc0 70 163
sub_80A1C30 a1c30 60 163
sub_80A1D18 a1d18 6c
sub_80A1D84 a1d84 48 163
sub_80A1DCC a1dcc 1c 163
sub_80A1DE8 a1de8 70 163
sub_80A2078 a2078 30 163
sub_80A20A8 a20a8 2c 163
sub_80A2178 a2178 20
sub_80A2198 a2198 48 185
sub_80A21E0 a21e0 14 185
sub_80A21F4 a21f4 6a 185
sub_80A2260 a2260 3a 185
sub_80A229C a229c 34 185
sub_80A22D0 a22d0 24 185
sub_80A22F4 a22f4 22 185
sub_80A2318 a2318 30 185
sub_80A2348 a2348 28 185
sub_80A2370 a2370 36 185
sub_80A23B8 a23b8 10 185
sub_80A23C8 a23c8 3e 185
sub_80A2490 a2490 74 185
sub_80A28A0 a28a0 52 87
sub_80A3118 a3118 1a 116
sub_80A3134 a3134 48 116
sub_80A34B4 a34b4 34 116
sub_80A34E8 a34e8 38
sub_80A362C a362c 58 116
sub_80A36B8 a36b8 5c 116
sub_80A3740 a3740 30 116
sub_80A3770 a3770 50 116
sub_80A37C0 a37c0 38 116
sub_80A37F8 a37f8 15c 116
sub_80A3954 a3954 18 116
sub_80A396C a396c 4c 116
sub_80A39B8 a39b8 2c 116
sub_80A39E4 a39e4 dc 116
sub_80A3D24 a3d24 1c 116
sub_80A3D40 a3d40 1a 116
sub_80A3D5C a3d5c b0 116
sub_80A3E0C a3e0c 60
sub_80A3E70 a3e70 20 116
sub_80A3E90 a3e90 64 116
sub_80A3EF4 a3ef4 5c 116
sub_80A3F50 a3f50 50 116
sub_80A3FA0 a3fa0 66
sub_80A4008 a4008 28 116
sub_80A4164 a4164 28
sub_80A418C a418c 48
sub_80A41D4 a41d4 a 116
sub_80A41E0 a41e0 7a 116
sub_80A425C a425c 54 116
sub_80A42B0 a42b0 d0 116
sub_80A4380 a4380 cc 116
sub_80A444C a444c fa 116
sub_80A4548 a4548 1b4 116
sub_80A46FC a46fc ec 116
sub_80A47E8 a47e8 fe 116
sub_80A48E8 a48e8 10 116
sub_80A48F8 a48f8 14 116
sub_80A4A98 a4a98 42 116
sub_80A4ADC a4adc 38 116
sub_80A4B14 a4b14 44 116
sub_80A4B58 a4b58 38 116
sub_80A4B90 a4b90 60 116
sub_80A4BF0 a4bf0 1b4 116
sub_80A4DA4 a4da4 32 116
sub_80A4DD8 a4dd8 b4 116
sub_80A4E8C a4e8c 80 116
sub_80A4F0C a4f0c 5c 116
sub_80A4F68 a4f68 a 116
sub_80A4F74 a4f74 154 116
sub_80A50C8 a50c8 1fa 116
sub_80A5350 a5350 7a 116
sub_80A53CC a53cc 2c 116
sub_80A53F8 a53f8 1c
sub_80A5414 a5414 1ec 116
sub_80A5600 a5600 1c4 116
sub_80A57C4 a57c4 c4 116
sub_80A5888 a5888 114 116
sub_80A5AAC a5aac 38 116
sub_80A5AE4 a5ae4 1a 116
sub_80A5B40 a5b40 38
sub_80A5BF8 a5bf8 2c 116
sub_80A5C24 a5c24 24 116
sub_80A5D04 a5d04 34
sub_80A5D38 a5d38 40 116
sub_80A5D78 a5d78 28 116
sub_80A5DA0 a5da0 58 116
sub_80A5DF8 a5df8 24 116
sub_80A5E1C a5e1c 44 116
sub_80A5E60 a5e60 30 116
sub_80A5E90 a5e90 e 116
sub_80A5EA0 a5ea0 72 116
sub_80A5F80 a5f80 2a 116
sub_80A6000 a6000 24 116
sub_80A6024 a6024 58 116
sub_80A61A8 a61a8 28 116
sub_80A61D0 a61d0 1c
sub_80A62D8 a62d8 28 116
sub_80A640C a640c 38 116
sub_80A6444 a6444 48 116
sub_80A648C a648c 94 116
sub_80A6520 a6520 28 116
sub_80A6548 a6548 2c 116
sub_80A6574 a6574 38 116
sub_80A65AC a65ac 6c 116
sub_80A6618 a6618 38 116
sub_80A6650 a6650 20 116
sub_80A6760 a6760 38 116
sub_80A683C a683c 34 116
sub_80A6870 a6870 34 116
sub_80A68A4 a68a4 28 116
sub_80A6940 a6940 38 116
sub_80A6978 a6978 24
sub_80A699C a699c 1c 116
sub_80A6A08 a6a08 28 116
sub_80A6A30 a6a30 1c
sub_80A6A84 a6a84 7c 116
sub_80A6B00 a6b00 64 116
sub_80A6B64 a6b64 7c 116
sub_80A6BE0 a6be0 8c 116
sub_80A6D98 a6d98 34 116
sub_80A6DCC a6dcc 24
sub_80A6DF0 a6df0 c8 116
sub_80A6EB8 a6eb8 124 116
sub_80A6FDC a6fdc 48 116
sub_80A7094 a7094 44
sub_80A7124 a7124 2a 116
sub_80A7150 a7150 4c 116
sub_80A7230 a7230 13a 116
sub_80A73C0 a73c0 30 116
sub_80A73F0 a73f0 a 116
sub_80A73FC a73fc e 116
sub_80A740C a740c 12 116
sub_80A7420 a7420 fc 116
sub_80A751C a751c c 116
sub_80A7528 a7528 44 116
sub_80A756C a756c 24 116
sub_80A7590 a7590 16 116
sub_80A75A8 a75a8 1c 116
sub_80A75C4 a75c4 20 116
sub_80A75E4 a75e4 4c 116
sub_80A7630 a7630 c 116
sub_80A763C a763c 3a 116
sub_80A7678 a7678 1c 116
sub_80A7694 a7694 c 116
sub_80A76A0 a76a0 16 116
sub_80A76B8 a76b8 18 116
sub_80A76D0 a76d0 18 116
sub_80A76E8 a76e8 24 116
sub_80A770C a770c c 116
sub_80A7768 a7768 c0 116
sub_80A7828 a7828 c 116
sub_80A7834 a7834 34 116
sub_80A7868 a7868 18 116
sub_80A7880 a7880 20 116
sub_80A78A0 a78a0 18 116
sub_80A78B8 a78b8 c 116
sub_80A78C4 a78c4 22 116
sub_80A78E8 a78e8 a 116
sub_80A78F4 a78f4 24 116
sub_80A7918 a7918 a 116
sub_80A7924 a7924 32 116
sub_80A7958 a7958 18 116
sub_80A7970 a7970 a 116
sub_80A797C a797c c 116
sub_80A7988 a7988 10 116
sub_80A7998 a7998 1c 116
sub_80A79B4 a79b4 38 116
sub_80A79EC a79ec a8 116
sub_80A7A94 a7a94 4e 116
sub_80A7AE4 a7ae4 2c 116
sub_80A7B28 a7b28 20 116
sub_80A7B48 a7b48 22 116
sub_80A7B6C a7b6c b4 116
sub_80A7C64 a7c64 3c 116
sub_80A7DD4 a7dd4 18
sub_80A7DEC a7dec 70
sub_80A7E5C a7e5c 20
sub_80A8488 a8488 78 8
sub_80A8818 a8818 d8 8
sub_80A88F0 a88f0 30 8
sub_80A8A80 a8a80 bc
sub_80A8B3C a8b3c 4c 8
sub_80A8E04 a8e04 f8
sub_80A8EFC a8efc dc
sub_80A8FD8 a8fd8 80 8
sub_80A9058 a9058 e4
sub_80A913C a913c e8 8
sub_80A9B78 a9b78 42 130
sub_80A9BE4 a9be4 38 130
sub_80A9C98 a9c98 28 130
sub_80A9CC0 a9cc0 1c 130
sub_80A9CDC a9cdc 1c 130
sub_80A9CF8 a9cf8 38 130
sub_80A9D30 a9d30 28 130
sub_80A9D58 a9d58 64 130
sub_80A9DBC a9dbc 1c 130
sub_80A9DD8 a9dd8 2c 130
sub_80A9E04 a9e04 38 130
sub_80A9E3C a9e3c 44 130
sub_80A9E80 a9e80 58 130
sub_80A9ED8 a9ed8 38 130
sub_80A9F10 a9f10 40 130
sub_80A9F50 a9f50 94 130
sub_80A9FE4 a9fe4 80 130
sub_80AA064 aa064 2c 130
sub_80AA090 aa090 7c 130
sub_80AA10C aa10c 174 130
sub_80AA280 aa280 c0
sub_80AA340 aa340 48 130
sub_80AA388 aa388 48 130
sub_80AA3D0 aa3d0 48 130
sub_80AA418 aa418 48 130
sub_80AA460 aa460 48 130
sub_80AA4A8 aa4a8 48 130
sub_80AA4F0 aa4f0 cc 130
sub_80AA5BC aa5bc 2c 130
sub_80AA5E8 aa5e8 2c
sub_80AA614 aa614 44 130
sub_80AA658 aa658 44
sub_80AA754 aa754 14c
sub_80AA8A0 aa8a0 26 130
sub_80AA8C8 aa8c8 10
sub_80AA8D8 aa8d8 10
sub_80AA8E8 aa8e8 10
sub_80AA8F8 aa8f8 10
sub_80AA908 aa908 28 130
sub_80AA930 aa930 44
sub_80AA974 aa974 44
sub_80AA9B8 aa9b8 44
sub_80AA9FC aa9fc 44
sub_80AAA40 aaa40 44
sub_80AAA84 aaa84 44
sub_80AAAC8 aaac8 28 130
sub_80AAAF0 aaaf0 40
sub_80AAB30 aab30 40
sub_80AAB70 aab70 40
sub_80AABB0 aabb0 40
sub_80AABF0 aabf0 6c
sub_80AAC5C aac5c 68
sub_80AACC4 aacc4 44
sub_80AAD08 aad08 3c 130
sub_80AAD44 aad44 40
sub_80AAD84 aad84 164
sub_80AAF30 aaf30 ac
sub_80ABC3C abc3c 34
sub_80ADB04 adb04 44
sub_80AF1E4 af1e4 9c
sub_80AF2A0 af2a0 40
sub_80AFE78 afe78 98
sub_80AFF60 aff60 40
sub_80B0238 b0238 48
sub_80B0280 b0280 28
sub_80B02A8 b02a8 4c
sub_80B02F4 b02f4 30
sub_80B0368 b0368 40
sub_80B03A8 b03a8 30
sub_80B03D8 b03d8 80
sub_80B0458 b0458 c0
sub_80B3240 b3240 30 193
sub_80B45B4 b45b4 15c
sub_80B4710 b4710 c8
sub_80B47D8 b47d8 4c
sub_80B4824 b4824 18
sub_80B483C b483c 14
sub_80B4850 b4850 32
sub_80B53B4 b53b4 b6 184
sub_80B5AA0 b5aa0 16 141
sub_80B5DFC b5dfc 22 141
sub_80B5E20 b5e20 1a 141
sub_80B5E3C b5e3c 12 141
sub_80B5E50 b5e50 20 141
sub_80B61C8 b61c8 10 141
sub_80B6438 b6438 28 141
sub_80B6460 b6460 72 141
sub_80B654C b654c 60 141
sub_80B65AC b65ac 28 141
sub_80B65D4 b65d4 1c 141
sub_80B6888 b6888 50 141
sub_80B68D8 b68d8 3c 141
sub_80B6914 b6914 24 141
sub_80B6998 b6998 e8
sub_80B6A80 b6a80 94 141
sub_80B6B14 b6b14 20 141
sub_80B6B34 b6b34 28
sub_80B6B5C b6b5c 3c 141
sub_80B6B98 b6b98 4 141
sub_80B6B9C b6b9c 6c 141
sub_80B6C08 b6c08 40 141
sub_80B6C48 b6c48 60 141
sub_80B6CA8 b6ca8 5c 141
sub_80B6D04 b6d04 98 141
sub_80B6D9C b6d9c 4c
sub_80B6DE8 b6de8 5c
sub_80B6E44 b6e44 20 141
sub_80B6E68 b6e68 54 141
sub_80B6EBC b6ebc 40 141
sub_80B6EFC b6efc 48 141
sub_80B7004 b7004 8a 141
sub_80B7090 b7090 74 141
sub_80B7104 b7104 38 141
sub_80B713C b713c 38 141
sub_80B7198 b7198 4c 141
sub_80B71E4 b71e4 28 141
sub_80B720C b720c 58 141
sub_80B7264 b7264 40 141
sub_80B72A4 b72a4 cc 141
sub_80B7370 b7370 5c 141
sub_80B73CC b73cc a8 141
sub_80B7474 b7474 3c 141
sub_80B74B0 b74b0 4c 141
sub_80B753C b753c 1c 141
sub_80B7558 b7558 e 141
sub_80B7568 b7568 48 141
sub_80B75B0 b75b0 14 141
sub_80B75C4 b75c4 50 141
sub_80B7614 b7614 3c 141
sub_80B7650 b7650 10 141
sub_80B7660 b7660 10 141
sub_80B7670 b7670 10 141
sub_80B7680 b7680 18 141
sub_80B7698 b7698 48 141
sub_80B76E0 b76e0 4c 141
sub_80B772C b772c 14 141
sub_80B7740 b7740 24 141
sub_80B7794 b7794 64 141
sub_80B77F8 b77f8 40 141
sub_80B7838 b7838 c 141
sub_80B7844 b7844 c 141
sub_80B7850 b7850 c 141
sub_80B78A8 b78a8 4c 141
sub_80B78F8 b78f8 28 141
sub_80B7924 b7924 3c 141
sub_80B7960 b7960 48 141
sub_80B7AEC b7aec 46
sub_80B95F0 b95f0 1ec
sub_80B99B4 b99b4 34
sub_80B9A78 b9a78 10
sub_80B9A88 b9a88 94
sub_80B9BBC b9bbc 8
sub_80B9BC4 b9bc4 88
sub_80B9C4C b9c4c 1e
sub_80BA00C ba00c 9c
sub_80BA384 ba384 7c
sub_80BA65C ba65c 30
sub_80BA68C ba68c 2c
sub_80BA79C ba79c 62
sub_80BAE10 bae10 68
sub_80BAF84 baf84 b4
sub_80BB038 bb038 19c
sub_80BB1D4 bb1d4 86
sub_80BB5D0 bb5d0 14
sub_80BB66C bb66c 9e
sub_80BB70C bb70c 18
sub_80BB764 bb764 9a
sub_80BB8A8 bb8a8 22
sub_80BB8CC bb8cc a4
sub_80BBA14 bba14 34
sub_80BBA48 bba48 a8
sub_80BBAF0 bbaf0 34
sub_80BBB24 bbb24 2a
sub_80BBB50 bbb50 40
sub_80BBB90 bbb90 5c
sub_80BBBEC bbbec 8c
sub_80BBC78 bbc78 30
sub_80BBDD0 bbdd0 1d4
sub_80BC038 bc038 18
sub_80BC050 bc050 22
sub_80BC074 bc074 84
sub_80BC0F8 bc0f8 1c
sub_80BC114 bc114 38
sub_80BC14C bc14c 44
sub_80BC190 bc190 40
sub_80BC268 bc268 2e
sub_80BC440 bc440 24
sub_80BC474 bc474 96
sub_80BC538 bc538 34
sub_80BC6B0 bc6b0 128
sub_80BC7D8 bc7d8 4c 187
sub_80BC824 bc824 122 187
sub_80BC948 bc948 38 187
sub_80BC980 bc980 64 187
sub_80BC9E4 bc9e4 9e 187
sub_80BCA84 bca84 68 187
sub_80BCAEC bcaec 24 187
sub_80BCB10 bcb10 80
sub_80BCB90 bcb90 30 187
sub_80BCBC0 bcbc0 38 187
sub_80BCBF8 bcbf8 5c 187
sub_80BCC54 bcc54 50 187
sub_80BCE1C bce1c 30
sub_80BCE4C bce4c 44
sub_80BCE90 bce90 8c
sub_80BCF1C bcf1c 118
sub_80BD034 bd034 3c
sub_80BD070 bd070 2e
sub_80BD0A0 bd0a0 4a
sub_80BD0EC bd0ec 3e
sub_80BD12C bd12c 42
sub_80BD170 bd170 40
sub_80BD1B0 bd1b0 4a
sub_80BD1FC bd1fc 84
sub_80BD280 bd280 a8
sub_80BD328 bd328 30
sub_80BD358 bd358 82
sub_80BD3DC bd3dc b6
sub_80BD494 bd494 80
sub_80BD514 bd514 fa
sub_80BD610 bd610 64
sub_80BD8B8 bd8b8 4e
sub_80BDEAC bdeac 1a
sub_80BE028 be028 4c
sub_80BE074 be074 c4
sub_80BE138 be138 28
sub_80BE160 be160 26
sub_80BE23C be23c 48
sub_80BE284 be284 9c
sub_80BE3BC be3bc bc
sub_80BE478 be478 f8
sub_80BE778 be778 e0
sub_80BE8EC be8ec 66
sub_80BE97C be97c 58
sub_80BE9D4 be9d4 7c
sub_80BEA50 bea50 c
sub_80BEA5C bea5c 2c
sub_80BEA88 bea88 98
sub_80BEB20 beb20 a8
sub_80BEBC8 bebc8 2c
sub_80BEBF4 bebf4 1a
sub_80BEC10 bec10 30
sub_80BEC40 bec40 60
sub_80BEE48 bee48 3c
sub_80BEE84 bee84 8c
sub_80BEF10 bef10 94
sub_80BF088 bf088 30
sub_80BF0B8 bf0b8 9c
sub_80BF154 bf154 5e
sub_80BF1B4 bf1b4 56
sub_80BF20C bf20c 50
sub_80BF25C bf25c 66
sub_80BF55C bf55c 2c
sub_80BF588 bf588 b0
sub_80BF638 bf638 3c
sub_80BF674 bf674 62
sub_80BF6D8 bf6d8 48
sub_80BF720 bf720 2c
sub_80BF74C bf74c 30
sub_80BF77C bf77c 20
sub_80BF79C bf79c 4c
sub_80BF7E8 bf7e8 36
sub_80BF820 bf820 154
sub_80BFD20 bfd20 24
sub_80BFE24 bfe24 144
sub_80BFF68 bff68 e4
sub_80C004C c004c 66
sub_80C00B4 c00b4 7e
sub_80C0134 c0134 68
sub_80C019C c019c 38
sub_80C01D4 c01d4 1d2
sub_80C03A8 c03a8 20
sub_80C03C8 c03c8 40
sub_80C0408 c0408 54
sub_80C045C c045c 44
sub_80C04A0 c04a0 74
sub_80C05C4 c05c4 f8
sub_80C06BC c06bc 2c
sub_80C06E8 c06e8 48
sub_80C0730 c0730 1e
sub_80C0750 c0750 38
sub_80C0788 c0788 3c
sub_80C0DC0 917cc 4c 158
sub_80C2020 c2020 124
sub_80C2144 c2144 128
sub_80C226C c226c d4
sub_80C2340 c2340 18
sub_80C2358 c2358 d8
sub_80C2430 c2430 16 43
sub_80C2448 c2448 ac 43
sub_80C24F4 c24f4 68 43
sub_80C255C c255c 48 43
sub_80C25A4 c25a4 1c 43
sub_80C25C0 c25c0 40 43
sub_80C2600 c2600 e4 43
sub_80C26E4 c26e4 8c 43
sub_80C2770 c2770 7c 43
sub_80C27EC c27ec 8c 43
sub_80C2878 c2878 214 43
sub_80C2A8C c2a8c 290 43
sub_80C2D1C c2d1c 64 43
sub_80C2D80 c2d80 58 43
sub_80C2DD8 c2dd8 3c 43
sub_80C2E14 c2e14 8c 43
sub_80C2EA0 c2ea0 88 43
sub_80C2F28 c2f28 3c 43
sub_80C2F64 c2f64 c0 43
sub_80C3024 c3024 b0
sub_80C310C c310c 4c
sub_80C3158 c3158 284
sub_80C33DC c33dc d0
sub_80C34AC c34ac 1e
sub_80C34CC c34cc 54
sub_80C3520 c3520 44
sub_80C3564 c3564 24
sub_80C3588 c3588 74
sub_80C35FC c35fc 34
sub_80C3630 c3630 68
sub_80C3698 c3698 cc
sub_80C3764 c3764 80
sub_80C37E4 c37e4 1ac
sub_80C3990 c3990 54
sub_80C39E4 c39e4 76
sub_80C3A5C c3a5c d4
sub_80C3B30 c3b30 a8
sub_80C3BD8 c3bd8 6a
sub_80C3C44 c3c44 74
sub_80C3CB8 c3cb8 4c
sub_80C3D04 c3d04 ec
sub_80C3DF0 c3df0 70
sub_80C3E60 c3e60 44
sub_80C3EA4 c3ea4 5c
sub_80C3F00 c3f00 1d2
sub_80C40D4 c40d4 1ec
sub_80C42C0 c42c0 134
sub_80C488C c488c 10
sub_80C489C c489c 2c
sub_80C48C8 c48c8 2c
sub_80C4914 c4914 2c
sub_80C4940 c4940 2c
sub_80C5044 c5044 c
sub_80C5164 c5164 2c
sub_80C5190 c5190 98
sub_80C5568 c5568 18
sub_80C5580 c5580 30
sub_80C5CD4 c5cd4 f8
sub_80C5DCC c5dcc 6c
sub_80C5E38 c5e38 160
sub_80C5F98 c5f98 a4
sub_80C603C c603c 3c 151
sub_80C6078 c6078 54 151
sub_80C60CC c60cc 64 151
sub_80C6130 c6130 80 151
sub_80C68EC c68ec 7e 88
sub_80C69C4 c69c4 50 88
sub_80C6A14 c6a14 3e 88
sub_80C7754 c7754 4c
sub_80C78A0 c78a0 7a
sub_80C791C c791c 3c
sub_80C7958 c7958 44
sub_80C824C c824c 70
sub_80C8644 c8644 1c 42
sub_80C8660 c8660 40 42
sub_80C8734 c8734 178
sub_80C8A38 c8a38 98
sub_80C9688 c9688 98
sub_80C9720 c9720 118
sub_80C9838 c9838 ce
sub_80CA07C ca07c 1c 117
sub_80CA294 ca294 28
sub_80CA2BC ca2bc 54
sub_80CA394 ca394 2c
sub_80CA3C0 ca3c0 34
sub_80CA7B0 ca7b0 50
sub_80CA800 ca800 58
sub_80CA858 ca858 5c
sub_80CA8B4 ca8b4 74 147
sub_80CA928 ca928 80
sub_80CA9A8 ca9a8 50
sub_80CA9F8 ca9f8 1a 147
sub_80CAA14 caa14 b8
sub_80CAACC caacc 4c 147
sub_80CABF8 cabf8 4c
sub_80CAC44 cac44 a8 146
sub_80CACEC cacec 68
sub_80CAD54 cad54 54
sub_80CADA8 cada8 78 146
sub_80CAE20 cae20 54
sub_80CAE74 cae74 64 146
sub_80CAED8 caed8 48
sub_80CAF20 caf20 4c 119
sub_80CAF6C caf6c 62 119
sub_80CB25C cb25c 3c
sub_80CB298 cb298 3c 213
sub_80CB2D4 cb2d4 6c 213
sub_80CB340 cb340 68
sub_80CB3A8 cb3a8 90 195
sub_80CB438 cb438 94 195
sub_80CB4CC cb4cc d0
sub_80CB59C cb59c 84
sub_80CB620 cb620 f0
sub_80CB710 cb710 56 173
sub_80CB768 cb768 84
sub_80CB7EC cb7ec 28
sub_80CB814 cb814 a4
sub_80CB8B8 cb8b8 2e
sub_80CB8E8 cb8e8 64
sub_80CB94C cb94c 78
sub_80CB9C4 cb9c4 62
sub_80CBA28 cba28 7c
sub_80CBAA4 cbaa4 44
sub_80CBAE8 cbae8 78
sub_80CBB60 cbb60 90 112
sub_80CBBF0 cbbf0 9a
sub_80CBC8C cbc8c 6c 210
sub_80CBCF8 cbcf8 b8 210
sub_80CBDB0 cbdb0 42 210
sub_80CBDF4 cbdf4 168
sub_80CBF5C cbf5c 3da 99
sub_80CC338 cc338 1e 99
sub_80CC358 cc358 b0 99
sub_80CC408 cc408 6c 99
sub_80CC474 cc474 10c
sub_80CC580 cc580 76 100
sub_80CC5F8 cc5f8 d4
sub_80CC6CC cc6cc 108
sub_80CC7D4 cc7d4 3c 111
sub_80CC810 cc810 1a 238
sub_80CC82C cc82c 58
sub_80CC884 cc884 44
sub_80CC8C8 cc8c8 4c
sub_80CC9BC cc9bc 144
sub_80CCC50 ccc50 64
sub_80CCCB4 cccb4 6e 228
sub_80CCD24 ccd24 e8
sub_80CCE0C cce0c f8 192
sub_80CCF04 ccf04 6c
sub_80CCF70 ccf70 15c 30
sub_80CD0CC cd0cc 72 30
sub_80CD140 cd140 50
sub_80CD190 cd190 e4
sub_80CD274 cd274 60
sub_80CD2D4 cd2d4 52 229
sub_80CD328 cd328 6c
sub_80CD394 cd394 4a 197
sub_80CD3E0 cd3e0 28
sub_80CD408 cd408 b0 179
sub_80CD4B8 cd4b8 34 179
sub_80CD4EC cd4ec bc 179
sub_80CD5A8 cd5a8 ac 179
sub_80CD654 cd654 28 179
sub_80CD67C cd67c 4e 179
sub_80CD6CC cd6cc a8
sub_80CD774 cd774 58
sub_80CD7CC cd7cc 50 124
sub_80CD81C cd81c 8c 124
sub_80CD8A8 cd8a8 50 124
sub_80CD8F8 cd8f8 24 124
sub_80CD91C cd91c 9c 124
sub_80CD9B8 cd9b8 a 124
sub_80CD9C4 cd9c4 10
sub_80CD9D4 cd9d4 f4 124
sub_80CDAC8 cdac8 98
sub_80CDB60 cdb60 1c0 124
sub_80CDD20 cdd20 52 124
sub_80CDD74 cdd74 68
sub_80CDDDC cdddc 48
sub_80CDE24 cde24 54
sub_80CDE78 cde78 38 196
sub_80CDEB0 cdeb0 10 196
sub_80CDEC0 cdec0 4c 196
sub_80CDF0C cdf0c 64
sub_80CDF70 cdf70 40 31
sub_80CDFB0 cdfb0 50
sub_80CE000 ce000 9c 48
sub_80CE09C ce09c 6c
sub_80CE108 ce108 74
sub_80CE17C ce17c 30
sub_80CE1AC ce1ac 64 219
sub_80CE210 ce210 50
sub_80CE30C ce30c 48
sub_80CE354 ce354 16 136
sub_80CE36C ce36c 44
sub_80CE3B0 ce3b0 3c 226
sub_80CE3EC ce3ec e8
sub_80CE4D4 ce4d4 19c 85
sub_80CE670 ce670 128
sub_80CE798 ce798 48 207
sub_80CE7E0 ce7e0 130
sub_80CE910 ce910 64 62
sub_80CE974 ce974 90 62
sub_80CEA04 cea04 1c
sub_80CEA20 cea20 b8
sub_80CEAD8 cead8 34
sub_80CEB0C ceb0c b8
sub_80CEBC4 cebc4 58 138
sub_80CEC1C cec1c cc 138
sub_80CECE8 cece8 90
sub_80CED78 ced78 78 138
sub_80CEDF0 cedf0 70
sub_80CEE60 cee60 88
sub_80CEEE8 ceee8 5c 138
sub_80CEF44 cef44 58
sub_80CEF9C cef9c 6c
sub_80CF008 cf008 38 216
sub_80CF040 cf040 48
sub_80CF088 cf088 34 82
sub_80CF0BC cf0bc 7c
sub_80CF138 cf138 20 82
sub_80CF158 cf158 70 82
sub_80CF1C8 cf1c8 60
sub_80CF228 cf228 3c 82
sub_80CF264 cf264 1c 82
sub_80CF280 cf280 50
sub_80CF2D0 cf2d0 40
sub_80CF310 cf310 64 230
sub_80CF374 cf374 50 231
sub_80CF3C4 cf3c4 94
sub_80CF458 cf458 38
sub_80CF490 cf490 28 232
sub_80CF4B8 cf4b8 1e 232
sub_80CF4D8 cf4d8 3c
sub_80CF514 cf514 fa 242
sub_80CF610 cf610 80
sub_80CF690 cf690 24
sub_80CF6B4 cf6b4 28 211
sub_80CF7E0 cf7e0 34
sub_80CF814 cf814 a4
sub_80CF8B8 cf8b8 140
sub_80CF9F8 cf9f8 28
sub_80CFA20 cfa20 e4
sub_80CFB04 cfb04 2f8
sub_80CFDFC cfdfc 30
sub_80CFE2C cfe2c 70 233
sub_80CFE9C cfe9c b4
sub_80CFF50 cff50 18
sub_80CFF68 cff68 70 135
sub_80CFFD8 cffd8 58
sub_80D0030 d0030 84 34
sub_80D00B4 d00b4 64 34
sub_80D0118 d0118 60
sub_80D0178 d0178 94
sub_80D020C d020c 1a 103
sub_80D0228 d0228 a8
sub_80D02D0 d02d0 74 106
sub_80D0344 d0344 64 106
sub_80D03A8 d03a8 1a 106
sub_80D03C4 d03c4 64
sub_80D0428 d0428 60 190
sub_80D08C8 d08c8 3c
sub_80D0904 d0904 2c 105
sub_80D0930 d0930 90
sub_80D09C0 d09c0 8c
sub_80D0A4C d0a4c 40
sub_80D0A8C d0a8c 2c 217
sub_80D0AB8 d0ab8 84
sub_80D0B3C d0b3c 14a 217
sub_80D0C88 d0c88 e0
sub_80D0D68 d0d68 c8 57
sub_80D0E30 d0e30 5c
sub_80D0E8C d0e8c 14a 57
sub_80D0FD8 d0fd8 c0
sub_80D1098 d1098 20 169
sub_80D10B8 d10b8 260
sub_80D1318 d1318 50
sub_80D1368 d1368 44
sub_80D13AC d13ac 78 169
sub_80D1424 d1424 28 169
sub_80D144C d144c 78 169
sub_80D14C4 d14c4 40 169
sub_80D1504 d1504 48 169
sub_80D154C d154c 40 169
sub_80D158C d158c 18 169
sub_80D15A4 d15a4 3c
sub_80D15E0 d15e0 58 61
sub_80D1638 d1638 68
sub_80D16A0 d16a0 124 61
sub_80D17C4 d17c4 44
sub_80D1808 d1808 cc 61
sub_80D18D4 d18d4 5c
sub_80D1930 d1930 140 61
sub_80D1A70 d1a70 6c
sub_80D1ADC d1adc a4
sub_80D1B80 d1b80 28
sub_80D1BA8 d1ba8 60 108
sub_80D1C08 d1c08 78
sub_80D1C80 d1c80 50
sub_80D1CD0 d1cd0 78
sub_80D1D48 d1d48 54 50
sub_80D1D9C d1d9c 9c 50
sub_80D1E38 d1e38 90
sub_80D1EC8 d1ec8 90
sub_80D1F58 d1f58 4c
sub_80D1FA4 d1fa4 36 29
sub_80D1FDC d1fdc 86
sub_80D2064 d2064 30
sub_80D2094 d2094 6c 98
sub_80D2100 d2100 f0
sub_80D21F0 d21f0 1c4 123
sub_80D23B4 d23b4 12c
sub_80D24E0 d24e0 1c4 181
sub_80D287C d287c 30 202
sub_80D28AC d28ac 58
sub_80D2904 d2904 1a 152
sub_80D2920 d2920 18
sub_80D2938 d2938 94
sub_80D29CC d29cc 6a 2
sub_80D2A38 d2a38 84
sub_80D2ABC d2abc 12a
sub_80D2BE8 d2be8 4e
sub_80D2C38 d2c38 8c
sub_80D2CC4 d2cc4 34 209
sub_80D2CF8 d2cf8 44
sub_80D2D3C d2d3c 2c 234
sub_80D2D68 d2d68 c8
sub_80D2E30 d2e30 38 142
sub_80D2E68 d2e68 60
sub_80D2EC8 d2ec8 b8
sub_80D2F80 d2f80 24 144
sub_80D2FA4 d2fa4 70 144
sub_80D3014 d3014 98
sub_80D31C8 d31c8 120
sub_80D32E8 d32e8 88 32
sub_80D3370 d3370 28 32
sub_80D3398 d3398 1c 32
sub_80D3554 d3554 88
sub_80D35DC d35dc 52 60
sub_80D3630 d3630 2c
sub_80D365C d365c 3c 60
sub_80D3698 d3698 74
sub_80D370C d370c 1a 60
sub_80D3728 d3728 d4
sub_80D37FC d37fc 3c
sub_80D3838 d3838 3c
sub_80D3874 d3874 46 237
sub_80D3B60 d3b60 208
sub_80D3D68 d3d68 2dc
sub_80D4044 d4044 64
sub_80D40A8 d40a8 4c
sub_80D40F4 d40f4 5c
sub_80D4150 d4150 242
sub_80D4394 d4394 84
sub_80D4418 d4418 114
sub_80D452C d452c ac
sub_80D45D8 d45d8 64
sub_80D463C d463c f0
sub_80D472C d472c a4
sub_80D47D0 d47d0 ac
sub_80D487C d487c 78
sub_80D48F4 d48f4 94
sub_80D4988 d4988 146
sub_80D4AD0 d4ad0 6c
sub_80D4B3C d4b3c 68
sub_80D4BA4 d4ba4 4c
sub_80D4BF0 d4bf0 28
sub_80D4C18 d4c18 4a
sub_80D4C64 d4c64 3e
sub_80D4CA4 d4ca4 48
sub_80D4CEC d4cec 76
sub_80D4D64 d4d64 174
sub_80D4ED8 d4ed8 40
sub_80D4F18 d4f18 44
sub_80D4F5C d4f5c 70
sub_80D4FCC d4fcc 6c
sub_80D5038 d5038 3c 83
sub_80D5074 d5074 74
sub_80D50E8 d50e8 94 83
sub_80D517C d517c 2c
sub_80D5210 d5210 1c
sub_80D53B4 d53b4 40
sub_80D53F4 d53f4 28 84
sub_80D541C d541c 52 84
sub_80D5470 d5470 70
sub_80D54E0 d54e0 2e2 84
sub_80D57C4 d57c4 138 84
sub_80D58FC d58fc 44
sub_80D5940 d5940 52
sub_80D5994 d5994 1c
sub_80D59B0 d59b0 70 84
sub_80D5A20 d5a20 54
sub_80D5A74 d5a74 96 84
sub_80D5B0C d5b0c 150
sub_80D5C5C d5c5c 64 241
sub_80D5CC0 d5cc0 11c
sub_80D5DDC d5ddc 70
sub_80D5E4C d5e4c 234 240
sub_80D60B4 d60b4 114
sub_80D61C8 d61c8 50
sub_80D6218 d6218 1a 218
sub_80D6234 d6234 44
sub_80D6278 d6278 1a 27
sub_80D6294 d6294 94
sub_80D6328 d6328 164
sub_80D648C d648c 88
sub_80D6514 d6514 76 49
sub_80D658C d658c 4e 49
sub_80D65DC d65dc 7c
sub_80D6658 d6658 d4
sub_80D672C d672c 6e 49
sub_80D679C d679c 80
sub_80D681C d681c 58
sub_80D6874 d6874 1a8 49
sub_80D6A1C d6a1c 4e
sub_80D6A6C d6a6c 84
sub_80D6AF0 d6af0 4c 49
sub_80D6B3C d6b3c 7c
sub_80D6BB8 d6bb8 114 49
sub_80D6CCC d6ccc 34 49
sub_80D6D00 d6d00 18 49
sub_80D6D18 d6d18 58
sub_80D6D70 d6d70 68
sub_80D6DD8 d6dd8 60
sub_80D6E38 d6e38 64 49
sub_80D6E9C d6e9c 170
sub_80D700C d700c 188
sub_80D7194 d7194 9c 49
sub_80D7230 d7230 4c
sub_80D727C d727c 5e
sub_80D72DC d72dc 192
sub_80D7470 d7470 ea 49
sub_80D755C d755c 40
sub_80D759C d759c b8
sub_80D7654 d7654 70 49
sub_80D76C4 d76c4 40 49
sub_80D7704 d7704 184 113
sub_80D7888 d7888 64 113
sub_80D8874 d8874 268 113
sub_80D8BA8 d8ba8 172
sub_80D902C d902c 4c
sub_80D9078 d9078 2c
sub_80D90F4 d90f4 188
sub_80D927C d927c 52 81
sub_80D92D0 d92d0 58
sub_80D9328 d9328 50 81
sub_80D9378 d9378 8c
sub_80D9404 d9404 38 81
sub_80D9540 d9540 8e
sub_80D95D0 d95d0 70
sub_80D9640 d9640 78 81
sub_80D96B8 d96b8 e8
sub_80D97A0 d97a0 2c 81
sub_80D97CC d97cc a0
sub_80D986C d986c 6c 81
sub_80D98D8 d98d8 5c
sub_80D9934 d9934 c0 81
sub_80D99F4 d99f4 44 81
sub_80D9A38 d9a38 ec
sub_80D9B24 d9b24 22 81
sub_80D9B48 d9b48 8c
sub_80D9BD4 d9bd4 6c
sub_80D9C40 d9c40 40
sub_80D9C80 d9c80 f0
sub_80D9D70 d9d70 64
sub_80D9DD4 d9dd4 1a 154
sub_80D9DF0 d9df0 88
sub_80D9E78 d9e78 1a 154
sub_80D9E94 d9e94 54
sub_80D9EE8 d9ee8 2c 154
sub_80D9F14 d9f14 74
sub_80DA034 da034 28 97
sub_80DA05C da05c 40 97
sub_80DA09C da09c 40
sub_80DA0DC da0dc 90 97
sub_80DA16C da16c 80 97
sub_80DA1EC da1ec 1a 97
sub_80DA208 da208 f8 97
sub_80DA300 da300 48 97
sub_80DA348 da348 42 97
sub_80DA38C da38c 84 97
sub_80DA410 da410 7c 97
sub_80DA48C da48c 4c
sub_80DAD30 dad30 54 97
sub_80DAD84 dad84 188 97
sub_80DAF0C daf0c f4 97
sub_80DB000 db000 a0 97
sub_80DB0A0 db0a0 48 97
sub_80DB0E8 db0e8 ac
sub_80DB194 db194 5e 97
sub_80DB1F4 db1f4 94 97
sub_80DB288 db288 48 97
sub_80DB2D0 db2d0 60 97
sub_80DB330 db330 42 97
sub_80DB374 db374 e4 97
sub_80DB458 db458 b0 97
sub_80DB508 db508 5c 97
sub_80DB564 db564 14 97
sub_80DB578 db578 6a 97
sub_80DB5E4 db5e4 bc 97
sub_80DB6A0 db6a0 44 97
sub_80DB74C db74c 140
sub_80DB88C db88c 34 165
sub_80DB8C0 db8c0 6c 165
sub_80DB92C db92c b8 165
sub_80DB9E4 db9e4 68 165
sub_80DBA4C dba4c a6
sub_80DBAF4 dbaf4 7c
sub_80DBB70 dbb70 90
sub_80DBC00 dbc00 34 165
sub_80DBC34 dbc34 5e 165
sub_80DBC94 dbc94 3c
sub_80DBCD0 dbcd0 2c 165
sub_80DBCFC dbcfc 5c
sub_80DBD58 dbd58 a8 165
sub_80DBE00 dbe00 98
sub_80DBE98 dbe98 188 165
sub_80DC020 dc020 48 165
sub_80DC068 dc068 48
sub_80DC0B0 dc0b0 14c
sub_80DC1FC dc1fc b2 165
sub_80DC2B0 dc2b0 24
sub_80DC2D4 dc2d4 120
sub_80DC3F4 dc3f4 fe 165
sub_80DC4F4 dc4f4 100
sub_80DC5F4 dc5f4 10a
sub_80DC700 dc700 124
sub_80DC824 dc824 d0
sub_80DC8F4 dc8f4 ac
sub_80DC9A0 dc9a0 98
sub_80DCA38 dca38 38 33
sub_80DCA70 dca70 7c
sub_80DCAEC dcaec 4c 33
sub_80DCB38 dcb38 24
sub_80DCB5C dcb5c 58 33
sub_80DCBB4 dcbb4 18 33
sub_80DCE40 dce40 5c
sub_80DCE9C dce9c 80
sub_80DCF1C dcf1c 44 170
sub_80DCF60 dcf60 84
sub_80DCFE4 dcfe4 48
sub_80DD02C dd02c 4c 170
sub_80DD190 dd190 21c 170
sub_80DD4D4 dd4d4 130
sub_80DD604 dd604 16e 170
sub_80DD774 dd774 108 170
sub_80DD87C dd87c 40
sub_80DD8BC dd8bc 2c 170
sub_80DD8E8 dd8e8 40
sub_80DD928 dd928 4e 170
sub_80DD978 dd978 2c
sub_80DD9A4 dd9a4 58
sub_80DD9FC dd9fc 50 170
sub_80DDA4C dda4c 40
sub_80DDA8C dda8c 64
sub_80DDAF0 ddaf0 7c
sub_80DDB6C ddb6c 6c 102
sub_80DDBD8 ddbd8 74 102
sub_80DDC4C ddc4c 7c 102
sub_80DDCC8 ddcc8 90 102
sub_80DDD58 ddd58 20 102
sub_80DDD78 ddd78 76 102
sub_80DDDF0 dddf0 8c
sub_80DDE7C dde7c 54 102
sub_80DDED0 dded0 70 102
sub_80DE0FC de0fc 18 102
sub_80DE114 de114 9c 102
sub_80DE1B0 de1b0 12c
sub_80DE2DC de2dc d0 102
sub_80DE3AC de3ac 28
sub_80DE3D4 de3d4 248 102
sub_80DE61C de61c 94 102
sub_80DE6B0 de6b0 106 102
sub_80DE7B8 de7b8 120 102
sub_80DE8D8 de8d8 3e 102
sub_80DE918 de918 220
sub_80DEB38 deb38 178 102
sub_80DECB0 decb0 b0
sub_80DED60 ded60 188 102
sub_80DEEE8 deee8 54 102
sub_80DEF3C def3c 5c 102
sub_80DEF98 def98 7e 102
sub_80DF018 df018 78 102
sub_80DF090 df090 28 102
sub_80DF0B8 df0b8 d4 102
sub_80DF18C df18c 18 102
sub_80DF1A4 df1a4 a8
sub_80DF24C df24c 18c 102
sub_80DF3D8 df3d8 c4 102
sub_80DF49C df49c 58 102
sub_80DF4F4 df4f4 ac 102
sub_80DF5A0 df5a0 9c
sub_80DF63C df63c b4
sub_80DF6F0 df6f0 70
sub_80DF760 df760 2c
sub_80DF78C df78c 90
sub_80DF81C df81c 108 56
sub_80DF924 df924 d0
sub_80DF9F4 df9f4 ba 56
sub_80DFAB0 dfab0 78 56
sub_80DFB28 dfb28 b0
sub_80DFBD8 dfbd8 4a 56
sub_80DFC24 dfc24 78
sub_80DFC9C dfc9c 88 51
sub_80DFD24 dfd24 34
sub_80DFD58 dfd58 68 51
sub_80DFDC0 dfdc0 54
sub_80DFE14 dfe14 7c
sub_80DFE90 dfe90 8a 51
sub_80DFF1C dff1c 3c
sub_80DFF58 dff58 40 51
sub_80DFF98 dff98 36 51
sub_80DFFD0 dffd0 100
sub_80E00D0 e00d0 1a 51
sub_80E00EC e00ec 1b8
sub_80E02A4 e02a4 118 51
sub_80E03BC e03bc 264
sub_80E0620 e0620 17c 51
sub_80E079C e079c 130 51
sub_80E08CC e08cc 4c 51
sub_80E0918 e0918 ac
sub_80E09C4 e09c4 4c
sub_80E0A10 e0a10 3c
sub_80E0A4C e0a4c 284
sub_80E0CD0 e0cd0 154 51
sub_80E0E24 e0e24 c4
sub_80E0EE8 e0ee8 34
sub_80E1244 e1244 40
sub_80E1284 e1284 1b8 104
sub_80E143C e143c 60 104
sub_80E149C e149c 40
sub_80E14DC e14dc 84 104
sub_80E1560 e1560 108 104
sub_80E1668 e1668 c0 104
sub_80E1864 e1864 d0
sub_80E1934 e1934 f8 104
sub_80E1A2C e1a2c e4 104
sub_80E1B10 e1b10 78 104
sub_80E1B88 e1b88 28
sub_80E1BB0 e1bb0 a8
sub_80E1C58 e1c58 5c 104
sub_80E1E2C e1e2c 54 143
sub_80E1E80 e1e80 8a 143
sub_80E1F0C e1f0c 30 143
sub_80E1F3C e1f3c 50 143
sub_80E1F8C e1f8c 50
sub_80E1FDC e1fdc 50 143
sub_80E202C e202c 68 143
sub_80E2094 e2094 50
sub_80E20E4 e20e4 5c 143
sub_80E2140 e2140 68 143
sub_80E21A8 e21a8 6c
sub_80E2214 e2214 b8 143
sub_80E22CC e22cc 58 143
sub_80E2324 e2324 84
sub_80E24B8 e24b8 a4 143
sub_80E255C e255c b0 143
sub_80E260C e260c ae 143
sub_80E26BC e26bc 54
sub_80E2710 e2710 90 143
sub_80E27A0 e27a0 48 143
sub_80E27E8 e27e8 50 143
sub_80E2838 e2838 38 143
sub_80E2870 e2870 98 143
sub_80E2908 e2908 70 143
sub_80E2978 e2978 48 143
sub_80E29C0 e29c0 3c 143
sub_80E29FC e29fc 3a 143
sub_80E2A38 e2a38 44
sub_80E2A7C e2a7c f8
sub_80E2B74 e2b74 ec
sub_80E2D78 e2d78 40
sub_80E2DB8 e2db8 20 143
sub_80E2DD8 e2dd8 38
sub_80E2E10 e2e10 d8 143
sub_80E2EE8 e2ee8 44 143
sub_80E2F2C e2f2c 268
sub_80E3194 e3194 14c 143
sub_80E32E0 e32e0 58
sub_80E3338 e3338 3cc 143
sub_80E3704 e3704 188 143
sub_80E388C e388c 6c
sub_80E38F8 e38f8 c4 143
sub_80E39BC e39bc 4c 143
sub_80E3A08 e3a08 50
sub_80E3A58 e3a58 78
sub_80E3AD0 e3ad0 7c 143
sub_80E3B4C e3b4c 2c
sub_80E3B78 e3b78 2c
sub_80E3BA4 e3ba4 38
sub_80E3BDC e3bdc 70
sub_80E3C4C e3c4c 218
sub_80E3E64 e3e64 1a4 143
sub_80E4028 e4028 a8
sub_80E40D0 e40d0 a8
sub_80E4178 e4178 88
sub_80E4200 e4200 34
sub_80E4234 e4234 30
sub_80E4264 e4264 4c
sub_80E42B0 e42b0 20
sub_80E42D0 e42d0 30
sub_80E4300 e4300 68
sub_80E4368 e4368 58 143
sub_80E4EF8 e4ef8 e4
sub_80E62A0 e62a0 58
sub_80E62F8 e62f8 12c
sub_80E6424 e6424 130
sub_80E6554 e6554 dc
sub_80E6630 e6630 5e
sub_80E6690 e6690 d4
sub_80E682C e682c 10
sub_80E683C e683c ac
sub_80E68E8 e68e8 110
sub_80E69F8 e69f8 74
sub_80E6A6C e6a6c 1a
sub_80E6A88 e6a88 20
sub_80E6AA8 e6aa8 1c
sub_80E6AC4 e6ac4 20
sub_80E6AE4 e6ae4 dc
sub_80E6BC0 e6bc0 c4
sub_80E6C84 e6c84 f8
sub_80E6D7C e6d7c 1ec
sub_80E6F68 e6f68 60
sub_80E6FC8 e6fc8 14c
sub_80E7114 e7114 78
sub_80E718C e718c 8c
sub_80E7218 e7218 7c
sub_80E7294 e7294 90
sub_80E7324 e7324 ac
sub_80E73D0 e73d0 88
sub_80E7458 e7458 d4
sub_80E752C e752c 48
sub_80E7574 e7574 64
sub_80E75D8 e75d8 1f0
sub_80E77C8 e77c8 2ce
sub_80E7A98 e7a98 3c
sub_80E7AD4 e7ad4 6c
sub_80E7B40 e7b40 1f0
sub_80E7D30 e7d30 3c
sub_80E7D6C e7d6c 30
sub_80E7D9C e7d9c 34
sub_80E7DD0 e7dd0 80
sub_80E7E50 e7e50 b0
sub_80E7F00 e7f00 a8
sub_80E7FA8 e7fa8 ac
sub_80E8054 e8054 3e
sub_80E8094 e8094 76
sub_80E810C e810c b4
sub_80E81C0 e81c0 3c
sub_80E81FC e81fc 1c
sub_80E8218 e8218 50
sub_80E8268 e8268 54
sub_80E82BC e82bc dc
sub_80E8398 e8398 88
sub_80E8420 e8420 e4
sub_80E8504 e8504 30
sub_80E8534 e8534 c4
sub_80E85F8 e85f8 134
sub_80E872C e872c 34
sub_80E8760 e8760 42
sub_80E87A4 e87a4 28
sub_80E87CC e87cc 4c
sub_80E8818 e8818 48
sub_80E8860 e8860 90
sub_80E88F0 e88f0 68
sub_80E8958 e8958 124
sub_80E8A7C e8a7c fc
sub_80E8B78 e8b78 7c
sub_80E8BF4 e8bf4 f8
sub_80E8CEC e8cec 68
sub_80E8D54 e8d54 38
sub_80E8D8C e8d8c 4a
sub_80E8DD8 e8dd8 1cc
sub_80E8FA4 e8fa4 164
sub_80E9108 e9108 70
sub_80E9178 e9178 20
sub_80E9198 e9198 c
sub_80E91A4 e91a4 c
sub_80E91B0 e91b0 22
sub_80E91D4 e91d4 194
sub_80E9368 e9368 124
sub_80E948C e948c 118
sub_80E95A4 e95a4 7c
sub_80E9620 e9620 124
sub_80E9744 e9744 7c
sub_80E97C0 e97c0 104
sub_80E98C4 e98c4 7c
sub_80E9940 e9940 34
sub_80E9974 e9974 a0
sub_80E9A14 e9a14 38
sub_80E9A4C e9a4c 14
sub_80E9A60 e9a60 1a
sub_80E9A7C e9a7c 58
sub_80E9AD4 e9ad4 24
sub_80E9AF8 e9af8 17c
sub_80E9C74 e9c74 1e
sub_80E9C94 e9c94 6a
sub_80E9D00 e9d00 7c
sub_80E9D7C e9d7c 8c
sub_80E9E08 e9e08 4c
sub_80E9E54 e9e54 40
sub_80E9E98 e9e98 10
sub_80E9EA8 e9ea8 a6
sub_80E9F50 e9f50 82
sub_80E9FD4 e9fd4 40
sub_80EA014 ea014 3c
sub_80EA050 ea050 92
sub_80EA0E4 ea0e4 9e
sub_80EA184 ea184 5c
sub_80EA1E0 ea1e0 6c
sub_80EA24C ea24c fc
sub_80EA348 ea348 15c
sub_80EA4A4 ea4a4 fc
sub_80EA5A0 ea5a0 164
sub_80EA704 ea704 60
sub_80EA764 ea764 90
sub_80EA7F4 ea7f4 c8
sub_80EA8BC ea8bc 8c
sub_80EA948 ea948 fc
sub_80EAA44 eaa44 90
sub_80EAAD4 eaad4 100
sub_80EABD4 eabd4 36
sub_80EAC0C eac0c 22
sub_80EAC30 eac30 16
sub_80EAC48 eac48 12
sub_80EAC5C eac5c 60
sub_80EACBC eacbc 4a
sub_80EAD08 ead08 5c
sub_80EAD7C ead7c 44
sub_80EADC0 eadc0 c8
sub_80EAE88 eae88 44
sub_80EAECC eaecc 174
sub_80EB0B0 eb0b0 168
sub_80EB218 eb218 bc
sub_80EB2D4 eb2d4 a6
sub_80EB37C eb37c 80
sub_80EB544 eb544 9c
sub_80EB680 eb680 4
sub_80EB6FC eb6fc 30
sub_80EB72C eb72c 58
sub_80EB784 eb784 40
sub_80EB7C4 eb7c4 78
sub_80EB868 eb868 28
sub_80EB8C0 eb8c0 2a
sub_80EB8EC eb8ec 74
sub_80EB960 eb960 68 58
sub_80EB9C8 eb9c8 e
sub_80EB9D8 eb9d8 84 58
sub_80EBA5C eba5c 18c
sub_80EBBE8 ebbe8 28
sub_80EBC10 ebc10 98
sub_80EBCA8 ebca8 70
sub_80EBD18 ebd18 16
sub_80EBD30 ebd30 1a
sub_80EBD4C ebd4c 1a
sub_80EBD68 ebd68 16
sub_80EBD80 ebd80 e
sub_80EBD90 ebd90 2c
sub_80EBDBC ebdbc 1c
sub_80EBDD8 ebdd8 234
sub_80EC00C ec00c 204
sub_80EC210 ec210 58
sub_80EC268 ec268 238
sub_80EC4A0 ec4a0 1dc
sub_80EC67C ec67c 1a0
sub_80EC81C ec81c 50
sub_80EC86C ec86c f4
sub_80EC960 ec960 48
sub_80EC9A8 ec9a8 68
sub_80ECA10 eca10 1f8
sub_80ECC08 ecc08 178
sub_80ECD80 ecd80 29c
sub_80ED01C ed01c 300
sub_80ED31C ed31c b4
sub_80ED3D0 ed3d0 108
sub_80ED4D8 ed4d8 148
sub_80ED620 ed620 238
sub_80ED858 ed858 330
sub_80EDB88 edb88 234
sub_80EDDBC eddbc b4
sub_80EDE70 ede70 74
sub_80EDEE4 edee4 188
sub_80EE06C ee06c 228
sub_80EE294 ee294 144
sub_80EE3D8 ee3d8 1b4
sub_80EE58C ee58c cc
sub_80EE658 ee658 29c
sub_80EE8F4 ee8f4 78
sub_80EE96C ee96c 54
sub_80EE9C0 ee9c0 4c
sub_80EEA0C eea0c 204
sub_80EEC10 eec10 80
sub_80EEC90 eec90 7c
sub_80EED0C eed0c e
sub_80EED1C eed1c e
sub_80EED2C eed2c 70
sub_80EED9C eed9c 28
sub_80EEDC4 eedc4 24
sub_80EEDE8 eede8 20
sub_80EEE08 eee08 18
sub_80EEE20 eee20 34
sub_80EEE54 eee54 e0
sub_80EEF34 eef34 44
sub_80EEF78 eef78 44
sub_80EEFBC eefbc 28c
sub_80EF248 ef248 3c
sub_80EF284 ef284 1a4
sub_80EF428 ef428 68
sub_80EF490 ef490 68
sub_80EF4F8 ef4f8 54
sub_80EF54C ef54c 40
sub_80EF58C ef58c 98
sub_80EF624 ef624 11a
sub_80EF740 ef740 40
sub_80EF780 ef780 54
sub_80EF7D4 ef7d4 40
sub_80EF814 ef814 2c
sub_80EF840 ef840 34
sub_80EF874 ef874 184
sub_80EF9F8 ef9f8 1b8
sub_80EFBB0 efbb0 2a
sub_80EFBDC efbdc 60
sub_80EFC3C efc3c 28
sub_80EFC64 efc64 d8
sub_80EFD3C efd3c 38
sub_80EFD74 efd74 2c
sub_80EFDA0 efda0 44
sub_80EFDE4 efde4 98
sub_80EFE7C efe7c b8
sub_80EFF34 eff34 34
sub_80EFF68 eff68 20c
sub_80F0174 f0174 30
sub_80F01A4 f01a4 3c
sub_80F01E0 f01e0 84
sub_80F0264 f0264 3c
sub_80F02A0 f02a0 39c
sub_80F063C f063c dc
sub_80F0718 f0718 80
sub_80F081C f081c c8
sub_80F08E4 f08e4 1c
sub_80F0900 f0900 44
sub_80F0944 f0944 e
sub_80F0954 f0954 38
sub_80F098C f098c 98
sub_80F0A24 f0a24 50
sub_80F0A74 f0a74 b0
sub_80F0B24 f0b24 20
sub_80F0B44 f0b44 e4
sub_80F0C28 f0c28 20
sub_80F0C48 f0c48 90
sub_80F0D5C f0d5c 164
sub_80F0EC0 f0ec0 34
sub_80F0EF4 f0ef4 70
sub_80F0F64 f0f64 3c
sub_80F0FA0 f0fa0 4c
sub_80F0FEC f0fec e
sub_80F0FFC f0ffc 60
sub_80F105C f105c 24
sub_80F1080 f1080 1b8
sub_80F13FC f13fc 3c
sub_80F1438 f1438 48
sub_80F1480 f1480 12
sub_80F1494 f1494 114
sub_80F15A8 f15a8 6c
sub_80F1614 f1614 18
sub_80F162C f162c e0
sub_80F170C f170c 30
sub_80F173C f173c 3c
sub_80F1778 f1778 1bc
sub_80F1934 f1934 a8
sub_80F19DC f19dc 20
sub_80F19FC f19fc 78
sub_80F1A74 f1a74 c
sub_80F1A80 f1a80 10
sub_80F1A90 f1a90 34
sub_80F1AC4 f1ac4 c8
sub_80F1B8C f1b8c 3c
sub_80F1BC8 f1bc8 228
sub_80F1DF0 f1df0 60
sub_80F1E50 f1e50 1a
sub_80F1E6C f1e6c 16
sub_80F1E84 f1e84 8c
sub_80F1F10 f1f10 e0
sub_80F1FF0 f1ff0 9c
sub_80F208C f208c a
sub_80F2098 f2098 5c
sub_80F20F4 f20f4 14
sub_80F2108 f2108 40
sub_80F2148 f2148 28
sub_80F2170 f2170 88
sub_80F21F8 f21f8 20
sub_80F2218 f2218 28
sub_80F2240 f2240 6e
sub_80F22B0 f22b0 46
sub_80F22F8 f22f8 68
sub_80F2360 f2360 68
sub_80F23C8 f23c8 44
sub_80F240C f240c 4c
sub_80F2458 f2458 bc
sub_80F2514 f2514 84
sub_80F2598 f2598 86
sub_80F2620 f2620 34
sub_80F2654 f2654 32
sub_80F2688 f2688 34
sub_80F26BC f26bc 120
sub_80F27DC f27dc 1dc
sub_80F29B8 f29b8 204
sub_80F2BBC f2bbc 58
sub_80F2C14 f2c14 42
sub_80F2C58 f2c58 28
sub_80F2C80 f2c80 3c
sub_80F2CBC f2cbc 48
sub_80F2D04 f2d04 68
sub_80F2D6C f2d6c 6c
sub_80F2DD8 f2dd8 1a
sub_80F2DF4 f2df4 a
sub_80F2E00 f2e00 18
sub_80F2E18 f2e18 130
sub_80F2F48 f2f48 34
sub_80F2F7C f2f7c 34
sub_80F2FB0 f2fb0 3c
sub_80F2FEC f2fec 1c
sub_80F3008 f3008 128
sub_80F3130 f3130 60
sub_80F3190 f3190 1c
sub_80F31AC f31ac b6
sub_80F3264 f3264 30
sub_80F3294 f3294 94
sub_80F3328 f3328 38
sub_80F3360 f3360 48
sub_80F33A8 f33a8 1d4
sub_80F357C f357c 38
sub_80F35B4 f35b4 60
sub_80F3614 f3614 28
sub_80F363C f363c 2c
sub_80F3668 f3668 30
sub_80F3698 f3698 58
sub_80F36F0 f36f0 34
sub_80F3724 f3724 78
sub_80F379C f379c 34
sub_80F37D0 f37d0 e6
sub_80F38B8 f38b8 34
sub_80F38EC f38ec 84
sub_80F3970 f3970 34
sub_80F39A4 f39a4 96
sub_80F3A3C f3a3c c4
sub_80F3B00 f3b00 58
sub_80F3B58 f3b58 3c
sub_80F3B94 f3b94 40
sub_80F3BD4 f3bd4 58
sub_80F3C2C f3c2c 68
sub_80F3C94 f3c94 54
sub_80F3CE8 f3ce8 16
sub_80F3D00 f3d00 a8
sub_80F3DDC f3ddc 26
sub_80F3E04 f3e04 20
sub_80F3E24 f3e24 78
sub_80F3E9C f3e9c 84
sub_80F3F20 f3f20 8c
sub_80F3FAC f3fac 44
sub_80F3FF0 f3ff0 34
sub_80F4024 f4024 114
sub_80F4138 f4138 5a
sub_80F4194 f4194 130
sub_80F42C4 f42c4 d0
sub_80F4394 f4394 40
sub_80F43D4 f43d4 54
sub_80F4428 f4428 12
sub_80F443C f443c 20
sub_80F445C f445c 54
sub_80F44B0 f44b0 98
sub_80F45A0 f45a0 ec
sub_80F468C f468c 198
sub_80F4824 f4824 dc
sub_80F4900 f4900 2c
sub_80F492C f492c 18
sub_80F4944 f4944 b0
sub_80F49F4 f49f4 12c
sub_80F4B20 f4b20 b0
sub_80F4BD0 f4bd0 120
sub_80F4CF0 f4cf0 54
sub_80F4D44 f4d44 44
sub_80F4D88 f4d88 1ee
sub_80F4F78 f4f78 3c
sub_80F4FB4 f4fb4 28
sub_80F4FDC f4fdc 5c
sub_80F5038 f5038 28
sub_80F5060 f5060 1e4
sub_80F5264 f5264 94
sub_80F52F8 f52f8 6c
sub_80F5364 f5364 88
sub_80F53EC f53ec 118
sub_80F5504 f5504 4c
sub_80F5550 f5550 a
sub_80F555C f555c e
sub_80F556C f556c 40
sub_80F55AC f55ac d0
sub_80F567C f567c a
sub_80F5688 f5688 254
sub_80F58DC f58dc 140
sub_80F5A1C f5a1c 11c
sub_80F5B38 f5b38 18
sub_80F5B50 f5b50 8c
sub_80F5BDC f5bdc 14
sub_80F5BF0 f5bf0 ec
sub_80F5CDC f5cdc f8
sub_80F5DD4 f5dd4 4c
sub_80F5E20 f5e20 c4
sub_80F5EE4 f5ee4 d0
sub_80F5FB4 f5fb4 5c
sub_80F6010 f6010 62
sub_80F6074 f6074 c0
sub_80F6134 f6134 d4
sub_80F6208 f6208 48
sub_80F6250 f6250 13a
sub_80F638C f638c 44
sub_80F63D0 f63d0 142
sub_80F6514 f6514 1cc
sub_80F66E0 f66e0 208
sub_80F68E8 f68e8 164
sub_80F6A4C f6a4c a4
sub_80F6AF0 f6af0 130
sub_80F6C20 f6c20 198
sub_80F6DB8 f6db8 4c
sub_80F6E04 f6e04 98
sub_80F6E9C f6e9c 38
sub_80F6ED4 f6ed4 3c
sub_80F6F10 f6f10 54
sub_80F6F64 f6f64 54
sub_80F6FB8 f6fb8 44
sub_80F6FFC f6ffc 10
sub_80F700C f700c 80
sub_80F708C f708c 70
sub_80F70FC f70fc 128
sub_80F7224 f7224 56
sub_80F727C f727c 10
sub_80F728C f728c 48
sub_80F72D4 f72d4 130
sub_80F7404 f7404 14
sub_80F7418 f7418 58
sub_80F7470 f7470 90
sub_80F7500 f7500 11a
sub_80F761C f761c 2ac 134
sub_80F78CC f78cc 3a 134
sub_80F7908 f7908 18 134
sub_80F7920 f7920 20
sub_80F7940 f7940 20
sub_80F7960 f7960 b0 134
sub_80F7A10 f7a10 24
sub_80F7DC0 f7dc0 13a 131
sub_80F7EFC f7efc 10 131
sub_80F7F0C f7f0c c 131
sub_80F7F18 f7f18 a 131
sub_80F7F24 f7f24 a 131
sub_80F7F30 f7f30 4e
sub_80F8428 f8428 10 131
sub_80F8A28 f8a28 328 126
sub_80F8D50 f8d50 2c 126
sub_80F8D7C f8d7c 22 126
sub_80F8DA0 f8da0 e0 126
sub_80F8E80 f8e80 98 126
sub_80F8F18 f8f18 12 126
sub_80F8F2C f8f2c 2c 126
sub_80F8F58 f8f58 20 126
sub_80F8F78 f8f78 3c 126
sub_80F8FB4 f8fb4 6c 126
sub_80F9090 f9090 28 133
sub_80F9284 f9284 38
sub_80F92BC f92bc 38
sub_80F92F4 f92f4 26
sub_80F931C f931c 28
sub_80F9344 f9344 22
sub_80F9368 f9368 d0
sub_80F9480 f9480 24
sub_80F94A4 f94a4 54
sub_80F94F8 f94f8 28
sub_80F9520 f9520 1c
sub_80F9834 f9834 70 133
sub_80F99CC f99cc 40
sub_80F9C00 f9c00 6c
sub_80F9E1C f9e1c 48
sub_80FA364 fa364 108
sub_80FA46C fa46c 76 53
sub_80FA670 fa670 d0 53
sub_80FA740 fa740 88 53
sub_80FA904 fa904 3c
sub_80FA940 fa940 1d0
sub_80FAB60 fab60 18
sub_80FAB78 fab78 cc 167
sub_80FAD04 fad04 e0 167
sub_80FADE4 fade4 e0 167
sub_80FAEC4 faec4 fa
sub_80FAFC0 fafc0 1b0
sub_80FB238 fb238 28 167
sub_80FB600 fb600 158 167
sub_80FB758 fb758 24e 167
sub_80FBA18 fba18 88 167
sub_80FBAA0 fbaa0 50 167
sub_80FBCA0 fbca0 30
sub_80FBDF8 fbdf8 2c 167
sub_80FBE24 fbe24 80 167
sub_80FBF94 fbf94 20
sub_80FC244 fc244 10
sub_80FC5B4 fc5b4 4c 167
sub_80FC600 fc600 9c 167
sub_80FC69C fc69c 104
sub_80FE1DC fe1dc 44
sub_80FE220 fe220 1c
sub_80FE2B4 fe2b4 38
sub_80FE394 fe394 30
sub_80FE418 fe418 e
sub_80FE428 fe428 48
sub_80FE470 fe470 b8
sub_80FE528 fe528 84
sub_80FE5AC fe5ac 58
sub_80FE604 fe604 122
sub_80FE728 fe728 2e
sub_80FE758 fe758 50
sub_80FE7A8 fe7a8 2c
sub_80FE7D4 fe7d4 18
sub_80FE7EC fe7ec 7c
sub_80FE868 fe868 2c
sub_80FE894 fe894 b2
sub_80FE948 fe948 174
sub_80FEABC feabc 1d8
sub_80FEC94 fec94 22
sub_80FECB8 fecb8 26
sub_80FECE0 fece0 3c
sub_80FED1C fed1c 1e
sub_80FED3C fed3c 28
sub_80FED64 fed64 2c
sub_80FED90 fed90 198
sub_80FEF28 fef28 28
sub_80FEF50 fef50 24
sub_80FEF74 fef74 30
sub_80FEFA4 fefa4 4e
sub_80FEFF4 feff4 40
sub_80FF034 ff034 24
sub_80FF058 ff058 40
sub_80FF098 ff098 48
sub_80FF0E0 ff0e0 34
sub_80FF114 ff114 4c
sub_80FF160 ff160 50
sub_80FF1B0 ff1b0 3c
sub_80FF1EC ff1ec 1a8
sub_80FF394 ff394 e0
sub_80FF474 ff474 116
sub_80FF58C ff58c 30
sub_80FF5BC ff5bc f0
sub_80FF6AC ff6ac d4
sub_80FF960 ff960 150
sub_80FFAB0 ffab0 58
sub_80FFB08 ffb08 64
sub_80FFB6C ffb6c 26
sub_80FFB94 ffb94 48
sub_80FFBDC ffbdc 48
sub_80FFC24 ffc24 412
sub_8100038 100038 68
sub_81000A0 1000a0 24
sub_81000C4 1000c4 b0
sub_8100174 100174 d4
sub_8100248 100248 24
sub_810026C 10026c 20
sub_810028C 10028c 30
sub_8100334 100334 30
sub_8100364 100364 28
sub_810038C 10038c a4
sub_8100430 100430 2a
sub_810045C 10045c 38
sub_8100494 100494 1c8
sub_810065C 10065c 4c
sub_81006A8 1006a8 28
sub_81006D0 1006d0 3c
sub_810070C 10070c 34
sub_8100740 100740 132
sub_8100874 100874 28
sub_810089C 10089c 20
sub_81008BC 1008bc 74
sub_8100930 100930 78
sub_81009A8 1009a8 18
sub_81009C0 1009c0 4a
sub_8100A0C 100a0c 54
sub_8100A60 100a60 1c
sub_8100A7C 100a7c a4
sub_8100B20 100b20 4a
sub_8100B6C 100b6c 11c
sub_8100C88 100c88 b0
sub_8100D38 100d38 4c
sub_8100E70 100e70 7c
sub_8100EEC 100eec 9c
sub_8100F88 100f88 2c
sub_8100FB4 100fb4 70
sub_8101024 101024 cc
sub_81010F0 1010f0 28
sub_8101118 101118 80
sub_8101198 101198 68
sub_8101200 101200 a0
sub_81012A0 1012a0 9e
sub_8101340 101340 78
sub_81013B8 1013b8 a8
sub_8101460 101460 b8
sub_8101518 101518 24
sub_810153C 10153c 30
sub_810156C 10156c 24
sub_8101590 101590 20
sub_81015B0 1015b0 30
sub_81015E0 1015e0 68
sub_8101648 101648 30
sub_8101678 101678 20
sub_8101698 101698 30
sub_81016C8 1016c8 2c
sub_81016F4 1016f4 c
sub_8101700 101700 50
sub_8101750 101750 50
sub_81017A0 1017a0 84
sub_8101824 101824 24
sub_8101848 101848 58
sub_81019EC 1019ec 38 199
sub_8101D04 101d04 20 199
sub_8101D24 101d24 38 199
sub_8101D5C 101d5c 30 199
sub_8101D8C 101d8c 24 199
sub_8101DB0 101db0 42 199
sub_8101DF4 101df4 1c 199
sub_8101E10 101e10 2c 199
sub_8101E3C 101e3c f0 199
sub_8101F2C 101f2c 18 199
sub_8101F44 101f44 1c 199
sub_8101F60 101f60 28 199
sub_8101F88 101f88 1c 199
sub_8101FA4 101fa4 64 199
sub_8102008 102008 2c 199
sub_8102034 102034 24 199
sub_8102058 102058 38 199
sub_8102090 102090 38 199
sub_81020C8 1020c8 118
sub_81021E0 1021e0 1c 199
sub_81021FC 1021fc 68 199
sub_8102264 102264 3c 199
sub_81022A0 1022a0 2c 199
sub_81022CC 1022cc 24 199
sub_81022F0 1022f0 28 199
sub_8102318 102318 2c 199
sub_8102344 102344 58 199
sub_810239C 10239c 1c 199
sub_81023B8 1023b8 28 199
sub_81023E0 1023e0 1c 199
sub_81023FC 1023fc 28 199
sub_8102424 102424 3c 199
sub_8102460 102460 24 199
sub_8102484 102484 6c 199
sub_81024F0 1024f0 1c 199
sub_810250C 10250c 34 199
sub_8102540 102540 38 199
sub_8102578 102578 44 199
sub_81025BC 1025bc 90 199
sub_810264C 10264c 34 199
sub_8102680 102680 5c 199
sub_81026DC 1026dc 2c 199
sub_8102A24 102a24 20 199
sub_8102A44 102a44 1e 199
sub_8102A64 102a64 38 199
sub_8102A9C 102a9c 34 199
sub_8102AD0 102ad0 b0 199
sub_8102B80 102b80 24 199
sub_8102C48 102c48 3c 199
sub_8102C84 102c84 48 199
sub_8102CCC 102ccc 5c 199
sub_8102D28 102d28 34 199
sub_8102D5C 102d5c 4c 199
sub_8102DA8 102da8 44 199
sub_8102DEC 102dec 30 199
sub_8102E1C 102e1c 24 199
sub_8102E40 102e40 28 199
sub_8102E68 102e68 38 199
sub_8102EA0 102ea0 4 199
sub_8102EA4 102ea4 1c 199
sub_8102EC0 102ec0 8c 199
sub_8102F4C 102f4c bc 199
sub_8103008 103008 54 199
sub_810305C 10305c 48 199
sub_81030A4 1030a4 3c 199
sub_81030E0 1030e0 54 199
sub_8103134 103134 1e 199
sub_8103154 103154 5e 199
sub_81031B4 1031b4 10c 199
sub_81032C0 1032c0 28 199
sub_81032E8 1032e8 54 199
sub_810333C 10333c a0 199
sub_81033DC 1033dc 40 199
sub_810341C 10341c 5e 199
sub_810347C 10347c 78 199
sub_81034F4 1034f4 2c 199
sub_8103520 103520 20 199
sub_8103540 103540 24 199
sub_8103564 103564 88 199
sub_8103668 103668 fa 199
sub_8103764 103764 26 199
sub_810378C 10378c 30 199
sub_81037BC 1037bc 50 199
sub_810380C 10380c 24 199
sub_8103830 103830 e0 199
sub_8103910 103910 168 199
sub_8103A78 103a78 19a 199
sub_8103C14 103c14 34 199
sub_8103C48 103c48 30 199
sub_8103C78 103c78 34 199
sub_8103CAC 103cac 1c 199
sub_8103CC8 103cc8 38 199
sub_8103D00 103d00 28 199
sub_8103D28 103d28 28 199
sub_8103D50 103d50 3c 199
sub_8103D8C 103d8c 3c 199
sub_8103DC8 103dc8 3c 199
sub_8103E04 103e04 34 199
sub_8103E38 103e38 42 199
sub_8103E7C 103e7c 2e 199
sub_8103EAC 103eac 36 199
sub_8103EE4 103ee4 8c 199
sub_8103F70 103f70 30 199
sub_8103FA0 103fa0 48 199
sub_8103FE8 103fe8 60 199
sub_8104048 104048 1c 199
sub_8104064 104064 34 199
sub_8104098 104098 30 199
sub_81040C8 1040c8 20 199
sub_81040E8 1040e8 30 199
sub_810411C 10411c 28 199
sub_8104144 104144 68 199
sub_81041AC 1041ac 70 199
sub_810421C 10421c 1e 199
sub_810423C 10423c ce 199
sub_810430C 10430c 20 199
sub_810432C 10432c 1e 199
sub_810434C 10434c 30 199
sub_810437C 10437c 70 199
sub_81043EC 1043ec 7c 199
sub_8104468 104468 30 199
sub_8104498 104498 b0 199
sub_8104548 104548 50 199
sub_8104598 104598 32 199
sub_81045CC 1045cc 6e 199
sub_810463C 10463c 84 199
sub_81046C0 1046c0 a4 199
sub_8104764 104764 2e 199
sub_8104794 104794 58 199
sub_81047EC 1047ec 74 199
sub_8104860 104860 48 199
sub_81048A8 1048a8 24 199
sub_81048CC 1048cc 74 199
sub_8104940 104940 88 199
sub_81049C8 1049c8 30 199
sub_81049F8 1049f8 48 199
sub_8104A40 104a40 48 199
sub_8104A88 104a88 30 199
sub_8104AB8 104ab8 34 199
sub_8104AEC 104aec 1e 199
sub_8104B0C 104b0c 30 199
sub_8104B3C 104b3c 24 199
sub_8104B60 104b60 20 199
sub_8104B80 104b80 48 199
sub_8104BC8 104bc8 34 199
sub_8104BFC 104bfc 48 199
sub_8104C44 104c44 18 199
sub_8104C5C 104c5c 50 199
sub_8104CAC 104cac 84 199
sub_8104D30 104d30 72 199
sub_8104DA4 104da4 74
sub_8104E18 104e18 5a 199
sub_8104E74 104e74 30 199
sub_8104EA8 104ea8 70 199
sub_8104F18 104f18 74 199
sub_8104F8C 104f8c 68 199
sub_8104FF4 104ff4 78 199
sub_810506C 10506c 58 199
sub_81050C4 1050c4 3c 199
sub_8105100 105100 4c 199
sub_810514C 10514c 24 199
sub_8105170 105170 50 199
sub_81051C0 1051c0 c4 199
sub_8105284 105284 68 199
sub_81052EC 1052ec 70 199
sub_810535C 10535c 44 199
sub_81053A0 1053a0 bc 199
sub_810545C 10545c 5c 199
sub_81054B8 1054b8 6c 199
sub_8105524 105524 30 199
sub_8105554 105554 24 199
sub_8105578 105578 b4 199
sub_810562C 10562c 5c 199
sub_8105688 105688 38 199
sub_81056C0 1056c0 30 199
sub_81056F0 1056f0 94 199
sub_8105784 105784 64 199
sub_81057E8 1057e8 1c 199
sub_8105804 105804 50 199
sub_8105854 105854 40 199
sub_8105894 105894 c 199
sub_81058A0 1058a0 24 199
sub_81058C4 1058c4 88 199
sub_810594C 10594c 6a 199
sub_81059B8 1059b8 30 199
sub_81059E8 1059e8 50 199
sub_8105A38 105a38 92 199
sub_8105ACC 105acc 20 199
sub_8105AEC 105aec 30 199
sub_8105B1C 105b1c 54 199
sub_8105B70 105b70 18 199
sub_8105B88 105b88 2c 199
sub_8105BB4 105bb4 44
sub_8105BF8 105bf8 6c 199
sub_8105C64 105c64 6 199
sub_8105C6C 105c6c 84 199
sub_8105CF0 105cf0 16 199
sub_8105D08 105d08 16 199
sub_8105D20 105d20 1a 199
sub_8105D3C 105d3c 68 199
sub_8105DA4 105da4 62 199
sub_8105E08 105e08 ac 199
sub_8105EB4 105eb4 a0 199
sub_8105F54 105f54 48 199
sub_8105F9C 105f9c bc 199
sub_8106058 106058 a4 199
sub_81060FC 1060fc cc 199
sub_81061C8 1061c8 68 199
sub_8106230 106230 130 199
sub_8106364 106364 c 199
sub_8106370 106370 2c 199
sub_810639C 10639c 24 199
sub_81063C0 1063c0 44 199
sub_8106404 106404 44 199
sub_8106448 106448 70 199
sub_81064B8 1064b8 20 199
sub_81065A8 1065a8 34 199
sub_81065DC 1065dc 54 199
sub_810745C 10745c 44
sub_810993C 10993c 90
sub_8109A20 109a20 10
sub_8109A30 109a30 18
sub_8109B34 109b34 48
sub_8109D04 109d04 a8
sub_8109DAC 109dac 34
sub_810A62C 10a62c 60 206
sub_810A68C 10a68c 38 206
sub_810B3DC 10b3dc 4c 171
sub_810B428 10b428 a4 171
sub_810B4CC 10b4cc 38 171
sub_810B53C 10b53c 20 171
sub_810B58C 10b58c 16 171
sub_810B5D8 10b5d8 20 171
sub_810B634 10b634 40 171
sub_810B674 10b674 16 156
sub_810B68C 10b68c 34 156
sub_810B6C0 10b6c0 2aa 156
sub_810B96C 10b96c 2c
sub_810B998 10b998 b6 156
sub_810BA50 10ba50 2c
sub_810BA7C 10ba7c 60
sub_810BADC 10badc 18
sub_810BB0C 10bb0c 24 156
sub_810BB30 10bb30 58 156
sub_810BB88 10bb88 fc 156
sub_810BC84 10bc84 14 156
sub_810BC98 10bc98 70 156
sub_810BD08 10bd08 5c 156
sub_810BD64 10bd64 48 156
sub_810BDAC 10bdac 18a 156
sub_810BF38 10bf38 44 156
sub_810BF7C 10bf7c 14c 156
sub_810C0C8 10c0c8 100 156
sub_810C1C8 10c1c8 74 156
sub_810C23C 10c23c 74 156
sub_810C2B0 10c2b0 16 156
sub_810C2C8 10c2c8 54 156
sub_810C31C 10c31c 4c 156
sub_810C368 10c368 a4 156
sub_810C40C 10c40c b6 156
sub_810C4C4 10c4c4 44 156
sub_810C508 10c508 38 156
sub_810C540 10c540 80 156
sub_810C5C0 10c5c0 2c 156
sub_810C5EC 10c5ec 24 156
sub_810C610 10c610 58 156
sub_810C668 10c668 74 156
sub_810C6DC 10c6dc 28 156
sub_810C704 10c704 44 156
sub_810C748 10c748 40 156
sub_810C788 10c788 cc 156
sub_810C854 10c854 80 156
sub_810C8D4 10c8d4 7c 156
sub_810C9B0 10c9b0 36
sub_810C9E8 10c9e8 16
sub_810CB68 10cb68 4a
sub_810CBFC 10cbfc 38 89
sub_810CC34 10cc34 20 89
sub_810CC54 10cc54 16
sub_810CC80 10cc80 dc
sub_810CD5C 10cd5c 5c 89
sub_810CE5C 10ce5c 1c 89
sub_810CE78 10ce78 a0 89
sub_810CF18 10cf18 44 89
sub_810CF5C 10cf5c 68 89
sub_810CFC4 10cfc4 34 89
sub_810D00C 10d00c 1c 89
sub_810D028 10d028 9c 89
sub_810D0C4 10d0c4 64 89
sub_810D128 10d128 58 89
sub_810E874 10e874 d0 76
sub_810E984 10e984 144
sub_810EAC8 10eac8 c8
sub_810EB90 10eb90 5c
sub_810EC34 10ec34 68
sub_810EC9C 10ec9c 12
sub_810ECB0 10ecb0 24
sub_810ECD4 10ecd4 28
sub_810ECFC 10ecfc 44
sub_810ED40 10ed40 20
sub_810ED60 10ed60 17c
sub_810EEDC 10eedc 30
sub_810F118 10f118 dc
sub_810F1F4 10f1f4 9c
sub_810F290 10f290 24
sub_810F2B4 10f2b4 28
sub_810F7A8 10f7a8 6c 76
sub_810F814 10f814 12 76
sub_810FA74 10fa74 2c
sub_810FB10 10fb10 8c
sub_810FB9C 10fb9c 7c
sub_810FC18 10fc18 98
sub_810FD80 10fd80 2c
sub_810FE1C 10fe1c e0
sub_810FEFC 10fefc 34
sub_810FF30 10ff30 18
sub_810FF48 10ff48 18
sub_810FF60 10ff60 18
sub_8110494 110494 52 19
sub_81141F0 1141f0 11c
sub_811430C 11430c c0
sub_8114DB4 114db4 3c
sub_8114DF0 114df0 56
sub_8114E48 114e48 188
sub_81150D8 1150d8 20 65
sub_81150FC 1150fc 28
sub_8115124 115124 114
sub_8115238 115238 14a
sub_8115384 115384 2b0
sub_8115634 115634 88
sub_81156BC 1156bc 78
sub_8115734 115734 48
sub_811577C 11577c 30
sub_81157AC 1157ac 24
sub_81157D0 1157d0 158
sub_8115928 115928 54
sub_811597C 11597c 40
sub_81159BC 1159bc d8
sub_8115A94 115a94 c2
sub_8115B58 115b58 200
sub_8115D58 115d58 48
sub_8115DA0 115da0 74
sub_8115E14 115e14 b8
sub_8115ECC 115ecc 8c
sub_8115F58 115f58 1a8
sub_8116100 116100 208
sub_8116308 116308 74
sub_811637C 11637c f8
sub_8116474 116474 a0
sub_8116514 116514 88
sub_811659C 11659c 9c
sub_8116638 116638 b0
sub_81166E8 1166e8 94
sub_811677C 11677c 78
sub_81167F4 1167f4 8c
sub_8116880 116880 174
sub_8116AB0 116ab0 90
sub_8116B40 116b40 80
sub_8116BC0 116bc0 74
sub_8116C34 116c34 78
sub_8116CAC 116cac 4c
sub_8116CF8 116cf8 5c
sub_8116D54 116d54 108
sub_8116E5C 116e5c 9a
sub_8116EF8 116ef8 260
sub_8117158 117158 228
sub_8117380 117380 b2
sub_8117434 117434 90
sub_81174C4 1174c4 1c
sub_81174E0 1174e0 18
sub_81174F8 1174f8 30
sub_8117528 117528 34
sub_811755C 11755c 64
sub_81175C0 1175c0 1c
sub_81175DC 1175dc 54
sub_8117630 117630 78
sub_8117838 117838 56
sub_8117890 117890 70
sub_8117900 117900 174
sub_8117AA8 117aa8 114
sub_8117BBC 117bbc a4
sub_8117C60 117c60 106
sub_8117D68 117d68 8c
sub_8117DF4 117df4 a4
sub_8117E98 117e98 94
sub_8117F2C 117f2c 1c8
sub_81180F4 1180f4 f4
sub_81181E8 1181e8 b2
sub_811829C 11829c 5c
sub_81182F8 1182f8 1d4
sub_81184CC 1184cc c
sub_81184D8 1184d8 7c
sub_8118554 118554 28
sub_811857C 11857c 6c
sub_81185E8 1185e8 84
sub_811866C 11866c 4a
sub_81186B8 1186b8 30
sub_81186E8 1186e8 3c
sub_8118724 118724 110
sub_8118834 118834 68
sub_811889C 11889c 10c
sub_81189A8 1189a8 188
sub_8118B30 118b30 a8
sub_8118BD8 118bd8 d4
sub_8118CAC 118cac 40
sub_8118CEC 118cec 40
sub_8118D2C 118d2c b6
sub_8118DE4 118de4 1a8
sub_8118F8C 118f8c fc
sub_8119088 119088 ac
sub_8119134 119134 c0
sub_81191F4 1191f4 30
sub_8119224 119224 1b0
sub_81193D4 1193d4 158
sub_811952C 11952c 254
sub_8119780 119780 58
sub_81197D8 1197d8 c0
sub_8119898 119898 cc
sub_8119964 119964 12c
sub_8119A90 119a90 1a
sub_8119AAC 119aac 78
sub_8119B24 119b24 a8
sub_8119BCC 119bcc 13c
sub_8119D08 119d08 78
sub_8119D80 119d80 bc
sub_811AA18 11aa18 20 94
sub_811AA38 11aa38 1c 94
sub_811AA9C 11aa9c 20 94
sub_811B720 11b720 c8 23
sub_811C90C 11c90c 28 23
sub_811C934 11c934 4 23
sub_811C938 11c938 4c 23
sub_811C984 11c984 32 23
sub_811C9B8 11c9b8 2c 23
sub_811C9E4 11c9e4 2a 23
sub_811CA10 11ca10 18 23
sub_811CA28 11ca28 1c 23
sub_811CA44 11ca44 18 23
sub_811CFD0 11cfd0 e8 23
sub_811D52C 11d52c 1e 23
sub_811D658 11d658 24 23
sub_811D690 11d690 18 23
sub_811D6A8 11d6a8 2c 23
sub_811D6D4 11d6d4 12 23
sub_811D6E8 11d6e8 7c 23
sub_811D764 11d764 198 23
sub_811D8FC 11d8fc 7a 23
sub_811D978 11d978 fc 23
sub_811DAE4 11dae4 38
sub_811DB1C 11db1c 68
sub_811DB84 11db84 3c
sub_811DBC0 11dbc0 e0
sub_811DCA0 11dca0 148
sub_811DDE8 11dde8 40
sub_811DE98 11de98 9c
sub_811DF34 11df34 6c
sub_811DFA0 11dfa0 18
sub_811E034 11e034 6c
sub_811E0A0 11e0a0 2c
sub_811E0CC 11e0cc f0
sub_811E1BC 11e1bc 9c
sub_811E258 11e258 44
sub_811E29C 11e29c 78
sub_811E38C 11e38c 2c
sub_811E3B8 11e3b8 2c
sub_811EC68 11ec68 9fc
sub_811F864 11f864 16c
sub_811FA5C 11fa5c 88
sub_811FF30 11ff30 164
sub_812071C 12071c 10c
sub_81208E0 1208e0 40
sub_8121E10 121e10 24
sub_8121E34 121e34 24
sub_81220C8 1220c8 104 37
sub_81221F8 1221f8 b8 37
sub_812238C 12238c c4 37
sub_8122450 122450 30 37
sub_8122480 122480 28 37
sub_81224A8 1224a8 88 37
sub_8122530 122530 72 37
sub_81225A4 1225a4 30 37
sub_81225D4 1225d4 88 37
sub_8122728 122728 48 37
sub_81227FC 1227fc 3c 37
sub_81228E8 1228e8 68 37
sub_8122950 122950 68 37
sub_81229B8 1229b8 8e 37
sub_8122AB8 122ab8 58 37
sub_8122B10 122b10 108 37
sub_8122C18 122c18 48 37
sub_8122D94 122d94 78 37
sub_8122F90 122f90 72 37
sub_8123004 123004 30 37
sub_8123034 123034 88 37
sub_8123138 123138 38
sub_8123170 123170 3c 37
sub_81231AC 1231ac 18 37
sub_81231C4 1231c4 26 37
sub_8123740 123740 138 35
sub_8123878 123878 16c 35
sub_81239E4 1239e4 114 35
sub_8123AF8 123af8 148 35
sub_8123CB8 123cb8 e0 35
sub_8123D98 123d98 11e 35
sub_8123EB8 123eb8 8a 35
sub_8123F44 123f44 78 35
sub_8123FBC 123fbc 15c 35
sub_812446C 12446c d0 35
sub_812453C 12453c 5c 35
sub_8124598 124598 5c 35
sub_81245F4 1245f4 178 35
sub_812476C 12476c 140 35
sub_81248AC 1248ac 6c 35
sub_8124918 124918 14
sub_812492C 12492c 84
sub_81249E4 1249e4 208 175
sub_8124BEC 124bec 90 175
sub_8124CE8 124ce8 54
sub_8124D3C 124d3c 9e
sub_8124DDC 124ddc 50
sub_8124E2C 124e2c 50
sub_812550C 12550c 5e 177
sub_812556C 12556c 4c 177
sub_81255B8 1255b8 19e 177
sub_812587C 12587c 3e 177
sub_81258BC 1258bc b8 177
sub_8125D80 125d80 26
sub_8125DA8 125da8 34
sub_8125DDC 125ddc 28
sub_8125E04 125e04 28
sub_8125E2C 125e2c 40
sub_8125E6C 125e6c 5c
sub_8127ED0 127ed0 2c
sub_8127EFC 127efc 2c
sub_8127F28 127f28 34
sub_8127F5C 127f5c 8 70
sub_8127F64 127f64 a 70
sub_8127F70 127f70 c 70
sub_8127FD4 127fd4 38 70
sub_812800C 12800c 94 70
sub_81280A0 1280a0 82 70
sub_8128124 128124 50
sub_8128174 128174 40 70
sub_812869C 12869c 28
sub_81286C4 1286c4 3c
sub_812882C 12882c c8 70
sub_8128A7C 128a7c 2c 40
sub_812ACA4 12aca4 24 40
sub_812ACC8 12acc8 34 40
sub_812AF10 12af10 20
sub_812AF30 12af30 68
sub_812AF98 12af98 6c 189
sub_812B004 12b004 54 189
sub_812B058 12b058 b0
sub_812B108 12b108 84 189
sub_812B18C 12b18c 12a
sub_812B2B8 12b2b8 54
sub_812B30C 12b30c 34
sub_812B340 12b340 34
sub_812B374 12b374 90
sub_812B404 12b404 60 189
sub_812B65C 12b65c 38
sub_812B694 12b694 18
sub_812B6AC 12b6ac 40
sub_812B724 12b724 34
sub_812B758 12b758 3c
sub_812B794 12b794 2c
sub_812C144 12c144 40 7
sub_812C184 12c184 4a 7
sub_812C1D0 12c1d0 50
sub_812C220 12c220 48 7
sub_812C268 12c268 3c 7
sub_812C2A4 12c2a4 18 7
sub_812C2BC 12c2bc 9c 7
sub_812C358 12c358 28 7
sub_812C380 12c380 8c 7
sub_812C40C 12c40c 44 7
sub_812C450 12c450 ac 7
sub_812C4FC 12c4fc 64 7
sub_812C560 12c560 28
sub_812C588 12c588 9c 7
sub_812C624 12c624 28
sub_812C64C 12c64c d4 7
sub_812C720 12c720 78 7
sub_812C798 12c798 30 7
sub_812C7C8 12c7c8 44 7
sub_812C80C 12c80c 3c 7
sub_812C848 12c848 be 7
sub_812C908 12c908 1a 7
sub_812C924 12c924 3c
sub_812C960 12c960 30
sub_812C990 12c990 74 7
sub_812CA04 12ca04 cc 7
sub_812CAD0 12cad0 2c 7
sub_812CAFC 12cafc b8 7
sub_812CBB4 12cbb4 72 7
sub_812CC28 12cc28 1c 7
sub_812CC44 12cc44 64
sub_812CCA8 12cca8 40
sub_812CCE8 12cce8 7c 7
sub_812CD64 12cd64 62 7
sub_812CDC8 12cdc8 128
sub_812CEF0 12cef0 118 7
sub_812D008 12d008 64
sub_812D06C 12d06c 1e6 7
sub_812D254 12d254 40 7
sub_812D294 12d294 bc 7
sub_812D350 12d350 5c
sub_812D3AC 12d3ac 108 7
sub_812D4B4 12d4b4 38 7
sub_812D4EC 12d4ec 9c 7
sub_812D588 12d588 60 7
sub_812D5E8 12d5e8 8c 7
sub_812D674 12d674 58
sub_812D6CC 12d6cc 58
sub_812D724 12d724 6a 7
sub_812D790 12d790 58
sub_812D7E8 12d7e8 330
sub_812DB58 12db58 2c
sub_812DB84 12db84 328
sub_812DEAC 12deac 140 7
sub_812DFEC 12dfec b0 7
sub_812E09C 12e09c 5c 7
sub_812E0F8 12e0f8 54 7
sub_812E14C 12e14c 34c
sub_812E498 12e498 58
sub_812E4F0 12e4f0 78 7
sub_812E568 12e568 d0
sub_812E638 12e638 166 7
sub_812E7A0 12e7a0 50 7
sub_812E7F0 12e7f0 70 7
sub_812E860 12e860 54
sub_812E8B4 12e8b4 198 7
sub_812EA4C 12ea4c c4 7
sub_812EB10 12eb10 168
sub_812EC78 12ec78 ac 7
sub_812ED24 12ed24 60 7
sub_812ED84 12ed84 7c 7
sub_812EE00 12ee00 a4 7
sub_812EEA4 12eea4 48 7
sub_812EEEC 12eeec dc 7
sub_812F290 12f290 84 7
sub_812F314 12f314 160
sub_812F474 12f474 2ae 7
sub_812F724 12f724 48
sub_812F76C 12f76c 98 7
sub_812F804 12f804 68 7
sub_812F86C 12f86c 1e
sub_812F88C 12f88c 50 7
sub_812F8DC 12f8dc 6c 7
sub_812F948 12f948 68 7
sub_812F9B0 12f9b0 148 7
sub_812FAF8 12faf8 170 7
sub_812FC68 12fc68 114
sub_812FD7C 12fd7c a4
sub_812FE20 12fe20 98 7
sub_812FEB8 12feb8 dc 7
sub_812FF94 12ff94 50 7
sub_812FFE4 12ffe4 58
sub_813003C 13003c 68 7
sub_81300A4 1300a4 50
sub_81300F4 1300f4 c0 7
sub_81301B4 1301b4 38 7
sub_81301EC 1301ec f8
sub_81302E4 1302e4 13e 7
sub_8130424 130424 b6 7
sub_81304DC 1304dc 40 7
sub_813051C 13051c 38 7
sub_8130554 130554 150
sub_81306A4 1306a4 10c 7
sub_81307B0 1307b0 ac 7
sub_813085C 13085c bc 7
sub_8130918 130918 58
sub_8130970 130970 bc 7
sub_8130A2C 130a2c 68 7
sub_8130A94 130a94 58 7
sub_8130AEC 130aec 4c 7
sub_8130B38 130b38 1e6 7
sub_8130D20 130d20 9c
sub_8130DBC 130dbc 1a0 7
sub_8130F5C 130f5c 84 7
sub_8130FE0 130fe0 204 7
sub_81311E4 1311e4 80 7
sub_8131264 131264 80 7
sub_81312E4 1312e4 124
sub_8131408 131408 15c 7
sub_8131564 131564 64 7
sub_81315C8 1315c8 130 7
sub_81316F8 1316f8 118
sub_8131810 131810 28 7
sub_8131838 131838 b8 7
sub_8131EB8 131eb8 142
sub_8133D28 133d28 28
sub_8133D50 133d50 124 93
sub_8133EF8 133ef8 54 93
sub_8134548 134548 d4
sub_8134AC0 134ac0 1b4
sub_81354CC 1354cc 68
sub_8135534 135534 38
sub_8135AC4 135ac4 dc
sub_8135CFC 135cfc 40 22
sub_8136130 136130 44
sub_8136174 136174 70 235
sub_81361E4 1361e4 48 235
sub_813622C 13622c 16 235
sub_8136244 136244 20 235
sub_8136264 136264 1c 235
sub_8136294 136294 30c 235
sub_81365A0 1365a0 28 235
sub_81365C8 1365c8 70 235
sub_8136638 136638 1d0 235
sub_8136808 136808 9c 235
sub_81368A4 1368a4 128 235
sub_81369CC 1369cc 178 235
sub_8136B44 136b44 72 235
sub_8136BB8 136bb8 88 235
sub_8136C40 136c40 2c 235
sub_8136C6C 136c6c 94 235
sub_8136D00 136d00 60 235
sub_8136D60 136d60 2c 235
sub_8136D8C 136d8c 14 235
sub_8136E40 136e40 b0 235
sub_8136EF0 136ef0 84 235
sub_8136F74 136f74 e4 235
sub_8137058 137058 4a 235
sub_81370A4 1370a4 40 235
sub_81370E4 1370e4 40 235
sub_8137124 137124 12
sub_8137138 137138 a4 235
sub_81371DC 1371dc 44 235
sub_813CCE8 13cce8 148 114
sub_813CE30 13ce30 58
sub_813CE88 13ce88 120 114
sub_813CFA8 13cfa8 dc 114
sub_813D084 13d084 48 114
sub_813D0CC 13d0cc 8a 114
sub_813D158 13d158 ae 114
sub_813D208 13d208 18 114
sub_813D220 13d220 148 114
sub_813D368 13d368 ac 114
sub_813D414 13d414 70 114
sub_813D788 13d788 f8 114
sub_813D880 13d880 88 114
sub_813D908 13d908 4a 114
sub_813DA64 13da64 138 114
sub_813DB9C 13db9c 1ba 114
sub_813DD58 13dd58 116 114
sub_813DE70 13de70 29c 114
sub_813E10C 13e10c 102 114
sub_813E210 13e210 fa 114
sub_813E30C 13e30c 1ac 114
sub_813E4B8 13e4b8 c8 114
sub_813E580 13e580 60 114
sub_813E5E0 13e5e0 e0 114
sub_813E6C0 13e6c0 100 114
sub_813E7C0 13e7c0 44 114
sub_813E804 13e804 12a 114
sub_813E930 13e930 50 114
sub_813E980 13e980 e0 114
sub_813EA60 13ea60 ec 114
sub_813EBBC 13ebbc d4 114
sub_813EC90 13ec90 12c 114
sub_813EDFC 13edfc b8 114
sub_813EFDC 13efdc ec
sub_813F0C8 13f0c8 2c
sub_813F300 13f300 1ec 9
sub_813F4EC 13f4ec fc
sub_813F5E8 13f5e8 b8
sub_813F6A0 13f6a0 2c
sub_813F6CC 13f6cc cc 9
sub_813F798 13f798 ac
sub_813F844 13f844 14c
sub_813F990 13f990 28
sub_813F9B8 13f9b8 28
sub_813F9E0 13f9e0 34
sub_813FA94 13fa94 e8
sub_813FB7C 13fb7c 3c 9
sub_813FBB8 13fbb8 104
sub_813FCBC 13fcbc 78 9
sub_813FD34 13fd34 5c 9
sub_813FD90 13fd90 30 9
sub_813FDC0 13fdc0 b0 9
sub_813FE70 13fe70 58 9
sub_813FEC8 13fec8 14c 9
sub_8140014 140014 44 9
sub_8140058 140058 100 9
sub_8140158 140158 48 9
sub_81401A0 1401a0 270 9
sub_8140410 140410 24 9
sub_8140434 140434 20 9
sub_8140454 140454 90 9
sub_81404E4 1404e4 e4 9
sub_81405C8 1405c8 2a 9
sub_81405F4 1405f4 c8 9
sub_81406BC 1406bc fc 9
sub_81407B8 1407b8 3c 9
sub_81407F4 1407f4 78 9
sub_8141314 141314 c8
sub_81413DC 1413dc 90 9
sub_814146C 14146c 50 9
sub_81414BC 1414bc 60 9
sub_814151C 14151c 1a8
sub_81416C4 1416c4 114
sub_81417D8 1417d8 30
sub_8141808 141808 20
sub_814191C 14191c 1bc 9
sub_8141AD8 141ad8 48 9
sub_8141B20 141b20 54 9
sub_8141B74 141b74 60 9
sub_8141BD4 141bd4 34
sub_8141C08 141c08 28
sub_8141C30 141c30 8c 9
sub_8141CBC 141cbc 38 9
sub_8141CF4 141cf4 2c 9
sub_8141D20 141d20 5c 9
sub_8141D7C 141d7c 30
sub_8141DAC 141dac 64
sub_8141E10 141e10 28
sub_8141E64 141e64 12a 107
sub_8141F90 141f90 34
sub_8141FC4 141fc4 34 107
sub_8141FF8 141ff8 184 107
sub_8142274 142274 44 107
sub_81422B8 1422b8 30 107
sub_81422E8 1422e8 38 107
sub_8142320 142320 e4 107
sub_8142404 142404 80 107
sub_8142484 142484 ec 107
sub_8142570 142570 a8 107
sub_8142618 142618 e0 107
sub_81426F8 1426f8 40 107
sub_8142738 142738 5c 107
sub_8142794 142794 84 107
sub_8142818 142818 38 107
sub_8142850 142850 50 107
sub_81428A0 1428a0 2c 107
sub_81428CC 1428cc 15c
sub_8142A28 142a28 dc 107
sub_8142B04 142b04 1c4 107
sub_8142CC8 142cc8 12c 107
sub_8142DF4 142df4 184 107
sub_8142F78 142f78 54 107
sub_8142FCC 142fcc 20 107
sub_8142FEC 142fec 40 107
sub_814302C 14302c 3c 107
sub_8143068 143068 20 107
sub_81433E0 1433e0 190 107
sub_8143570 143570 48 107
sub_81435B8 1435b8 24 107
sub_81435DC 1435dc 68 107
sub_8143648 143648 38
sub_8143680 143680 3c
sub_814386C 14386c 58 107
sub_81438C4 1438c4 84 107
sub_8146014 146014 16 26
sub_814602C 14602c 2c 26
sub_8146058 146058 202 26
sub_8146288 146288 30 26
sub_81462B8 1462b8 154 26
sub_814640C 14640c 34 26
sub_8146440 146440 40 26
sub_8146480 146480 64 26
sub_81464E4 1464e4 11c 26
sub_8146600 146600 a0 26
sub_81466A0 1466a0 48 26
sub_81466E8 1466e8 ae 26
sub_8146798 146798 78 26
sub_8146810 146810 ac 26
sub_81468BC 1468bc 44 26
sub_8147B04 147b04 1c 157
sub_8147B20 147b20 16e 157
sub_8147CC8 147cc8 114 157
sub_8148044 148044 34 157
sub_8148078 148078 3c 157
sub_81480B4 1480b4 54 157
sub_8148108 148108 74 157
sub_81481DC 1481dc 80 157
sub_814825C 14825c 2e4 157
sub_8148540 148540 8c 157
sub_81485CC 1485cc 4c 157
sub_814862C 14862c e4 157
sub_8148710 148710 f0
sub_8148C78 148c78 38
sub_8148CB0 148cb0 1e0
sub_8148E90 148e90 30
sub_8148EC0 148ec0 7c
sub_8148F3C 148f3c e4
sub_814910C 14910c 68
sub_8149174 149174 d4
sub_8149248 149248 1c
sub_8149264 149264 1c
sub_8149280 149280 1c
sub_81492A0 1492a0 70
sub_81493C4 1493c4 60
sub_8149E7C 149e7c 14c
sub_8149FC8 149fc8 24 64
sub_8149FEC 149fec 50 64
sub_814A03C 14a03c 11c 64
sub_814A464 14a464 52 227
sub_814A4B8 14a4b8 60 227
sub_814A590 14a590 30
sub_814A758 14a758 54
sub_814A904 14a904 54
sub_814A958 14a958 164
sub_814AABC 14aabc 3c
sub_814AAF8 14aaf8 8c
sub_814AB84 14ab84 60
sub_814ADC8 14adc8 2c
sub_814ADF4 14adf4 3c
sub_81DD264 1dd1f4 2bc
sub_81DD520 1dd4b0 8c
task00_8084310 86604 80
task05_08033660 30ea0 10c
task08_080A1C44 ca170 1c
task08_080C9820 10b34c 90 171
task0A_asap_script_env_2_enable_and_set_ctx_running 80970 1e
task0A_fade_n_map_maybe 810f0 6c
task50_0807B6D4 7e270 f4
task50_0807F0C8 8193c 22 75
taskFF_0805D1D4 5a268 6c 73
task_intro_14 13c54c 84 114
task_intro_15 13c5d0 54 114
task_intro_16 13c624 1c 114
task_intro_17 13c640 28 114
task_intro_19 13cadc 18 114
task_intro_20 13caf4 1bc 114
task_intro_29 967b8 24
task_map_chg_seq_0807E20C 80cb4 c0
task_map_chg_seq_0807E2CC 80d74 50
task_mpl_807DD60 809cc 70
task_mpl_807E3C8 80e04 22
task_pA_ma0A_obj_to_bg_pal 76588 d8 6
task_pc_turn_off 6bf00 26
task_tutorial_controls_fadein 124c7c 6a
tilemap_move_something 579d0 1c 66
umul3232H32 1dcda4 10
unc_0807DAB4 80654 5e
unref_GetRivalAvatarGenderByGraphicsId 5988c 2c
unref_sub_800D42C d42c 258
unref_sub_801030C 1030c 14
unref_sub_8011950 11950 20
unref_sub_8011A68 11a68 98
unref_sub_801B40C 1b40c 188
unref_sub_802C2B8 2c2b8 34
unref_sub_8031364 31364 3c
unref_sub_8031A64 31a64 2
unref_sub_8031BA0 31ba0 90
unref_sub_8032604 32604 32
unref_sub_803F938 3f938 11a
unref_sub_8040DAC 40dac 40
unref_sub_8041824 41824 4c
unref_sub_80438E0 438e0 32
unref_sub_8043E70 43e70 40
unref_sub_80504FC 504fc c
unref_sub_8050514 50514 c
unref_sub_80516F8 516f8 124
unref_sub_8053790 53790 3c
unref_sub_8054260 54264 24
unref_sub_8055568 5556c c
unref_sub_8055A6C 55a70 30
unref_sub_8055A9C 55aa0 4c
unref_sub_8055B74 55b78 28
unref_sub_805869C 586a0 18
unref_sub_8059790 59794 30
unref_sub_805BE24 5be28 34
unref_sub_805C014 5c018 20
unref_sub_805C43C 5c440 62
unref_sub_805C624 5c628 3c
unref_sub_8064BB8 64bbc 18
unref_sub_8064BD0 64bd4 22
unref_sub_8064CA0 64ca4 20
unref_sub_8064E5C 64e60 50
unref_sub_80651DC 651e0 24
unref_sub_806BCB8 6bcbc 30
unref_sub_806D964 6d968 38
unref_sub_806E564 6e568 2
unref_sub_806E568 6e56c 2
unref_sub_8070F90 70f94 24
unref_sub_8071DA4 71da8 5c
unref_sub_8071F98 71f9c 24
unref_sub_8071FBC 71fc0 40
unref_sub_8072098 7209c 18
unref_sub_8072A5C 72a60 54
unref_sub_8072D0C 72d10 c
unref_sub_8072DC0 72dc4 a
unref_sub_8073D3C 73d40 48
unref_sub_8073D84 73d88 78
unref_sub_8074168 7416c 2c
unref_sub_8074194 74198 30
unref_sub_80781F0 781f4 88
unref_sub_8078414 78418 44
unref_sub_8078588 7858c 44
unref_sub_80785CC 785d0 16
unref_sub_80793B0 793b4 12
unref_sub_8079D20 79d24 104
unref_sub_807B69C 7b6a0 144
unref_sub_807D894 7d894 2c
unref_sub_807DCB4 7dcb4 96
unref_sub_807DE24 7de24 14
unref_sub_8082590 82590 12
unref_sub_808286C 8286c 14
unref_sub_8082EEC 82eec 34
unref_sub_8083BB0 83bb0 2c
unref_sub_8083CC8 83cc8 28
unref_sub_8083CF0 83cf0 5c
unref_sub_808AD88 8ad88 24
unref_sub_808C540 8c540 b0
unref_sub_8094588 94588 38
unref_sub_8094928 94928 18
unref_sub_8094940 94940 18
unref_sub_8094DB0 94db0 70
unref_sub_8095A48 95a48 92
unref_sub_8095C60 95c60 2a
unref_sub_8095D08 95d08 c4
unref_sub_809D26C 9d26c 90
unref_sub_80A2DF4 a2df4 4
unref_sub_80A2F44 a2f44 10
unref_sub_80AAEE8 aaee8 46
unref_sub_80AE908 ae908 f4
unref_sub_80AF280 af280 20
unref_sub_80AF2E0 af2e0 1a
unref_sub_80AF5D0 af5d0 60
unref_sub_80AF89C af89c b0
unref_sub_80AFAB8 afab8 88
unref_sub_80B011C b011c 94
unref_sub_80B01B0 b01b0 30
unref_sub_80B01E0 b01e0 58
unref_sub_80B0994 b0994 1c
unref_sub_80B0EE8 b0ee8 3e
unref_sub_80B19D0 b19d0 2c
unref_sub_80BB724 bb724 40
unref_sub_80BCD7C bcd7c a0
unref_sub_80C8418 c8418 2e
unref_sub_80CA410 ca410 1c
unref_sub_80CA448 ca448 80
unref_sub_80CCB6C ccb6c e4
unref_sub_80CE260 ce260 74
unref_sub_80CE2D4 ce2d4 38
unref_sub_80DB6E4 db6e4 68
unref_sub_80E23A8 e23a8 110
unref_sub_80E4EC8 e4ec8 2e
unref_sub_80E4FDC e4fdc cc
unref_sub_80EB5E0 eb5e0 a0
unref_sub_80EB684 eb684 78
unref_sub_80FBCD0 fbcd0 10
unref_sub_80FBCE0 fbce0 10
unref_sub_81074A0 1074a0 24
unref_sub_8113B50 113b50 6a0
unref_sub_81143CC 1143cc 9e8
unref_sub_8117A74 117a74 34
unref_sub_8122C60 122c60 132
unref_sub_81249B0 1249b0 34
unref_sub_8124F94 124f94 44
unref_sub_8124FD8 124fd8 ca
unref_sub_81250A4 1250a4 72
unref_sub_8125118 125118 7c
unref_sub_8125F4C 125f4c 54
unref_sub_8125FA0 125fa0 4e
unref_sub_8125FF0 125ff0 78
unref_sub_8126068 126068 18
unref_sub_8126080 126080 18
unref_sub_812AECC 12aecc 42
unref_sub_812B464 12b464 2
unref_sub_812B838 12b838 2c
unref_sub_813F0F4 13f0f4 20c
unref_sub_814A7AC 14a7ac 50
unref_sub_814ABE4 14abe4 74
unused_sub_8073DFC 73e00 164 149
unused_sub_8073F60 73f64 c0 149
unused_sub_8074020 74024 58 149
walkrun_is_standing_still 64cc4 1a
warp1_set_2 53490 20
waterfall_1_do_anim_probably 86fd0 3c
waterfall_2_wait_anim_finish_probably 8700c 22
write_word_to_mem 52d00 10
zffu_offset_calc 60bc8 18
]==],
}
