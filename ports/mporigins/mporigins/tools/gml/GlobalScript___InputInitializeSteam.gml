function __InputInitializeSteam()
{
    with (__InputSystem())
    {
        __usingSteam = false;
        __usingSteamworks = false;
        __onSteamDeck = false;
        __onWINE = false;
        __steamHandlesArray = [];
        __steamSwitchLabels = false;
        __usingBigPicture = false;
        __steamTypeToInputTypeMap = ds_map_create();
        __steamTypeToDescriptionMap = ds_map_create();
        __steamInputTypeIgnoreMap = ds_map_create();
        var _steamEnviron = environment_get_variable("SteamEnv");
        
        if (_steamEnviron != "" && _steamEnviron == "1")
            __usingSteam = true;
        
        try
        {
        }
        catch (_error)
        {
            __InputTrace("Steamworks extension unavailable");
        }
        
        if (__usingSteamworks && string(steam_get_app_id()) == "480")
            __InputError("Steam application ID 480 is not supported.\nPlease change to your game's actual Steam application ID.\n \nIf you need a testing ID you should:\n1. Use ID 378090\n2. Set Debug to Enabled\n3. Install the game itself (Rebel Wings) on Steam.");
        
        if (!__onSteamDeck)
        {
            var _deck_envar = environment_get_variable("SteamDeck");
            
            if (_deck_envar != "")
            {
                __onSteamDeck = _deck_envar == "1";
            }
            else
            {
                var _map = os_get_info();
                
                if (ds_exists(_map, ds_type_map))
                {
                    var _identifier = undefined;
                    _identifier = ds_map_find_value(_map, "video_adapter_description");
                    
                    if (_identifier != undefined && __InputStringContains(_identifier, "AMD Custom GPU 0"))
                        __onSteamDeck = true;
                    
                    ds_map_destroy(_map);
                }
            }
        }
        
        var _switchLabels = environment_get_variable("SDL_GAMECONTROLLER_USE_BUTTON_LABELS");
        
        if (_switchLabels != "")
            __steamSwitchLabels = _switchLabels == "1";
        else
            __steamSwitchLabels = __onSteamDeck;
        
        if (__usingSteamworks)
        {
            __onWINE = environment_get_variable("WINEDLLPATH") != "";
            
            var _funcAddType = function(arg0, arg1, arg2)
            {
                ds_map_set(__steamTypeToInputTypeMap, arg0, arg1);
                ds_map_set(__steamTypeToDescriptionMap, arg0, arg2);
            };
            
            _funcAddType(steam_input_type_xbox_360_controller, 2, "Xbox 360 Controller");
            _funcAddType(steam_input_type_xbox_one_controller, 2, "Xbox One Controller");
            _funcAddType(steam_input_type_ps3_controller, 3, "PS3 Controller");
            _funcAddType(steam_input_type_ps4_controller, 3, "PS4 Controller");
            _funcAddType(steam_input_type_ps5_controller, 4, "PS5 Controller");
            _funcAddType(steam_input_type_steam_controller, 2, "Steam Controller");
            _funcAddType(steam_input_type_steam_deck_controller, 2, "Steam Deck Controller");
            _funcAddType(steam_input_type_mobile_touch, 2, "Steam Link");
            
            if (__steamSwitchLabels)
            {
                _funcAddType(steam_input_type_switch_pro_controller, 2, "Switch Pro Controller");
                _funcAddType(steam_input_type_switch_joycon_single, 2, "Joy-Con");
                _funcAddType(steam_input_type_switch_joycon_pair, 2, "Joy-Con Pair");
            }
            else
            {
                _funcAddType(steam_input_type_switch_pro_controller, 5, "Switch Pro Controller");
                _funcAddType(steam_input_type_switch_joycon_single, 7, "Joy-Con");
                _funcAddType(steam_input_type_switch_joycon_pair, 5, "Joy-Con Pair");
            }
            
            _funcAddType("unknown", 1, "Controller");
        }
    }
}
