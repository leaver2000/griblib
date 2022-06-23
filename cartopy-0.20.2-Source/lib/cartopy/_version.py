
import json
import sys
version="0.20.2"
version_json = '''
{
    "dirty": false,
    "error": null,
    "full-revisionid": "178a15e39d085758832d30aa9f77f34f708a7d1e",
    "version": "0.20.2"
}
    '''  # END VERSION_JSON


def get_versions():
    return json.loads(version_json)

