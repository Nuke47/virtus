local Category = "Vehicle Utilities"

local function StandAnimation( vehicle, player )
	return player:SelectWeightedSequence( ACT_HL2MP_IDLE_PASSIVE )
end

local V = {
	Name = "Patrol Transport Passenger Seat",
	Model = "models/nova/airboat_seat.mdl",
	Class = "prop_vehicle_prisoner_pod",
	Category = Category,

	Author = "Syphadias, Oninoni, KingPommes",
	Information = "Seat with custom animation",
	Offset = 0,

	KeyValues = {
		vehiclescript = "scripts/vehicles/prisoner_pod.txt",
		limitview = "0"
	},
	Members = {
		HandleAnimation = StandAnimation
	}
}
list.Set( "Vehicles", "pommes_patrol_seat", V )