import os
import shutil
import sys

import yaml


def ensure_config_exists():
    script_dir = os.path.dirname(os.path.realpath(__file__))
    template_path = os.path.join(script_dir, "config_template.yaml")
    config_path = os.path.join(script_dir, "config.yaml")

    if not os.path.exists(config_path):
        print("\n`config.yaml` not found. Generating it from `config_template.yaml`...")
        if os.path.exists(template_path):
            shutil.copy(template_path, config_path)
            print(f"`config.yaml` has been created.")
        else:
            raise FileNotFoundError("`config_template.yaml` is missing! Please add it to the project directory.")
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
            if field not in config[section] or config[section][field] is None or str(config[section][field]).strip() == "":
                missing_fields.append(f"{section}.{field}")

    if missing_fields:
        print("\nConfiguration Error: The following required fields are missing or empty:")
        for field in missing_fields:
            print(f"  - {field}")
        print("\nPlease update `config.yaml` and try again.")
        sys.exit(1)


def load_config(config_path):
    with open(config_path, 'r') as file:
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

    with open(config_path, "w") as file:
        yaml.safe_dump(config, file, default_flow_style=False)

    print(f"\nConfiguration updated and saved to {config_path}")
    return config
