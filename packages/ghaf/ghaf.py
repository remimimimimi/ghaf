#! @python3@/bin/python3
import os
import argparse
import subprocess
import shutil
import json
from pathlib import Path

TARGET = "@targetName@"
GHAF_SOURCE = "@ghafSource@"
CONFIG_PATH = "@configPath@"


def replace_in_file(file, old, new):
    file = Path(file)
    file.write_text(file.read_text().replace(old, new))


# Useful to ensure that directory and all required files exist
def proxy_flake_path():
    if not os.path.exists(CONFIG_PATH):
        os.makedirs(CONFIG_PATH)
    if not os.path.exists(CONFIG_PATH + "/flake.nix"):
        with open(
            GHAF_SOURCE + "/templates/targets/x86_64/proxy_flake/flake.nix", "r"
        ) as f:
            flake = f.read()

        with open(CONFIG_PATH + "/flake.nix", "w") as f:
            f.write(
                flake.replace(
                    "path:/nix/store/...-source", f"path:{GHAF_SOURCE}"
                ).replace("generic-x86_64-debug", TARGET)
            )

    if not os.path.exists(CONFIG_PATH + "/flake.lock"):
        shutil.copy(GHAF_SOURCE + "/flake.lock", CONFIG_PATH)
    if not os.path.exists(CONFIG_PATH + "/auto-appvms.json"):
        shutil.copy(
            GHAF_SOURCE + "/templates/targets/x86_64/proxy_flake/auto-appvms.json",
            CONFIG_PATH,
        )

        # with open(CONFIG_PATH + "auto-appvms.json", "w") as f:
        #     json.dump([], f, indent=4)

    return CONFIG_PATH


def appvms_config():
    return proxy_flake_path() + "/auto-appvms.json"


def appvms():
    with open(appvms_config(), "r") as f:
        return json.load(f)


def parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="ghaf",
        description="Application that helps you managing Ghaf.\nCurrently only helps install applications.",
        add_help=True,
    )

    # TODO: Add checks
    parser.add_argument("-p", "--package", action="store", required=True)
    parser.add_argument(
        "-m",
        "--memory",
        action="store",
        type=int,
        help="Specify memory allocated for application virtual machine in MB",
        default=1024,
    )
    parser.add_argument(
        "-c",
        "--cores",
        action="store",
        type=int,
        help="Specify CPU cores allocated for appvm",
        default=2,
    )

    return parser


def main():
    args = parser().parse_args()

    if os.geteuid() != 0:
        exit(
            "You need to have root privileges to run this script.\n"
            + "Please try again, this time using 'sudo'."
        )

    vms = appvms()
    vms.append({"package": args.package, "memory": args.memory, "cores": args.cores})
    with open(appvms_config(), "w") as f:
        json.dump(vms, f, indent=4)

    # Run only nixos-rebuild with sudo
    subprocess.run(
        [
            "nixos-rebuild",
            "switch",
            "--flake",
            CONFIG_PATH + "#PROJ_NAME-ghaf-debug",
        ]
    )


if __name__ == "__main__":
    main()
