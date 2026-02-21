#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define PLUGIN_NAME "Menu Based Rules"
#define PLUGIN_AUTHOR "XARiUS, X8ETr1x"
#define PLUGIN_VERSION "1.6.1"
#define PLUGIN_URL "https://github.com/Radioactive-Gaming/sm-menu-based-rules/"
#define PLUGIN_DESC "Display menu of rules to clients when they join a server, or by console command."

char    clientname[MAX_NAME_LENGTH];
char    language[4];
char    languagecode[4];
char    playerid[MAXPLAYERS + 1][64];
char    steamid[64];
char    g_joinsound[PLATFORM_MAX_PATH];
int     playeridcount;
int     NumTries = 1;
int     g_expiration;
UserMsg g_VGUIMenu;
bool    prevclient;
bool    g_AdminChecked[MAXPLAYERS + 1];
bool    g_CookiesCached[MAXPLAYERS + 1];
bool    g_IntermissionCalled;
bool    g_enabled;
bool    g_showonjoin;
bool    g_showtoadmins;
bool    g_displayfailurekick;
bool    g_showmenuoptions;
int     g_menutime;
int     g_displayattempts;
Handle  g_Cvarenabled;
Handle  g_Cvarmenutime;
Handle  g_Cvarshowonjoin;
Handle  g_Cvarshowtoadmins;
Handle  g_Cvardisplayattempts;
Handle  g_Cvardisplayfailurekick;
Handle  g_Cvarshowmenuoptions;
Handle  g_Cvarjoinsound;
Handle  g_Cvarexpiration;
Handle  g_cookie;

public Plugin myinfo = {
	name        = PLUGIN_NAME,
	author      = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version     = PLUGIN_VERSION,
	url         = PLUGIN_URL
};

public void OnPluginStart() {

	LoadTranslations("common.phrases");
	LoadTranslations("showrules.phrases");
	LoadTranslations("showrulesdata.phrases");
  
	g_cookie = RegClientCookie("showrules", "Rules Agreement Timestamp", CookieAccess_Protected);
	GetLanguageInfo(GetServerLanguage(), languagecode, sizeof(languagecode), language, sizeof(language));
  
	CreateConVar("sm_showrules_version", PLUGIN_VERSION, "Menu Rules Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_Cvarenabled = CreateConVar("sm_showrules_enabled", "1", "Enable this plugin.  0 = Disabled.");
	g_Cvarjoinsound = CreateConVar("sm_showrules_joinsound", "", "Sound file to play to connecting clients.  Relative to the sound/ folder.  Example: 'welcome.mp3' or 'mysounds/welcome.mp3'");
	g_Cvarmenutime = CreateConVar("sm_showrules_menutime", "120", "Time to display rules menu to client before dissolving (and kicking them).");
	g_Cvarshowonjoin = CreateConVar("sm_showrules_showonjoin", "1", "Display Rules menu to clients automatically upon joining the server.");
	g_Cvarshowtoadmins = CreateConVar("sm_showrules_showtoadmins", "0", "On join, display menu to admins.");
	g_Cvardisplayattempts = CreateConVar("sm_showrules_displayattempts", "20", "Number of times to attempt to display the rules menu. (3 second intervals)");
	g_Cvardisplayfailurekick = CreateConVar("sm_showrules_displayfailurekick", "1", "Kick the client if the rules cannot be displayed after defined display attempts.");
	g_Cvarshowmenuoptions = CreateConVar("sm_showrules_showmenuoptions", "1", "Shows agree/disagree options instead of a single option to close the rules menu.");
	g_Cvarexpiration = CreateConVar("sm_showrules_expiration", "24", "Number of hours before the previous terms agreement expires.");
	
	RegAdminCmd("sm_showrules", Command_rules, ADMFLAG_KICK, "sm_showrules <#userid|name>");

	HookConVarChange(g_Cvarenabled, OnSettingChanged);
	HookConVarChange(g_Cvarmenutime, OnSettingChanged);
	HookConVarChange(g_Cvarshowonjoin, OnSettingChanged);
	HookConVarChange(g_Cvarshowtoadmins, OnSettingChanged);
	HookConVarChange(g_Cvardisplayattempts, OnSettingChanged);
	HookConVarChange(g_Cvardisplayfailurekick, OnSettingChanged);
	HookConVarChange(g_Cvarshowmenuoptions, OnSettingChanged);
	HookConVarChange(g_Cvarexpiration, OnSettingChanged);
	
	g_VGUIMenu = GetUserMessageId("VGUIMenu");
  
	if (g_VGUIMenu == INVALID_MESSAGE_ID) {
		LogError("FATAL: Cannot find VGUIMenu user message id.");
		SetFailState("VGUIMenu Not Found");
	}

	HookUserMessage(g_VGUIMenu, UserMsg_VGUIMenu);

	AutoExecConfig(true);

}

public void OnConfigsExecuted() {

	g_enabled = GetConVarBool(g_Cvarenabled);
	g_menutime = GetConVarInt(g_Cvarmenutime);
	g_showonjoin = GetConVarBool(g_Cvarshowonjoin);
	g_showtoadmins = GetConVarBool(g_Cvarshowtoadmins);
	g_displayattempts = GetConVarInt(g_Cvardisplayattempts);
	g_displayfailurekick = GetConVarBool(g_Cvardisplayfailurekick);
	g_showmenuoptions = GetConVarBool(g_Cvarshowmenuoptions);
	g_expiration = GetConVarInt(g_Cvarexpiration) * 3600;
	GetConVarString(g_Cvarjoinsound, g_joinsound, sizeof(g_joinsound));
	char buffer[PLATFORM_MAX_PATH];

	if (StrEqual(g_joinsound, "", false) == false) {
		
		Format(buffer, PLATFORM_MAX_PATH, "sound/%s", g_joinsound);

		if (FileExists(buffer, false)) {

			Format(buffer, PLATFORM_MAX_PATH, "%s", g_joinsound);

			if (!PrecacheSound(buffer, true)) {
	
				LogError("Menu Based Rules: Could not pre-cache defined sound: %s", buffer);
				SetFailState("Menu Based Rules: Could not pre-cache sound: %s", buffer);
      
			}
      
			else {
        
				Format(buffer, PLATFORM_MAX_PATH, "sound/%s", g_joinsound);
				AddFileToDownloadsTable(buffer);
      
			}

		}

	}

}

public void OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue) {

        if (convar == g_Cvarmenutime) {

                g_menutime = StringToInt(newValue);

        }

        if (convar == g_Cvardisplayattempts) {
        
                g_displayattempts = StringToInt(newValue);

        }

        if (convar == g_Cvarexpiration) {
        
                g_expiration = StringToInt(newValue) * 3600;

        }

        if (convar == g_Cvarenabled) {

                if (newValue[0] == '1') {
		
		        g_enabled = true;
                }

                else {
                
                        g_enabled = false;
                
                }
                
        }

        if (convar == g_Cvardisplayfailurekick) {

                if (newValue[0] == '1') {
			
		        g_displayfailurekick = true;
                }

                else {
      
                        g_displayfailurekick = false;
                
                }
  
        }

        if (convar == g_Cvarshowmenuoptions) {
    
                if (newValue[0] == '1') {
			
			g_showmenuoptions = true;
                
                }

                else {
      
                        g_showmenuoptions = false;
  
                }
  
        }

        if (convar == g_Cvarshowonjoin) {

                if (newValue[0] == '1') {
			
			g_showonjoin = true;
                }
                
                else {
      
                        g_showonjoin = false;
    
                }
        
        }
  
        if (convar == g_Cvarshowtoadmins) {
    
                if (newValue[0] == '1') {
			
			g_showtoadmins = true;
                
                }
    
                else {
      
                        g_showtoadmins = false;
    
                }
  
        }

}

public Action PlayJoinSound(Handle timer, any client) {

        if (!StrEqual(g_joinsound, "")) {
                
                EmitSoundToClient(client, g_joinsound);

        }

        return Plugin_Handled;

}

public Action CheckForMenu(Handle timer, any client) {

        if (GetClientMenu(client) == MenuSource_None && IsClientConnected(client) && IsClientInGame(client)) {

                Show_Rules(client);
                NumTries = 1;
    
                return Plugin_Stop;
        }
         
        else {
    
                if (NumTries++ >= g_displayattempts) {
      
                        NumTries = 1;
      
                        if (g_displayfailurekick) {
      
                                CreateTimer(0.5, KickPlayer, client);
      
                        }
      
                        return Plugin_Stop;
    
                }
  
        }
  
        return Plugin_Continue;

}

public void OnMapEnd() {

	g_IntermissionCalled = false;

}

public Action UserMsg_VGUIMenu(UserMsg msg_id, Handle bf, const int[] players, int playersNum, bool reliable, bool init) {

        if (g_IntermissionCalled) {
                
                return Plugin_Handled;
        
        }
  
        char type[15];

        /* If we don't get a valid string, bail out. */
        if (BfReadString(bf, type, sizeof(type)) < 0) {
                
                return Plugin_Handled;
        
        }
 
        if (BfReadByte(bf) == 1 && BfReadByte(bf) == 0 && (strcmp(type, "scores", false) == 0)) {
    
                g_IntermissionCalled = true;
                playeridcount = 0;

                for (int i = 1; i <= MaxClients; i++) {
            
                        if (IsClientInGame(i) && !IsFakeClient(i) && GetClientAuthId(i, AuthId_Steam2, playerid[playeridcount], sizeof(playerid[]))) {
            
                                playeridcount++;
        
                        }
      
                }
  
        }
  
        return Plugin_Handled;

}

public void CheckCookies(int client) {

        g_AdminChecked[client] = false;
        g_CookiesCached[client] = false;
        char cookie[64];
        GetClientCookie(client, g_cookie, cookie, sizeof(cookie));
  
        if (StrEqual(cookie, "")) {
                
                CreateTimer(3.0, CheckForMenu, client, TIMER_REPEAT);
        
        }
  
        else {
    
                int timestamp;
                timestamp = StringToInt(cookie);
    
                if ((GetTime() - timestamp) > g_expiration) {
      
                        CreateTimer(3.0, CheckForMenu, client, TIMER_REPEAT);
                
                }
  
        }

}

public void OnClientCookiesCached(int client) {
  
        g_CookiesCached[client] = true;
  
        if (g_AdminChecked[client]) {
                
                CheckCookies(client);
  
        }

}

public void OnClientPostAdminCheck(int client) {
  
        if (g_enabled) {
    
                if (g_showonjoin && IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client)) {
      
                        GetClientName(client, clientname, sizeof(clientname));
      
                        if (!g_showtoadmins) {
        
                                AdminId isadmin = GetUserAdmin(client);
        
                                if (isadmin != INVALID_ADMIN_ID) {
          
                                        return;
                        
                                }
      
                        }
      
                        g_AdminChecked[client] = true;
      
                        // Search through playerid array to see if user was here for map change.
                        prevclient = false;
                        GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
                        playeridcount = 0;

                        for (int i = 1; i <= MaxClients; i++) {
        
                                if (StrEqual(steamid,playerid[playeridcount])) {
          
                                        prevclient = true;
          
                                        return;
                                
                                }
                                
                                else {
          
                                        playeridcount++;
        
                                }
      
                        }
      
                        if (!prevclient) {
        
                                CreateTimer(1.0, PlayJoinSound, client);
      
                        }
      
                        if (g_CookiesCached[client]) {
        
                                CheckCookies(client);
      
                        }
    
                }
    
                return;
  
        }

}

public Action Command_rules(int client, int args) {
  
        char arg1[32];
        GetCmdArg(1,arg1, sizeof(arg1));
  
        if (args < 1) {
    
                ReplyToCommand(client, "[SM] Usage: sm_showrules <#userid|name>");
    
                return Plugin_Handled;
  
        }

        char Arguments[256];
        GetCmdArgString(Arguments, sizeof(Arguments));
        char arg[65];
        char len = BreakString(Arguments, arg, sizeof(arg));

        if (len == -1) {
    
                len = 0;
                Arguments[0] = '\0';
  
        }

        char target_name[MAX_TARGET_LENGTH];
        int target_list[MAXPLAYERS];
        int target_count;
        bool tn_is_ml;

        target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml);
        
        if (target_count <= 0) {
        
                ReplyToTargetError(client, target_count);

                return Plugin_Handled;
  
        }
  
        for (int i = 0; i < target_count; i++) {
                
                if (!IsClientConnected(target_list[i]) || IsFakeClient(target_list[i]) || !IsClientInGame(target_list[i])) {
                        
                        ReplyToCommand(client,"[SM] Client %s has not finished connecting or is timing out.  Please try again.", target_name);
      
                        return Plugin_Handled;
                }
                
                else {
      
                        if (GetClientMenu(target_list[i]) == MenuSource_None) {
        
                                Show_Rules(target_list[i]);
                        }
                        
                        else {
        
                                CreateTimer(3.0, CheckForMenu, target_list[i], TIMER_REPEAT);
      
                        }
      
                        ReplyToCommand(client,"[SM] %t %s", "Client Command Success", target_name);
    
                }
  
        }
        
        return Plugin_Handled;

}

public void PanelHandler(Handle menu, MenuAction action, int param1, int param2) {
	
	if (action == MenuAction_Select) {
    
                if (param2 == 1) {
      
                        if (g_showmenuoptions) {
        
                                char timestamp[64];
        
                                IntToString(GetTime(), timestamp, sizeof(timestamp));
                                SetClientCookie(param1, g_cookie, timestamp);
                                PrintToChat(param1,"[SM] %t", "Player agrees to rules");
                        
                        }
    
                }
    
                else {
      
                        PrintToChatAll("[SM] %s %t", clientname, "Player disagreed public");
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

public Action KickPlayer(Handle timer, any param1) {
  
        if (IsClientInGame(param1)) {
    
                GetClientName(param1, clientname, sizeof(clientname));
                KickClient(param1, "%t", "Player disagrees to rules");
                LogMessage("%t %s", "Log kick message", clientname);
        
        }
  
        return Plugin_Handled;

}
 
public Action Show_Rules(int client) {
  
        char title[128];
        char question[128];
        char yes[128];
        char no[128];
        char close[128];
        char ruleData[10][512];
        Handle panel = CreatePanel();
  
        Format(title,127, "%T", "Rules menu title", client);
        Format(question,127, "%T", "Agree Question", client);
        Format(yes,127, "%T", "Yes Option", client);
        Format(no,127, "%T", "No Option", client);
        Format(close,127, "%T", "Close Option", client);
        Format(ruleData[0], 512, "%T", "Rule Line 1", client);
        Format(ruleData[1], 512, "%T", "Rule Line 2", client);
        Format(ruleData[2], 512, "%T", "Rule Line 3", client);
        Format(ruleData[3], 512, "%T", "Rule Line 4", client);
        Format(ruleData[4], 512, "%T", "Rule Line 5", client);
        Format(ruleData[5], 512, "%T", "Rule Line 6", client);
        Format(ruleData[6], 512, "%T", "Rule Line 7", client);
        Format(ruleData[7], 512, "%T", "Rule Line 8", client);
        Format(ruleData[8], 512, "%T", "Rule Line 9", client);
        Format(ruleData[9], 512, "%T", "Rule Line 10", client);
  
        SetPanelTitle(panel,title);
        DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
        
        for (int i = 0; i <= 9; i++) {
    
                if (strlen(ruleData[i]) > 1) {
      
                        DrawPanelText(panel, ruleData[i]);
    
                }
  
        }
  
        DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
  
        if (g_showmenuoptions) {
    
                DrawPanelText(panel,question);
                DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
                DrawPanelItem(panel,yes);
                DrawPanelItem(panel,no);
  
        }
        
        else {
    
                DrawPanelItem(panel,close);

        }

        SendPanelToClient(panel, client, PanelHandler, g_menutime);
        CloseHandle(panel);
  
        return Plugin_Handled;

}

