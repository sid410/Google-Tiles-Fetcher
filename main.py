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
    update_config_from_args,
)
from blender_utils import (
    parse_blender_args,
    install_and_enable_blosm,
    set_blosm_preferences,
    import_google_3d_tiles,
    save_blender_file,
)


if __name__ == "__main__":
    arguments = parse_blender_args()

    config_path = ensure_config_exists()
    config = load_config(config_path)
    config = update_config_from_args(config, arguments, config_path)

    validate_config(config)

    if install_and_enable_blosm(config):
        set_blosm_preferences(config)
        import_google_3d_tiles(config)
        save_blender_file(config)
    else:
        print("\nBlosm addon installation failed. Exiting.")
