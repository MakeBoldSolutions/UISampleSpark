# migrate-to-documentation.ps1
# Migrates DevSpark projects from old structure (.specify/, memory/, scripts/, templates/)
# to new .documentation/ structure
#
# Usage:
#   .\migrate-to-documentation.ps1           # Interactive migration
#   .\migrate-to-documentation.ps1 -DryRun   # Preview changes without modifying files
#   .\migrate-to-documentation.ps1 -Cleanup  # Remove .old backup directories

param(
    [switch]$DryRun,
    [switch]$Cleanup,
    [switch]$Help
)

# Stop on errors
$ErrorActionPreference = "Stop"

# Counters for reporting
$script:DirsMovedCount = 0
$script:FilesUpdatedCount = 0
$script:WarningsCount = 0

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White",
        [switch]$NoNewline
    )
    if ($NoNewline) {
        Write-Host $Message -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $Message -ForegroundColor $Color
    }
}

function Print-Status {
    param([string]$Message)
    Write-ColorOutput "✓ $Message" "Green"
}

function Print-Warning {
    param([string]$Message)
    Write-ColorOutput "⚠ $Message" "Yellow"
    $script:WarningsCount++
}

function Print-Error {
    param([string]$Message)
    Write-ColorOutput "✗ $Message" "Red"
}

function Print-Info {
    param([string]$Message)
    Write-ColorOutput "ℹ $Message" "Cyan"
}

function Print-DryRun {
    param([string]$Message)
    Write-ColorOutput "[DRY RUN] $Message" "Cyan"
}

# Help mode
if ($Help) {
    Write-Host "Usage: .\migrate-to-documentation.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -DryRun    Preview changes without modifying files"
    Write-Host "  -Cleanup   Remove .old backup directories after verification"
    Write-Host "  -Help      Show this help message"
    exit 0
}

# Cleanup mode - remove .old directories
if ($Cleanup) {
    Write-ColorOutput "============================================" "Blue"
    Write-ColorOutput "Cleanup Mode: Remove Backup Directories" "Blue"
    Write-ColorOutput "============================================" "Blue"
    Write-Host ""

    # Find .old directories
    $oldDirs = @()
    if (Test-Path ".specify.old") { $oldDirs += ".specify.old" }
    if (Test-Path "memory.old") { $oldDirs += "memory.old" }
    if (Test-Path "scripts.old") { $oldDirs += "scripts.old" }
    if (Test-Path "templates.old") { $oldDirs += "templates.old" }

    if ($oldDirs.Count -eq 0) {
        Print-Info "No .old backup directories found"
        exit 0
    }

    Write-Host "Found backup directories:"
    foreach ($dir in $oldDirs) {
        $size = (Get-ChildItem -Path $dir -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
        Write-Host "  - $dir ($([math]::Round($size, 2)) MB)"
    }
    Write-Host ""

    Write-ColorOutput "WARNING: This will permanently delete these directories!" "Red"
    Write-ColorOutput "Make sure you have verified the migration was successful first." "Yellow"
    Write-Host ""
    Write-Host "Type " -NoNewline
    Write-ColorOutput "DELETE" "Red" -NoNewline
    Write-Host " to confirm deletion, or anything else to cancel:"
    $confirmation = Read-Host

    if ($confirmation -eq "DELETE") {
        foreach ($dir in $oldDirs) {
            Write-Host "Deleting $dir..."
            Remove-Item -Path $dir -Recurse -Force
            Print-Status "Deleted $dir"
        }
        Write-Host ""
        Print-Status "Cleanup complete"
    } else {
        Print-Info "Cleanup cancelled"
    }
    exit 0
}

# Main migration mode
Write-ColorOutput "============================================" "Blue"
if ($DryRun) {
    Write-ColorOutput "DRY RUN MODE - No files will be modified" "Cyan"
    Write-ColorOutput "============================================" "Blue"
} else {
    Write-ColorOutput "DevSpark Migration to .documentation/" "Blue"
    Write-ColorOutput "============================================" "Blue"
}
Write-Host ""

# Safety checks
Write-ColorOutput "Running safety checks..." "Blue"
Write-Host ""

# Check if we're in a git repository
$inGitRepo = Test-Path ".git"
if ($inGitRepo) {
    Print-Status "Git repository detected"

    # Check for uncommitted changes
    $gitStatus = git status --porcelain 2>$null
    if ($gitStatus) {
        Print-Warning "You have uncommitted changes in your repository"
        Write-Host "  It's recommended to commit or stash changes before migration"
        Write-Host ""
        if (-not $DryRun) {
            $response = Read-Host "Continue anyway? (y/N)"
            if ($response -notmatch '^[Yy]$') {
                Print-Info "Migration cancelled"
                exit 0
            }
        }
    } else {
        Print-Status "Working tree is clean"
    }
} else {
    Print-Warning "Not a git repository - cannot preserve history"
}

# Check if .documentation already exists
if (Test-Path ".documentation") {
    Print-Warning ".documentation/ already exists - will merge with existing content"
}

Write-Host ""
Write-ColorOutput "Detecting old structure..." "Blue"
Write-Host ""

# Detect what needs to be migrated
$oldStructuresFound = $false
$structuresToMigrate = @()

if (Test-Path ".specify") {
    Print-Status "Found .specify/ directory"
    $structuresToMigrate += ".specify"
    $oldStructuresFound = $true
}

if ((Test-Path "memory") -and -not (Test-Path ".documentation\memory")) {
    Print-Status "Found memory/ directory"
    $structuresToMigrate += "memory"
    $oldStructuresFound = $true
}

if ((Test-Path "scripts") -and -not (Test-Path ".documentation\scripts")) {
    Print-Status "Found scripts/ directory"
    $structuresToMigrate += "scripts"
    $oldStructuresFound = $true
}

if ((Test-Path "templates") -and -not (Test-Path ".documentation\templates")) {
    Print-Status "Found templates/ directory"
    $structuresToMigrate += "templates"
    $oldStructuresFound = $true
}

if ((Test-Path "specs") -and -not (Test-Path ".documentation\specs")) {
    Print-Status "Found specs/ directory"
    $structuresToMigrate += "specs"
    $oldStructuresFound = $true
}

if (-not $oldStructuresFound) {
    Write-Host ""
    Print-Error "No old structure found to migrate."
    Write-Host "Looking for: .specify/, memory/, scripts/, templates/, or specs/"
    Write-Host ""
    exit 0
}

Write-Host ""
Write-ColorOutput "Migration Plan:" "Blue"
Write-Host ""
Write-Host "The following actions will be performed:"
Write-Host ""
Write-Host "  1. Create .documentation/ directory structure"
Write-Host "  2. Copy files from old locations to new locations:"
foreach ($struct in $structuresToMigrate) {
    Write-Host "     - $struct/ → .documentation/"
}
Write-Host "  3. Update path references in files:"
Write-Host "     - Agent command files (.claude/, .github/, etc.)"
Write-Host "     - Script files (.documentation/scripts/)"
Write-Host "     - Documentation files (README.md, etc.)"
Write-Host "  4. Rename old directories with .old suffix:"
foreach ($struct in $structuresToMigrate) {
    Write-Host "     - $struct/ → $struct.old/"
}
Write-Host "  5. Update .gitignore if needed"
Write-Host ""
Write-ColorOutput "Your specs/ directory will be moved to .documentation/specs/" "Green"
Write-Host ""

if (-not $DryRun) {
    Write-ColorOutput "This operation will modify your repository." "Yellow"
    Write-ColorOutput "Press Enter to continue, or Ctrl+C to cancel..." "Yellow"
    Read-Host
}

Write-Host ""
Write-ColorOutput "Step 1: Creating .documentation/ structure" "Blue"

# Create directory structure
if ($DryRun) {
    Print-DryRun "Would create .documentation\memory\"
    Print-DryRun "Would create .documentation\scripts\bash\"
    Print-DryRun "Would create .documentation\scripts\powershell\"
    Print-DryRun "Would create .documentation\templates\"
} else {
    New-Item -ItemType Directory -Path ".documentation\memory" -Force | Out-Null
    Print-Status "Created .documentation\memory\"

    New-Item -ItemType Directory -Path ".documentation\scripts\bash" -Force | Out-Null
    New-Item -ItemType Directory -Path ".documentation\scripts\powershell" -Force | Out-Null
    Print-Status "Created .documentation\scripts\"

    New-Item -ItemType Directory -Path ".documentation\templates" -Force | Out-Null
    Print-Status "Created .documentation\templates\"

    New-Item -ItemType Directory -Path ".documentation\specs" -Force | Out-Null
    Print-Status "Created .documentation\specs\"
}

Write-Host ""
Write-ColorOutput "Step 2: Copying files" "Blue"

function Copy-Directory {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Name
    )

    if (Test-Path $Source) {
        $fileCount = (Get-ChildItem -Path $Source -Recurse -File).Count

        if ($DryRun) {
            Print-DryRun "Would copy $fileCount files from $Name to $Destination\"
            Print-DryRun "Would rename $Source to $Source.old"
        } else {
            # Copy all contents
            Get-ChildItem -Path $Source -Recurse | ForEach-Object {
                $targetPath = $_.FullName.Replace($Source, $Destination)
                $targetDir = Split-Path $targetPath -Parent

                if (-not (Test-Path $targetDir)) {
                    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                }

                if ($_.PSIsContainer -eq $false) {
                    Copy-Item $_.FullName -Destination $targetPath -Force
                }
            }

            # Rename old directory
            Rename-Item -Path $Source -NewName "$Source.old" -Force
            $script:DirsMovedCount++
            Print-Status "Copied $Name to $Destination\ ($fileCount files)"
            Print-Status "Renamed $Source to $Source.old"
        }
    }
}

# Copy .specify/ if exists
if (Test-Path ".specify") {
    if ($DryRun) {
        if (Test-Path ".specify\memory") { Print-DryRun "Would copy .specify\memory\ to .documentation\memory\" }
        if (Test-Path ".specify\scripts") { Print-DryRun "Would copy .specify\scripts\ to .documentation\scripts\" }
        if (Test-Path ".specify\templates") { Print-DryRun "Would copy .specify\templates\ to .documentation\templates\" }
        Print-DryRun "Would copy .specify\ root files to .documentation\"
        Print-DryRun "Would rename .specify to .specify.old"
    } else {
        # .specify might contain memory, scripts, templates subdirectories
        if (Test-Path ".specify\memory") {
            Get-ChildItem ".specify\memory" -Recurse | ForEach-Object {
                $target = $_.FullName.Replace(".specify\memory", ".documentation\memory")
                if ($_.PSIsContainer -eq $false) {
                    $targetDir = Split-Path $target -Parent
                    if (-not (Test-Path $targetDir)) {
                        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                    }
                    Copy-Item $_.FullName -Destination $target -Force
                }
            }
            Print-Status "Copied .specify\memory\ to .documentation\memory\"
        }

        if (Test-Path ".specify\scripts") {
            Get-ChildItem ".specify\scripts" -Recurse | ForEach-Object {
                $target = $_.FullName.Replace(".specify\scripts", ".documentation\scripts")
                if ($_.PSIsContainer -eq $false) {
                    $targetDir = Split-Path $target -Parent
                    if (-not (Test-Path $targetDir)) {
                        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                    }
                    Copy-Item $_.FullName -Destination $target -Force
                }
            }
            Print-Status "Copied .specify\scripts\ to .documentation\scripts\"
        }

        if (Test-Path ".specify\templates") {
            Get-ChildItem ".specify\templates" -Recurse | ForEach-Object {
                $target = $_.FullName.Replace(".specify\templates", ".documentation\templates")
                if ($_.PSIsContainer -eq $false) {
                    $targetDir = Split-Path $target -Parent
                    if (-not (Test-Path $targetDir)) {
                        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                    }
                    Copy-Item $_.FullName -Destination $target -Force
                }
            }
            Print-Status "Copied .specify\templates\ to .documentation\templates\"
        }

        if (Test-Path ".specify\specs") {
            Get-ChildItem ".specify\specs" -Recurse | ForEach-Object {
                $target = $_.FullName.Replace(".specify\specs", ".documentation\specs")
                if ($_.PSIsContainer -eq $false) {
                    $targetDir = Split-Path $target -Parent
                    if (-not (Test-Path $targetDir)) {
                        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                    }
                    Copy-Item $_.FullName -Destination $target -Force
                }
            }
            Print-Status "Copied .specify\specs\ to .documentation\specs\"
        }

        # Copy any other files in .specify root
        Get-ChildItem ".specify" -File | ForEach-Object {
            Copy-Item $_.FullName -Destination ".documentation\" -Force
        }
        Print-Status "Copied .specify\ root files to .documentation\"

        Rename-Item -Path ".specify" -NewName ".specify.old" -Force
        $script:DirsMovedCount++
        Print-Status "Renamed .specify to .specify.old"
    }
}

# Copy top-level directories
Copy-Directory "memory" ".documentation\memory" "memory\"
Copy-Directory "scripts" ".documentation\scripts" "scripts\"
Copy-Directory "templates" ".documentation\templates" "templates\"
Copy-Directory "specs" ".documentation\specs" "specs\"

Write-Host ""
Write-ColorOutput "Step 3: Updating path references in files" "Blue"

function Update-FileReferences {
    param([string]$FilePath)

    if (-not (Test-Path $FilePath)) {
        return
    }

    # Read file content
    $content = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) {
        return
    }

    # Store original for comparison
    $originalContent = $content

    # Update references using regex
    $content = $content -replace '(/?)\.specify/', '$1.documentation/'
    $content = $content -replace '(^|\s|`)/memory/', '$1/.documentation/memory/'
    $content = $content -replace '(^|\s|`)/scripts/', '$1/.documentation/scripts/'
    $content = $content -replace '(^|\s|`)/templates/', '$1/.documentation/templates/'
    $content = $content -replace 'memory/constitution\.md', '.documentation/memory/constitution.md'

    # Check if changed
    if ($content -ne $originalContent) {
        if ($DryRun) {
            Print-DryRun "Would update references in $FilePath"
        } else {
            Set-Content -Path $FilePath -Value $content -NoNewline
            $script:FilesUpdatedCount++
            Print-Status "Updated references in $FilePath"
        }
    }
}

# Update agent command files
$agentDirs = @('.claude', '.github', '.cursor', '.windsurf', '.gemini', '.qwen', '.opencode',
               '.codex', '.kilocode', '.augment', '.roo', '.codebuddy', '.qoder', '.amazonq',
               '.agents', '.shai', '.bob')

foreach ($dir in $agentDirs) {
    if (Test-Path $dir) {
        Get-ChildItem -Path $dir -Recurse -Include "*.md", "*.toml" -ErrorAction SilentlyContinue | ForEach-Object {
            Update-FileReferences $_.FullName
        }
    }
}

# Update script files
if (Test-Path ".documentation\scripts") {
    Get-ChildItem -Path ".documentation\scripts" -Recurse -Include "*.sh", "*.ps1" -ErrorAction SilentlyContinue | ForEach-Object {
        Update-FileReferences $_.FullName
    }
}

# Update documentation files
$docsToUpdate = @("README.md")
if (Test-Path ".vscode\settings.json") {
    $docsToUpdate += ".vscode\settings.json"
}

foreach ($file in $docsToUpdate) {
    if (Test-Path $file) {
        Update-FileReferences $file
    }
}

# Update all markdown files in .documentation
if (Test-Path ".documentation") {
    Get-ChildItem -Path ".documentation" -Filter "*.md" -ErrorAction SilentlyContinue | ForEach-Object {
        Update-FileReferences $_.FullName
    }
}

Write-Host ""
Write-ColorOutput "Step 4: Updating .gitignore" "Blue"

# Add .documentation build output to .gitignore if needed
if (Test-Path ".gitignore") {
    $gitignoreContent = Get-Content ".gitignore" -Raw
    if ($gitignoreContent -notmatch ".documentation/_site") {
        if ($DryRun) {
            Print-DryRun "Would add .documentation/_site/ to .gitignore"
        } else {
            Add-Content -Path ".gitignore" -Value "`n# DevSpark documentation build output`n.documentation/_site/"
            Print-Status "Added .documentation/_site/ to .gitignore"
        }
    } else {
        Print-Status ".gitignore already configured"
    }
}

Write-Host ""
Write-ColorOutput "============================================" "Green"
if ($DryRun) {
    Write-ColorOutput "Dry Run Complete - No Changes Made" "Cyan"
} else {
    Write-ColorOutput "Migration Complete!" "Green"
}
Write-ColorOutput "============================================" "Green"
Write-Host ""

if (-not $DryRun) {
    Write-Host "Summary:"
    Write-Host "  - Directories moved: $script:DirsMovedCount"
    Write-Host "  - Files updated: $script:FilesUpdatedCount"
    Write-Host "  - Warnings: $script:WarningsCount"
    Write-Host ""
    Write-Host "Backup directories created:"
    if (Test-Path ".specify.old") { Write-Host "  - .specify.old\" }
    if (Test-Path "memory.old") { Write-Host "  - memory.old\" }
    if (Test-Path "scripts.old") { Write-Host "  - scripts.old\" }
    if (Test-Path "templates.old") { Write-Host "  - templates.old\" }
    Write-Host ""
}

Write-Host "Next steps:"
if ($DryRun) {
    Write-Host "  1. Review the dry run output above"
    Write-Host "  2. Run without -DryRun to perform the migration:"
    Write-ColorOutput "     .\migrate-to-documentation.ps1" "Yellow"
} else {
    Write-Host "  1. Review changes: " -NoNewline
    Write-ColorOutput "git status" "Yellow" -NoNewline
    Write-Host " and " -NoNewline
    Write-ColorOutput "git diff" "Yellow"
    Write-Host "  2. Test slash commands in your AI assistant"
    Write-Host "  3. Test scripts: " -NoNewline
    Write-ColorOutput ".\.documentation\scripts\powershell\setup-plan.ps1" "Yellow"
    Write-Host "  4. Verify constitution loads: " -NoNewline
    Write-ColorOutput "Get-Content .documentation\memory\constitution.md" "Yellow"
    Write-Host "  5. If everything works, commit:"
    Write-ColorOutput "     git add -A" "Yellow"
    Write-ColorOutput "     git commit -m 'chore: migrate to .documentation/ structure'" "Yellow"
    Write-Host "  6. After verifying and committing, delete old backups:"
    Write-ColorOutput "     .\migrate-to-documentation.ps1 -Cleanup" "Yellow"
    Write-Host ""
    Write-ColorOutput "⚠ IMPORTANT: Do NOT delete .old directories until you've verified the migration!" "Yellow"
}
Write-Host ""

if ($script:WarningsCount -gt 0) {
    Write-ColorOutput "⚠ Please review warnings above before committing" "Yellow"
    Write-Host ""
}

if (-not $DryRun) {
    Print-Status "Migration script completed successfully"
    Write-Host ""
    Write-ColorOutput "Need help? See .documentation\upgrade.md" "Cyan"
}
