		class sniperRiflesMarksmen 
		{
			displayName = __EVAL(formatText ["%1 %2", localize "STR_A3AU_Marksmen", localize "STR_A3AU_sniperRifles"]);
			picture = "a3\ui_f\data\gui\Rsc\RscDisplayArsenal\primaryWeapon_ca.paa";

			ITEM(srifle_DMR_04_F, SNIP127 * 2, RIFLE_STOCK);
			ITEM(srifle_DMR_04_Tan_F, SNIP127 * 2, RIFLE_STOCK);

			ITEM(srifle_DMR_05_blk_F, SNIP127 * 2, RIFLE_STOCK);
			ITEM(srifle_DMR_05_hex_F, SNIP127 * 2, RIFLE_STOCK);
			ITEM(srifle_DMR_05_tan_f, SNIP127 * 2, RIFLE_STOCK);

			ITEM(srifle_DMR_02_F, MOD556 * 2, RIFLE_STOCK);
			ITEM(srifle_DMR_02_camo_F, MOD556 * 2, RIFLE_STOCK);
			ITEM(srifle_DMR_02_sniper_F, MOD556 * 2, RIFLE_STOCK);

			ITEM(srifle_DMR_03_F, MOD762 * 2, RIFLE_STOCK);
			ITEM(srifle_DMR_03_multicam_F, MOD762 * 2, RIFLE_STOCK);
			ITEM(srifle_DMR_03_khaki_F, MOD762 * 2, RIFLE_STOCK);
			ITEM(srifle_DMR_03_tan_F, MOD762 * 2, RIFLE_STOCK);
			ITEM(srifle_DMR_03_woodland_F, MOD762 * 2, RIFLE_STOCK);

			ITEM(srifle_DMR_06_camo_F, OLD762 * 2, RIFLE_STOCK);
			ITEM(srifle_DMR_06_olive_F, OLD762 * 2, RIFLE_STOCK);

		};

		class mgMarksmen 
		{
			displayName = __EVAL(formatText ["%1 %2", localize "STR_A3AU_Marksmen", localize "STR_A3AU_mgs"]);
			picture = "a3\ui_f\data\gui\Rsc\RscDisplayArsenal\primaryWeapon_ca.paa";

			ITEM(MMG_01_hex_F, MOD762 * 1.5, RIFLE_STOCK);
			ITEM(MMG_01_tan_F, MOD762 * 1.5, RIFLE_STOCK);

			ITEM(MMG_02_black_F, MOD762 * 1.5, RIFLE_STOCK);
			ITEM(MMG_02_camo_F, MOD762 * 1.5, RIFLE_STOCK);
			ITEM(MMG_02_sand_F, MOD762 * 1.5, RIFLE_STOCK);

		};

		class navigationMarksmen
		{
			displayName = __EVAL(formatText ["%1 %2, %3 %4 %5", localize "STR_A3AU_Marksmen", localize "STR_A3AU_gps", localize "STR_A3AU_binoculars", localize "STR_A3AU_and", localize "STR_A3AU_nvgs"]);
			picture = "a3\ui_f\data\gui\Rsc\RscDisplayArsenal\compass_ca.paa";

			ITEM(Laserdesignator_02, 1200, NN_STOCK);
			ITEM(Laserdesignator_03, 1200, NN_STOCK);

		};

		class underbarrelMarksmen
		{
			displayName = __EVAL(formatText ["%1 %2", localize "STR_A3AU_Marksmen", localize "STR_A3AU_bipods"]);
			picture = "a3\ui_f\data\gui\Rsc\RscDisplayArsenal\itemBipod_ca.paa";

			ITEM(bipod_03_F_blk, 100, 50);
			ITEM(bipod_02_F_blk, 100, 50);
			ITEM(bipod_01_F_blk, 100, 50);
			ITEM(bipod_02_F_hex, 100, 50);
			ITEM(bipod_01_F_mtp, 100, 50);
			ITEM(bipod_03_F_oli, 100, 50);
			ITEM(bipod_01_F_snd, 100, 50);
			ITEM(bipod_02_F_tan, 100, 50);

		};

		class muzzlesMarksmen 
		{
			displayName = __EVAL(formatText ["%1 %2", localize "STR_A3AU_Marksmen", localize "STR_A3AU_muzzles"]);
			picture = "a3\ui_f\data\gui\Rsc\RscDisplayArsenal\itemMuzzle_ca.paa";

			ITEM(muzzle_snds_338_black, 500, MZ_STOCK); //5
			ITEM(muzzle_snds_338_green, 500, MZ_STOCK);
			ITEM(muzzle_snds_338_sand, 500, MZ_STOCK);

			ITEM(muzzle_snds_93mmg, 600, MZ_STOCK); //4
			ITEM(muzzle_snds_93mmg_tan, 600, MZ_STOCK);

		};

		class opticsMarksmen 
		{
			displayName = __EVAL(formatText ["%1 %2", localize "STR_A3AU_Marksmen", localize "STR_A3AU_sights"]);
			picture = "\A3\Ui_f\data\GUI\Rsc\RscDisplayArsenal\ItemOptic_ca.paa";

			class optic_AMS {
				price = 1000;
				stock = 20;
			};
			class optic_AMS_khk {
				price = 1000;
				stock = 20;
			};
			class optic_AMS_snd {
				price = 1000;
				stock = 20;
			};

			class optic_KHS_blk {
				price = 800;
				stock = 20;
			};
			class optic_KHS_hex  {
				price = 800;
				stock = 20;
			};
			class optic_KHS_tan {
				price = 800;
				stock = 20;
			};

			class optic_KHS_old  {
				price = 700;
				stock = 25;
			};

		};

		class magazinesMarksmen 
		{
			displayName = __EVAL(formatText["%1 %2", localize "STR_A3AU_Marksmen", localize "STR_A3AU_magazines"]);
			picture = "a3\ui_f\data\gui\Rsc\RscDisplayArsenal\cargoMag_ca.paa";
		
			///////////////////////////////////////////////////////
			// DMRs, Sniper Rifles
			///////////////////////////////////////////////////////

			ITEM(10Rnd_127x54_Mag, 20 + LARGBULPRICE * 10, 100);

			ITEM(10Rnd_93x64_DMR_05_Mag, 20 + LARGBULPRICE * 10, 100);

			ITEM(10Rnd_338_Mag, 20 + BULPRICE * 10, 100);

			ITEM(20Rnd_762x51_Mag, 20 + BULPRICE * 20, 100);
			ITEM(10Rnd_Mk14_762x51_Mag, 20 + BULPRICE * 10, 100);

			///////////////////////////////////////////////////////
			// MGs
			///////////////////////////////////////////////////////
			ITEM(150Rnd_93x64_Mag, 20 + LARGBULPRICE * 150, 100);
			ITEM(130Rnd_338_Mag, 20 + BULPRICE * 130, 100);

		};