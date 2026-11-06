"""Build and verify the standalone Luna Forever ZIP using Python's stdlib."""
from pathlib import Path, PurePosixPath
import argparse
import hashlib
import re
import shutil
import xml.etree.ElementTree as ET
from zipfile import ZipFile, ZIP_DEFLATED

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'DragonflightUI'
MANIFESTS = ('DragonflightUI.toc', 'DragonflightUI_Forever.toc', 'DragonflightUI_Camelot.toc')
DOCUMENTS = (
    'LICENSE', 'README.md', 'CHANGELOG.md', 'CONTRIBUTORS.md',
    'THIRD_PARTY_NOTICES.md', 'ASSET_PROVENANCE.md', 'ASSET_MANIFEST.sha256',
    'CURSEFORGE_DESCRIPTION.md',
)
DIRECTORIES = (
    'Forever', 'Textures', 'THIRD_PARTY_LICENSES', 'Libs/LibStub',
    'Libs/CallbackHandler-1.0', 'Libs/AceAddon-3.0', 'Libs/AceConsole-3.0',
)


def metadata(text):
    return dict(re.findall(r'^##\s*([^:]+):\s*(.*?)\s*$', text, re.M))


def validate(archive, version, title):
    names = archive.namelist()
    assert len(names) == len(set(names)), 'Duplicate archive members'
    assert archive.testzip() is None, 'ZIP integrity check failed'
    assert all(name.startswith('DragonflightUI/') and '..' not in PurePosixPath(name).parts for name in names)
    assert {name for name in names if name.count('/') == 1 and name.endswith('.toc')} == {
        'DragonflightUI/' + name for name in MANIFESTS
    }, 'Unexpected client manifest'
    contents = [archive.read('DragonflightUI/' + name) for name in MANIFESTS]
    assert len(set(contents)) == 1, 'Manifest aliases differ'
    for data in contents:
        info = metadata(data.decode('utf-8-sig'))
        assert (info['Interface'], info['Version'], info['Title']) == ('16001', version, title)

    visited = set()

    def check_reference(name):
        if name in visited:
            return
        visited.add(name)
        data = archive.read(name)
        if name.endswith('.xml'):
            for child in ET.fromstring(data):
                reference = child.attrib.get('file')
                if reference:
                    check_reference(str(PurePosixPath(name).parent / reference.replace('\\', '/')))

    for line in contents[0].decode('utf-8-sig').splitlines():
        line = line.strip()
        if line and not line.startswith('#'):
            check_reference('DragonflightUI/' + line.replace('\\', '/'))

    assets = 0
    for line in archive.read('DragonflightUI/ASSET_MANIFEST.sha256').decode('utf-8-sig').splitlines():
        if not line.strip():
            continue
        digest, size, path = line.split(maxsplit=2)
        data = archive.read('DragonflightUI/' + path)
        assert len(data) == int(size) and hashlib.sha256(data).hexdigest() == digest, path
        assets += 1
    core = archive.read('DragonflightUI/Forever/Core.lua').decode('utf-8-sig')
    assert "DF.version = '" + version + "'" in core
    assert "DF.title = '" + title + "'" in core
    return len(names), len(visited), assets


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output-dir', type=Path, required=True)
    args = parser.parse_args()
    info = metadata((SOURCE / MANIFESTS[0]).read_text(encoding='utf-8-sig'))
    title, version = info['Title'], info['Version']
    assert re.fullmatch(r'[A-Za-z0-9 ._-]+', title)
    assert re.fullmatch(r'\d+(?:\.\d+)*', version)
    files = {SOURCE / name for name in (*MANIFESTS, *DOCUMENTS, 'Libs/LICENSE.txt')}
    for directory in DIRECTORIES:
        files.update(path for path in (SOURCE / directory).rglob('*') if path.is_file() and not any(
            part.startswith('.') or part == '__pycache__' for part in path.relative_to(SOURCE).parts
        ))
    args.output_dir.mkdir(parents=True, exist_ok=True)
    output = args.output_dir / (title + ' ' + version + '.zip')
    with ZipFile(output, 'w', compression=ZIP_DEFLATED, compresslevel=9) as archive:
        for path in sorted(files):
            archive.write(path, 'DragonflightUI/' + path.relative_to(SOURCE).as_posix())
    with ZipFile(output) as archive:
        count, references, assets = validate(archive, version, title)
    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    output.with_suffix('.zip.sha256').write_text(digest + '  ' + output.name + '\n', encoding='utf-8')
    shutil.copyfile(SOURCE / 'CURSEFORGE_DESCRIPTION.md', args.output_dir / (title + ' - CurseForge Description.md'))
    print(output)
    print(f'Verified: {count} files; {references} loaded runtime files; {assets} assets; {output.stat().st_size:,} bytes')
    print('SHA-256: ' + digest)


if __name__ == '__main__':
    main()
