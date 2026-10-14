import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location('editor', Path(__file__).parents[1] / 'editor.py')
editor = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(editor)


class EditorTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.data = self.root / 'data'
        self.env = patch.dict(os.environ, {'HOME': str(self.root), 'XDG_DATA_HOME': str(self.data), 'NVIM_APPNAME': 'nvim'})
        self.env.start()
        self.addCleanup(self.env.stop)
        lock = self.root / 'editors/nvim/lazy-lock.json'
        lock.parent.mkdir(parents=True)
        lock.write_text(json.dumps({'test.nvim': {'commit': 'a' * 40}}))
        self.manifest = {'plugins': {'test.nvim': 'owner/test.nvim'}, 'builds': {}}

    def test_readiness_reports_missing_lock_without_install(self):
        with patch.object(editor, 'lua', return_value=self.manifest), patch.object(editor, 'run') as run:
            result = editor.check(self.root)
        self.assertFalse(result['healthy'])
        self.assertIn('found missing', result['errors'][0])
        run.assert_not_called()
        self.assertFalse(self.data.exists())

    def test_preflight_blocks_live_editor_before_install(self):
        with patch.object(editor, 'run', return_value=f'{os.getuid()} 123 /opt/bin/nvim'), patch.object(editor, 'lua') as lua:
            result = editor.check(self.root, apply=True)
        self.assertIn('close Neovim process 123', result['errors'][0])
        lua.assert_not_called()

    def test_preflight_preserves_dirty_and_symlinked_plugins(self):
        plugins = self.data / 'nvim/lazy'
        dirty = plugins / 'dirty'
        (dirty / '.git').mkdir(parents=True)
        (plugins / 'foreign').symlink_to(self.root)
        with patch.object(editor, 'run', side_effect=[' M custom.lua', '']):
            result = editor.preflight(self.root)
        self.assertEqual(2, len(result['errors']))
        self.assertTrue((plugins / 'foreign').is_symlink())

    def test_locked_plugins_still_require_parser_and_tool_health(self):
        plugin = self.data / 'nvim/lazy/test.nvim'
        plugin.mkdir(parents=True)
        with patch.object(editor, 'run', side_effect=['', 'a' * 40]), patch.object(editor, 'lua', side_effect=[self.manifest, {'errors': ['missing parser rust']}]) as lua:
            result = editor.check(self.root)
        self.assertEqual(['missing parser rust'], result['errors'])
        self.assertEqual('check', lua.call_args.args[1])

    def test_unlocked_declaration_is_not_installed(self):
        self.manifest['plugins']['new'] = 'owner/new'
        with patch.object(editor, 'lua', return_value=self.manifest):
            result = editor.check(self.root)
        self.assertIn('plugins missing from lazy-lock: new', result['errors'][0])

    def test_apply_restores_exact_commit_without_updates(self):
        plugin = self.data / 'nvim/lazy/test.nvim'
        plugin.mkdir(parents=True)
        with patch.object(editor, 'preflight', return_value={'errors': []}), patch.object(editor, 'run', side_effect=['', 'b' * 40, '', '']) as run, patch.object(editor, 'lua', side_effect=[self.manifest, {'errors': []}]):
            result = editor.check(self.root, apply=True)
        self.assertTrue(result['healthy'], result)
        self.assertEqual(('git', '-C', str(plugin), 'fetch', 'origin', 'a' * 40), run.call_args_list[-2].args)
        self.assertEqual(('git', '-C', str(plugin), 'checkout', '--detach', 'a' * 40), run.call_args_list[-1].args)
