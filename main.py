import os
import sys

# Since Blender uses it's own Python interpreter,
# ensure the script directory is in sys.path
script_dir = os.path.dirname(os.path.realpath(__file__))
if script_dir not in sys.path:
    sys.path.append(script_dir)

from config_utils import (
    ensure_config_exists,
    validate_config,
    load_config,
    update_config,
)
from blender_utils import (
    parse_blender_args,
    install_and_enable_blosm,
    set_blosm_preferences,
    import_google_3d_tiles,
    save_blender_file,
    export_gltf
)
from flask_utils import run_map_selection_ui


if __name__ == "__main__":
    arguments = parse_blender_args()

    config_path = ensure_config_exists()
    config = load_config(config_path)

    if "map_select_ui" in arguments:
        print("Launching Map Selection UI...")
        map_selection = run_map_selection_ui()

        arguments["min_lat"] = map_selection["min_lat"]
        arguments["min_lon"] = map_selection["min_lon"]
        arguments["max_lat"] = map_selection["max_lat"]
        arguments["max_lon"] = map_selection["max_lon"]

        # Use the first selected LOD. Change to loop later
        arguments["lod"] = map_selection["lods"][0]

    config = update_config(config, arguments, config_path)
    validate_config(config)

    if install_and_enable_blosm(config):
        set_blosm_preferences(config)
        import_google_3d_tiles(config)
        output_dir, filename = save_blender_file(config)
        export_gltf(output_dir, filename)
    else:
        print("\nBlosm addon installation failed. Exiting.")
