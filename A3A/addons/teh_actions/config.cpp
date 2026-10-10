#include "script_component.hpp"

class CfgPatches
{
    class teh_actions
    {
        name = "TEH Actions";
        requiredVersion = 1.0;
        requiredAddons[] = {"cba_xeh", "cba_ui"};
        units[] = {};
        weapons[] = {};
    };
};

class CfgFunctions
{
    class teh_actions
    {
        class Actions
        {
            file = QPATHTOFOLDER(functions);
            class addInteraction {};
            class removeInteraction {};
            class getInteractions {};
            class canInteract {};
            class hasInteractions {};
            class initObject {};
            class distanceToTarget {};
            class openInteractionMenu {};
            class executeInteraction {};
            class handleMenuKey {};
            class handleMenuWheel {};
            class progressBar {};
        };
    };
};

class RscText;
class RscListBox;
class RscButton;

class TEH_Actions_Dialog
{
    idd = 96001;
    movingEnable = 0;
    enableSimulation = 1;
    onKeyDown = "_this call teh_actions_fnc_handleMenuKey";

    class controlsBackground
    {
        class Background: RscText
        {
            idc = -1;
            x = "safeZoneX + safeZoneW * 0.35";
            y = "safeZoneY + safeZoneH * 0.25";
            w = "safeZoneW * 0.30";
            h = "safeZoneH * 0.50";
            colorBackground[] = {0.05, 0.05, 0.05, 0.94};
        };
    };

    class controls
    {
        class Title: RscText
        {
            idc = -1;
            text = "TEH Actions";
            x = "safeZoneX + safeZoneW * 0.36";
            y = "safeZoneY + safeZoneH * 0.27";
            w = "safeZoneW * 0.28";
            h = "safeZoneH * 0.05";
        };
        class Actions: RscListBox
        {
            idc = 96002;
            x = "safeZoneX + safeZoneW * 0.36";
            y = "safeZoneY + safeZoneH * 0.33";
            w = "safeZoneW * 0.28";
            h = "safeZoneH * 0.33";
            onLBDblClick = "[] call teh_actions_fnc_executeInteraction";
            onMouseZChanged = "_this call teh_actions_fnc_handleMenuWheel";
        };
        class Run: RscButton
        {
            idc = -1;
            text = "Use";
            x = "safeZoneX + safeZoneW * 0.47";
            y = "safeZoneY + safeZoneH * 0.68";
            w = "safeZoneW * 0.08";
            h = "safeZoneH * 0.045";
            action = "[] call teh_actions_fnc_executeInteraction";
        };
        class Cancel: RscButton
        {
            idc = -1;
            text = "Cancel";
            x = "safeZoneX + safeZoneW * 0.56";
            y = "safeZoneY + safeZoneH * 0.68";
            w = "safeZoneW * 0.08";
            h = "safeZoneH * 0.045";
            action = "closeDialog 0";
        };
    };
};
