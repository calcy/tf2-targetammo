/**
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 */

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_VERSION "0.50"

#define REFRESH_RATE 0.25

new Handle:h_HudTarget = INVALID_HANDLE;
new Handle:h_HudMedicHeal = INVALID_HANDLE;

new offset_ammo, offset_clip;

public Plugin:myinfo =
{
	name = "Target Ammo Viewer",
	author = "calcy",
	description = "Shows ammo a player is carrying when you target them",
	version = PLUGIN_VERSION,
	url = "https://github.com/calcy"
};

public OnPluginStart() {
	CreateConVar("ta_version", PLUGIN_VERSION, "[TF2] Team Ammo Viewer");

	h_HudTarget = CreateHudSynchronizer();
	h_HudMedicHeal = CreateHudSynchronizer();

	offset_ammo = FindSendPropInfo("CTFPlayer", "m_iAmmo");
	offset_clip = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
}

public OnMapStart() {
	CreateTimer(REFRESH_RATE, Timer_TargetAmmoCheck, _, TIMER_REPEAT);
}

public Action:Timer_TargetAmmoCheck(Handle:timer) {
	for (new i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || IsFakeClient(i) || !IsPlayerAlive(i))
			continue;

		new target = CheckMedicHeals(i);
		CheckTargetAim(i, target);
	}

	return Plugin_Continue;
}

stock CheckMedicHeals(player) {
	new medicTarget;
	
	medicTarget = TF2_GetHealingTarget(player)
	if (medicTarget > 0)
		WriteAmmoOnHud(player, medicTarget, true);
	
	return medicTarget;
}

stock CheckTargetAim(player, medicTarget = -1) {
	new target = GetClientAimTarget(player);

	if (target != -1 && target != medicTarget)
		WriteAmmoOnHud(player, target);
}

stock WriteAmmoOnHud(player, target, bool:medic_healing = false) {
	new weapon = TF2_GetCurrentWeapon(target);
	if (!IsValidEntity(weapon))
		return;
	
	new slot = TF2_GetSlotByWeapon(target);

	// we only care about primary & secondary slots
	if (slot != 1 && slot != 2)
		return;
	
	new String:ammotext[255];

	new clip = GetEntProp(weapon, Prop_Send, "m_iClip1"); // current clip

	if (clip != 255) {
		Format(ammotext, sizeof(ammotext), "%i / ", clip);
	}

	// also equals ammo for no-clip weapons (and maybe no-damage weapons?)
	new reserve = GetEntData(target, offset_ammo + slot * 4);

	Format(ammotext, sizeof(ammotext), "%s%i", ammotext, reserve);

	//new TFClassType:target_class = TF2_GetPlayerClass(target);

	new red, green, blue;

	new player_team = GetClientTeam(player);

	if (player_team == 2) { // RED
		red = 255;
		green = 0;
		blue = 0;
	} else {
		red = 0;
		green = 50;
		blue = 255;
	}

	if (medic_healing) {
		SetHudTextParams(0.6, 0.7, REFRESH_RATE, red, green, blue, 0.8, 0, 0, 0, 0);
		ShowSyncHudText(player, h_HudMedicHeal, ammotext);
	}
	else {
		SetHudTextParams(0.6, 0.5, REFRESH_RATE, red, green, blue, 0.8, 0, 0, 0, 0);
		ShowSyncHudText(player, h_HudTarget, ammotext);
	}
	

	if (medic_healing)
		Format(ammotext, sizeof(ammotext), "%s | HEALING", ammotext);
	
	PrintToChat(player, "[SM] Ammo: %s", ammotext);
}

// Following functions taken from simple-plugins-core
stock TF2_GetHealingTarget(client) {
	new String:classname[64];
	TF2_GetCurrentWeaponClass(client, classname, sizeof(classname));

	if(StrEqual(classname, "CWeaponMedigun"))	{
		new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(GetEntProp(index, Prop_Send, "m_bHealing") == 1) {
			return GetEntPropEnt(index, Prop_Send, "m_hHealingTarget");
		}
	}

	return -1;
}

stock TF2_GetCurrentWeaponClass(client, String:name[], maxlength) {
	if(client > 0) {
		new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (index > 0)
			GetEntityNetClass(index, name, maxlength);
	}
}

stock TF2_GetCurrentWeapon(client) {
	if(client > 0) {
		new weaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		return weaponIndex;
	}

	return -1;
}

stock TF2_GetSlotWeapon(any:client, slot)
{
	if( client > 0 && slot >= 0)
	{
		new weaponIndex = GetPlayerWeaponSlot(client, slot-1);
		return weaponIndex;
	}
	return -1;
}

stock TF2_GetSlotByWeapon(client)
{
	new weapon = TF2_GetCurrentWeapon(client);
	for (new i; i < 10; i++)
	{
		if (TF2_GetSlotWeapon(client, i) == weapon)
		{
			return i;
		}
	}
	return -1;
}

