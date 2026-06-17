# Test Fixture: Invalid Configuration (Contains Local Paths)

## Bad Example 1: Absolute Unix Paths

```bash
# This will be caught by the guard
export DATA_DIR="/home/chad/TAGS/data"
cd /home/user/project
python /home/john/scripts/run.py
```

## Bad Example 2: VS Code Server Paths

```
Workspace stored at file:///home/chad/.vscode-server/
Settings: /home/user/.vscode-server-insiders/extensions
Chrome cache at /home/username/workspaceStorage/abc123/
```

## Bad Example 3: Windows Paths

```
Home: C:\Users\Developer\Projects\
Build: C:\Users\Builder\build\output
Config: C:\Users\Admin\AppData\
```

## Bad Example 4: File URIs

```
Open file:///home/user/project/main.py
Reference: file:///home/chad/TAGS/docs/guide.md
```
