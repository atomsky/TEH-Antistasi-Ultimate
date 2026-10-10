class launchersTanks
		{
			displayName = __EVAL(formatText ["%1 %2", localize "STR_A3AU_Tanks", localize "STR_A3AU_launchers"]);
			picture = "a3\ui_f\data\gui\Rsc\RscDisplayArsenal\secondaryWeapon_ca.paa";

			ITEM(launch_MRAWS_olive_F, RPG_RELOADABLE, LAUNCHER_STOCK);
			ITEM(launch_MRAWS_olive_rail_F, RPG_RELOADABLE * RAIL, LAUNCHER_STOCK);
			ITEM(launch_MRAWS_green_F, RPG_RELOADABLE, LAUNCHER_STOCK);
			ITEM(launch_MRAWS_green_rail_F,  RPG_RELOADABLE * RAIL, LAUNCHER_STOCK);
			ITEM(launch_MRAWS_sand_F, RPG_RELOADABLE, LAUNCHER_STOCK);
			ITEM(launch_MRAWS_sand_rail_F,  RPG_RELOADABLE * RAIL, LAUNCHER_STOCK);

			ITEM(launch_O_Vorona_brown_F, WIRE_AT_LAUNCHER, 10);
			ITEM(launch_O_Vorona_green_F, WIRE_AT_LAUNCHER, 10);
		};

		class launcherMagazinesTanks 
		{
			displayName = __EVAL(formatText ["%1 %2", localize "STR_A3AU_Tanks", localize "STR_A3AU_launcherAmmo"]);
			picture = "a3\ui_f\data\gui\Rsc\RscDisplayArsenal\cargoMag_ca.paa";
		
			class Vorona_HE {
				price = WIRE_AT_MISSILE;
				stock = 50;
			};
			class Vorona_HEAT {
				price = WIRE_AT_MISSILE;
				stock = 50;
			};
			class MRAWS_HEAT55_F {
				price = RPG_AT_ROUND;
				stock = 50;
			};
			class MRAWS_HE_F {
				price = RPG_HE_ROUND;
				stock = 50;
			};
			class MRAWS_HEAT_F {
				price = RPG_THERM_ROUND;
				stock = 50;
			};
		};

		class miscTanks 
		{
			displayName = __EVAL(formatText ["%1 %2", localize "STR_A3AU_Tanks", localize "STR_A3AU_misc"]);
			picture = "a3\ui_f\data\gui\Rsc\RscDisplayArsenal\backpack_ca.paa";

			ITEM(U_Tank_green_F, 500, MISC_STOCK);
			ITEM(H_Tank_black_F, 500, MISC_STOCK);

		};