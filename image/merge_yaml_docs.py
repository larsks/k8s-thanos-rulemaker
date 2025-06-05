#!/usr/bin/python3
# pyright: reportUnusedCallResult=false,reportUnknownParameterType=false,reportMissingParameterType=false,reportAny=false,reportUnknownArgumentType=false,reportUnknownVariableType=false

import sys
import argparse
import yaml


def parse_args():
    p = argparse.ArgumentParser()

    p.add_argument("--output", "-o")
    p.add_argument("yamldocs", nargs="+")

    return p.parse_args()


def recursive_merge(dict1, dict2):
    for key in dict2:
        if key in dict1:
            if isinstance(dict1[key], dict) and isinstance(dict2[key], dict):
                recursive_merge(dict1[key], dict2[key])
            elif isinstance(dict1[key], list) and isinstance(dict2[key], list):
                dict1[key].extend(dict2[key])
            else:
                dict1[key] = dict2[key]
        else:
            dict1[key] = dict2[key]
    return dict1


def main():
    args = parse_args()

    merged = {}
    for path in args.yamldocs:
        with open(path) as fd:
            doc = yaml.safe_load(fd)
        merged = recursive_merge(merged, doc)

    with sys.stdout if args.output is None else open(args.output, "w") as fd:
        yaml.dump(merged, fd)


if __name__ == "__main__":
    main()
