
function GetTavernRestDurationMultiplier( bedLevel: ETavernBedLevel ) : int
{
	switch ( bedLevel ) {
		case TBL_Rich:
		case TBL_Decent:
			return 2;
		case TBL_Poor:
			return 1;
		case TBL_IncrediblyPoor:
		default:
			return 0;
	}
}

function GetTavernRestValueMultiplier( bedLevel: ETavernBedLevel ) : int
{
	switch ( bedLevel ) {
		case TBL_Rich:
			return 4;
		case TBL_Decent:
			return 2;
		case TBL_Poor:
			return 1;
		case TBL_IncrediblyPoor:
		default:
			return 0;
	}
}

class W3Effect_TavernRested extends CBaseGameplayEffect
{
	default attributeName = 'vitality';
	default effectType = EET_TavernRested;
	default isPositive = true;

	event OnEffectAdded( customParams : W3BuffCustomParams )
	{
		var i: int;
		var bed: W3TavernBed;
		var multiplier: int;

		bed = FindActiveTavernBed();

		if( bed )
		{
			multiplier = GetTavernRestValueMultiplier( bed.GetBedLevel() );

			// The call to super.OnEffectAdded (below) applies the effect once. Here we re-apply the effect 
			// a few more times so that the vitality given is multiplied depending on bed level.
			// Duration calculation is done in CalculateDuration (below).
			if ( multiplier > 1 ) // Avoid applying for 1 because the call to the super function already applies the effect once.
			{
				for ( i = 1; i < multiplier; i += 1 )
				{
					target.AddAbility( abilityName, true );
				}
			}
		}
		else
		{
			LogEffects("Tavern bed not found while trying to grant tavern rested effect.");
		}

		theGame.GetGuiManager().ShowNotification( GetLocStringByKeyExt( "tavern_message_rested_buff_applied" ),, true );

		// super.OnEffectAdded applies the effect once.
		super.OnEffectAdded( customParams );	
	}	

	event OnEffectRemoved()
	{
		target.RemoveAbilityAll( abilityName );
		
		super.OnEffectRemoved();
	}
	
	protected function CalculateDuration(optional setInitialDuration : bool)
	{
		var bed: W3TavernBed;
		var min, max: SAbilityAttributeValue;

		if( isOnPlayer )
		{
			bed = FindActiveTavernBed();
			theGame.GetDefinitionsManager().GetAbilityAttributeValue( abilityName, 'duration', min, max );
			duration = min.valueAdditive;

			if( bed )
			{
				duration *= GetTavernRestDurationMultiplier( bed.GetBedLevel() );
			}
			else
			{
				LogEffects("Tavern bed not found while trying to grant tavern rested effect.");
			}
		}
		
		super.CalculateDuration( true );
	}
}
