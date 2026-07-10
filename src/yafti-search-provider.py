#!/usr/bin/env python3
import os
import yaml
import shutil
import subprocess
from gi.repository import GLib
from pydbus import SessionBus

class YaftiSearchProvider:
    """
    <node>
        <interface name="org.gnome.Shell.SearchProvider2">
            <method name="GetInitialResultSet">
                <arg type="as" name="terms" direction="in"/>
                <arg type="as" name="results" direction="out"/>
            </method>
            <method name="GetSubsearchResultSet">
                <arg type="as" name="previous_results" direction="in"/>
                <arg type="as" name="terms" direction="in"/>
                <arg type="as" name="results" direction="out"/>
            </method>
            <method name="GetResultMetas">
                <arg type="as" name="identifiers" direction="in"/>
                <arg type="aa{sv}" name="metas" direction="out"/>
            </method>
            <method name="ActivateResult">
                <arg type="s" name="identifier" direction="in"/>
                <arg type="as" name="terms" direction="in"/>
                <arg type="u" name="timestamp" direction="in"/>
            </method>
            <method name="LaunchSearch">
                <arg type="as" name="terms" direction="in"/>
                <arg type="u" name="timestamp" direction="in"/>
            </method>
        </interface>
    </node>
    """

    def __init__(self):
        self.actions = []
        self.load_actions()

    def load_actions(self):
        yaml_path = "/usr/share/yafti/yafti.yml" #
        try:
            with open(yaml_path, 'r') as f:
                config = yaml.safe_load(f)
        except Exception as e:
            print(f"Yafti config not found or invalid: {e}")
            return

        if 'screens' not in config: #
            return

        for screen in config['screens']:
            if screen.get('hidden', False): #
                continue

            if 'actions' not in screen: #
                continue

            for action in screen['actions']:
                if action.get('hidden', False): #
                    continue

                act_id = action.get('id', '') #
                if act_id:
                    self.actions.append({
                        'id': act_id,
                        'title': action.get('title', ''), #
                        'description': action.get('description', '') #
                    })

    def _search(self, terms):
        query = " ".join(terms).strip().lower() #
        if not query:
            return []

        results = []
        for act in self.actions:
            # Match query against title or description
            if query in act['title'].lower() or query in act['description'].lower():
                results.append(act['id'])
        return results

    def GetInitialResultSet(self, terms):
        return self._search(terms)

    def GetSubsearchResultSet(self, previous_results, terms):
        return self._search(terms)

    def GetResultMetas(self, identifiers):
        metas = []
        for act_id in identifiers:
            match = next((act for act in self.actions if act['id'] == act_id), None)
            if match:
                metas.append({
                    "id": GLib.Variant('s', match['id']),
                    "name": GLib.Variant('s', match['title']),
                    "description": GLib.Variant('s', match['description'])
                })
        return metas

    def ActivateResult(self, identifier, terms, timestamp):

        script_path = "/usr/bin/yafti_gtk.py" #
        yaml_path = "/usr/share/yafti/yafti.yml"

        if not os.path.exists(script_path):
            found = shutil.which("yafti_gtk.py") #
            if found:
                script_path = found
            else:
                return

        # Launch process in detached mode
        subprocess.Popen([script_path, yaml_path, "--action-id", identifier])

    def LaunchSearch(self, terms, timestamp):
        # Optional: Called if the user clicks the Search Provider header instead of a specific result.
        pass

if __name__ == '__main__':
    loop = GLib.MainLoop()
    bus = SessionBus()
    # Publish to the session bus. D-Bus Object path will be /io/github/ublue_os/yafti/SearchProvider
    bus.publish("io.github.ublue_os.yafti.SearchProvider", YaftiSearchProvider())
    loop.run()
