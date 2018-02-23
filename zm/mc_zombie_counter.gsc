#using scripts\shared\flag_shared;
#using scripts\shared\ai\zombie_utility;
#using scripts\shared\callbacks_shared;

/*
#####################
by: M.A.K.E C E N T S
#####################
Script:
mapname script:
#using scripts\zm\mc_zombie_counter;

zone:
scriptparsetree,scripts/zm/mc_zombie_counter.gsc

*/
#define MINLIMIT 10
#define ZOMBIESLEFT "Zombies Left: "
#namespace zombcount;
function autoexec init()
{
	callback::on_connect(&Zombie_Counter);
	callback::on_ai_spawned(&WaitToDie);
}

function private Zombie_Counter()
{
	level waittill("startgame");
	if(isdefined(self.zombiecounter) && self.zombiecounter)
	{
		text = ZOMBIESLEFT;
		if(isdefined(level.mc_continuous_spawning) && level.mc_continuous_spawning)
		{
			text = level.zombiesalive;
		}		
		self.zhud = self ZombieText(text);
		self.zcount = self ZombieCounter(0);
		self.zhud.alpha = 0;
		self.zcount.alpha = 0;

	}		
}

function WaitToDie()
{
	thread UpdateZPerPlayer();
	self waittill("death");
	thread UpdateZPerPlayer();
}

function UpdateZPerPlayer()
{
	foreach(player in GetPlayers())
	{
		if(isdefined(player.zhud))
		{
			player thread UpdateZCounter();
		}
	}
}

function UpdateZCounter()
{
	self notify("hud_update");
	self endon("hud_update");

	text = ZOMBIESLEFT;
	if(isdefined(level.continuespawning) && level.continuespawning)
	{
		if(self.zhud.alpha == 0)
		{
			self.zhud.alpha = 1;
			
		}
		if(self.zcount.alpha ==0)
		{
			self.zcount.alpha = 1;
		}
		total = GetAISpeciesArray().size;
		//IPrintLnBold("test " + total);
		self.zcount SetValue(total);
		return;
	}
	if(isdefined(level.mc_continuous_spawning) && level.mc_continuous_spawning)
	{
		text = level.zombiesalive;
	}	
	if(isdefined(level.mc_continuous_spawning) && level.mc_continuous_spawning)
	{
		total = GetAISpeciesArray().size;
	}
	else
	{
		total = level.zombie_total + zombie_utility::get_current_zombie_count();
	}
	minlimit = MINLIMIT;
	if(isdefined(level.mc_difficulty))
	{
		if(level.mc_difficulty>0)
		{
			minlimit = MINLIMIT/level.mc_difficulty;
		}
	}
	if(total>minlimit)
	{
		if(self.zhud.alpha==1)
		{
			self.zhud.alpha = 0;
			self.zcount.alpha = 0;
			self.zhud SetText(text);
		}			
	}
	else
	{
		if(self.zhud.alpha ==0)
		{
			self.zhud SetText(text);
			self.zhud.alpha = 1;
			self.zcount.alpha = 1;
		}
		
	}
	if(total == 0)
	{
		self.zhud SetText("Intermission");
		if(self.zcount.alpha==1)
		{			
			self.zcount.alpha = 0;
		}
	}
	else
	{
		if(self.zcount.alpha == 0 && total<minlimit)
		{
			self.zhud SetText(text);
			self.zcount.alpha = 1;
		}

		self.zcount SetValue(total);
	}
}

function private ZombieText(text){

	hud = NewClientHudElem(self);
   	hud.horzAlign = "center";
   	hud.vertAlign = "top";
   	hud.alignX = "right";
   	hud.alignY = "top";
   	hud.y = 10;
   	hud.x+=35;
   	// hud.x = -200;
   	hud.foreground = 1;
   	hud.fontscale = 1.5;
   	hud.alpha = 1;
   	hud.color = ( 0.52, 0.86, 0.99 );
   	hud SetText(text);
   	return hud;
}

function private ZombieCounter(total){

	hud = NewClientHudElem(self);
   	hud.horzAlign = "center";
   	hud.vertAlign = "top";
   	hud.alignX = "left";
   	hud.alignY = "top";
   	hud.y = 10;
   	hud.x+=35;
   	// hud.x = -200;
   	hud.foreground = 1;
   	hud.fontscale = 1.5;
   	hud.alpha = 1;
   	hud.color = ( 0.52, 0.86, 0.99 );
   	hud setvalue(total);
   	return hud;
}
