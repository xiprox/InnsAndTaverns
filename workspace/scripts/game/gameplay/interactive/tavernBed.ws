/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/


// - Incredibly poor, could be a straw mattress, minimal padding, etc. No bonuses.
// - Basic poor bed. No bonuses.
// - Decent bed. Average bonuses.
// - Luxurious, rich bed. Good bonuses.
// Note: rest bonuses have not been implemented yet.
enum ETavernBedLevel 
{
	TBL_IncrediblyPoor,
	TBL_Poor,
	TBL_Decent,
	TBL_Rich
}

statemachine class W3TavernBed extends W3AnimationInteractionEntity
{
	private var m_InUse: bool;
	public var m_bedSaveLock: int;
	
	editable var m_bedLevel: ETavernBedLevel; 			
		hint m_bedLevel = "Represent level of bed";

	editable var m_hasStables: bool;
		hint m_hasStables = "Whether the tavern has stables or not";

	editable var m_handsIkActive: bool;	
		hint m_handsIkActive = "Enables IK for hands";

	default	interactionAnim = PEA_GoToSleep;
	default focusModeVisibility = FMV_Interactive;

	event OnAreaEnter( area: CTriggerAreaComponent, activator: CComponent )
	{
		var mapManager : CCommonMapManager = theGame.GetCommonMapManager();

		if( activator.GetEntity() == GetWitcherPlayer() )
		{
			mapManager.SetEntityMapPinDiscoveredScript( false, entityName, true );
		}
	}
	
	event OnInteraction( actionName: string, activator: CEntity )
	{
		var l_movingAgentComponent: CMovingPhysicalAgentComponent;
		
		l_movingAgentComponent = (CMovingPhysicalAgentComponent)((CActor)activator).GetMovingAgentComponent();
		
		if( l_movingAgentComponent.IsOnGround() )
		{
			m_InUse = true;
			GotoState( 'Sleep' );
		}
	}
	
	public function GetInUse() : bool
	{
		return m_InUse;
	}
	
	public function SetInUse( b: bool )
	{
		m_InUse = b;
	}
	
	public function GetBedLevel() : int
	{
		return m_bedLevel;
	}

	public function GetHasStables(): bool {
		return m_hasStables;
	}
	
	public function IsHandsIkActive() : bool
	{
		return m_handsIkActive;
	}
	
	public function EnableHandsIk()
	{
		var l_leftHandSlotValid: bool;
		var l_leftHandSlotMatrix: Matrix;
		var l_rightHandSlotValid: bool;
		var l_rightHandSlotMatrix: Matrix; 
	
		if ( IsHandsIkActive() )
		{
			l_leftHandSlotValid = CalcEntitySlotMatrix( 'bedLeftHandLocation', l_leftHandSlotMatrix );
			if ( l_leftHandSlotValid )
			{
				thePlayer.SetBehaviorVectorVariable( 'bedLeftHandLocation', MatrixGetTranslation( l_leftHandSlotMatrix ) );
			}
			
			l_rightHandSlotValid = CalcEntitySlotMatrix( 'bedRightHandLocation', l_rightHandSlotMatrix );
			if ( l_rightHandSlotValid )
			{
				thePlayer.SetBehaviorVectorVariable( 'bedRightHandLocation', MatrixGetTranslation( l_rightHandSlotMatrix ) );
			}
			
			thePlayer.SetBehaviorVariable( 'bedIkActive', 1.f );
		}
	}
	
	public function DisableHandsIk()
	{
		if ( IsHandsIkActive() )
		{
			thePlayer.SetBehaviorVariable( 'bedIkActive', 0.f );
		}
	}
}

state Sleep in W3TavernBed
{
	event OnEnterState( prevStateName: name )
	{		
		theGame.CreateNoSaveLock( "Approaching Bed", parent.m_bedSaveLock, true );
		MovePlayerToBed();

		parent.EnableHandsIk();
	}
	
	event OnLeaveState( nextStateName: name )
	{
		parent.DisableHandsIk();
	}
	
	entry function MovePlayerToBed()
	{
		var l_movAdj: CMovementAdjustor; 
		var l_ticket: SMovementAdjustmentRequestTicket;
		var l_node: CNode;
		var l_component: CComponent;
		var l_HACKmovementCorrector: CExplorationMovementCorrector;
		var l_buffsHud: CR4HudModuleBuffs;
		

		l_HACKmovementCorrector = thePlayer.substateManager.m_MovementCorrectorO;
		l_HACKmovementCorrector.disallowRotWhenGoingToSleep = true;		
		
		l_buffsHud = (CR4HudModuleBuffs)theGame.GetHud().GetHudModule( 'BuffsModule' );
		l_buffsHud.SetDisplayBuffs( false );
		
		l_node = parent.GetComponent( "tavernBed_WP_1" );
		
		
		l_component = parent.GetComponentByClassName( 'CInteractionComponent' );
		l_component.SetEnabled( false );
		
		thePlayer.OnMeleeForceHolster( false );
		
		if( thePlayer.IsCurrentlyUsingItemL() )
		{
			thePlayer.OnUseSelectedItem();
		}
		
		thePlayer.AddBuffImmunity_AllCritical( 'Bed', true );
		thePlayer.AddBuffImmunity_AllNegative( 'Bed', true );
		
		
		thePlayer.BlockAllActions( 'TavernBed', true,,,,,false );
		thePlayer.ActionMoveToNodeWithHeading( l_node, MT_Walk, 1.f, 0.4f );
		
		
		parent.ApplyAppearance( "no_collision" );
		
		thePlayer.RaiseEvent( 'ForceIdle' );
		
		
		l_movAdj = thePlayer.GetMovingAgentComponent().GetMovementAdjustor();
		l_ticket = l_movAdj.CreateNewRequest( 'InteractionEntity' );
	
		l_movAdj.AdjustmentDuration( l_ticket, 0.75f );
		l_movAdj.SlideTowards( l_ticket, l_node );	
		l_movAdj.RotateTowards( l_ticket, parent, 40 );

		
		thePlayer.PlayerStartAction( PEA_GoToSleep );
	}
}

state WakeUp in W3TavernBed
{	
	event OnEnterState( prevStateName: name )
	{
		var l_component: CComponent;
		var l_buffsHud: CR4HudModuleBuffs;
		
		l_buffsHud = (CR4HudModuleBuffs)theGame.GetHud().GetHudModule( 'BuffsModule' );
		l_component = parent.GetComponentByClassName( 'CInteractionComponent' );

		parent.ApplyAppearance( "collision" );
		
		l_buffsHud.SetDisplayBuffs( true );
		
		l_component.SetEnabled( true );		
	}
}