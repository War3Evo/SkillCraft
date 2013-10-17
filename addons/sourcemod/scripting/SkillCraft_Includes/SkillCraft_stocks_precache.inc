

// default beamsprite which is often used (moved here to keep compatibilty across diff. games)
stock SC_PrecacheBeamSprite() {
	new w3_spriteindex = PrecacheModel("materials/sprites/lgtning.vmt");
	if(w3_spriteindex == -1) {
		LogError("Failed to precache BeamSprite material!");
	}
	return w3_spriteindex;
}
// same goes for halosprite
stock SC_PrecacheHaloSprite() {
	new w3_spriteindex = PrecacheModel("materials/sprites/halo01.vmt");
	if(w3_spriteindex == -1) {
		LogError("Failed to precache HaloSprite material!");
	}
	return w3_spriteindex;
}