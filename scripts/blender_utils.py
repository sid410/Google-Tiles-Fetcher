import csv
from pathlib import Path
import sys
import bpy
from scripts.projection_utils import TransverseMercator, calculate_real_bounds


def parse_blender_args():
    argv = sys.argv
    if "--" in argv:
        args = argv[argv.index("--") + 1 :]
    else:
        args = []

    arguments = {}
    for arg in args:
        if "=" in arg:
            key, value = arg.split("=", 1)
            arguments[key] = value
        else:
            arguments[arg] = True

    return arguments


def ensure_output_directory(output_dir):
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    print(f"\nOutput directory ensured: {output_dir}")


def install_and_enable_blosm(config):
    addon_name = "blosm"
    addon_zip_path = Path(config["blosm"]["addon_zip_path"])

    if addon_name in bpy.context.preferences.addons:
        print(f"\n{addon_name} is already installed and enabled.")
        return True

    if not addon_zip_path.exists():
        print(f"\nError: Addon zip file not found at {addon_zip_path}")
        return False

    print(f"\nInstalling addon from {addon_zip_path}...")
    result = bpy.ops.preferences.addon_install(filepath=str(addon_zip_path))

    if "FINISHED" in result:
        print(f"Enabling addon {addon_name}...")
        bpy.ops.preferences.addon_enable(module=addon_name)
        bpy.ops.wm.save_userpref()

        if addon_name in bpy.context.preferences.addons:
            print(f"Addon {addon_name} installed and enabled successfully.")
            return True
    print(f"Failed to enable addon {addon_name}.")
    return False


def set_blosm_preferences(config):
    addon_name = "blosm"
    blosm_prefs = bpy.context.preferences.addons[addon_name].preferences

    data_dir = Path(config["blosm"]["data_dir"])
    data_dir.mkdir(parents=True, exist_ok=True)
    blosm_prefs.dataDir = str(data_dir)

    blosm_prefs.googleMapsApiKey = config["secret"]["google_api_key"]

    bpy.ops.wm.save_userpref()
    print(f"\nPreferences updated: dataDir={data_dir}, Google API key set.")


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    print("\nScene cleared: All objects removed.")

    default_collection = bpy.data.collections.get("Collection")
    if default_collection:
        bpy.data.collections.remove(default_collection)
        print("Default Collection removed.\n")

    prev_tile_collection = bpy.data.collections.get("Google 3D Tiles")
    if prev_tile_collection:
        bpy.data.collections.remove(prev_tile_collection)
        print("Previous Google 3D Tiles Collection removed.\n")


def rescale_scene(scale_factor):
    for obj in bpy.context.scene.objects:
        if obj.type == "MESH":
            obj.scale *= scale_factor
            obj.location *= scale_factor  # also adjust location to match scale
    print(f"Scene rescaled by a factor of {scale_factor}.")


def import_google_3d_tiles(config):
    clear_scene()

    addon_name = "blosm"
    if addon_name not in bpy.context.preferences.addons:
        print(
            f"\n{addon_name} addon is not enabled. Please install and enable it first."
        )
        return

    scene = bpy.context.scene
    blosm_props = scene.blosm
    blosm_props.dataType = "3d-tiles"
    blosm_props.minLon = config["input"]["min_lon"]
    blosm_props.minLat = config["input"]["min_lat"]
    blosm_props.maxLon = config["input"]["max_lon"]
    blosm_props.maxLat = config["input"]["max_lat"]
    blosm_props.lodOf3dTiles = config["blosm"]["lod"]
    blosm_props.threedTilesSource = config["blosm"]["threed_tiles_source"]
    blosm_props.join3dTilesObjects = config["blosm"]["join_tiles_objects"]
    blosm_props.relativeToInitialImport = config["blosm"]["relative_to_initial_import"]

    if bpy.ops.blosm.import_data() == {"FINISHED"}:
        print("\n3D Tiles successfully imported!\n")
        rescale_scene(config["blosm"]["scale_factor"])
    else:
        print("\nFailed to import 3D Tiles.")


def validate_collection_and_save_metadata(
    output_dir, base_name, lod, projection, scale_factor
):
    tiles_collection = bpy.data.collections.get("Google 3D Tiles")

    global_min_lat, global_min_lon = float("inf"), float("inf")
    global_max_lat, global_max_lon = float("-inf"), float("-inf")

    metadata = []

    origin_lat, origin_lon = projection.toGeographic(0, 0)
    metadata.append(
        {
            "mesh_ID": "origin:",
            "max_lat": origin_lat,
            "max_lon": origin_lon,
            "min_lat": "scale_factor:",
            "min_lon": scale_factor,
        }
    )

    # Calculate combined bounds for all objects in the collection
    for obj in tiles_collection.objects:
        if obj.type == "MESH":
            real_min_lat, real_min_lon, real_max_lat, real_max_lon = (
                calculate_real_bounds(obj, projection)
            )

            global_min_lat = min(global_min_lat, real_min_lat)
            global_min_lon = min(global_min_lon, real_min_lon)
            global_max_lat = max(global_max_lat, real_max_lat)
            global_max_lon = max(global_max_lon, real_max_lon)

            metadata.append(
                {
                    "mesh_ID": obj.name,
                    "max_lat": real_max_lat,
                    "max_lon": real_max_lon,
                    "min_lat": real_min_lat,
                    "min_lon": real_min_lon,
                }
            )

    custom_name = f"{base_name}_{lod}_{global_min_lat}_{global_min_lon}_{global_max_lat}_{global_max_lon}"
    csv_path = Path(output_dir) / f"{custom_name}_metadata.csv"

    with csv_path.open(mode="w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(
            file, fieldnames=["mesh_ID", "max_lat", "max_lon", "min_lat", "min_lon"]
        )
        writer.writeheader()
        writer.writerows(metadata)

    print(f"Metadata saved to {csv_path}\n")

    return custom_name


def save_blender_file(config):
    scene = bpy.context.scene
    projection = TransverseMercator(
        lat=scene.get("lat", 0.0), lon=scene.get("lon", 0.0)
    )

    base_name = config["output"]["base_name"]
    lod = config["blosm"]["lod"]
    scale_factor = config["blosm"]["scale_factor"]

    output_dir = Path(config["output"]["output_dir"])
    ensure_output_directory(output_dir)

    custom_name = validate_collection_and_save_metadata(
        output_dir, base_name, lod, projection, scale_factor
    )

    blender_file = output_dir / f"{custom_name}.blend"
    if blender_file.exists():
        print(f"File {blender_file} already exists and will be overwritten.\n")

    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(blender_file))
    print(f"\nScene saved to {blender_file}")

    return output_dir, custom_name


def unpack_textures():
    print("\nUnpacking textures...")

    unpack_dir = Path(bpy.data.filepath).parent / "textures"
    bpy.ops.file.unpack_all(method="USE_LOCAL")
    bpy.ops.file.make_paths_absolute()

    return unpack_dir


# Is this step really needed??
def ensure_texture_links(texture_dir):
    print("\nEnsuring textures are correctly linked to materials...")
    for mat in bpy.data.materials:
        if mat.use_nodes:
            for node in mat.node_tree.nodes:
                if node.type == "TEX_IMAGE" and node.image:
                    texture_path = texture_dir / Path(node.image.filepath).name
                    if texture_path.exists():
                        print(f"Linking {node.image.name} to {texture_path}")
                        node.image.filepath = str(texture_path)
                    else:
                        print(f"Missing texture: {texture_path}")


def setup_fbx_export_settings():
    bpy.context.scene.render.engine = "CYCLES"
    bpy.context.scene.use_nodes = False
    bpy.context.scene.render.use_simplify = True
    bpy.context.scene.render.simplify_subdivision = 0
    print("\nFBX export settings prepared.")


def export_fbx(output_dir, custom_name):
    blender_file = Path(output_dir) / f"{custom_name}.blend"
    if not blender_file.exists():
        print(f"Error: Input file {blender_file} does not exist.")
        return

    print(f"\nLoading Blender file: {blender_file}")
    bpy.ops.wm.open_mainfile(filepath=str(blender_file))

    texture_dir = unpack_textures()
    ensure_texture_links(texture_dir)
    setup_fbx_export_settings()

    fbx_filepath = Path(output_dir) / f"{custom_name}.fbx"
    bpy.ops.export_scene.fbx(
        filepath=str(fbx_filepath),
        embed_textures=True,
        path_mode="COPY",
        apply_scale_options="FBX_SCALE_NONE",
        bake_space_transform=False,
        bake_anim=False,  # NEED TO BE FALSE OTHERWISE EXPORT WILL HANG
    )

    print(f"FBX export completed: {fbx_filepath}")


def export_gltf(output_dir, custom_name):
    blender_file = Path(output_dir) / f"{custom_name}.blend"
    if not blender_file.exists():
        print(f"Error: Input file {blender_file} does not exist.")
        return

    print(f"\nLoading Blender file: {blender_file}")
    bpy.ops.wm.open_mainfile(filepath=str(blender_file))

    gltf_filepath = Path(output_dir) / f"{custom_name}.glb"
    bpy.ops.export_scene.gltf(filepath=str(gltf_filepath), export_format="GLB")
    print(f"GLTF export completed: {gltf_filepath}")
