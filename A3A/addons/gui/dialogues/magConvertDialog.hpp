/*
  Mag type change dialog
*/

#include "ids.inc"

class RscMagConvertDialog {
    idd = A3A_IDD_MAGCONVERTDIALOG;
    movingEnable = false;
    enableSimulation = true;

    class controlsBackground {
        class Background: RscText {
            x = 0.2; y = 0.3;
            w = 0.6; h = 0.36;
            colorBackground[] = {0,0,0,0.7};
        };
    };

    class controls {
        class Title: RscText {
            text = "Magazine Conversion";
            x = 0.21; y = 0.31;
            w = 0.58; h = 0.04;
            sizeEx = 0.04;
        };

        class SourceLabel: RscText {
            text = "Source magazine model:";
            x = 0.21; y = 0.355;
            w = 0.58; h = 0.03;
            sizeEx = 0.035;
        };
        class SourceCombo: RscCombo {
            idc = A3A_IDC_MAGCONVERT_SOURCE;
            x = 0.21; y = 0.39;
            w = 0.58; h = 0.04;
            onLBSelChanged = "_this call A3A_fnc_magConvert_onSourceChanged;";

            colorBackground[] = {0.2, 0.2, 0.2, 1};
            colorSelectBackground[] = {0.4, 0.4, 0.4, 1};
            colorSelect[] = {1,1,1,1};
            colorText[] = {1,1,1,1};
        };

        class TargetLabel: RscText {
            text = "Target magazine model:";
            x = 0.21; y = 0.44;
            w = 0.58; h = 0.03;
            sizeEx = 0.035;
        };
        class TargetCombo: RscCombo {
            idc = A3A_IDC_MAGCONVERT_TARGET;
            x = 0.21; y = 0.475;
            w = 0.58; h = 0.04;

            colorBackground[] = {0.2, 0.2, 0.2, 1};
            colorSelectBackground[] = {0.4, 0.4, 0.4, 1};
            colorSelect[] = {1,1,1,1};
            colorText[] = {1,1,1,1};
        };

        class AmountLabel: RscText {
            text = "Amount:";
            x = 0.21; y = 0.525;
            w = 0.2; h = 0.03;
            sizeEx = 0.035;
        };
        class AmountCombo: RscCombo {
            idc = A3A_IDC_MAGCONVERT_AMOUNT;
            x = 0.42; y = 0.525;
            w = 0.37; h = 0.04;
        };

        class ConvertButton: RscButton {
            idc = A3A_IDC_MAGCONVERT_BUTTON;
            text = "Convert";
            x = 0.21; y = 0.575;
            w = 0.58; h = 0.04;
            action = "[] call A3A_fnc_magConvert_convert;";
        };
    };
};
