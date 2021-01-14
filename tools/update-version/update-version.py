#!/usr/bin/python3
# This script will to help to manage rhdm components modules version, it will update all needed files
# Example of usage:
#   # move the current version to the next one or rcX
#   python3 scripts/update-version.py -v 7.15.1 --confirm
#
#   # to only see the proposed changes (dry run):
#   python3 scripts/update-version.py -v 7.15.1
#
# Version pattern is: X.YY.Z
# Dependencies:
#  ruamel.yaml

import argparse
import glob
import re
import sys

# All rhdm modules that will be updated.
TESTS_DIR = {"", ""}

# e.g. 7.16.0
VERSION_REGEX = re.compile(r'\b7[.]\d{2}[.]\d\b')
# e.g. 7.16
SHORTENED_VERSION_REGEX = re.compile(r'\b7[.]\d{2}\b|7[.]\d{2}')


def get_shortened_version(version):
    return '.'.join([str(elem) for elem in str(version).split(".")[0:2]])


def get_rhdm_behave_tests_files():
    files = []
    for file in glob.glob("tests/features/rhdm/*.feature"):
        files.append(file)
    return files


def get_rhpam_behave_tests_files():
    files = []
    for file in glob.glob("tests/features/rhpam/*.feature"):
        files.append(file)
    return files


def get_updated_rhdm_prefix(version):
    return "rhdm{0}".format(get_shortened_version(version).replace(".", ""))


def update_rhdm_behave_tests(version, confirm):
    """
    Update the rhdm behave tests to the given version.
    :param version: version to set into the module
    :param confirm: if true will save the changes otherwise will print the proposed changes
    """

    tests_to_update = get_rhdm_behave_tests_files()
    print("Updating rhdm behave test files {0}".format(tests_to_update))

    try:
        for test_to_update in tests_to_update:
            with open(test_to_update) as bh:
                # replace all occurrences of shortened version first
                plain = SHORTENED_VERSION_REGEX.sub(get_shortened_version(version), bh.read())

                if not confirm:
                    print("Applied changes are [{0}]: \n".format(test_to_update))
                    print(plain)
                    print("\n----------------------------------\n")

            if confirm:
                with open(test_to_update, 'w') as bh:
                    bh.write(plain)

    except TypeError:
        raise


def update_rhpam_behave_tests(version, confirm):
    """
    Update the rhpam behave tests to the given version.
    :param version: version to set into the module
    :param confirm: if true will save the changes otherwise will print the proposed changes
    """

    tests_to_update = get_rhpam_behave_tests_files()
    print("Updating rhpam behave test files {0}".format(tests_to_update))

    try:
        for test_to_update in tests_to_update:
            with open(test_to_update) as bh:
                # replace all occurrences of shortened version first
                plain = SHORTENED_VERSION_REGEX.sub(get_shortened_version(version), bh.read())

                if not confirm:
                    print("Applied changes are [{0}]: \n".format(test_to_update))
                    print(plain)
                    print("\n----------------------------------\n")

            if confirm:
                with open(test_to_update, 'w') as bh:
                    bh.write(plain)

    except TypeError:
        raise


def update_adocs_readme(version, confirm):
    """
    Update the adoc README files occurrences of the given version.
    :param version: version to set updated
    :param confirm: if true will save the changes otherwise will print the proposed changes
    """

    readmes = ['tools/gen-template-doc/README_RHDM.adoc.in', 'tools/gen-template-doc/README_RHPAM.adoc.in']

    if confirm:
        for readme in readmes:
            print("Updating the {0} version occurrences to {1} using shortened version".format(readme, version))
            try:
                with open(readme) as ig:
                    # replace all occurrences of shortened version first
                    plain = SHORTENED_VERSION_REGEX.sub(get_shortened_version(version), ig.read())

                with open(readme, 'w') as ig:
                    ig.write(plain)

            except TypeError:
                raise

    else:
        print("Skipping adocs README {0}".format(readmes))


def update_build_overrides_script(version, confirm):
    """
    Update the build-overrides.sh script occurrences of the given version.
    :param version: version to set updated
    :param confirm: if true will save the changes otherwise will print the proposed changes
    """

    build_overrides_file = 'tools/build-overrides/build-overrides.sh'

    if confirm:
        try:
            with open(build_overrides_file) as ig:
                # replace all occurrences of shortened version first
                plain = VERSION_REGEX.sub(version, ig.read())

            with open(build_overrides_file, 'w') as ig:
                print("Updating the {0} version occurrences to {1} using version".format(build_overrides_file, version))
                ig.write(plain)

        except TypeError:
            raise

    else:
        print("Skipping build-overrides {0} file".format(build_overrides_file))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='RHDM Version Manager')
    parser.add_argument('-v', dest='t_version', help='update everything to the next version')
    parser.add_argument('--confirm', default=False, action='store_true', help='if not set, script will not update the '
                                                                              'rhdm modules. (Dry run)')
    args = parser.parse_args()

    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        sys.exit(1)

    else:
        # validate if the provided version is valid.
        # e.g. 7.15.0
        pattern = "d.d{2}.d"

        if VERSION_REGEX.match(args.t_version):
            print("Version will be updated to {0}".format(args.t_version))
            update_rhdm_behave_tests(args.t_version, args.confirm)
            update_rhpam_behave_tests(args.t_version, args.confirm)
            update_adocs_readme(args.t_version, args.confirm)
            update_build_overrides_script(args.t_version, args.confirm)

        else:
            print("Provided version {0} does not match the expected regex - {1}".format(args.t_version, pattern))
