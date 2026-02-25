git add -A 2>$null
git diff --cached --quiet
<#
fix-git-index.ps1
One-shot helper to clean git index from build artifacts and node_modules.

Usage:
  PowerShell -ExecutionPolicy Bypass -File .\fix-git-index.ps1

This script will:
  - Backup current git status to git-status-backup.txt
  - Append common ignore patterns to .gitignore (if not present)
  - Reset index and remove common build folders from git tracking (cached)
  - Commit changes if any
  - Optionally push to origin/main with --force-with-lease
#>

Write-Output "== fix-git-index: start =="

# 1) Confirm current directory
$cwd = Get-Location
Write-Output ("Current path: " + $cwd.Path)

# 2) Backup git status
Write-Output "Backing up git status to git-status-backup.txt"
git status --porcelain > git-status-backup.txt 2>$null

# 3) Prepare ignore block
$ignoreBlock = @'
# Build & dependencies (added by fix-git-index.ps1)
node_modules/
my-app/node_modules/
my-app/.next/
my-app/out/
.next/
# Logs & envs
*.log
.env
.env.local
'@

if (-not (Test-Path -Path .gitignore)) {
    Write-Output "Creating .gitignore"
    $ignoreBlock | Out-File -FilePath .gitignore -Encoding utf8
} else {
    $existing = Get-Content .gitignore -Raw
    if ($existing -notmatch "my-app/\.next") {
        Write-Output "Appending rules to .gitignore"
        "`n# Added by fix-git-index.ps1`n" | Out-File -FilePath .gitignore -Encoding utf8 -Append
        $ignoreBlock | Out-File -FilePath .gitignore -Encoding utf8 -Append
    } else {
        Write-Output ".gitignore already contains rules, skipping append."
    }
}

# 4) Unstage all (move staged back to unstaged)
Write-Output "Running: git reset HEAD -- ."
git reset HEAD -- . 2>$null

# 5) Remove common paths from index (cached only)
$paths = @(
    'my-app/.next',
    'my-app/node_modules',
    'node_modules',
    '.next',
    'my-app/out'
)

foreach ($p in $paths) {
    if (Test-Path $p) {
        Write-Output ("Removing from index: " + $p)
        git rm -r --cached $p 2>$null
    } else {
        Write-Output ("Path not found, skip: " + $p)
    }
}

# 6) Show first 80 untracked files for inspection
Write-Output "First 80 untracked files (after ignoring):"
try { git ls-files -o --exclude-standard | Select-Object -First 80 } catch { }

# 7) Add and commit changes if any
Write-Output "Adding .gitignore and staging changes"
git add .gitignore 2>$null
git add -A 2>$null

# Check if there is anything to commit
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
    Write-Output "Staged changes detected, committing..."
    git commit -m "chore: remove build artifacts and node_modules from index; update .gitignore"
} else {
    Write-Output "No staged changes to commit."
}

# 8) Optionally push
$push = Read-Host "Push changes to origin/main using --force-with-lease? (y/n)"
if ($push -eq 'y' -or $push -eq 'Y') {
    Write-Output "Pushing to origin/main using --force-with-lease"
    git branch -M main 2>$null
    Write-Output "Make sure origin is set: git remote -v"
    git push origin main --force-with-lease
} else {
    Write-Output "Skipping push. You can run: git push origin main --force-with-lease"
}

Write-Output "== fix-git-index: done. Check 'git status' to verify. =="
