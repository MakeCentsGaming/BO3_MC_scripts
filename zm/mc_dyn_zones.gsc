#using scripts\zm\_zm_zonemgr;
#using scripts\codescripts\struct;
#using scripts\shared\array_shared;
#using scripts\shared\flag_shared;
/*
#####################
by: M.A.K.E C E N T S
#####################
Script:

Add to top of mapname.gsc
#using scripts\zm\mc_dyn_zones;
In main change the following:
//level.zone_manager_init_func =&usermap_test_zone_init;
level.zone_manager_init_func =&mc_dyn_zones::SetUpZones;

Add to zone file
scriptparsetree,scripts/zm/mc_dyn_zones.gsc

Radiant:
Add zones (info_volume) with spawners as targets (can be auto targets), no targetname needed
Add a struct between zones with kvps:
script_noteworthy or targetname>mc_dyn_zones (or whatever you define MCDYNZONESSCRIPTNOTE is)

If you place structs away from triggers then make them the target of the structs that are near
	triggers, that you want to activate at the same time (for splitting zones) or give it a known
	script_flags are not needed

The struct needs placed within MCDYNTRIGDISTANCEMAX units of the trigger you want to trigger it
Setting USEZONESFLAGFORNONEFOUND to true will enable any zone a struct didn't have a script_flag kvp
	that is touching it

###############################################################################
*/

#define MCDYNZONESSCRIPTNOTE "mc_dyn_zones" //script_noteworthy for structs
#define MCDYNSTRUCTDISTMAX 150
#define MCDYNTRIGDISTANCEMAX 100
#define USEZONESFLAGFORNONEFOUND false //false for dyn doors, otherwise everythign is adjacent through walls
#define MCDYNFLAGS "mc_dyn_flags"
#define DEFAULTMODEL "p7_zm_vending_revive"

function SetUpZones()
{
	level.lastmczonecount = 0;
	SetZoneStructs();
	mc_zones = getentarray(MCDYNZONESSCRIPTNOTE, "targetname");
	
	foreach(index, z in mc_zones)
	{
		z.targetname = z.targetname+index;
		level.lastmczonecount=index;
	}
	level SetupFlags();
	level SpawnModels();
	level CheckTriggers();
	level DeleteZoneStructs();
}


function private SetZoneStructs()
{
	level.zonestructs = struct::get_array(MCDYNZONESSCRIPTNOTE, "script_noteworthy");
	level.zonestructs = ArrayCombine(level.zonestructs, struct::get_array(MCDYNZONESSCRIPTNOTE, "targetname"),false,false);
	targets = [];
	foreach(s in level.zonestructs)
	{
		if(isdefined(s.target))
		{
			ts = struct::get_array(s.target, "targetname");
			foreach(t in ts)
			{
				targets[targets.size] = t;
			}
		}
	}
	level.zonestructs = ArrayCombine(level.zonestructs,targets,false,false);
}

function CheckTriggers()
{
	trigs = GetEntArray("trigger_use","classname");
	foreach(trig in trigs)
	{
		foreach(z in level.zonestructs)
		{
			if(Distance(z.origin,trig.origin)<MCDYNSTRUCTDISTMAX)
			{
				z AddThisFlag(trig);				
			}
		}
	}
}

function DeleteZoneStructs()
{
	foreach(z in level.zonestructs)
	{
		struct::delete();
	}
}

function SetupFlags()
{
	//if dynamic doors are being used, wait till they have moved to establish adjacent zones
	if(isdefined(level.waitfordyndoors))
	{
		level flag::wait_till(level.waitfordyndoors);
	}

	foreach(z in level.zonestructs)
	{
		if(!isdefined(z.script_flag)) 
		{
			//try to get flag from close trigger
			z.script_flag = z GetClosestTriggerScriptFlag(MCDYNTRIGDISTANCEMAX);
			if(!isdefined(z.script_flag))
			{
				//make zones active from start
				if(USEZONESFLAGFORNONEFOUND)
				{
					z.script_flag = "zones_initialized";
				}
				//get the next flag available
				else
				{							
					z.script_flag = GetNextFlag();
					//thread DelayPrint(z.script_flag);
				}
			}
		}
		if(isdefined(z.target))
		{
			z AddFlagToEachTarget();
		}		
	}	
}

function DelayPrint(z, index = 0)
{
	wait(index+12);
	IPrintLn(z);
}

function SpawnModels()
{	
	foreach(index,z in level.zonestructs)
	{
		//thread DelayPrint(z.script_flag, index);
		model = spawn("script_model", z.origin);
		model.script_flag = z.script_flag;
		model SetModel(DEFAULTMODEL);
		model DynzoneSetup();	
		model delete();
	}
}

function AddFlagToEachTarget()
{
	dyn_zone_structs = struct::get_array(self.target, "targetname");
	foreach(dzs in dyn_zone_structs)
	{
		self AddThisFlag(dzs);
	}
}

function AddThisFlag(dzs)
{
	if(!isdefined(self.script_flag) || StrStrip(self.script_flag) =="") return;
	if(!isdefined(dzs.script_flag))
	{
		dzs.script_flag = self.script_flag;
		return;
	}	
	if(IsSubStr(dzs.script_flag, self.script_flag)) return;
	dzs.script_flag = dzs.script_flag+"," + self.script_flag;
}

function GetNextFlag()
{
	if(!isdefined(level.mcdynflags))
	{
		level.mcdynflags = 0;
	}
	level.mcdynflags++;
	return MCDYNFLAGS+level.mcdynflags;
}

function GetClosestTriggerScriptFlag(max = 100000)
{
	trigs = GetUseTrigsWithScriptFlags();
	// IPrintLnBold(trigs.size + " available trigs");
	closest = self GetClosestTrigger(trigs, max);
	if(!isdefined(closest))
	{
		return undefined;
	}
	if(StrStrip(closest.script_flag)=="")
	{
		return undefined;
	}
	return closest.script_flag;
}

function GetClosestTrigger(trigs, max = 100000)
{	
	if(trigs.size<=0) return undefined;
	ctrig = undefined;
	closest = max;
	
	foreach(trig in trigs)
	{
		ndist = Distance(trig.origin,self.origin);
		if(ndist < closest)
		{
			closest = ndist;
			ctrig = trig;
		}
	}
	return ctrig;
}

function GetUseTrigsWithScriptFlags()
{
	trigs =getentarray("trigger_use", "classname");
	// IPrintLnBold(trigs.size + " available trigs");
	strigs= [];
	foreach(trig in trigs)
	{
		if(isdefined(trig.script_flag))
		{
			strigs[strigs.size] = trig;
		}
	}
	return strigs;

}

function GetAdjacentZones()
{
	adjacentzones= [];
	zones = GetEntArray("info_volume","classname");
	foreach(z in zones)
	{
		if(z IsTouching(self))
		{
			if(!isdefined(z.targetname))
			{
				level.lastmczonecount++;
				z.targetname = MCDYNZONESSCRIPTNOTE + level.lastmczonecount;
			}
			adjacentzones[adjacentzones.size] = z.targetname;
		}
	}
	return adjacentzones;
}

function DynZoneSetup()
{	
	addzones = self GetAdjacentZones();
		
	flags = self GetFlags();
	count = 0;
	while(addzones.size>=2+count)
	{
		foreach(index,flag in flags)
		{
			if(addzones.size>=2)
			{
				//thread AddAdjacentPrint(addzones[0],addzones[1], flag, index);
				zm_zonemgr::add_adjacent_zone(addzones[0+count], addzones[1+count], flag);	
			}
		}
		count++;
	}
}

function GetFlags()
{
	flags = StrTok(self.script_flag, ",");
	foreach(index, str_flag in flags )
	{
		flags[index] = StrStrip(str_flag);
	}
	return flags;
}

function AddAdjacentPrint(a,b,f,time)
{
	wait(20+time);
	IPrintLn("add_adjacent_zone(" + a+","+ b+","+ f +")");
}
