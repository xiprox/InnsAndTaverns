
/// Searches all tavern bed entities and returns the first (probably only) one that is in use.
function FindActiveTavernBed(): W3TavernBed {
    var allTavernBeds: array<CEntity>;
    var i: int;
    var cursor: W3TavernBed;

    theGame.GetEntitiesByTag('tavernBed', allTavernBeds);

    for (i = 0; i < allTavernBeds.Size(); i+=1) {
        cursor = (W3TavernBed) allTavernBeds[i];
        if (cursor.GetInUse()) {
            return cursor;
        }
    }

    return NULL;
}