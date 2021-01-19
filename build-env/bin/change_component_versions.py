#!/usr/bin/env python3
import sys
import logging
import argparse
import re

import yaml

logger = logging.getLogger(__name__)
logger.setLevel(logging.WARN)

PATHS = {
    'maestro': {
        'files': [
            {
                'name': 'maestro/deb/build.sh',
                're': re.compile('(\["git@github.com:armPelionEdge/maestro.git"\]=")[^"]+(")'),
            },
        ]
    },
}

def main(argv=None):
    if argv is None:
        argv = sys.argv
    parser = argparse.ArgumentParser()
    parser.add_argument('versionmap', type=argparse.FileType('r'))
    parser.add_argument('-v', '--verbose', action='count', default=0)
    args = parser.parse_args(argv[1:])

    if args.verbose > 0:
        logging.basicConfig()
        if args.verbose == 1:
            logger.setLevel(logging.INFO)
        elif args.verbose > 1:
            logger.setLevel(logging.DEBUG)

    pe = yaml.load(args.versionmap)
    for name, info in pe['components'].items():
        logger.debug("changing component %s version to %s", name, info['version'])
        try:
            paths = PATHS[name]['files']
        except:
            logger.warning("Don't have path to change version for %s", name)
            continue
        for path in paths:
            code = open(path['name'], 'r').read()
            code = path['re'].sub(r"\g<1>" + info['version'] + r"\g<2>", code)
            open(path['name'], 'w').write(code)


if __name__ == '__main__':
    sys.exit(main())
