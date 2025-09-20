# [Priest] Empower Champion
Small addon for maintaining Empower Champion on Proclaimed players.

[SuperWoW](https://github.com/balakethelock/SuperWoW) is requried.

## Usage
1. Cast **Proclaim Champion** on any player in the raid/party.
2. Cast **Empower Champion**/**Champion's Grace**/**Champion's Bond** on the **Proclaimed Champion**.
3. Put **/empower** in any healing/misc macro.
4. Then you use macro with **/empower** instruction it will check player for **2 conditionals** before updating **Empower Buff**:
	1) If **Proclaimed Champion** doesn't have** Empower Buff** then addon will try to update the buff.
	2) If **You** and **Proclaimed Champion** are **not in combat** and **current duration half expired** then addon will try to update the buff.
