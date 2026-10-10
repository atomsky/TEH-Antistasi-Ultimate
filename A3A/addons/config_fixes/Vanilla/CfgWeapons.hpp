//Vanilla - CfgWeapons.hpp

class CfgWeapons 
{
    class arifle_AK12_GL_base_F;
    class arifle_AK12_GL_lush_F : arifle_AK12_GL_base_F
    {
        baseWeapon = "arifle_AK12_GL_lush_F";
    };
    
    class Default;
    class Put : Default {
		class PutMuzzle;
        class bigied_muzzle : PutMuzzle {
            magazines[] = {
                "IEDUrbanBig_Remote_Mag",
                "IEDLandBig_Remote_Mag"
            };
        };
    };
};