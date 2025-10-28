from typing import List, Annotated
from fastapi import FastAPI, Path, Query
from pydantic import BaseModel, Field

TheSquadFFB = FastAPI(title="fastapi_test")

### Request model (incoming payload) ###
class UserRequest(BaseModel):
    # e.g., "Justin Jefferson"
    # TODO: Need to remove whitespace somehow
    name: str = Field(min_length=1)    
    # e.g., "MN, NYG, etc"
    # Constaints: All A-Z chars, 2-3 chars     
    team_abbr: str = Field(pattern=r"^[A-Z]{2,3}$")

### Response model (outgoing payload) ###
class TeamOffSumm(BaseModel):
    team_abbr: str
    # ge: ≥ (greater than/equal - inclusive min)
    # gt: > (greater than - exclusive min)
    # le: ≤ (less than/equal - inclusive max)
    # lt: < (less than - exclusive max)
    # e.g. -> week: int = Field(ge=1, le=18)
    attempted_p: int = Field(ge=0)
    completed_p: int = Field(ge=0)
    incomplete_p: int = Field(ge=0)
    fav_target: str

class PlayerSumm(BaseModel):
    # player_id: str
    name: str
    team_abbr: str
    season: int
    targets: int = Field(ge=0)
    receptions: int = Field(ge=0)
    # List of nested models example
    # game_log: List[Matchups] = []

### ROUTES ###

### POST
##  - Accepts a JSON body shaped like the expected "UserRequest"
##  - Returns JSON shaped like PlayerSumm

# EXAMPLE Terminal (visual) Test:
# curl -X POST http://127.0.0.1:8000/players/summary \
#   -H "Content-Type: application/json" \
#   -d '{"name":"Justin Jefferson","team":"MIN"}'

@TheSquadFFB.post("/players/summary", response_model=PlayerSumm)
async def get_player_summary(req: UserRequest) -> PlayerSumm:

    # Example Demo payload being returned
    return PlayerSumm(
        # Strip whitespace
        name=req.name.strip(),      # Reference model name
        team_abbr=req.team_abbr,    # Reference model team_abbr
        season=2024,
        targets=20,
        receptions=14,

    )

# GET /players/MIN/Justin%20Jefferson
# Traditional GET request where the user explicitly uses predetermined 
#   URL path information/strings to indicate what's being requested
@TheSquadFFB.get("/players/{team_abbr}/{name}", response_model=PlayerSumm)
async def get_player_summary_by_path(
    team_abbr: Annotated[str, Path(pattern=r"^[A-Z]{2,3}$")],
    name: Annotated[str, Path(min_length=1)]
) -> PlayerSumm:
    return PlayerSumm(
        name=name.strip(),
        team_abbr=team_abbr,
        season=2024,
        targets=20,
        receptions=14,
    )

# GET 
# Traditional GET request where the user provides parameters in the URL
# e.g. ...../players?team=MIN&name=Justin%20Jefferson
@TheSquadFFB.get("/players", response_model=PlayerSumm)
async def get_player_summary_by_query(
    team_abbr: Annotated[str, Query(pattern=r"^[A-Z]{2,3}$")],
    name: Annotated[str, Query(min_length=1)]
) -> PlayerSumm:
    return PlayerSumm(
        name=name.strip(),
        team_abbr=team_abbr,
        season=2024,
        targets=20,
        receptions=14,
    )

# Connection checker to make sure the API is functioning correctly
@TheSquadFFB.get("/health")
def health():
    return {"ok": True}