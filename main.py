import os
import sys

# Since Blender uses its own Python interpreter,
# ensure the script directory is in sys.path
script_dir = os.path.dirname(os.path.realpath(__file__))
scripts_dir = os.path.join(script_dir, "scripts")
if script_dir not in sys.path:
    sys.path.append(script_dir)

from scripts.config_utils import (
    ensure_config_exists,
    validate_config,
    load_config,
    update_config,
)
from scripts.blender_utils import (
    parse_blender_args,
    install_and_enable_blosm,
    set_blosm_preferences,
    import_google_3d_tiles,
    save_blender_file,
    export_gltf,
)
from scripts.flask_utils import run_map_selection_ui


def process_args(arguments, config_path):
    config = update_config(load_config(config_path), arguments, config_path)
    validate_config(config)

    if install_and_enable_blosm(config):
        set_blosm_preferences(config)
        import_google_3d_tiles(config)
        output_dir, filename = save_blender_file(config)
        export_gltf(output_dir, filename)
        print(f"\nProcessing for {config['blosm']['lod']} completed successfully.")
    else:
        print(f"\nBlosm addon installation failed for {config['blosm']['lod']}.")


if __name__ == "__main__":
    arguments = parse_blender_args()
    config_path = ensure_config_exists()

    if "map_select_ui" in arguments:
        print("Launching Map Selection UI...")
        map_selection = run_map_selection_ui()

        arguments.update(
            {
                "google_api_key": map_selection["google_api_key"],
                "base_name": map_selection["base_name"],
                "min_lat": map_selection["min_lat"],
                "min_lon": map_selection["min_lon"],
                "max_lat": map_selection["max_lat"],
                "max_lon": map_selection["max_lon"],
            }
        )

        for lod in map_selection["lods"]:
            print(f"\nProcessing: {lod}")
            arguments["lod"] = lod
            process_args(arguments, config_path)

    # limit terminal command to accept only 1 LOD at a time
    else:
        process_args(arguments, config_path)
