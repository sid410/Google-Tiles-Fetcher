from pathlib import Path
import sys
import os
import platform

# import subprocess

# Ensure the script directory is in sys.path
script_dir = Path(__file__).resolve().parent
scripts_dir = script_dir / "scripts"
if str(script_dir) not in sys.path:
    sys.path.append(str(script_dir))

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


def open_output_folder(output_dir):
    """
    Currently we only open the folder for Windows.
    """
    try:
        system_name = platform.system()
        if system_name == "Windows":
            os.startfile(output_dir)
        # elif system_name == "Darwin":  # macOS
        #     subprocess.run(["open", output_dir], check=True)
        # else:  # Linux and other Unix-like systems
        #     subprocess.run(["xdg-open", output_dir], check=True)
        else:
            print(f"Not on Windows so skipping auto open folder.")
    except Exception as e:
        print(f"Failed to open folder {output_dir}: {e}")


def process_args(arguments, config_path):
    config = update_config(load_config(config_path), arguments, config_path)
    validate_config(config)

    if install_and_enable_blosm(config):
        set_blosm_preferences(config)
        import_google_3d_tiles(config)
        output_dir, filename = save_blender_file(config)
        export_gltf(output_dir, filename)
        print(f"\nProcessing for {config['blosm']['lod']} completed successfully.")
        return output_dir, filename
    else:
        print(f"\nBlosm addon installation failed for {config['blosm']['lod']}.")
        return None, None


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
                "scale_factor": map_selection["scale_factor"],
                "min_lat": map_selection["min_lat"],
                "min_lon": map_selection["min_lon"],
                "max_lat": map_selection["max_lat"],
                "max_lon": map_selection["max_lon"],
            }
        )

        output_dir = None

        for lod in map_selection["lods"]:
            print(f"\nProcessing: {lod}")
            arguments["lod"] = lod
            output_dir, _ = process_args(arguments, config_path)

        if output_dir:
            open_output_folder(output_dir)

    else:
        output_dir, _ = process_args(arguments, config_path)

        if output_dir:
            open_output_folder(output_dir)
