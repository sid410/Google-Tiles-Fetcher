from pathlib import Path
import shutil
import yaml
import sys


def ensure_config_exists():
    script_dir = Path(__file__).resolve().parent
    config_dir = script_dir.parent / "config"
    template_path = config_dir / "config_template.yaml"
    config_path = config_dir / "config.yaml"

    if not config_path.exists():
        print("\n`config.yaml` not found. Generating it from `config_template.yaml`...")
        if template_path.exists():
            shutil.copy(template_path, config_path)
            print(f"`config.yaml` has been created.")
        else:
            raise FileNotFoundError(
                f"`config_template.yaml` is missing in the `config` folder! Please add it to: {config_dir}"
            )
    else:
        print("\n`config.yaml` already exists. Proceeding...")
    return config_path


def validate_config(config):
    required_fields = {
        "secret": ["google_api_key"],
        "input": ["min_lat", "min_lon", "max_lat", "max_lon"],
        "output": ["base_name"],
    }

    missing_fields = []

    for section, fields in required_fields.items():
        if section not in config:
            missing_fields.append(f"Missing section: {section}")
            continue

        for field in fields:
            if (
                field not in config[section]
                or config[section][field] is None
                or str(config[section][field]).strip() == ""
            ):
                missing_fields.append(f"{section}.{field}")

    if missing_fields:
        error_message = (
            "\nConfiguration Error: The following required fields are missing or empty:"
        )
        for field in missing_fields:
            error_message += f"\n  - {field}"
        error_message += "\n\nPlease update `config.yaml` and try again."
        raise ValueError(error_message)


def load_config(config_path):
    with config_path.open("r", encoding="utf-8") as file:
        config = yaml.safe_load(file)
    return config


def update_config(config, arguments, config_path):
    if "google_api_key" in arguments:
        config.setdefault("secret", {})["google_api_key"] = arguments["google_api_key"]

    if "min_lat" in arguments:
        config.setdefault("input", {})["min_lat"] = float(arguments["min_lat"])
    if "min_lon" in arguments:
        config.setdefault("input", {})["min_lon"] = float(arguments["min_lon"])
    if "max_lat" in arguments:
        config.setdefault("input", {})["max_lat"] = float(arguments["max_lat"])
    if "max_lon" in arguments:
        config.setdefault("input", {})["max_lon"] = float(arguments["max_lon"])

    if "base_name" in arguments:
        config.setdefault("output", {})["base_name"] = arguments["base_name"]

    if "lod" in arguments:
        config.setdefault("blosm", {})["lod"] = arguments["lod"]

    if "scale_factor" in arguments:
        scale_factor = float(arguments["scale_factor"])
        if scale_factor <= 0:
            raise ValueError("Scale factor must be a positive value greater than 0.")
        config.setdefault("blosm", {})["scale_factor"] = scale_factor

    with config_path.open("w", encoding="utf-8") as file:
        yaml.safe_dump(config, file, default_flow_style=False)

    print(f"\nConfiguration updated and saved to {config_path}")
    return config
