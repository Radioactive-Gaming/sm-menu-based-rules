#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define LANGUAGE_LENGTH 3
#define LANGUAGE_CODE_LENGTH 3
#define PLUGIN_NAME "Menu Based Rules"
#define PLUGIN_AUTHOR "XARiUS, X8ETr1x"
#define PLUGIN_VERSION "2.0.0"
#define PLUGIN_URL "https://github.com/Radioactive-Gaming/sm-menu-based-rules/"
#define PLUGIN_DESC "Display menu of rules to clients when they join a server, or by console command."

////////////////////////////////////////////////////////////////////////////////
//
// VARIABLES
//
////////////////////////////////////////////////////////////////////////////////

// CVar handles, defined in OnPluginStart().
Handle  g_CvarEnabled;
Handle  g_CvarMenuTime;
Handle  g_CvarShowOnJoin;
Handle  g_CvarShowToAdmins;
Handle  g_CvarDisplayAttempts;
Handle  g_CvarDisplayFailureKick;
Handle  g_CvarShowMenuOptions;
Handle  g_CvarExpiration;

// Variables used to change CVar handle values after AutoExecConfig()
bool    g_displayFailureKick;                   // Maps to g_CvarDisplayFailureKick.
bool    g_pluginEnabled;                        // Maps to g_CvarEnabled.
bool    g_showMenuOptions;                      // Maps to g_CvarShowMenuOptions.
bool    g_showOnJoin;                           // Maps to g_CvarShowOnJoin.
bool    g_showToAdmins;                         // Maps to g_CvarShowToAdmins.
int     g_displayAttempts;                      // Maps to g_CvarDisplayAttempts.
int     g_expiration;                           // Maps to g_CvarExpiration
int     g_menuTime;                             // Maps to g_CvarMenuTime.

// Player data
bool    g_CookieExists[MAXPLAYERS];             // Tracks if the timer cookie exists for the player.
bool    g_CookiesCached[MAXPLAYERS];            // Tracks if the players cookies have been cached.
bool    g_IntermissionCalled;                   // Tracks if a player is intermission i.e. after a player has died and is waiting to spawn.  
char    g_clientName[MAX_NAME_LENGTH];          // Tracks player display name. Used for messages to the server chat.
Handle  g_cookie;                               // The read-only client cookie that sets an expiration time stamp.
 

// Menu and language settings
char    language[LANGUAGE_LENGTH];              // The language code of the server.
char    languageCode[LANGUAGE_CODE_LENGTH];     // Follows ISO 639 https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes
UserMsg g_VGUIMenu;

////////////////////////////////////////////////////////////////////////////////
//
// ENUMS
//
////////////////////////////////////////////////////////////////////////////////

public Plugin myinfo = {
	name        = PLUGIN_NAME,
	author      = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version     = PLUGIN_VERSION,
	url         = PLUGIN_URL
};

////////////////////////////////////////////////////////////////////////////////
//
// MAIN
//
////////////////////////////////////////////////////////////////////////////////

public void OnPluginStart() {
	
	// Load translation files
	LoadTranslations("common.phrases");
	LoadTranslations("showrules.phrases");
	LoadTranslations("showrulesdata.phrases");
	
        // Set the language for the translations
	int serverLanguage = GetServerLanguage();
	GetLanguageInfo(serverLanguage, languageCode, LANGUAGE_CODE_LENGTH, language, LANGUAGE_LENGTH);
  
	// Register a cookie for the time of rule acceptance.
	g_cookie = RegClientCookie("showrules", "Rules Agreement Timestamp", CookieAccess_Protected);
	
	// Late load support to ensure cookies are loaded for all players.
	for (int i = MaxClients; i > 0; --i) {
        
                if (AreClientCookiesCached(i) == false) {
            
                        continue;
                
                }
                
                else if (AreClientCookiesCached(i) == true) {
        
                        OnClientCookiesCached(i);
                        
                }
                
                else {
                
                        LogMessage("[ERROR] OnPluginStart(): AreClientCookiesCached contains a non-boolean value.");
                        
                        continue;
                        
                }
        
        }
        
	// Set CVars 
	CreateConVar("sm_showrules_version", PLUGIN_VERSION, "Menu Rules Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_CvarEnabled = CreateConVar("sm_showrules_enabled", "1", "Enable this plugin.  0 = Disabled.");
	g_CvarMenuTime = CreateConVar("sm_showrules_menutime", "120", "Time to display rules menu to client before dissolving (and kicking them).");
	g_CvarShowOnJoin = CreateConVar("sm_showrules_showonjoin", "1", "Display Rules menu to clients automatically upon joining the server.");
	g_CvarShowToAdmins = CreateConVar("sm_showrules_showtoadmins", "0", "On join, display menu to admins.");
	g_CvarDisplayAttempts = CreateConVar("sm_showrules_displayattempts", "20", "Number of times to attempt to display the rules menu. (3 second intervals)");
	g_CvarDisplayFailureKick = CreateConVar("sm_showrules_displayfailurekick", "1", "Kick the client if the rules cannot be displayed after defined display attempts.");
	g_CvarShowMenuOptions = CreateConVar("sm_showrules_showmenuoptions", "1", "Shows agree/disagree options instead of a single option to close the rules menu.");
	g_CvarExpiration = CreateConVar("sm_showrules_expiration", "24", "Number of hours before the previous terms agreement expires.");
	
	// Register server commands
	RegAdminCmd("sm_showrules", Command_rules, ADMFLAG_KICK, "sm_showrules <#userid|name>");

	// Create hooks for custom CVar values
	HookConVarChange(g_CvarEnabled, OnSettingChanged);
	HookConVarChange(g_CvarMenuTime, OnSettingChanged);
	HookConVarChange(g_CvarShowOnJoin, OnSettingChanged);
	HookConVarChange(g_CvarShowToAdmins, OnSettingChanged);
	HookConVarChange(g_CvarDisplayAttempts, OnSettingChanged);
	HookConVarChange(g_CvarDisplayFailureKick, OnSettingChanged);
	HookConVarChange(g_CvarShowMenuOptions, OnSettingChanged);
	HookConVarChange(g_CvarExpiration, OnSettingChanged);
	
	// Check for the VGUIMenu state
	g_VGUIMenu = GetUserMessageId("VGUIMenu");
  
	if (g_VGUIMenu == INVALID_MESSAGE_ID) {
	
		LogError("[CRITICAL] Cannot find VGUIMenu user message id.");
		SetFailState("VGUIMenu Not Found");
	
	}
	
	else {

	        HookUserMessage(g_VGUIMenu, UserMsg_VGUIMenu);
	        
        }

	// Execute the configuration
	AutoExecConfig(true);
	LogMessage("[INFO] Plugin loaded.");

}

public void OnConfigsExecuted() {

    // Convert CVars to required data types.
	g_pluginEnabled = GetConVarBool(g_CvarEnabled);
	g_menuTime = GetConVarInt(g_CvarMenuTime);
	g_showOnJoin = GetConVarBool(g_CvarShowOnJoin);
	g_showToAdmins = GetConVarBool(g_CvarShowToAdmins);
	g_displayAttempts = GetConVarInt(g_CvarDisplayAttempts);
	g_displayFailureKick = GetConVarBool(g_CvarDisplayFailureKick);
	g_showMenuOptions = GetConVarBool(g_CvarShowMenuOptions);
	g_expiration = GetConVarInt(g_CvarExpiration) * 3600;           // Convert from hours to seconds.

}

public void OnClientPostAdminCheck(int client) {
   
        // Skip everything if the plugin is set to disabled.
        if (g_pluginEnabled == true) {
                
                // Skip automatic rule display if disabled.                
                if (g_showOnJoin ==  true) {
                        
                        /* 
                        Check for a race condition with OnClientCookiesCached().
                        
                        This is unlikely as the client cookies on modern servers are typically 
                        cached far faster than the admin check completes. However, it is good to
                        catch it regardless.
                        */
                        for (int i = 0; i < 50; i++) {
                        
                                if (g_CookiesCached[client] == false) {
                        
                                        OnClientCookiesCached(client);
                        
                                }
                                
                                else if (g_CookiesCached[client] == true) {
                                
                                        i = 50;
                                        
                                }
                        
                        }
                        
                        // Skip if it's a bot.
                        if (IsFakeClient(client) == true) {
                                
                                return;
                                
                        }
                        
                        else if (IsFakeClient(client) == false) {
                                
                                // Skip if the player is an admin.
                                if (g_showToAdmins == false) {
                                                
                                        AdminId adminID = GetUserAdmin(client);
                                                
                                        if (adminID != INVALID_ADMIN_ID) {
                                                
                                                bool isAdmin = GetAdminFlag(adminID, Admin_Generic, Access_Effective); 
                                                                                                                                              
                                                if (isAdmin == true) {
                                                        
                                                        return;
                                                                
                                                }
                                                
                                        }
                                                
                                }
                                
                                if (g_CookieExists[client] == true) {
                                        
                                        char cookie[255];
                                        GetClientCookie(client, g_cookie, cookie, sizeof(cookie));
                                        int cookieTimeStamp = StringToInt(cookie);
                                        int cookieAge = GetTime() - cookieTimeStamp;
                                        
                                        if (cookieAge < g_expiration) {
                                                
                                                return;
        
                                        }
        
                                        else if (cookieAge >= g_expiration) {
                                                
                                                CreateTimer(3.0, CheckForMenu, client, TIMER_REPEAT);
                
                                        }
                                        
                                }
                        
                        }
                        
                        else {

                                LogMessage("[ERROR] Unexpected result in OnClientPostAdminCheck(): IsFakeClient() must return a boolean result.");
                
                        }

                }
        
                else if (g_showOnJoin ==  false) {
        
                        return;
                
                }
        
                else {
        
                        LogMessage("[ERROR] Unexpected result in OnClientPostAdminCheck(): g_showOnJoin must be a boolean value.");
                
                }
  
        }
        
        else if (g_pluginEnabled == false) {
        
                return;
        
        }
        
        else {
        
                LogMessage("[ERROR] Unexpected result in OnClientPostAdminCheck(): g_pluginEnabled must be a boolean value.");
        
        }

}

public void OnClientCookiesCached(int client) {

        // Track that cookies have been cached.
        g_CookiesCached[client] = true;
        
        // Check for the timer expiration cookie.
        char cookie[255];
        GetClientCookie(client, g_cookie, cookie, sizeof(cookie));
        
        if (IsNullString(cookie) == true) {

                g_CookieExists[client] = false;
                                        
        }
        
        else if (IsNullString(cookie) == false) {

                g_CookieExists[client] = true;
                                                
        }
        
}

public void OnMapEnd() {

	g_IntermissionCalled = false;

}

public void OnSettingChanged(ConVar convar, const char[] oldValue, const char[] newValue) {

        if (convar == g_CvarMenuTime) {
                
                g_menuTime = StringToInt(newValue);

        }

        else if (convar == g_CvarDisplayAttempts) {
        
                g_displayAttempts = StringToInt(newValue);

        }

        else if (convar == g_CvarExpiration) {
        
                g_expiration = StringToInt(newValue) * 3600;

        }

        else if (convar == g_CvarEnabled) {

                if (newValue[0] == '1') {
		
		        g_pluginEnabled = true;
                        LogMessage("[INFO] Plugin enabled, executing.");
                
                }

                else if (newValue[0] == '0') {
                
                        g_pluginEnabled = false;
                        LogMessage("[INFO] Plugin disabled.");
                
                }
                
                else {
                
                        LogMessage("[ERROR] Unexpected value for sm_showrules_enabled.");
                
                }
                
        }

        else if (convar == g_CvarDisplayFailureKick) {

                if (newValue[0] == '1') {
			
		        g_displayFailureKick = true;
		        LogMessage("[INFO] Kicking players on menu display failure.");
                }

                else if (newValue[0] == '0') {
      
                        g_displayFailureKick = false;
                        LogMessage("[INFO] Ignoring menu display failures.");
                
                }
                
                else {
                
                        LogMessage("[ERROR] Unexpected value for sm_showrules_displayfailurekick.");
                
                }
  
        }

        else if (convar == g_CvarShowMenuOptions) {
    
                if (newValue[0] == '1') {
			
			g_showMenuOptions = true;
			LogMessage("[INFO] Menu options enabled.");
                
                }

                else if (newValue[0] == '0') {
      
                        g_showMenuOptions = false;
                        LogMessage("[INFO] Menu options disabled.");
  
                }
                
                else {
                
                        LogMessage("[ERROR] Unexpected value for sm_showrules_showmenuoptions.");
                
                }
  
        }

        else if (convar == g_CvarShowOnJoin) {

                if (newValue[0] == '1') {
			
			g_showOnJoin = true;
			LogMessage("[INFO] Rules on join enabled.");
                }
                
                else if (newValue[0] == '0') {
      
                        g_showOnJoin = false;
                        LogMessage("[INFO] Rules on join disabled.");
    
                }
                
                else {
                
                        LogMessage("[ERROR] Unexpected value for sm_showrules_showonjoin.");
                
                }
        
        }
  
        else if (convar == g_CvarShowToAdmins) {
    
                if (newValue[0] == '1') {
			
			g_showToAdmins = true;
			LogMessage("[INFO] Rules to admins enabled.");
                
                }
    
                else if (newValue[0] == '0') {
      
                        g_showToAdmins = false;
                        LogMessage("[INFO] Rules to admins disabled.");
    
                }
                
                else {
                
                        LogMessage("[ERROR] Unexpected value for sm_showrules_showtoadmins.");
                
                }
  
        }
        
        else {
        
                LogMessage("[WARN] Unexpected CVar, skipping.");
        
        }

}

////////////////////////////////////////////////////////////////////////////////
//
// ACTIONS
//
////////////////////////////////////////////////////////////////////////////////

Action CheckForMenu(Handle timer, int client) {

        // Ensure the player is valid
        if ((IsClientConnected(client) == true) && (IsClientInGame(client) == true)) {
                
                // Try to display the menu up to the maximum tries.
                for (int i; i <= g_displayAttempts; i++) {
                        
                        MenuSource menuSrc = GetClientMenu(client);
                        
                        if (menuSrc == MenuSource_None) {
                                
                                Show_Rules(client);
                                i = g_displayAttempts + 1;
    
                                return Plugin_Stop;
                        
                        }
                        
                        else {
      
                                if (i == g_displayAttempts) {
                                
                                        // Kick the player upon failure.
                                        if (g_displayFailureKick == true) {
      
                                                CreateTimer(0.5, KickPlayer, client);
                                                
                                                return Plugin_Stop;
      
                                        }
                                        
                                        else {
                                                
                                                return Plugin_Continue;
                                                
                                        }
                                
                                }
    
                        }
  
                }
                
                return Plugin_Continue;
                
        }
        
        else {
                
                return Plugin_Continue;
                
        }

}

Action UserMsg_VGUIMenu(UserMsg msg_id, Handle bf, const int[] players, int playersNum, bool reliable, bool init) {
        
        if (g_IntermissionCalled == true) {
                
                return Plugin_Handled;
        
        }
        
        else if (g_IntermissionCalled == false) {
                
                char type[4];
                int strSize = BfReadString(bf, type, 4);

                // Check for a valid menu handle string.
                if (strSize < 0) {
                        
                        return Plugin_Handled;
                
                }
         
                else if (BfReadByte(bf) == 1 || BfReadByte(bf) == 0 || (strcmp(type, "scores", false) == 0)) {
                        
                        g_IntermissionCalled = true;
 
                        return Plugin_Handled;
          
                }
                
                else {
                        
                        return Plugin_Handled;
                        
                }
                
        }
        
        else {
                        
                return Plugin_Handled;
        
        }

}

Action Command_rules(int client, int args) {
         
        // Check for the required number of arguments.
        if (args < 1) {
    
                ReplyToCommand(client, "[SM] Usage: sm_showrules <#userid|name>");
    
                return Plugin_Handled;
  
        }
        
        else if (args >= 1) {

                // Grab the entire argument string.
                char Arguments[256];
                char arg[65];
                
                GetCmdArgString(Arguments, 256);
                BreakString(Arguments, arg, 65);

                // Search for the player based on the provided string.
                char target_name[MAX_TARGET_LENGTH];
                int target_list[MAXPLAYERS];
                int target_count;
                bool tn_is_ml;
                
                target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, MAX_TARGET_LENGTH, tn_is_ml);
                
                // Return if there's no pattern match.
                if (target_count <= 0) {
                
                        ReplyToTargetError(client, target_count);

                        return Plugin_Handled;
          
                }
                
                else if (target_count > 0) {
          
                        // Loop through the results.
                        for (int i = 0; i < target_count; i++) {
                                
                                
                                // Abort if the client is a bot or not yet in game.
                                if ((IsClientConnected(target_list[i]) == false) || (IsFakeClient(target_list[i]) == true) || (IsClientInGame(target_list[i]) == false)) {
                                        
                                        ReplyToCommand(client, "[SM] Client %s has not finished connecting or is timing out.  Please try again.", target_name);
                      
                                        return Plugin_Handled;
                                }
                                
                                else {
                      
                                        // Check the current menu status.
                                        MenuSource menuSrc = GetClientMenu(client);
                                        
                                        if (menuSrc == MenuSource_None) {
                        
                                                Show_Rules(target_list[i]);
                                                
                                        }
                                        
                                        else {
                        
                                                CreateTimer(3.0, CheckForMenu, target_list[i], TIMER_REPEAT);
                      
                                        }
                      
                                        ReplyToCommand(client,"[SM] %t %s", "Client Command Success", target_name);
                                        
                                        return Plugin_Handled;
                    
                                }
                  
                        }
                
                        return Plugin_Handled;
                
                }
                
                else {
                
                        LogMessage("[ERROR] Command_rules(): unexpected value in int 'target_count'.");
                        
                        return Plugin_Handled;
                        
                }
                
        }
        
        else {
        
                LogMessage("[ERROR] Command_rules(): unexpected value in int 'args'.");
                
                return Plugin_Handled;
        
        }

}

////////////////////////////////////////////////////////////////////////////////
//
// LOCAL FUNCTIONS
//
////////////////////////////////////////////////////////////////////////////////

void PanelHandler(Handle menu, MenuAction action, int param1, int param2) {
	
	if (action == MenuAction_Select) {
    
                if (param2 == 1) {
      
                        if (g_showMenuOptions) {
        
                                char timestamp[64];
        
                                IntToString(GetTime(), timestamp, sizeof(timestamp));
                                SetClientCookie(param1, g_cookie, timestamp);
                                PrintToChat(param1,"[SM] %t", "Player agrees to rules");
                        
                        }
    
                }
    
                else {
                        
                        GetClientName(param1, g_clientName, sizeof(g_clientName));
                        PrintToChatAll("[SM] %s %t", g_clientName, "Player disagreed public");
                        CreateTimer(0.5, KickPlayer, param1);
                
                }
  
        }

	else if (action == MenuAction_Cancel) {
    
                // -1 = Client disconnected
                if (param2 == -1) {
      
                        return;
                
                } 
    
                // -5 = Menu Timeout
                else if (param2 == -5) {
      
                        CreateTimer(0.5, KickPlayer, param1); 
                
                }
    
                // -4 = Unable to display panel | -2 = Interrupted by another menu
                else if ((param2 == -4 || param2 == -2)) {
      
                        CreateTimer(3.0, CheckForMenu, param1, TIMER_REPEAT);
    
                } 
  
        }

}

Action KickPlayer(Handle timer, any param1) {
  
        // Check if the client is in game prior to kick.
        if (IsClientInGame(param1) == true) {
    
                GetClientName(param1, g_clientName, sizeof(g_clientName));
                KickClient(param1, "%t", "Player disagrees to rules");
                LogMessage("%t %s", "Log kick message", g_clientName);
        
        }
  
        return Plugin_Handled;

}
 
Action Show_Rules(int client) {
  
        char title[128];
        char question[128];
        char yes[128];
        char no[128];
        char close[128];
        char ruleData[10][512];
        Handle panel = CreatePanel();
  
        // Format the content table for the menu.
        Format(title,       127, "%T", "Rules menu title", client);
        Format(question,    127, "%T", "Agree Question",   client);
        Format(yes,         127, "%T", "Yes Option",       client);
        Format(no,          127, "%T", "No Option",        client);
        Format(close,       127, "%T", "Close Option",     client);
        Format(ruleData[0], 512, "%T", "Rule Line 1",      client);
        Format(ruleData[1], 512, "%T", "Rule Line 2",      client);
        Format(ruleData[2], 512, "%T", "Rule Line 3",      client);
        Format(ruleData[3], 512, "%T", "Rule Line 4",      client);
        Format(ruleData[4], 512, "%T", "Rule Line 5",      client);
        Format(ruleData[5], 512, "%T", "Rule Line 6",      client);
        Format(ruleData[6], 512, "%T", "Rule Line 7",      client);
        Format(ruleData[7], 512, "%T", "Rule Line 8",      client);
        Format(ruleData[8], 512, "%T", "Rule Line 9",      client);
        Format(ruleData[9], 512, "%T", "Rule Line 10",     client);
  
        SetPanelTitle(panel, title);
        DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE); 
        
        // Check for valid rules in the configuration file.
        for (int i = 0; i <= 9; i++) {
    
                if (strlen(ruleData[i]) > 1) {
      
                        DrawPanelText(panel, ruleData[i]);
    
                }
  
        }
  
        DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
  
        if (g_showMenuOptions == true) {
    
                DrawPanelText(panel, question);
                DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
                DrawPanelItem(panel, yes);
                DrawPanelItem(panel, no);
  
        }
        
        else {
    
                DrawPanelItem(panel,close);

        }

        SendPanelToClient(panel, client, PanelHandler, g_menuTime);
        CloseHandle(panel);
  
        return Plugin_Handled;

}

