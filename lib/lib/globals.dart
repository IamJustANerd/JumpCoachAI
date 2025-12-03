library my_globals;

double? calibration_value; // Base Altitude (Barometer)

// Elevation / Tilt
double? starting_elevation;
double jumping_elevation = 0.0;

// Jump Stats
double jump_duration = 0.0;
double? max_jump_height = 0.0; // <--- NEW: Tracks max altitude gain in meters
