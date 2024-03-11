#! /usr/bin/env python3
import os
import argparse


def parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="ghaf",
        description="Application that helps you managing Ghaf.",
        add_help=True,
    )

    # TODO: Add checks
    parser.add_argument("-p", "--package", action="store", required=True)
    parser.add_argument(
        "-m",
        "--memory",
        action="store",
        type=int,
        help="Specify memory allocated for application virtual machine",
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

    print(args)


if __name__ == "__main__":
    main()
