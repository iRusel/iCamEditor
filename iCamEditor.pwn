/*

			 _____           _     _
			|  __ \         | |   (_)
			| |  | |_ __ ___| |__  _ _ __
			| |  | | '__/ _ \ '_ \| | '_ \
			| |__| | | |  __/ |_) | | | | |
			|_____/|_|  \___|_.__/|_|_| |_|
						©2012
						
			            v 1.1

*/

/*	
	Отредактировано by iRusel
	Дата: 04.12.2014
	Контакты: skype: irusel-am | www: www.irusel.com | email: irusel@yandex.ru
	Описание:
	- По возможности переведено на русский язык.
	- Добавлена возможность снимать координаты для камеры игрока. (SetPlayerCameraPos, SetPlayerCameraLookAt)
	
	v.1.2
*/
#define FILTERSCRIPT

#include <a_samp>

#define MOVE_SPEED              100.0
#define ACCEL_RATE              0.03

#define CAMERA_MODE_NONE    	0
#define CAMERA_MODE_FLY     	1

#define MOVE_FORWARD    		1
#define MOVE_BACK       		2
#define MOVE_LEFT       		3
#define MOVE_RIGHT      		4
#define MOVE_FORWARD_LEFT       5
#define MOVE_FORWARD_RIGHT      6
#define MOVE_BACK_LEFT          7
#define MOVE_BACK_RIGHT         8

#define DIALOG_MENU 1574
#define DIALOG_MENU_POS 1575
#define DIALOG_MOVE_SPEED 1576
#define DIALOG_ROT_SPEED 1577
#define DIALOG_EXPORTNAME 1578
#define DIALOG_EXPORTNAME_POS 1579
#define DIALOG_CLOSE_NEW 1580

const Float:fScale = 5.0;
new MenuTimer;
new Float:fPX, Float:fPY, Float:fPZ,
			Float:fVX, Float:fVY, Float:fVZ,
			Float:object_x, Float:object_y, Float:object_z;
new bool:IsCreating[MAX_PLAYERS] 		= false;
new bool:IsReSettingStart[MAX_PLAYERS] 	= false;
new bool:IsReSettingEnd[MAX_PLAYERS] 	= false;
new bool:SettingFirstLoc[MAX_PLAYERS] 	= false;
new bool:SettingLastLoc[MAX_PLAYERS] 	= false;
new bool:IsCamMoving[MAX_PLAYERS] 		= false;

enum noclipenum
{
	cameramode,
	flyobject,
	mode,
	lrold,
	udold,
	lastmove,
	Float:accelmul
}
new noclipdata[MAX_PLAYERS][noclipenum];

enum Coordinates
{
	Float:StartX,
	Float:StartY,
	Float:StartZ,
	Float:EndX,
	Float:EndY,
	Float:EndZ,
	Float:StartLookX,
	Float:StartLookY,
	Float:StartLookZ,
	Float:EndLookX,
	Float:EndLookY,
	Float:EndLookZ,
	MoveSpeed,
	RotSpeed
}
new coordInfo[MAX_PLAYERS][Coordinates];

#if defined FILTERSCRIPT

public OnFilterScriptInit()
{
	print("\n--------------------------------------");
	print(" CamEditor by Drebin");
	print(" Отредактировано by iRusel");
	print("--------------------------------------\n");
	return 1;
}

public OnFilterScriptExit()
{
    for(new x; x<MAX_PLAYERS; x++)
	{
		if(noclipdata[x][cameramode] == CAMERA_MODE_FLY) CancelFlyMode(x);
	}
	return 1;
}

#endif

public OnPlayerConnect(playerid)
{
    noclipdata[playerid][cameramode] 	= CAMERA_MODE_NONE;
	noclipdata[playerid][lrold]	   	 	= 0;
	noclipdata[playerid][udold]   		= 0;
	noclipdata[playerid][mode]   		= 0;
	noclipdata[playerid][lastmove]   	= 0;
	noclipdata[playerid][accelmul]   	= 0.0;
	IsCreating[playerid] 				= false;
	IsReSettingStart[playerid] 			= false;
	IsReSettingEnd[playerid] 			= false;
	SettingFirstLoc[playerid] 			= false;
	SettingLastLoc[playerid] 			= false;
	IsCamMoving[playerid] 				= false;
	coordInfo[playerid][MoveSpeed] 		= 1000;
	coordInfo[playerid][RotSpeed] 		= 1000;
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(IsCreating[playerid] == false) SendClientMessage(playerid, -1, "Введи /cameditor для создания движущейся камеры | /cameditorpos для сохранения координат камеры.");
}

public OnPlayerCommandText(playerid, cmdtext[])
{
	if(!strcmp(cmdtext, "/cameditor", true))
	{
	    if(IsCamMoving[playerid] == false)
	    {
			if(GetPVarType(playerid, "FlyMode"))
			{
				CancelFlyMode(playerid);
				IsCreating[playerid] = false;
			}
			else FlyMode(playerid);
		}
		return 1;
	}
	if(!strcmp(cmdtext, "/cameditorpos", true))
	{
	    if(IsCamMoving[playerid] == false)
	    {
			if(GetPVarType(playerid, "FlyMode"))
			{
				CancelFlyMode(playerid);
				IsCreating[playerid] = false;
			}
			else
			{
				SetPVarInt(playerid, "CameraPosGet", 1);
				FlyMode(playerid);
			}
		}
		return 1;
	}
	if(!strcmp(cmdtext, "/closecameditor", true))
	{
	    if(IsCreating[playerid])
	    {
	        CancelFlyMode(playerid);
         	IsCreating[playerid] = false;
         	noclipdata[playerid][cameramode] 	= CAMERA_MODE_NONE;
			noclipdata[playerid][lrold]	   	 	= 0;
			noclipdata[playerid][udold]   		= 0;
			noclipdata[playerid][mode]   		= 0;
			noclipdata[playerid][lastmove]   	= 0;
			noclipdata[playerid][accelmul]   	= 0.0;
			IsCreating[playerid] 				= false;
			IsReSettingStart[playerid] 			= false;
			IsReSettingEnd[playerid] 			= false;
			SettingFirstLoc[playerid] 			= false;
			SettingLastLoc[playerid] 			= false;
			IsCamMoving[playerid] 				= false;
			coordInfo[playerid][MoveSpeed] 		= 1000;
			coordInfo[playerid][RotSpeed] 		= 1000;
			SendClientMessage(playerid, -1, "Вы покинули редактор передвижения камеры.");
	    }
	    else SendClientMessage(playerid, -1, "Вы не используете редактор.");
	    return 1;
	}
	return 0;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if ((newkeys & KEY_FIRE) && !(oldkeys & KEY_FIRE))
    {
        if(IsCreating[playerid] == true)
        {
            if(SettingFirstLoc[playerid] == true)
			{
		        const Float:fScale = 5.0;
				GetPlayerCameraPos(playerid, fPX, fPY, fPZ);
				GetPlayerCameraFrontVector(playerid, fVX, fVY, fVZ);
				object_x = fPX + floatmul(fVX, fScale);
				object_y = fPY + floatmul(fVY, fScale);
				object_z = fPZ + floatmul(fVZ, fScale);
				coordInfo[playerid][StartX] 		= fPX;
				coordInfo[playerid][StartY] 		= fPY;
				coordInfo[playerid][StartZ] 		= fPZ;
				coordInfo[playerid][StartLookX] 	= object_x;
				coordInfo[playerid][StartLookY] 	= object_y;
				coordInfo[playerid][StartLookZ] 	= object_z;
		        if(IsReSettingStart[playerid] == true)
		        {
					if(GetPVarInt(playerid, "CameraPosGet"))
					{
						SendClientMessage(playerid, -1, "{8EFF8E}>{FFFFFF} Позиция камеры {8EFF8E}переустановлена.");
						ShowPlayerDialog(playerid, DIALOG_MENU_POS, DIALOG_STYLE_LIST,"Что дальше?","Изменить позицию\nСохранить","Ок","Отмена");
						return 1;
					}
					SendClientMessage(playerid, -1, "{8EFF8E}>{FFFFFF} Начальная позиция {8EFF8E}переустановлена.");
					ShowPlayerDialog(playerid, DIALOG_MENU, DIALOG_STYLE_LIST,"Что дальше?","Предпросмотр\nИзменить начало\nИзменить конец\nИзменить скорость\nСохранить","Ок","Отмена");
					IsReSettingStart[playerid] 		= false;
					IsReSettingEnd[playerid] 		= false;
					SettingFirstLoc[playerid] 		= false;
					SettingLastLoc[playerid] 		= false;
				}
				else
				{
					if(GetPVarInt(playerid, "CameraPosGet")) 
					{
						SendClientMessage(playerid, -1, "{8EFF8E}>{FFFFFF} Позиция камеры {8EFF8E}установлена.");
						ShowPlayerDialog(playerid, DIALOG_MENU_POS, DIALOG_STYLE_LIST,"Что дальше?","Изменить позицию\nСохранить","Ок","Отмена");					
						return 1;
					}
				    SendClientMessage(playerid, -1, "{8EFF8E}>{FFFFFF} Начальная позиция {8EFF8E}установлена.");
				    SendClientMessage(playerid, -1, "Используй {F58282}~k~~PED_FIREWEAPON~ {FFFFFF}для сохранения позиции камеры и установки {F58282}конечной {FFFFFF}позиции.");
				    SettingLastLoc[playerid] = true;
				    SettingFirstLoc[playerid] = false;
				}
			}
			else if(SettingLastLoc[playerid] == true)
			{
			    const Float:fScale = 5.0;
		        new string[512];
			    format(string, sizeof(string), "Введите желаемое время {F58282}движения{a9c4e4} в миллисекундах\n\nТекущая скорость движения: \t{F58282}%i мс\n{a9c4e4}Текущая скорость вращения: \t{F58282}%i мс\n\n\nПримечание: {a9c4e4}1 секунда = 1000 миллисекунд", coordInfo[playerid][MoveSpeed], coordInfo[playerid][RotSpeed]);
			    ShowPlayerDialog(playerid, DIALOG_MOVE_SPEED, DIALOG_STYLE_INPUT, "Скорость движения", string,"Ок","Отмена");
				GetPlayerCameraPos(playerid, fPX, fPY, fPZ);
				GetPlayerCameraFrontVector(playerid, fVX, fVY, fVZ);
				object_x = fPX + floatmul(fVX, fScale);
				object_y = fPY + floatmul(fVY, fScale);
				object_z = fPZ + floatmul(fVZ, fScale);
				coordInfo[playerid][EndX] 			= fPX;
				coordInfo[playerid][EndY] 			= fPY;
				coordInfo[playerid][EndZ] 			= fPZ;
				coordInfo[playerid][EndLookX] 		= object_x;
				coordInfo[playerid][EndLookY] 		= object_y;
				coordInfo[playerid][EndLookZ] 		= object_z;
				if(IsReSettingEnd[playerid] == true)
				{
				    SendClientMessage(playerid, -1, "{8EFF8E}>{FFFFFF} Конечная позиция {8EFF8E}переустановлена.");
				    ShowPlayerDialog(playerid, DIALOG_MENU, DIALOG_STYLE_LIST,"Что дальше?","Предпросмотр\nИзменить начало\nИзменить конец\nИзменить скорость\nСохранить","Ок","Отмена");
		            IsReSettingStart[playerid] 		= false;
					IsReSettingEnd[playerid] 		= false;
					SettingFirstLoc[playerid] 		= false;
					SettingLastLoc[playerid] 		= false;
				}
				else
				{
				    SendClientMessage(playerid, -1, "{8EFF8E}>{FFFFFF} Конечная позиция {8EFF8E}установлена.");
				    SettingLastLoc[playerid] = false;
				}
			}
		}
    }
	return 1;
}

public OnPlayerUpdate(playerid)
{
	if(noclipdata[playerid][cameramode] == CAMERA_MODE_FLY)
	{
		new keys,ud,lr;
		GetPlayerKeys(playerid,keys,ud,lr);

		if(noclipdata[playerid][mode] && (GetTickCount() - noclipdata[playerid][lastmove] > 100))
		{
		    MoveCamera(playerid);
		}
		if(noclipdata[playerid][udold] != ud || noclipdata[playerid][lrold] != lr)
		{
			if((noclipdata[playerid][udold] != 0 || noclipdata[playerid][lrold] != 0) && ud == 0 && lr == 0){
				StopPlayerObject(playerid, noclipdata[playerid][flyobject]);
				noclipdata[playerid][mode]      = 0;
				noclipdata[playerid][accelmul]  = 0.0;
			}
			else
			{
				noclipdata[playerid][mode] = GetMoveDirectionFromKeys(ud, lr);
				MoveCamera(playerid);
			}
		}
		noclipdata[playerid][udold] = ud; noclipdata[playerid][lrold] = lr;
		return 0;
	}
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
	    case DIALOG_MENU:
	    {
	        if(response)
	        {
		        switch(listitem)
		        {
					case 0: //Preview
					{
					    PreviewMovement(playerid);
					}
					case 1: //Change start
					{
					    DestroyPlayerObject(playerid, noclipdata[playerid][flyobject]);
						IsReSettingEnd[playerid] 	= false;
						SettingLastLoc[playerid] 	= false;
					    IsReSettingStart[playerid] = true;
					    SettingFirstLoc[playerid]  = true;
					    noclipdata[playerid][flyobject] = CreatePlayerObject(playerid, 19300, coordInfo[playerid][StartX], coordInfo[playerid][StartY], coordInfo[playerid][StartZ], 0.0, 0.0, 0.0);
                        TogglePlayerSpectating(playerid, true);
						AttachCameraToPlayerObject(playerid, noclipdata[playerid][flyobject]);
						SetPVarInt(playerid, "FlyMode", 1);
						noclipdata[playerid][cameramode] = CAMERA_MODE_FLY;
						SendClientMessage(playerid, -1, "Используй {F58282}~k~~PED_FIREWEAPON~ {FFFFFF}чтобы установить новую {F58282}начальную {FFFFFF}позицию.");
					}
					case 2: //Change end
					{
					    DestroyPlayerObject(playerid, noclipdata[playerid][flyobject]);
						IsReSettingStart[playerid] 	= false;
						SettingFirstLoc[playerid] 	= false;
					    IsReSettingEnd[playerid] = true;
					    SettingLastLoc[playerid] = true;
					    IsCreating[playerid] 	 = true;
					    SetCameraBehindPlayer(playerid);
					    noclipdata[playerid][flyobject] = CreatePlayerObject(playerid, 19300, coordInfo[playerid][EndX], coordInfo[playerid][EndY], coordInfo[playerid][EndZ], 0.0, 0.0, 0.0);
                        TogglePlayerSpectating(playerid, true);
						AttachCameraToPlayerObject(playerid, noclipdata[playerid][flyobject]);
						SetPVarInt(playerid, "FlyMode", 1);
						noclipdata[playerid][cameramode] = CAMERA_MODE_FLY;
						SendClientMessage(playerid, -1, "Используй {F58282}~k~~PED_FIREWEAPON~ {FFFFFF}чтобы установить новую {F58282}конечную {FFFFFF}позицию.");
					}
					case 3: //Change speed
					{
					    new string[512];					
						format(string, sizeof(string), "Введите желаемое время {F58282}движения{a9c4e4} в миллисекундах\n\nТекущая скорость движения: \t{F58282}%i мс\n{a9c4e4}Текущая скорость вращения: \t{F58282}%i мс\n\n\nПримечание: {a9c4e4}1 секунда = 1000 миллисекунд", coordInfo[playerid][MoveSpeed], coordInfo[playerid][RotSpeed]);
						ShowPlayerDialog(playerid, DIALOG_MOVE_SPEED, DIALOG_STYLE_INPUT, "Скорость движения", string,"Ок","Отмена");
					}
					case 4: //Export
					{
					    ShowPlayerDialog(playerid, DIALOG_EXPORTNAME, DIALOG_STYLE_INPUT, "Сохранить движущуюся камеру","Введите имя для файла","Ок","Отмена");
					}
		        }
			}
			else
			{
				CancelFlyMode(playerid);
    			SendClientMessage(playerid, -1, "Вы покинули редактор камеры.");
   				IsCreating[playerid] = false;
			}
	    }
	 case DIALOG_MENU_POS:
	 {
		if(response)
	    {
			switch(listitem)
			{
				case 0:
				{
					DestroyPlayerObject(playerid, noclipdata[playerid][flyobject]);
					IsReSettingEnd[playerid] 	= false;
					SettingLastLoc[playerid] 	= false;
					IsReSettingStart[playerid] = true;
					SettingFirstLoc[playerid]  = true;
					noclipdata[playerid][flyobject] = CreatePlayerObject(playerid, 19300, coordInfo[playerid][StartX], coordInfo[playerid][StartY], coordInfo[playerid][StartZ], 0.0, 0.0, 0.0);
                    TogglePlayerSpectating(playerid, true);
					AttachCameraToPlayerObject(playerid, noclipdata[playerid][flyobject]);
					SetPVarInt(playerid, "FlyMode", 1);
					noclipdata[playerid][cameramode] = CAMERA_MODE_FLY;
					SendClientMessage(playerid, -1, "Используй {F58282}~k~~PED_FIREWEAPON~ {FFFFFF}чтобы установить новую {F58282}начальную {FFFFFF}позицию.");
				}
				case 1:
				{
					ShowPlayerDialog(playerid, DIALOG_EXPORTNAME_POS, DIALOG_STYLE_INPUT, "Сохранить камеру","Введите имя для файла","Ок","Отмена");					
				}
			}
		}
		else
		{
			CancelFlyMode(playerid);
    		SendClientMessage(playerid, -1, "Вы покинули редактор камеры.");
			IsCreating[playerid] = false;
		}
	 }
     case DIALOG_MOVE_SPEED:
	    {
	        if(response)
	        {
				if(strlen(inputtext))
				{
		            if(IsNumeric(inputtext))
		            {
		                coordInfo[playerid][MoveSpeed] = strval(inputtext);
		                new string[512];
		    			format(string, sizeof(string), "Введите жалаемое время {F58282}вращения{a9c4e4} в миллисекундах\n\nТекущая скорость движения: \t{F58282}%i мс\n{a9c4e4}Текущая скорость вращения: \t{F58282}%i мс\n\n\n{F58282}Примечание: {a9c4e4}1 секунда = 1000 миллисекунд", coordInfo[playerid][MoveSpeed], coordInfo[playerid][RotSpeed]);
	                    ShowPlayerDialog(playerid, DIALOG_ROT_SPEED, DIALOG_STYLE_INPUT, "Скорость вращения", string,"Ок","Отмена");
	                    IsReSettingStart[playerid] = false;
						IsReSettingEnd[playerid]   = false;
					}
		            else
		            {
		                new string[512];
	    				format(string, sizeof(string), "Введите желаемое время {F58282}движения{a9c4e4} в миллисекундах\n\nТекущая скорость движения: \t{F58282}%i мс\n{a9c4e4}Текущая скорость вращения: \t{F58282}%i мс\n\n\nПримечание: {a9c4e4}1 секунда = 1000 миллисекунд", coordInfo[playerid][MoveSpeed], coordInfo[playerid][RotSpeed]);
						ShowPlayerDialog(playerid, DIALOG_MOVE_SPEED, DIALOG_STYLE_INPUT, "Скорость движения", string,"Ок","Отмена");
		            }
				}
				else
				{
				    new string[512];
    				format(string, sizeof(string), "Введите желаемое время {F58282}движения{a9c4e4} в миллисекундах\n\nТекущая скорость движения: \t{F58282}%i мс\n{a9c4e4}Текущая скорость вращения: \t{F58282}%i мс\n\n\nПримечание: {a9c4e4}1 секунда = 1000 миллисекунд", coordInfo[playerid][MoveSpeed], coordInfo[playerid][RotSpeed]);
					ShowPlayerDialog(playerid, DIALOG_MOVE_SPEED, DIALOG_STYLE_INPUT, "Скорость движения", string,"Ок","Отмена");
				}
	        }
	        else
	        {
                ShowPlayerDialog(playerid, DIALOG_MENU, DIALOG_STYLE_LIST,"Что дальше?","Предпросмотр\nИзменить начало\nИзменить конец\nИзменить скорость\nСохранить","Ок","Отмена");
	        }
	    }
	    case DIALOG_ROT_SPEED:
	    {
	        if(response)
	        {
	            if(strlen(inputtext))
	            {
		            if(IsNumeric(inputtext))
		            {
		                coordInfo[playerid][RotSpeed] = strval(inputtext);
		                ShowPlayerDialog(playerid, DIALOG_MENU, DIALOG_STYLE_LIST,"Что дальше?","Предпросмотр\nИзменить начало\nИзменить конец\nИзменить скорость\nСохранить","Ок","Отмена");
	                    IsReSettingStart[playerid] = false;
						IsReSettingEnd[playerid]   = false;
					}
		            else
		            {
		                new string[512];
	    				format(string, sizeof(string), "Введите жалаемое время {F58282}вращения{a9c4e4} в миллисекундах\n\nТекущая скорость движения: \t{F58282}%i мс\n{a9c4e4}Текущая скорость вращения: \t{F58282}%i мс\n\n\n{F58282}Примечание: {a9c4e4}1 секунда = 1000 миллисекунд", coordInfo[playerid][MoveSpeed], coordInfo[playerid][RotSpeed]);
	                    ShowPlayerDialog(playerid, DIALOG_ROT_SPEED, DIALOG_STYLE_INPUT, "Скорость вращения", string,"Ок","Отмена");
		            }
				}
				else
				{
				    new string[512];
    				format(string, sizeof(string), "Введите жалаемое время {F58282}вращения{a9c4e4} в миллисекундах\n\nТекущая скорость движения: \t{F58282}%i мс\n{a9c4e4}Текущая скорость вращения: \t{F58282}%i мс\n\n\n{F58282}Примечание: {a9c4e4}1 секунда = 1000 миллисекунд", coordInfo[playerid][MoveSpeed], coordInfo[playerid][RotSpeed]);
	                ShowPlayerDialog(playerid, DIALOG_ROT_SPEED, DIALOG_STYLE_INPUT, "Скорость вращения", string,"Ок","Отмена");
				}
	        }
	        else
	        {
	            new string[512];
    			format(string, sizeof(string), "Введите желаемое время {F58282}движения{a9c4e4} в миллисекундах\n\nТекущая скорость движения: \t{F58282}%i мс\n{a9c4e4}Текущая скорость вращения: \t{F58282}%i мс\n\n\nПримечание: {a9c4e4}1 секунда = 1000 миллисекунд", coordInfo[playerid][MoveSpeed], coordInfo[playerid][RotSpeed]);
				ShowPlayerDialog(playerid, DIALOG_MOVE_SPEED, DIALOG_STYLE_INPUT, "Скорость движения", string,"Ок","Отмена");
	        }
	    }
	    case DIALOG_EXPORTNAME:
	    {
	        if(response)
	        {
                if(strlen(inputtext))
                {
					ExportMovement(playerid, inputtext);
				}
				else
				{
				    ShowPlayerDialog(playerid, DIALOG_EXPORTNAME, DIALOG_STYLE_INPUT, "Сохранить движущуюся камеру","Введите имя для файла","Ок","Отмена");
				}
			}
	        else
	        {
	            ShowPlayerDialog(playerid, DIALOG_MENU, DIALOG_STYLE_LIST,"Что дальше?","Предпросмотр\nИзменить начало\nИзменить конец\nИзменить скорость\nСохранить","Ок","Отмена");
	        }
	    }
		case DIALOG_EXPORTNAME_POS:
	    {
	        if(response)
	        {
                if(strlen(inputtext))
                {
					ExportCameraPos(playerid, inputtext);
				}
				else
				{
				    ShowPlayerDialog(playerid, DIALOG_EXPORTNAME_POS, DIALOG_STYLE_INPUT, "Сохранить камеру","Введите имя для файла","Ок","Отмена");					
				}
			}
	        else
	        {
	            ShowPlayerDialog(playerid, DIALOG_MENU_POS, DIALOG_STYLE_LIST,"Что дальше?","Изменить позицию\nСохранить","Ок","Отмена");
	        }
	    }
	    case DIALOG_CLOSE_NEW:
	    {
	        if(response)
	        {
	            IsCreating[playerid]      = true;
				SettingFirstLoc[playerid] = true;
				FlyMode(playerid);
	        }
	        else
	        {
	            SendClientMessage(playerid, -1, "Вы покинули редактор камеры.");
				CancelFlyMode(playerid);
	            IsCreating[playerid] = false;
	        }
	    }
	}
	return 1;
}

forward ShowPlayerMenu(playerid);
public ShowPlayerMenu(playerid)
{
	KillTimer(MenuTimer);
	IsCamMoving[playerid] = false;
	ShowPlayerDialog(playerid, DIALOG_MENU, DIALOG_STYLE_LIST,"Что дальше?","Предпросмотр\nИзменить начало\nИзменить конец\nИзменить скорость\nСохранить","Ок","Отмена");
	return 1;
}

forward PreviewMovement(playerid);
public PreviewMovement(playerid)
{
    IsCamMoving[playerid] = true;
    DestroyObject(noclipdata[playerid][flyobject]);
    SetCameraBehindPlayer(playerid);
    if(coordInfo[playerid][MoveSpeed] > coordInfo[playerid][RotSpeed])
    	MenuTimer = SetTimerEx("ShowPlayerMenu", coordInfo[playerid][MoveSpeed], 0, "i", playerid);
	else
		MenuTimer = SetTimerEx("ShowPlayerMenu", coordInfo[playerid][RotSpeed], 0, "i", playerid);
	InterpolateCameraPos(playerid, coordInfo[playerid][StartX], coordInfo[playerid][StartY], coordInfo[playerid][StartZ], coordInfo[playerid][EndX], coordInfo[playerid][EndY], coordInfo[playerid][EndZ],coordInfo[playerid][MoveSpeed]);
	InterpolateCameraLookAt(playerid, coordInfo[playerid][StartLookX],coordInfo[playerid][StartLookY],coordInfo[playerid][StartLookZ],coordInfo[playerid][EndLookX],coordInfo[playerid][EndLookY],coordInfo[playerid][EndLookZ],coordInfo[playerid][RotSpeed]);
	return 1;
}

forward ExportMovement(playerid, inputtext[]);
public ExportMovement(playerid, inputtext[])
{
    new tagstring[64];
	new movestring[512];
	new rotstring[512];
	new filename[50];
	format(filename, 128, "CamEdit_%s.txt", inputtext);
	format(tagstring, sizeof(tagstring), "|----------%s----------|\r\n", inputtext);
	format(movestring, sizeof(movestring),"InterpolateCameraPos(playerid, %f, %f, %f, %f, %f, %f, %i);\r\n",coordInfo[playerid][StartX], coordInfo[playerid][StartY], coordInfo[playerid][StartZ], coordInfo[playerid][EndX], coordInfo[playerid][EndY], coordInfo[playerid][EndZ],coordInfo[playerid][MoveSpeed]);
	format(rotstring,sizeof(rotstring),"InterpolateCameraLookAt(playerid, %f, %f, %f, %f, %f, %f, %i);",coordInfo[playerid][StartLookX],coordInfo[playerid][StartLookY],coordInfo[playerid][StartLookZ],coordInfo[playerid][EndLookX],coordInfo[playerid][EndLookY],coordInfo[playerid][EndLookZ],coordInfo[playerid][RotSpeed]);
	new File:File = fopen(filename, io_write);
	fwrite(File, tagstring);
	fwrite(File, movestring);
	fwrite(File, rotstring);
	fclose(File);
	new myOutpString[256];
	format(myOutpString, sizeof(myOutpString), "Позиция движущейся камеры сохранена под именем {F58282}%s {a9c4e4}в папке scriptfiles!\n\nЧто делаем дальше?", filename);
	ShowPlayerDialog(playerid, DIALOG_CLOSE_NEW, DIALOG_STYLE_MSGBOX,"Что делаем дальше?",myOutpString,"Создать новый","Выйти");
}

forward ExportCameraPos(playerid, inputtext[]);
public ExportCameraPos(playerid, inputtext[])
{
	new tagstring[64];
	new movestring[512];
	new rotstring[512];
	new filename[50];
	format(filename, 128, "iCamEdit_%s.txt", inputtext);
	format(tagstring, sizeof(tagstring), "|----------%s----------|\r\n", inputtext);
	format(movestring, sizeof(movestring),"SetPlayerCameraPos(playerid, %f, %f, %f);\r\n",coordInfo[playerid][StartX], coordInfo[playerid][StartY], coordInfo[playerid][StartZ]);
	format(rotstring,sizeof(rotstring),"SetPlayerCameraLookAt(playerid, %f, %f, %f);\r\n// by iRusel\r\n// http://www.irusel.com\r\n// http://pawn-wiki.ru",coordInfo[playerid][StartLookX],coordInfo[playerid][StartLookY],coordInfo[playerid][StartLookZ]);
	new File:File = fopen(filename, io_write);
	fwrite(File, tagstring);
	fwrite(File, movestring);
	fwrite(File, rotstring);
	fclose(File);
	new myOutpString[256];
	format(myOutpString, sizeof(myOutpString), "Позиция камеры сохранена под именем {F58282}%s {a9c4e4}в папке scriptfiles!\n\nЧто делаем дальше?", filename);
	ShowPlayerDialog(playerid, DIALOG_CLOSE_NEW, DIALOG_STYLE_MSGBOX,"Что делаем дальше?",myOutpString,"Создать новый","Выйти");
}

stock GetMoveDirectionFromKeys(ud, lr)
{
	new direction = 0;

    if(lr < 0)
	{
		if(ud < 0) 		direction = MOVE_FORWARD_LEFT;
		else if(ud > 0) direction = MOVE_BACK_LEFT;
		else            direction = MOVE_LEFT;
	}
	else if(lr > 0)
	{
		if(ud < 0)      direction = MOVE_FORWARD_RIGHT;
		else if(ud > 0) direction = MOVE_BACK_RIGHT;
		else			direction = MOVE_RIGHT;
	}
	else if(ud < 0) 	direction = MOVE_FORWARD;
	else if(ud > 0) 	direction = MOVE_BACK;

	return direction;
}

//--------------------------------------------------

stock MoveCamera(playerid)
{
	new Float:FV[3], Float:CP[3];
	GetPlayerCameraPos(playerid, CP[0], CP[1], CP[2]);
    GetPlayerCameraFrontVector(playerid, FV[0], FV[1], FV[2]);
	if(noclipdata[playerid][accelmul] <= 1) noclipdata[playerid][accelmul] += ACCEL_RATE;
	new Float:speed = MOVE_SPEED * noclipdata[playerid][accelmul];
	new Float:X, Float:Y, Float:Z;
	GetNextCameraPosition(noclipdata[playerid][mode], CP, FV, X, Y, Z);
	MovePlayerObject(playerid, noclipdata[playerid][flyobject], X, Y, Z, speed);
	noclipdata[playerid][lastmove] = GetTickCount();
	return 1;
}

//--------------------------------------------------

stock GetNextCameraPosition(move_mode, Float:CP[3], Float:FV[3], &Float:X, &Float:Y, &Float:Z)
{
    #define OFFSET_X (FV[0]*6000.0)
	#define OFFSET_Y (FV[1]*6000.0)
	#define OFFSET_Z (FV[2]*6000.0)
	switch(move_mode)
	{
		case MOVE_FORWARD:
		{
			X = CP[0]+OFFSET_X;
			Y = CP[1]+OFFSET_Y;
			Z = CP[2]+OFFSET_Z;
		}
		case MOVE_BACK:
		{
			X = CP[0]-OFFSET_X;
			Y = CP[1]-OFFSET_Y;
			Z = CP[2]-OFFSET_Z;
		}
		case MOVE_LEFT:
		{
			X = CP[0]-OFFSET_Y;
			Y = CP[1]+OFFSET_X;
			Z = CP[2];
		}
		case MOVE_RIGHT:
		{
			X = CP[0]+OFFSET_Y;
			Y = CP[1]-OFFSET_X;
			Z = CP[2];
		}
		case MOVE_BACK_LEFT:
		{
			X = CP[0]+(-OFFSET_X - OFFSET_Y);
 			Y = CP[1]+(-OFFSET_Y + OFFSET_X);
		 	Z = CP[2]-OFFSET_Z;
		}
		case MOVE_BACK_RIGHT:
		{
			X = CP[0]+(-OFFSET_X + OFFSET_Y);
 			Y = CP[1]+(-OFFSET_Y - OFFSET_X);
		 	Z = CP[2]-OFFSET_Z;
		}
		case MOVE_FORWARD_LEFT:
		{
			X = CP[0]+(OFFSET_X  - OFFSET_Y);
			Y = CP[1]+(OFFSET_Y  + OFFSET_X);
			Z = CP[2]+OFFSET_Z;
		}
		case MOVE_FORWARD_RIGHT:
		{
			X = CP[0]+(OFFSET_X  + OFFSET_Y);
			Y = CP[1]+(OFFSET_Y  - OFFSET_X);
			Z = CP[2]+OFFSET_Z;
		}
	}
}
//--------------------------------------------------

stock CancelFlyMode(playerid)
{
	DeletePVar(playerid, "FlyMode");
	CancelEdit(playerid);
	TogglePlayerSpectating(playerid, false);
	DestroyPlayerObject(playerid, noclipdata[playerid][flyobject]);
	noclipdata[playerid][cameramode] = CAMERA_MODE_NONE;
	IsReSettingStart[playerid] 	= false;
	IsReSettingEnd[playerid] 	= false;
	SettingFirstLoc[playerid] 	= false;
	SettingLastLoc[playerid] 	= false;
	return 1;
}

//--------------------------------------------------

stock FlyMode(playerid)
{
	new Float:X, Float:Y, Float:Z;
	IsCreating[playerid] = true;
	SettingFirstLoc[playerid] = true;
	GetPlayerPos(playerid, X, Y, Z);
	noclipdata[playerid][flyobject] = CreatePlayerObject(playerid, 19300, X, Y, Z, 0.0, 0.0, 0.0);
	TogglePlayerSpectating(playerid, true);
	AttachCameraToPlayerObject(playerid, noclipdata[playerid][flyobject]);

	SetPVarInt(playerid, "FlyMode", 1);
	noclipdata[playerid][cameramode] = CAMERA_MODE_FLY;	
	SendClientMessage(playerid, -1, "Вы вошли в редактор движущейся камеры.");
	SendClientMessage(playerid, -1, "Используй /closecameditor чтобы закрыть редактор.");
	SendClientMessage(playerid, -1, "Используй {F58282}~k~~GO_FORWARD~, ~k~~GO_BACK~, ~k~~GO_LEFT~ и ~k~~GO_RIGHT~{FFFFFF} чтобы перемещать камеру.");	
	SendClientMessage(playerid, -1, "Используй {F58282}~k~~PED_FIREWEAPON~ {FFFFFF}чтобы сохранить {F58282}начальную {FFFFFF}позицию.");
	return 1;
}

IsNumeric(szInput[]) {
	new iChar, i = 0;
	while ((iChar = szInput[i++])) if (!('0' <= iChar <= '9')) return 0;
	return 1;
}
