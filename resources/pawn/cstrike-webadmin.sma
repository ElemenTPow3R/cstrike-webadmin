/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <sqlx>

#define PLUGIN "cstrike-webadmin"
#define VERSION "1.0"
#define AUTHOR "4evergaming"

//#define DEBUG

#define PREFIX "[SERVER]"

#define WEB "https://4evergaming.com.ar"

#define SERVER_ID 1


#define SQL_HOST ""
#define SQL_USER ""
#define SQL_PASSWORD ""
#define SQL_DATABASE ""


//#define USE_SXE

// =========== FROM THIS LINE, DO NOT TOUCH ===========
#define MYSQL_LOG "MYSQL_ERROR.txt"
#define MAX_BANS 250


// manejador de conexion sql
new Handle:g_SqlTuple;

enum {
    PLAYERS_INSERT,
    ADMINISTRATORS_SELECT,
    BANS_SELECT,
    GET_ADMIN_DATA,
    SHOW_BAN,
    STORE_BAN,
    DESTROY_BAN,
    SET_ONLINE_MODE,
}

new gBanAuth[MAX_BANS+1][44];
new gBanIp[MAX_BANS+1][32];

new gAdminId[MAX_PLAYERS+1][32];
new gAdminExpiration[MAX_PLAYERS+1][32];

// Ban Menu
new gAdminBanPlayer[MAX_PLAYERS+1];
new gAdminBanExpiration[MAX_PLAYERS+1][32];
new gAdminBanReason[MAX_PLAYERS+1][32];
new gLastPositionBan = 0;
new gUnbanPlayer[MAX_PLAYERS+1][44];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_concmd("amx_ban", "CmdBan", ADMIN_BAN, "<nick, #userid, authid> <time in minutes> <reason>");
	register_concmd("amx_banip", "CmdBan", ADMIN_BAN, "<nick, #userid, authid> <time in minutes> <reason>");
	register_concmd("amx_addban", "CmdBan", ADMIN_BAN, "<name> <authid or ip> <time in minutes> <reason>");
	register_concmd("amx_unban", "CmdUnban", ADMIN_BAN, "<authid or ip>");
	
	register_saycmd("adminmenu","cmdOpenAdminMenu", ADMIN_ADMIN,"Open Admin Menu");
	
	register_clcmd("nightvision", "cmdOpenAdminMenu");
	
	register_dictionary("cstrike_webadmin.txt");
	
	if (MYSQL_Init()) {
		loadAdmins();
		
		loadBans();
		
		set_task(300.0, "setOnlineMode", _, _, _, "b");
	}
}

public plugin_cfg()
{
    if(is_plugin_loaded("Pause Plugins") > -1)
        server_cmd("amx_pausecfg add ^"%s^"", PLUGIN);
}  

public setOnlineMode()
{
	new szQuery[300];
	formatex(szQuery, charsmax(szQuery), "UPDATE servers SET online_date = CURRENT_TIMESTAMP AND id = %d", SERVER_ID);
	
	#if defined DEBUG
		server_print("%s", szQuery);
	#endif
	
	executeLoadQuery(szQuery, SET_ONLINE_MODE);
}

public CmdUnban(id) {
	if(!is_user_admin(id) || !has_flag(id, "d")) return PLUGIN_HANDLED;
	
	// AuthID, IP or tag
	static arg[44];
	read_argv(1, arg, sizeof(arg) - 1);
	
	gUnbanPlayer[id] = arg;
	
	new szQuery[300];
	formatex(szQuery, charsmax(szQuery), "DELETE FROM bans WHERE (steam_id = ^"%s^" OR ip = ^"%s^" OR name = ^"%s^") AND server_id = %d", gUnbanPlayer[id], gUnbanPlayer[id], gUnbanPlayer[id], SERVER_ID);
	
	#if defined DEBUG
		server_print("%s", szQuery);
	#endif
	
	executeQuery(szQuery, id, DESTROY_BAN);
	
	return PLUGIN_HANDLED;
}

public CmdBan(id) {
	if(!is_user_admin(id) || !has_flag(id, "d")) return PLUGIN_HANDLED;
	
	if (equal(gAdminId[id], "")) {
		getAdminData(id);
		
		client_print_color(id, print_chat, "^4%s ^1%L", PREFIX, id, "ERROR_GETTING_DATA_FOR_ADMINISTRATOR");
		
		return PLUGIN_HANDLED;
	}
	
	// AuthID, IP or #userid
	static arg[128];
	read_argv(1, arg, sizeof(arg) - 1);
	
	new target = cmd_target(id, arg, GetTargetFlags(id));
	if(!target) return PLUGIN_HANDLED;
	
	if (has_flag(target, "a")) {
		client_cmd(id, "echo ^"^4%s ^1%L^"", PREFIX, id, "PLAYER_TO_BAN_HAS_IMMUNITY");
		
		return PLUGIN_HANDLED;
	}
	
	static target_authid[35];
	get_user_authid(target, target_authid, sizeof(target_authid) - 1);
	
	static target_authip[35];
	get_user_ip(target, target_authip, sizeof(target_authip) - 1, 1);
	
	for (new i = 0; i < MAX_BANS; i++) {
		if (equal(target_authid, gBanAuth[i]) || equal(target_authip, gBanIp[i])) {
			console_print(id, "%s %L", PREFIX, id, "ALREADY_BANNED");
			return PLUGIN_HANDLED;
		}
	}
	
	// Time
	read_argv(2, arg, sizeof(arg) - 1);
	
	if (equal(arg, "0")) {
		gAdminBanExpiration[id] = "null";
	} else {
		new minutes = str_to_num(arg);
		new seconds = minutes * 60;
		
		format_time(gAdminBanExpiration[id], 31, "^"%Y-%m-%d %H:%M^"", (get_systime() + seconds)); 
	}
	
	// Reason
	read_argv(3, arg, sizeof(arg) - 1);
	formatex(gAdminBanReason[id], charsmax(gAdminBanReason), "%s", arg);
	
	static target_name[32];
	get_user_name(target, target_name, sizeof(target_name) - 1);
	
	// IF AUTHID == VALVE_ID_LAN OR HLTV, BAN PER IP TO NOT BAN EVERYONE */
	if (equal("HLTV", target_authid) || equal("STEAM_ID_LAN", target_authid) || equali("VALVE_ID_LAN", target_authid)) {
		target_authid = "";
	}
	
	// Save index of the player
	gAdminBanPlayer[id] = get_user_index(target_name);
	
	new szQuery[300];
	formatex(szQuery, charsmax(szQuery), "INSERT INTO bans (name, steam_id, ip, expiration, reason, administrator_id, server_id) VALUES(^"%s^",^"%s^",^"%s^", %s,^"%s^",^"%s^",^"%d^")", target_name, target_authid, target_authip, gAdminBanExpiration[id], gAdminBanReason[id], gAdminId[id], SERVER_ID);
	
	#if defined DEBUG
		server_print("%s", szQuery);
	#endif
	
	executeQuery(szQuery, id, STORE_BAN);
	
	return PLUGIN_HANDLED;
}

GetTargetFlags(id) {
	static const flags_no_immunity = (CMDTARGET_ALLOW_SELF|CMDTARGET_NO_BOTS);
	static const flags_immunity = (CMDTARGET_ALLOW_SELF|CMDTARGET_NO_BOTS|CMDTARGET_OBEY_IMMUNITY);
	
	return access(id, ADMIN_IMMUNITY) ? flags_no_immunity : flags_immunity;
}

public cmdOpenAdminMenu(id) {
	
	if (has_flag(id, "z") && !equal(gAdminExpiration[id], "")) {
		// Admin expired
		
		client_print_color(id, print_chat, "^4%s ^1%L ^4%s", PREFIX, id, "ADMINISTRATOR_HAS_EXPIRED_THE_DAY", gAdminExpiration[id]);
		
		client_print_color(id, print_chat, "^4%s ^1%L ^4%s", PREFIX, id, "RENEW_ADMIN", WEB);
		
		return PLUGIN_HANDLED;
	}
	
	if (! is_user_admin(id)) {
		client_print_color(id, print_chat, "^4%s ^1%L", PREFIX, id, "ONLY_ADMINISTRATORS");
		client_print_color(id, print_chat, "^4%s ^1%L ^4%s", PREFIX, id, "BUY_ADMINISTRATOR", WEB);
		
		return PLUGIN_HANDLED;
	}
	
	if (equal(gAdminId[id], "")) {
		getAdminData(id);
		
		client_print_color(id, print_chat, "^4%s ^1%L", PREFIX, id, "ERROR_GETTING_DATA_FOR_ADMINISTRATOR");
		
		return PLUGIN_HANDLED;
	}
	
	new gMenu = menu_create("\r[SERVER] \yAdmins Menu :", "handlerMenu");
	menu_additem(gMenu, "Kick", "1");
	menu_additem(gMenu, "Slay/Slap", "2");
	menu_additem(gMenu, "Ban", "3");   
	menu_additem(gMenu, "Change map", "4");
	menu_additem(gMenu, "Transfer players", "5");
	menu_additem(gMenu, "Start voting of maps", "6");
	
	#if defined USE_SXE
	menu_additem(gMenu, "Open Screens Menu", "7");
	menu_additem(gMenu, "Open Local Ban menu", "8");
	#endif
	
	menu_setprop( gMenu, MPROP_EXIT, "Exit" );
	menu_display(id, gMenu, 0);
	
	return PLUGIN_HANDLED;
}	

public handlerMenu(id, menu, item) {
	if (item == MENU_EXIT) {	
		menu_destroy(menu)       
		return PLUGIN_HANDLED;    
	}
	
	switch(item) {
		case 0: {
			// Kick
			client_cmd(id , "amx_kickmenu");
		}
		
		case 1: {
			// Slay-Slap
			client_cmd(id , "amx_slapmenu");
		}
		
		case 2: {
			// Ban
			openBanMenu(id);
		}
		
		case 3: {
			// Change map
			client_cmd(id , "amx_mapmenu");
		}
		
		case 4: {
			// Transfer Players
			client_cmd(id , "amx_teammenu");
		}
		
		case 5: {
			// Transferir jugador
			client_cmd(id , "amx_votemapmenu");
		}
		
		#if defined USE_SXE
		case 6: {
			// Sxe Screens Menu
			client_cmd(id , "say /sxescreen");
		}
		
		case 7: {
			// Sxe Ban Local Menu
			client_cmd(id , "say /sxeban");
		}
		#endif
	}
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public openBanMenu(id) {
	
	if (! has_flag(id, "d")) {
		client_print_color(id, print_chat, "^4%s ^1%L", PREFIX, id, "NOT_ACCESS_TO_BAN");
		
		return PLUGIN_HANDLED;
	}
	
	new option_name[64];
	new playerId[4];
		
	new menu = menu_create("\r[SERVER] \yBan Menu :", "handlerBanMenu");
	
	for (new player = 1; player <= MAX_PLAYERS; player++) {
		if (! is_user_connected(player))
			continue;

		if (id == player)
			continue;
		
		new name[32];
		get_user_name(player,name,31);
		num_to_str(player, playerId,3);
		
		if (has_flag(player, "a")) {
			formatex(option_name, 63, "%s [%L]", name, id, "IMMUNITY");
		} else {
			formatex(option_name, 63, "%s", name);
		}
		
		menu_additem(menu, option_name, playerId);
		
	}
	
	menu_setprop(menu, MPROP_EXIT, "Exit");
	menu_display(id, menu, 0);
	
	return PLUGIN_HANDLED;
}

public handlerBanMenu(id, menu, item) {
	if (item == MENU_EXIT) {	
		menu_destroy(menu)       
		return PLUGIN_HANDLED;    
	}
	
	new iData[6];
	new iAccess;
	
	menu_item_getinfo(menu, item, iAccess, iData, 5)
	new player = str_to_num(iData);
	
	if (! is_user_connected(player)) {
		client_print_color(id, print_chat, "^4%s ^1%L", PREFIX, id, "PLAYER_TO_BAN_NOT_CONNECTED");

		return PLUGIN_HANDLED;
	}
	
	if (has_flag(player, "a")) {
		client_print_color(id, print_chat, "^4%s ^1%L", PREFIX, id, "PLAYER_TO_BAN_HAS_IMMUNITY");

		return PLUGIN_HANDLED;
	}
	
	gAdminBanPlayer[id] = player;
	
	openBanTimeMenu(id);
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public openBanTimeMenu(id) {
		
	new menu = menu_create("\r[SERVER] \yBan Time Menu :", "handlerBanTimeMenu");
	
	menu_additem(menu, "15 minutes", "15");
	menu_additem(menu, "30 minutes", "30");
	menu_additem(menu, "1 hour", "60");
	menu_additem(menu, "1 day", "1440");
	menu_additem(menu, "3 days", "4320");
	menu_additem(menu, "5 days", "7200");
	menu_additem(menu, "30 days", "43200");
	menu_additem(menu, "Permanent", "null");
	
	menu_setprop(menu, MPROP_EXIT, "Exit");
	menu_display(id, menu, 0);
	
	return PLUGIN_HANDLED;
}

public handlerBanTimeMenu(id, menu, item) {
	if (item == MENU_EXIT) {	
		menu_destroy(menu)       
		return PLUGIN_HANDLED;    
	}
	
	new iData[10];
	new iAccess;
	
	menu_item_getinfo(menu, item, iAccess, iData, 9)
	
	if (equal(iData, "null")) {
		gAdminBanExpiration[id] = "null";
	} else {
		new minutes = str_to_num(iData);
		new seconds = minutes * 60;
		
		format_time(gAdminBanExpiration[id], 31, "^"%Y-%m-%d %H:%M^"", (get_systime() + seconds)); 
	}
	
	openBanReasonsMenu(id);
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public openBanReasonsMenu(id) {
		
	new menu = menu_create("\r[SERVER] \yBan Reasons Menu :", "handlerBanReasonsMenu");
	
	menu_additem(menu, "Cheat detected", "Cheat detected");
	menu_additem(menu, "Chat flood", "Chat flood");
	menu_additem(menu, "Voice flood", "Voice flood");
	menu_additem(menu, "Spam", "Spam");
	menu_additem(menu, "Player annoying", "Player annoying");
	menu_additem(menu, "Insults to administrators", "Insults to administrators");
	menu_additem(menu, "Violence to other players", "Violence to other players");
	menu_additem(menu, "Another reason", "Another reason");
	
	menu_setprop(menu, MPROP_EXIT, "Exit");
	menu_display(id, menu, 0);
	
	return PLUGIN_HANDLED;
}

public handlerBanReasonsMenu(id, menu, item) {
	if (item == MENU_EXIT) {	
		menu_destroy(menu)       
		return PLUGIN_HANDLED;    
	}
	
	new player = gAdminBanPlayer[id];
	
	if (! is_user_connected(player)) {
		client_print_color(id, print_chat, "^4%s ^1%L", PREFIX, id, "PLAYER_TO_BAN_NOT_CONNECTED");

		return PLUGIN_HANDLED;
	}
	
	new iAccess;
	
	menu_item_getinfo(menu, item, iAccess, gAdminBanReason[id], 31)
	
	static name[32];
	get_user_name(player, name, charsmax(name));
	
	static auth[32];
	get_user_authid(player, auth, charsmax(auth));
		
	static ip[32];
	get_user_ip(player, ip, charsmax(ip), 1);
	
	// IF AUTHID == VALVE_ID_LAN OR HLTV, BAN PER IP TO NOT BAN EVERYONE */
	if (equal("HLTV", auth) || equal("STEAM_ID_LAN", auth) || equali("VALVE_ID_LAN", auth)) {
		auth = "";
	}
	
	new szQuery[300];
	formatex(szQuery, charsmax(szQuery), "INSERT INTO bans (name, steam_id, ip, expiration, reason, administrator_id, server_id) VALUES(^"%s^",^"%s^",^"%s^", %s,^"%s^",^"%s^",^"%d^")", name, auth, ip, gAdminBanExpiration[id], gAdminBanReason[id], gAdminId[id], SERVER_ID);
	
	#if defined DEBUG
		server_print("%s", szQuery);
	#endif
	
	executeQuery(szQuery, id, STORE_BAN);
	
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public MYSQL_Init() {   
			
	g_SqlTuple = SQL_MakeDbTuple(SQL_HOST, SQL_USER, SQL_PASSWORD, SQL_DATABASE);
	
	if (!g_SqlTuple)
	{
		log_to_file(MYSQL_LOG, "Could not create database tuple")
        
		// Pausamos el plugin
		return pause("a");
	}
	
	
	return true;
} 

public loadAdmins() {
	new szQuery[300];
	formatex(szQuery, charsmax(szQuery), "SELECT A.auth, A.password, R.access_flags, A.account_flags, IF(A.expiration < CURRENT_DATE, 'expired', 'not expired') as expiration  FROM administrators A JOIN privileges P ON A.id = P.administrator_id JOIN ranks R ON A.rank_id = R.id WHERE P.server_id = %d",SERVER_ID);
	
	#if defined DEBUG
		server_print("%s", szQuery);
	#endif
	
	executeLoadQuery(szQuery, ADMINISTRATORS_SELECT);
}


public loadBans() {

	new szQuery[300];
	formatex(szQuery, charsmax(szQuery), "SELECT steam_id, ip FROM bans where expiration >= CURRENT_TIMESTAMP() AND server_id = %d ORDER BY expiration DESC LIMIT %d", SERVER_ID, MAX_BANS);
	
	#if defined DEBUG
		server_print("%s", szQuery);
	#endif
	
	executeLoadQuery(szQuery, BANS_SELECT);
}

public client_putinserver(id) {
	
	clearData(id);
		
	if (is_banned_user(id)) {
		
		static auth[32];
		get_user_authid(id, auth, charsmax(auth));
		
		static ip[32];
		get_user_ip(id, ip, charsmax(ip), 1);
		
		new szQuery[300];
		formatex(szQuery, charsmax(szQuery), "SELECT B.id, B.name, B.steam_id, B.ip, B.date, B.expiration, B.reason, A.name as administrator  FROM bans B LEFT JOIN administrators A ON B.administrator_id = A.id WHERE B.server_id = %d AND (steam_id = ^"%s^" OR ip = ^"%s^") LIMIT 1",SERVER_ID, auth, ip);
		
		#if defined DEBUG
			server_print("%s", szQuery);
		#endif
		
		executeQuery(szQuery, id, SHOW_BAN);
		
		return;
	}
	
	registerPlayerLogin(id);
	
	getAdminData(id);
	
}

public clearData(id) {
	gAdminId[id] = "";
	gAdminExpiration[id] = "";
}

public getAdminData(id) {
	
	if (! is_user_admin(id) && ! has_flag(id, "z")) {
		return;
	}
	
	static name[32];
	get_user_name(id, name, 31);
	
	static auth[32];
	get_user_authid(id, auth, charsmax(auth));
	
	static ip[32];
	get_user_ip(id, ip, charsmax(ip), 1);
	
	new szQuery[200];
	formatex(szQuery, charsmax(szQuery), "SELECT id, DATE_FORMAT(expiration, '%s/%s/%s') as expiration FROM administrators WHERE auth = '%s' OR auth = '%s' OR auth = '%s' LIMIT 1", "%d", "%m", "%Y", name, auth, ip)

	executeQuery(szQuery, id, GET_ADMIN_DATA);
	
	#if defined DEBUG
		server_print("%s", szQuery);
	#endif	
}

public is_banned_user(id) {
	
	if (is_user_admin(id) && has_flag(id, "a")) {
		return false;
	}
	
	new i = 0;
	new banned = false;
	
	
	while (i < MAX_BANS && !banned) {
		
		static auth[32];
		get_user_authid(id, auth, charsmax(auth));
		
		
		static ip[32];
		get_user_ip(id, ip, charsmax(ip), 1)
		
		
		if (equal(ip, gBanIp[i]) || equal(auth, gBanAuth[i])) {
			banned = true;
		}
		
		i++;
	}
	
	return banned;
}

public registerPlayerLogin(id) {
	static name[32];
	get_user_name(id, name, 31);
	
	static auth[32];
	get_user_authid(id, auth, charsmax(auth));
	
	static ip[32];
	get_user_ip(id, ip, charsmax(ip), 1);
	
	new szQuery[200];
	formatex(szQuery, charsmax(szQuery), "INSERT INTO `players` (`name`, `steam_id`, `ip`, `server_id`) VALUES (^"%s^", ^"%s^", ^"%s^", ^"%d^");", name, auth, ip, SERVER_ID)

	executeQuery(szQuery, id, PLAYERS_INSERT);
	
	#if defined DEBUG
		server_print("%s", szQuery);
	#endif
}

public printBanInformation(id, banId[], name[], steamId[], ip[], dateBan[], expiration[], reason[], administrator[]) {
	client_cmd(id, "echo ^"^"");
	
	client_cmd(id, "echo ^"************************************************^"");
	client_cmd(id, "echo ^"%L: %s^"", id, "PRINT_NAME", name);
	client_cmd(id, "echo ^"%L: %s^"", id, "PRINT_STEAM_ID", steamId);
	client_cmd(id, "echo ^"%L: %s^"", id, "PRINT_IP", ip);
	client_cmd(id, "echo ^"%L: %s^"", id, "PRINT_BAN_DATE", dateBan);
	
	if (equal(expiration, "null") || equal(expiration, "")) {
		client_cmd(id, "echo ^"%L: %L^"", id, "PRINT_EXPIRATION", id, "PRINT_PERMANENT");
	} else {
		client_cmd(id, "echo ^"%L: %s^"", id, "PRINT_EXPIRATION", expiration);
	}
	
	client_cmd(id, "echo ^"%L: %s^"", id, "PRINT_REASON", reason);

	if (! equal(administrator, "")) {
		client_cmd(id, "echo ^"%L: %s^"", id, "PRINT_ADMINISTRATOR", administrator);
	}

	

	if (! equal(banId, "")) {
		client_cmd(id, "echo ^"^"");
		client_cmd(id, "echo ^"%L: %s/show_ban/%s^"", id, "PRINT_MORE_INFORMATION_VISIT", WEB, banId);
	}
	
	client_cmd(id, "echo ^"************************************************^"");

}

public executeQuery(szQuery[], id, action) {
	new data[2]
	data[0] = id;
	data[1] = action;
	
	SQL_ThreadQuery(g_SqlTuple, "DataHandler", szQuery, data, 2); 
}

public executeLoadQuery(szQuery[], action) {
	new data[1]
	data[0] = action;
	
	SQL_ThreadQuery(g_SqlTuple, "DataLoadHandler", szQuery, data, 1); 
}

public DataHandler( failstate, Handle:query, error[ ], error2, data[ ], datasize, Float:time ) {
	
	static id;
	id = data[0];
    
	if(!is_user_connected(id)) {
		return;
	}
	
	switch(failstate) {
		case TQUERY_CONNECT_FAILED: {
			log_to_file(MYSQL_LOG, "Error connecting to MySQL [%i]: %s",error2, error);
			return;
		}
        
		case TQUERY_QUERY_FAILED: {
			log_to_file(MYSQL_LOG, "Error connecting to MySQL [%i]: %s",error2, error);
			return;
		}
	}
	
	
	switch (data[1]) {
		case PLAYERS_INSERT: {
		
			client_print_color(id, print_chat, "^4%s ^1%L", PREFIX, id, "DATA_RECORDED_FOR_SECURITY_REASONS");
		}
		
		case GET_ADMIN_DATA: {
			if (!SQL_NumResults(query)) {
				log_amx("No Admin found");
				return;
			}
			
			new colId = SQL_FieldNameToNum(query, "id");
			new colExpiration = SQL_FieldNameToNum(query, "expiration");			
			
			new administratorId[32];
			new expiration[32];
			
			
			while(SQL_MoreResults(query)) {
				
				SQL_ReadResult(query, colId, administratorId, 31);
				SQL_ReadResult(query, colExpiration, expiration, 31);
				
				gAdminId[id] = administratorId;
				gAdminExpiration[id] = expiration;
				
				#if defined DEBUG
				server_print("ADMIN DATA - %s %s", gAdminId[id], gAdminExpiration[id]);
				#endif
				
				SQL_NextRow(query);
			}
			
		}
		
		case SHOW_BAN: {
			
			if (!SQL_NumResults(query)) {
				// The ban was removed before the map was changed
				return;
			}
			
			new colId = SQL_FieldNameToNum(query, "id");
			new colName = SQL_FieldNameToNum(query, "name");
			new colSteamId = SQL_FieldNameToNum(query, "steam_id");
			new colIp = SQL_FieldNameToNum(query, "ip");
			new colDate = SQL_FieldNameToNum(query, "date");
			new colExpiration = SQL_FieldNameToNum(query, "expiration");
			new colReason = SQL_FieldNameToNum(query, "reason");
			new colAdministrator = SQL_FieldNameToNum(query, "administrator");
			
			new banId[32];
			new name[32];
			new steamId[32];
			new ip[32];
			new banDate[32];
			new expiration[32];
			new reason[32];
			new administrator[32];
			
			while(SQL_MoreResults(query)) {
				
				SQL_ReadResult(query, colId, banId, 31);
				SQL_ReadResult(query, colName, name, 31);
				SQL_ReadResult(query, colSteamId, steamId, 31);
				SQL_ReadResult(query, colIp, ip, 31);
				SQL_ReadResult(query, colDate, banDate, 31);
				SQL_ReadResult(query, colExpiration, expiration, 31);
				SQL_ReadResult(query, colReason, reason, 31);
				SQL_ReadResult(query, colAdministrator, administrator, 31);
				
				server_print("la fecha del ban es %s", expiration);
				
				printBanInformation(id, banId, name, steamId, ip, banDate, expiration, reason, administrator);
				
				SQL_NextRow(query);
			}
			
			set_task(1.0, "TaskDisconnectPlayer", id);
		}
		
		
		case STORE_BAN: {

				new playerId = gAdminBanPlayer[id];
				
				if (! is_user_connected(playerId))
					return;
				
				
				new player_name[32];
				new player_auth[44];
				new player_ip[32];

				get_user_name(playerId, player_name, 43);
				get_user_authid(playerId, player_auth, 31);
				get_user_ip(playerId, player_ip, 31, 1);

				new admin_name[32];
				get_user_name(id, admin_name, 31);
				
	
				addBanToMatrix(player_auth, player_ip);
				
				client_print_color(0, print_chat, "^4%s ^1ADMIN ^4%s ^1%L ^4%s^1. %L: ^4%s.", PREFIX, admin_name, id, "HAS_BEEN_BANNED", player_name, id, "REASON", gAdminBanReason[id]);
				client_cmd(id, "^4%s ^1ADMIN ^4%s ^1%L ^4%s^1. %L: ^4%s.", PREFIX, admin_name, id, "HAS_BEEN_BANNED", player_name, id, "REASON", gAdminBanReason[id]);
				
				new dateBan[32];
				format_time(dateBan, 31, "%Y-%m-%d %H:%M", get_systime()); 
				printBanInformation(playerId, "", player_name, player_auth, player_ip, dateBan, gAdminBanExpiration[id], gAdminBanReason[id], admin_name);
				
				
				set_task(1.0, "TaskDisconnectPlayer", playerId);
		}
		
		case DESTROY_BAN: {
			
			new admin_name[32];
			get_user_name(id, admin_name, 31);
				
			removeBanToMatrix(gUnbanPlayer[id]);
				
			client_print_color(0, print_chat, "^4%s ^1ADMIN ^4%s ^1%L ^4%s", PREFIX, admin_name, id, "HAS_BEEN_UNBANNED", gUnbanPlayer[id]);
			client_cmd(id, "^4%s ^1ADMIN ^4%s ^1%L ^4%s", PREFIX, admin_name, id, "HAS_BEEN_UNBANNED", gUnbanPlayer[id]);	
		
		}
	}
}

public TaskDisconnectPlayer(id) {
	if (! is_user_connected(id))
		return;
		

	server_cmd("kick #%i ^"%L^"", get_user_userid(id), id, "YOU_ARE_BANNED");
}


public DataLoadHandler( failstate, Handle:query, error[ ], error2, data[ ], datasize, Float:time ) {

	switch(failstate) {
		case TQUERY_CONNECT_FAILED: {
			log_to_file(MYSQL_LOG, "Error connecting to MySQL [%i]: %s",error2, error);
			return;
		}
        
		case TQUERY_QUERY_FAILED: {
			log_to_file(MYSQL_LOG, "Error connecting to MySQL [%i]: %s",error2, error);
			return;
		}
	}
	
	
	switch (data[0]) {
		case ADMINISTRATORS_SELECT: {
		
			if (!SQL_NumResults(query)) {
				log_amx("No admins found");
				return;
			}
			
			
			new colAuth = SQL_FieldNameToNum(query, "auth");
			new colPass = SQL_FieldNameToNum(query, "password");
			new colAccessFlags = SQL_FieldNameToNum(query, "access_flags");
			new colAccountFlags = SQL_FieldNameToNum(query, "account_flags");
			new colExpiration = SQL_FieldNameToNum(query, "expiration");
						
						
			new auth[44];
			new password[44];
			new accessFlags[32];
			new accountFlags[32];
			new expiration[32];
			
			while(SQL_MoreResults(query)) {
				
				SQL_ReadResult(query, colAuth, auth, sizeof(auth) - 1);
				SQL_ReadResult(query, colPass, password, sizeof(password) -1);
				SQL_ReadResult(query, colAccessFlags, accessFlags, sizeof(accessFlags) - 1);
				SQL_ReadResult(query, colAccountFlags, accountFlags, sizeof(accountFlags) - 1);
				SQL_ReadResult(query, colExpiration, expiration, sizeof(expiration) - 1);
				
				
				if(equal(expiration, "expired")) {
					accessFlags = "z";
				}
			
				admins_push(auth, password, read_flags(accessFlags) , read_flags(accountFlags));
				
				
				#if defined DEBUG
					server_print("ADMIN LOADED: ^"%s^" ^"%s^" ^"%s^" ^"%s^" ^"%s^"", auth, password, accessFlags, accountFlags, expiration);
				#endif
				
				SQL_NextRow(query);
			}
		}
		
		
		case BANS_SELECT: {
		
			if (!SQL_NumResults(query)) {
				log_amx("No bans found");
				return;
			}
			
			
			new colSteamId = SQL_FieldNameToNum(query, "steam_id");
			new colIp = SQL_FieldNameToNum(query, "ip");
						
						
			new steamId[44];
			new ip[32];
			
			
			while(SQL_MoreResults(query)) {
				
				SQL_ReadResult(query, colSteamId, steamId, sizeof(steamId) - 1);
				SQL_ReadResult(query, colIp, ip, sizeof(ip) -1);
				
				if (! addBanToMatrix(steamId, ip))
					break;
				
				#if defined DEBUG
					server_print("BAN LOADED: ^"%s^" ^"%s^"", steamId, ip);
				#endif
				
				
				SQL_NextRow(query);
			}
		}
		
		case SET_ONLINE_MODE:
		{
			#if defined DEBUG
					server_print("Server updated");
			#endif
		}
	}
}

public addBanToMatrix(steamId[44], ip[32]) {
	
	if (gLastPositionBan >= MAX_BANS) {
		log_amx("Bans limit reached");
		
		return false;
	}
	
	gBanAuth[gLastPositionBan] = steamId;
	gBanIp[gLastPositionBan] = ip;
	
	gLastPositionBan++;
	
	return true;
	
}

public removeBanToMatrix(ban[]) {
	
	for (new i=0; i < MAX_BANS; i++) {
		if (equal(gBanAuth[i], ban)) {
			gBanAuth[i] = "";
		} else if (equal(gBanAuth[i], ban)) {
			gBanIp[i] = "";
		}
	}
}

public kickPlayer(id, razon[]) {
	new userid = get_user_userid(id)
	server_cmd("kick #%d ^"%s^"",userid, razon)
}

stock register_saycmd(saycommand[], function[], flags, info[]) {
	new temp[64];
	format(temp, 63, "say /%s", saycommand);
	register_clcmd(temp, function, flags, info);
	format(temp, 63, "say .%s", saycommand);
	register_clcmd(temp, function, flags, info);
	format(temp, 63, "say_team /%s", saycommand);
	register_clcmd(temp, function, flags, info);
	format(temp, 63, "say_team .%s", saycommand);
	register_clcmd(temp, function, flags, info);
	format(temp, 63, ".%s", saycommand);
	register_clcmd(temp, function, flags, info);
	format(temp, 63, "/%s", saycommand);
	register_clcmd(temp, function, flags, info);
}
