state("FalloutNV")
{
	bool loadingPtr : 0xDDA4EC;
	//pre xnvse patch - bool introDone : 0xDDA590;
	bool introDone : 0xDDAC70;
	byte quest: 0x00DC6D50, 0x4;

	//Only valid on Steam,GOG
	//0x0DDEA3C Player Base
	float speed : 0x0DDEA3C, 0x68, 0x138, 0x514;
	float HorizontalSpeed : 0x0DDEA3C, 0x68, 0x138, 0x510;
	string6 QuestName: 0x0DDEA3C, 0x6B8, 0x64,0x0;
	int QuestStage: 0x0DDEA3C, 0x6B8, 0x60;
	int CellRefID : 0x0DDEA3C, 0x40, 0xAC, 0x40, 0xC;
	
}

startup
 {
	String speedometer;
	String questcounter;
	String maxSpeedometer;
	

    //creates text components for quest counter, speedometer and maxSpeedometer
	vars.SetTextComponent = (Action<string, string>)((id, text) =>
	{
        var textSettings = timer.Layout.Components.Where(x => x.GetType().Name == "TextComponent").Select(x => x.GetType().GetProperty("Settings").GetValue(x, null));
        var textSetting = textSettings.FirstOrDefault(x => (x.GetType().GetProperty("Text1").GetValue(x, null) as string) == id);
        if (textSetting == null)
        {
        var textComponentAssembly = Assembly.LoadFrom("Components\\LiveSplit.Text.dll");
        var textComponent = Activator.CreateInstance(textComponentAssembly.GetType("LiveSplit.UI.Components.TextComponent"), timer);
        timer.Layout.LayoutComponents.Add(new LiveSplit.UI.Components.LayoutComponent("LiveSplit.Text.dll", textComponent as LiveSplit.UI.Components.IComponent));

        textSetting = textComponent.GetType().GetProperty("Settings", BindingFlags.Instance | BindingFlags.Public).GetValue(textComponent, null);
        textSetting.GetType().GetProperty("Text1").SetValue(textSetting, id);
        }

        if (textSetting != null)
        textSetting.GetType().GetProperty("Text2").SetValue(textSetting, text);
    });

    settings.Add("Quest Counter", false, "Quest Counter");	
    settings.Add("Speed", false, "Speed");
	settings.Add("Max Speed", false, "Max Speed", "Speed");
	settings.Add("AutoStart",true,"AutoStart");
    settings.Add("Autosplitter", false, "Autosplitter");
	settings.Add("Quest&Cell_Splitter",true,"Category Autosplitters","Autosplitter");
	settings.Add("Quest_Splitter",false,"Quest Counter Autoplitter","Autosplitter");
	settings.Add("Debug",false,"Debug");
	
	
	
	
	//Categories
	settings.Add("Any%",true,"Any%","Quest&Cell_Splitter");
	settings.Add("Glitchless",false,"Glitchless","Quest&Cell_Splitter");
	settings.Add("Custom",false,"Custom","Quest&Cell_Splitter");
	
	
	settings.SetToolTip("Max Speed", "Records the maximum speed the character had in a run and will be set back to 0 when the timer is started or reset. Values over 100000 will reset it to 0.");
	settings.SetToolTip("Quest&Cell_Splitter","Splits based on set Quest and cell");
    settings.SetToolTip("Quest_Splitter", "Causes timer to split when the quest counter is the same as the quest number in your splits surrounded by () eg: (1) Infinite Dash\n Will not split if anything else surrounds the number ");
	settings.SetToolTip("Debug","Shows player info such as cell, questname and stage");
	settings.SetToolTip("Custom","Allows custom splits depending on a text file");
	settings.SetToolTip("AutoStart","Automatically start the timer when a run starts. It will not restart the timer mid run :)");

	vars.splitCount=0;
	
	
	
	//The hex code for cells can be found either using the debug tools or getting the cell ref id from a wiki page :)
	
	vars.any_Quests = new List<String>{"","","","","","","","","","","","","","","","","",""}; //if quest blank allow any quest to be active
    vars.any_Cell = new List<String>{"DAEBB","13B3CE","10BEEE","102195","1221C4","E8202","DDE34","161E98"};
	//split: doc, Enter Strip, Exit strip,Enter Pearls Barracks, basement, el dorado, enter dam, end
	
	
	
	vars.glitchless_Quests = new List<String>{"","","","","","","","","","","","","","","",""};
	vars.glitchless_Cell = new List<String>{"DAEBB","DDF33","13B3CE","10BEEE","DABEA","E18B2","DAEB9","10BEED","16DBE3","10BEED","DDE34","161E98"};
	//split: doc, black mtn, enter strip, leave strip, leave freeside, bos ft, goodsprings ft, ft back to strip,ft back to strip, ft strip again(after el dorado),dam,end

	//Normalise Lists so they are same length - Avoid out of range error
	if(vars.glitchless_Quests.Count == vars.glitchless_Cell.Count){}
	else if(vars.glitchless_Quests.Count > vars.glitchless_Cell.Count)
	{
		int len = vars.glitchless_Quests.Count - vars.glitchless_Cell.Count;
		for(int x=0;x<len;x++)
		{
			vars.glitchless_Cell.Add("");
		}
	}
	else
	{
		int len = vars.glitchless_Cell.Count - vars.glitchless_Quests.Count;
		for(int x=0;x<len;x++)
		{
			vars.glitchless_Quests.Add("");
		}
	}
		
	if(vars.any_Quests.Count == vars.any_Cell.Count){}
	else if(vars.any_Quests.Count > vars.any_Cell.Count)
	{
		int len = vars.any_Quests.Count - vars.any_Cell.Count;
		for(int x=0;x<len;x++)
		{
			vars.any_Cell.Add("");
		}
	}
	else
	{
		int len = vars.any_Cell.Count - vars.any_Quests.Count;
		for(int x=0;x<len;x++)
		{
			vars.any_Quests.Add("");
		}
	}
	
	
	
	
	vars.custom_Quests = new List<String>();
	vars.custom_Stage = new List<String>();
	vars.custom_Cell = new List<String>();

	//161E98 is the final cutscene room but will not include in MaxQ due to weird final quest
	


}


init
{
	//I know this sig looks horrible :) I couldn't find a way to shorten it by going to previous liens
	vars.isIntroDone = new SigScanTarget(2,
	"89 ?? ?? ?? ?? ??",				//mov [FalloutNV.exe+DDAC70], ecx	//IntroDone			
	"C7 ?? ?? ????????",				//mov [ebp-04],0
	"6A ??",							//push -01
	"68 ????????",						//push FalloutNV.exe+C70244
	"E8 ????????",
	"83 ?? ??",
	"A3 ????????",
	"C7 ?? ?? ????????",
	"0F?? ?? ??",
	"52",
	"A1 ????????","50","8B ?? ??","8B ?? ??","E8 ????????","8B ?? ??","64 ?? ?? ????????","59","8B ??","5D","C2 ????","????????????????","55","8B??","6A??",
	"68????????","64??????????","50","83????","A1????????","33??","50","8D????","64??????????","89????","A1????????","83????","75??","8B??????????","83????",
	"89??????????","C7????????????","6A??","68????????","E8????????","83????","A3????????","C7????????????","8B????","83??????","74??","A1????????","50","8B????",
	"8B????","E8????????","0F????","85??","74??","C7????????????","EB??","C7????????????","8A????","8B????","64????????????","59","8B??","5D","C3","????????????????????","55","8B??","83"
	);
	
	//
	vars.isLoadingSig = new SigScanTarget(1,
	"A2 ?? ?? ?? ??",					//mov [FalloutNV.exe+DDA4EC],al 			//Loading
	"83 3D ?? ?? ?? ?? ??",				//cmp dword ptr [FalloutNV.exe+DDA4F0],00
	"74 10"); 							//je FalloutNV.exe+3AA6D4

	var module = modules.First();
	var scanner = new SignatureScanner(game, module.BaseAddress, module.ModuleMemorySize);

	vars.isLoadingAddr = scanner.Scan(vars.isLoadingSig);
	vars.isIntroDoneAddr = scanner.Scan(vars.isIntroDone);
		
	if (vars.isLoadingAddr == IntPtr.Zero || vars.isIntroDoneAddr == IntPtr.Zero)
    {
        throw new Exception("Game engine not initialized - retrying");
    }
	vars.pointeraddr = new DeepPointer(vars.isLoadingAddr,0);
	vars.loading = new MemoryWatcher<bool>(vars.pointeraddr);
	
	vars.pointeraddrs = new DeepPointer(vars.isIntroDoneAddr,0);
	vars.intro = new MemoryWatcher<bool>(vars.pointeraddrs);
	
	vars.maxSpeedValue = 0.0f;
	vars.tempSpeed = 0.0f;

	//Allow splitting at custom times
	/*
	Make a text file with values seperated by commas
	First Line is the questname, use any for any quest
	Second Line is quest stage, use any for any stage
	Third Line is Cell ID , use any for any cell

	eg:
	VMQ01,any,VMQ02
	any,any,20
	BBEA3,BBEA3,109311
	*/
	
	
	if(settings["Custom"])
	{
		vars.temp = new List<String>();
		var lines = File.ReadAllLines("Components/CustomSplits.txt");
		for (var i = 0; i < lines.Length; i++ )
		{
			var line = lines[i].Split(',').ToList();
			// Process line
				switch (i)
				{
					case 0: //Quest Name
							foreach(var Quest in line)
							{
								vars.custom_Quests.Add(Quest.ToUpper());
								//print(Quest);
							}
							break;
					case 1: //Quest Stage
							foreach(var QuestStage in line)
							{
								vars.custom_Stage.Add(QuestStage.ToUpper());
								//print(QuestStage);
							}
							break;
					case 2:
							foreach(var CellID in line)
							{
								vars.custom_Cell.Add(CellID.ToUpper());
								//print(CellID);
							}
							break;						
					default:
						break;
				}
		}
		//Normalise Lists so they are same length - Avoid out of range error
		if(vars.custom_Quests.Count == vars.custom_Cell.Count){}
		else if(vars.custom_Quests.Count > vars.custom_Cell.Count)
		{
			int len = vars.custom_Quests.Count - vars.custom_Cell.Count;
			for(int x=0;x<len;x++)
			{
				vars.custom_Cell.Add("any");
			}
		}
		else
		{
			int len = vars.custom_Cell.Count - vars.custom_Quests.Count;
			for(int x=0;x<len;x++)
			{
				vars.custom_Quests.Add("any");
			}
		}
		if(vars.custom_Quests.Count == vars.custom_Stage.Count){}
		else if(vars.custom_Quests.Count > vars.custom_Stage.Count)
		{
			int len = vars.custom_Quests.Count - vars.custom_Stage.Count;
			for(int x=0;x<len;x++)
			{
				vars.custom_Stage.Add("any");
			}
		}
		else
		{
			int len = vars.custom_Stage.Count - vars.custom_Quests.Count;
			for(int x=0;x<len;x++)
			{
				vars.custom_Quests.Add("any");
			}
		}
	}
}

update
{
	vars.loading.Update(game);
	vars.intro.Update(game);
	vars.split = false;
    vars.isLoading = false;
	vars.doStart = false;


	string hexCell = Convert.ToString(current.CellRefID,16).ToUpper();
	if ((vars.loading.Current) || (!vars.intro.Current)) {
        vars.isLoading = true;
    }
	
	if (settings["Speed"]) 
	{
		if(vars.isLoading == false)
		{
			if(current.speed > 10000)
			{
				current.speed = 0;
			}
			vars.tempSpeed = (Math.Sqrt(Math.Pow(current.speed,2)+Math.Pow(current.HorizontalSpeed,2)));

			current.speedometer = vars.tempSpeed.ToString("000.0000");
			vars.SetTextComponent("Speed:", (current.speedometer));
			
			if (settings["Max Speed"])
			{	
				if(vars.maxSpeedValue > 100000)
				{
					vars.maxSpeedValue = 0;
				}
				if( vars.tempSpeed >= vars.maxSpeedValue)
				{
					vars.maxSpeedValue = vars.tempSpeed;
					current.maxSpeedometer = vars.maxSpeedValue.ToString("000.0000");
					vars.SetTextComponent("Max Speed:", (current.maxSpeedometer));
				}
			}
		}
	}
	if (settings["Quest Counter"]) 
	{

		current.questcounter = current.quest.ToString("0");
		vars.SetTextComponent("Quests:", (current.questcounter)); 
	}
	if(settings["Debug"])
	{
		
		String PaddedCellName = hexCell.PadLeft(8,'0');
		String QName = current.QuestName;
		int QStage = current.QuestStage;
		if(current.QuestName==null)
		{
			QName = "No Active Quest";
			QStage = 0;
		}
		vars.SetTextComponent("Cell Name:",PaddedCellName);
		vars.SetTextComponent("Quest Name:",QName);
		vars.SetTextComponent("Quest Stage:",QStage.ToString());
	}
	
	
	if(settings["AutoStart"])
	{
		timer.IsGameTimePaused = true;
		vars.doStart = hexCell=="103DF9" && current.QuestName==null && old.CellRefID!=current.CellRefID;
	}
	
	vars.splitCount= timer.CurrentSplitIndex;
	
	//Splitting
	//TODO: Find better way to make settings
	
	if(settings["Autosplitter"] && timer.CurrentPhase != TimerPhase.NotRunning)
	{
		if(settings["Quest&Cell_Splitter"])
		{
			if(settings["Any%"])
			{
				
				
				//print(Convert.ToString(current.CellRefID,16).ToUpper());

				if(vars.any_Quests[vars.splitCount]=="")
				{
					//Sequential splitting due to the nature of the run
					vars.split = vars.any_Cell[vars.splitCount] == hexCell && current.CellRefID!=old.CellRefID;	
					//vars.split = vars.any_Cell.Contains(hexCell) && current.CellRefID!=old.CellRefID;
				}
				else
				{
					
					vars.split = ((vars.any_Cell[vars.splitCount % vars.any_Cell.Count] == hexCell) && (vars.any_Quests[vars.splitCount % vars.any_Cell.Count] == current.QuestName) && (current.CellRefID!=old.CellRefID));
				}
				
			}
			else if(settings["Glitchless"])
			{
				if(vars.glitchless_Quests[vars.splitCount % vars.glitchless_Cell.Count]=="")
				{
					vars.split = vars.glitchless_Cell[vars.splitCount % vars.glitchless_Cell.Count] == hexCell && current.CellRefID!=old.CellRefID;	
				}
				else
				{
					vars.split = ((vars.glitchless_Cell[vars.splitCount % vars.glitchless_Cell.Count] == hexCell) && (vars.glitchless_Quests[vars.splitCount % vars.glitchless_Cell.Count] == current.QuestName) && (current.CellRefID!=old.CellRefID));
				}
				
				
			}
			else if(settings["Custom"])
			{

				if(vars.custom_Quests[vars.splitCount % vars.custom_Cell.Count].ToLower()=="any")
				{
					vars.split = vars.custom_Cell[vars.splitCount % vars.custom_Cell.Count] == hexCell && current.CellRefID!=old.CellRefID;	
				}
				
				else
				{
					if(vars.custom_Stage[vars.splitCount % vars.custom_Cell.Count].ToLower()=="any")
					{
						vars.split = ((vars.custom_Cell[vars.splitCount % vars.custom_Cell.Count] == hexCell) && (vars.custom_Quests[vars.splitCount % vars.custom_Cell.Count] == current.QuestName) && (current.CellRefID!=old.CellRefID));
					}
					else
					{
						print(((vars.custom_Quests[vars.splitCount % vars.custom_Cell.Count] == current.QuestName)).ToString());
						print(vars.custom_Quests[vars.splitCount % vars.custom_Cell.Count]);
						print(current.QuestName);
						vars.split = ((vars.custom_Cell[vars.splitCount % vars.custom_Cell.Count] == hexCell) && (vars.custom_Quests[vars.splitCount % vars.custom_Cell.Count] == current.QuestName) && (current.CellRefID!=old.CellRefID) && (current.QuestStage.ToString() == vars.custom_Stage[vars.splitCount % vars.custom_Cell.Count]));
					}
				}
			}
		
		}
		//splits when current split contains (x) where x is the current number of completed quests
		if(settings["Quest_Splitter"])
		{
			if(timer.CurrentSplit.Name.ToLower().Contains("("+current.questcounter+")"))
			{
				vars.split=true;
			}
		}
	}

}

onReset
{
	if (settings["Max Speed"])
	{
		vars.maxSpeedValue = 0.0f;
		current.maxSpeedometer = vars.maxSpeedValue.ToString("000.0000");
		vars.SetTextComponent("Max Speed:", (current.maxSpeedometer));
	}
}

onStart
{
	if (settings["Max Speed"])
	{
		vars.maxSpeedValue = 0.0f;
		current.maxSpeedometer = vars.maxSpeedValue.ToString("000.0000");
		vars.SetTextComponent("Max Speed:", (current.maxSpeedometer));
	}
}

start
{
	return vars.doStart;
}

split
{
	return vars.split;	
}

isLoading
{
	return vars.isLoading;
}
exit
{
	timer.IsGameTimePaused = true;
}