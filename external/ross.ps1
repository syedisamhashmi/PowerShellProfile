$ErrorActionPreference = "Stop";
set-strictmode -Version Latest

$env:EDITOR = "code";
$env:ASPNETCORE_ENVIRONMENT = "Development";
$env:DOTNET_NOLOGO = 1;
$env:DOTNET_CLI_TELEMETRY_OPTOUT = 1;
$env:DOTNET_CLI_CAPTURE_TIMING = 0;
$env:COMPlus_gcServer = 0;
$env:COMPlus_GCConserveMemory = 5;

$Z_UsePushLocation = $true;


function use-go {
  $env:PATH += ";c:/tools/go/bin;"
}

function use-java {
  clean-path "c:/java/"

  # it would be nice if this could always just be PATH += %JAVA_HOME%/bin; but it's screwy.
  (dir c:\java).Name | fzf | % {
    $env:JAVA_HOME = "C:/java/$_"
    $env:PATH += "$($env:JAVA_HOME)/bin;"
  }
}

if ($env:PROFILE_INIT -ne "1") {
  # weird, powershell considers this to be executable
  # but tools like where.exe do not report it
  $env:PATHEXT += ";.PS1";

  $env:PATH += ";"
  $env:PATH += "c:/tools;"
  $env:PATH += "C:/tools/pandoc;"
  $env:PATH += "c:/tools/git/bin;"
  $env:PATH += "c:/tools/sys-internals;"
  $env:PATH += "c:/tools/azure-func-core-tools;"

  # some optional things
  $env:PATH += "C:/tools/maven/bin;"
  # $env:PATH += "c:/tools/graphviz/bin;"
  # $env:PATH += "c:/tools/hercules;"

  $env:PATH += "C:/Program Files/7-Zip;"
  $env:PATH += "c:/Program Files (x86)/Google/Chrome/Application;"
  $env:PATH += "C:/Users/ross.jennings/AppData/Local/Programs/Python/Python310;"
  $env:PATH += "C:/Users/ross.jennings/AppData/Local/Programs/Python/Python310/Scripts;"
  $env:PATH += "c:/Program Files (x86)/Microsoft SDKs/Windows/v10.0A/bin/NETFX 4.8 Tools/x64;"
  $env:PATH += "$(yarn global bin);"

  function use-android {
    $ANDROID_SDK = "$($env:LOCALAPPDATA)\Android\Sdk"
    $env:PATH += "$ANDROID_SDK/platform-tools;";
    $env:PATH += "$ANDROID_SDK/emulator;";
    $env:PATH += "$ANDROID_SDK/cmdline-tools/latest/bin;";
    $env:ANDROID_SDK_ROOT= $ANDROID_SDK;
    $env:ANDROID_HOME = $ANDROID_SDK;
  }

  $PSDefaultParameterValues += @{
    "Install-Module:Scope" = "CurrentUser";
    "Out-File:Encoding" = "utf8NoBOM";
    "ConvertTo-Csv:NoTypeInformation" = $true;
    "Format-MarkdownTableTableStyle:HideStandardOutput" = $true;
    "Format-MarkdownTableTableStyle:ShowMarkdown" = $true;
    "Format-MarkdownTableTableStyle:DoNotCopyToClipboard" = $true;
  }
  $env:PROFILE_INIT = "1";
}


# PowerShell parameter completion shim for the dotnet CLI
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
  param($commandName, $wordToComplete, $cursorPosition)
      dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
         [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
      }
}

function chmod ($flags, $file) {
  # too lazy to do all the octal flag stuff
  if ($flags -eq 600) {
    takeown.exe /f $file
    icacls.exe $file /inheritance:d /grant user:f
  }
}

function get-bytes ($f) {
  return [system.io.File]::ReadAllBytes((resolve-path $f));
}

function to-base64 {
  [cmdletbinding()]
  param(
    [parameter(ValueFromPipeline)]
    [string] $stdin
  )

  [system.convert]::ToBase64String(
    [system.text.encoding]::UTF8.GetBytes($stdin)
  );
}

function from-base64 {
  [cmdletbinding()]
  param(
    [parameter(ValueFromPipeline)]
    [string] $stdin
  )

  [system.text.encoding]::UTF8.GetString(
    [system.convert]::FromBase64String($stdin.Trim())
  );
}

function read-text ($f) {
  [system.io.file]::ReadAllText((Resolve-Path $f));
}

function unix-time {
  return [long] ([datetime]::UtcNow - [datetime]::UnixEpoch).TotalSeconds;
}

# chunk a long list into evenly sized blocks
# and return as an array of arrays
function chunked($list, $sz) {
  $len = $list.Length;
  $chunks = [Math]::Ceiling($len / $sz);
  $outer = [Array]::CreateInstance([object], $chunks);
  for ($i = 0; $i -lt $chunks; $i++) {
    $off = $i * $sz;
    $max = [Math]::Min($off + $sz, $len);
    $inner = [Array]::CreateInstance([object], $max);
    for ($j = 0; ($j + $off) -lt $max; $j++) {
      $inner = $list[$off + $j];
    }

    $outer[$i] = $inner;
  }

  return $outer;
}

function format-xml($name) {
  $xml = [xml](cat $name);

  $s = [System.Xml.XmlWriterSettings]::new();
  $s.Indent = $true;

  $w = [System.Xml.XmlWriter]::Create($name, $s);
  $xml.Save($w);
}

function format-cer ($f) {
  $file = read-text $f;
  $len = $file.Length;
  $chunks = [math]::Ceiling($len / 64);
  "-----BEGIN CERTIFICATE-----";

  for ($i = 0; $i -lt $chunks; $i++) {
    $start = $i * 64;

    if (($i + 1) * 64 -ge $len) {
      $file.Substring($start);
    } else {
      $file.Substring($start, 64);
    }
  }

  "-----END CERTIFICATE-----";
}

function format-cer-inplace ($f) {
  $temp = [system.io.Path]::GetTempFileName();
  format-cer $f | out-file $temp;
  move-item $temp $f -force
}

function hexify ($bytes) {
  $sb = [System.Text.StringBuilder]::new($bytes.Count * 2);
  for ($i = 0; $i -lt $bytes.Count; $i++) {
    $sb.AppendFormat("{0:x2}", $bytes[$i]) | out-null;
  }
  return $sb.ToString();
}

function unhexify($str) {
  $off = if ($str.StartsWith("0x")) { 2 } else { 0 }
  $byte_count = ($str.Length - $off) / 2;
  $bytes = [Array]::CreateInstance([byte], $byte_count);

  for ($i = 0; $i -lt $byte_count; $i++) {
    $bytes[$i] = [byte]::Parse($str.substring($off + ($i * 2), 2), "HexNumber");
  }
  return $bytes;
}

function show_debug { $DebugPreference = "Continue"; }
function hide_debug { $DebugPreference = "SilentlyContinue"; }

function sha_256($text) {
  $sha = [System.Security.Cryptography.SHA256]::Create();
  $hash = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($text));
  return [Convert]::ToBase64String($hash);
}

<# disk space is at a premium gang, gotta kill the unused junk #>
function clean-disk() {
  function _ask($q) {
    return (read-host $q) -eq "y"
  }

  function _clean([string] $p, [scriptblock] $block) {
    if (_ask "purge '$p'? y/N") {
      $block.Invoke();
    }
  }

  dir ~\AppData\Local\CrashDumps | rmrf

  _clean -p "~\AppData\Local\temp" {
    if (test-path "~\AppData\Local\temp") {
      dir ~\AppData\Local\temp | rmrf;
    }
  }

  _clean -p "package caches" {
    # gradle is dangerous... might want to limit that
    # to only certain subfolders
    dir ~/.gradle/caches | rmrf;
    rmrf ~/.m2/repository
    npm cache clean --force
    yarn cache clean
    # dotnet nuget locals all --clear
  }

  if (_ask "clean c:/vs/edhc?") {
    cd c:\vs\EDHC && git clean --force -d -X
  }

  if (_ask "clean c:/vs/member") {
    cd c:\vs\member && git clean --force -d -X
  }
}

function gen_key($len, [switch] $hex) {
  $buff  = [array]::CreateInstance([byte], $len);
  $crypt = [System.Security.Cryptography.RNGCryptoServiceProvider]::new();
  $crypt.GetBytes($buff);
  $crypt.Dispose();

  if ($hex) {
    return hexify $buff
  }
  else {
    return [Convert]::ToBase64String($buff);
  }
}

function gen_pass($n, $min_len = 16, $max_len = 0, [switch] $specials) {
  # if you specify both it's on you to make sure they align properly
  if ($max_len -lt $min_len) {
    $max_len = $min_len + 4;
  }

  $ALPHABET =
    "abcdefghijklmnopqrstuvwxyz" +
    "abcdefghijklmnopqrstuvwxyz" +
    "01234567890123456789" +
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

  if ($specials) {
    $ALPHABET += "!@#$%^&*_+-./~?";
  }

  gen_keys_from_alpha -n $n -alpha $ALPHABET -min $min_len -max $max_len
}

$UPPER_ALPHA_NUMERIC = "ABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890123456789"

function gen_keys_from_alpha($n, $alpha, $min_len, $max_len) {
  $buff  = [array]::CreateInstance([byte], $max_len);
  $crypt = [System.Security.Cryptography.RNGCryptoServiceProvider]::new();
  $rng   = [system.random]::new();
  $a_len = $alpha.Length;

  for ($i = 0; $i -lt $n; $i++) {
    $len = $rng.Next($min_len, $max_len);
    $crypt.GetBytes($buff);

    for ($j = 0; $j -lt $len; $j++) {
      $buff[$j] = $alpha[$buff[$j] % $a_len];
    }

    [string]::new($buff, 0, $len);
  }
}

function aspnet_hash ($password) {
  $bytes = [System.Security.Cryptography.Rfc2898DeriveBytes]::new($password, 0x10, 0x3e8);

  try {
    $salt = $bytes.Salt;
    $buff = $bytes.GetBytes(0x20);
  }
  finally {
    $bytes.Dispose();
  }

  $dst = [array]::CreateInstance([byte], 0x31);
  [Buffer]::BlockCopy($salt, 0, $dst, 1, 0x10);
  [Buffer]::BlockCopy($buff, 0, $dst, 0x11, 0x20);

  return [Convert]::ToBase64String($dst);
}

function distinct {
  [cmdletbinding()]
  param(
    [parameter(ValueFromPipeline)]
    [string[]] $stdin
  )
  begin {
    $set = new-object "System.Collections.Generic.HashSet[string]"
  }
  process {
    foreach ($p in $stdin) {
      if ($set.Add($p)) {
        $p
      }
    }
  }
}

function abs_path {
  [cmdletbinding()]
  param(
    [parameter(ValueFromPipeline)]
    [string[]] $stdin
  )
  begin {
    [System.Environment]::CurrentDirectory = $pwd;
  }
  process {
    foreach ($p in $stdin) {
      [io.path]::GetFullPath($p.Replace("~", $HOME));
    }
  }
}

function rel_path {
  [cmdletbinding()]
  param(
    [parameter(ValueFromPipeline)]
    [string[]]$stdin
  )
  begin {
    $d = $pwd.toString().Replace("Microsoft.PowerShell.Core\FileSystem::", "")
    $len = $d.length;

    if (-not($d.EndsWith("\"))) {
      $len++;
    }
  }
  process {
    foreach ($p in $stdin) {
      $p.substring($len).replace("\", "/");
    }
  }
}

$hist_file = (Get-PsReadlineOption).HistorySavePath

function fh {
  cat $hist_file | fzf | % { $_; iex $_ }
}

function prune-history-common {
  prune-history "ls|cd ..|"
}

# delete all sqlcmd or cd <whatever> occurences
function prune-history ($pattern) {
  if (-not $pattern) {
    "you probably didn't mean to kill everything"
    "and if you did, just 'rm $hist_file'"
    return;
  }

  $hist_temp = [io.Path]::GetTempFileName();
  $killed = 0;
  cat $hist_file | % {
    if ($_ -notmatch $pattern) {
      $_
    } else { $killed++; }
  } | out-file -Append $hist_temp

  mv $hist_temp $hist_file -force

  Write-Host "removed $killed occurrences of $pattern"
}

$az_build_defs_cache = $null;

<# attempts to build the current branch on az pipelines #>
function az-build ($def) {
  $branch = (git branch --show-current);

  if (-not $branch) { return; }

  if (-not $def) {
    if (-not $az_build_defs_cache) {
      # it takes ~1s to load these, so just do it lazily and cache
      set-variable -scope global -name az_build_defs_cache -value (az pipelines build definition list --query "[].name" -o tsv)
    }

    $def = $az_build_defs_cache | fzf --bind one:accept;
  }

  if ($def) {
    az pipelines build queue --definition-name $def --branch $branch --open
  }
}

function az-show-pr {
  $root_url = (git remote get-url --all origin);
  $id = az repos pr list -s "$(git branch --show-current)" --query "[].pullRequestId | [0]" -o tsv;
  $path = if ($id) { '/pullrequest/' + $id; } else { '/pullrequests' }
  $url = $root_url + $path;

  Start-Process $url
}

# alias 'mkbr'
function git-make-remote-branch ($name) {
  if (-not $name -match "(epic/)?[A-Z]+-[0-9]+") {
    write-error 'specified branch name does not match the branch naming format'
  }

  git pull
  git checkout -b $name
  git push -u
}

# no alias
function git-ls-branches([switch] $remote) {
  $target = if (-not $remote) { "refs/heads/" } else { "refs/remotes/" }
  git for-each-ref --sort=-committerdate $target --format='%(refname:short)' `
  | % { $_.Replace("origin/", "") } `
  | fzf
}

function git-checkout-interactive($s) {
  $fzf_args = if ($s) { "-q $s" }

  git for-each-ref --format='%(refname:short)' `
  | % { $_.Replace("origin/", "") } `
  | sort | unique `
  | fzf $fzf_args --bind one:accept | % { git checkout $_ }

  git pull
}

function unpack_diagsession($path) {
  $temp = [system.io.path]::GetTempPath() + [guid]::NewGuid().ToString("n");

  # join with &&s?
  mkdir $temp; mv $path $temp; cd $temp;

  7z x *.diagsession
  rm *.diagsession

  $meta = [xml](gc metadata.xml);

  # basically just need to know where the symbols are
  # to throw into the debugger with a sympath command
  $res = $meta.package.content.resource;
  foreach ($r in $res) {
    [string] $id = [guid]::Parse($r.Id);
    switch($r.Type) {
      "ServiceProfiler.Resource.MiniDump" {
        mv "$id\$($r.Name)" ".\minidump.dmp";
        rmdir $id;
        break;
      }

      "DiagnosticsHub.Resource.SymbolCache" {
        ren $id "sym"
        break;
      }
    }
  }

  start_diagsession_debugger
}

function start_diagsession_debugger() {
  # dotnet tool update -g dotnet-sos
  dotnet sos install --architecture X86
  $sos_path = resolve-path "~\.dotnet\sos\sos.dll"
  $symcache = resolve-path .\sym\cache;
  cdb -z minidump.dmp `
    -y "srv*$symcache*https://msdl.microsoft.com/download/symbols" `
    -c ".load $sos_path"
}

function gg ($pattern) {
  $revs = git rev-list --all

  foreach ($r in $revs) {
    git grep $pattern $r
  }
}

function git-diff {
  git diff -w .
}

function git-diff-cached {
  git diff -w --cached .
}

function git-status {
  git status --renames -u all .
}

function time([string] $cmd) {
  $start = [DateTime]::Now;
  iex $cmd;
  $end = [DateTime]::Now;
  ($end - $start).ToString();
}

function except($left, $right) {
  $left_set = new-object "System.Collections.Generic.HashSet[string]"
  $right_set = new-object "System.Collections.Generic.HashSet[string]"

  foreach ($val in $left) { $left_set.Add($val) | out-null; }
  foreach ($val in $right) { $right_set.Add($val) | out-null; }

  $left_set.ExceptWith($right_set);
  $left_set
}

function copy_files($dir) {
  # robocopy lite
  get-childitem $dir -Recurse -File | %{
    $rel = $_.FullName.Substring($dir.Length - 1);
    # todo: make the directories if they don't already exist
    cp -Path $($_.FullName) -Destination $rel -Force -Verbose
  }
}

function list_directory ([switch] $sort_size) {
  # okay, technically this only makes sense in the context of a FILE
  if ((get-location).Provider.Name.EndsWith("FileSystem")) {

    $dir = [system.io.fileattributes]::Directory
    $hidden = [system.io.fileattributes]::Hidden
    $symlink = [system.io.fileattributes]::ReparsePoint
    $argv = [string]::Join(" ", $args)

    Invoke-Expression "Get-ChildItem $argv -Force" | % {
      $c = "white"

      if ($_.Attributes -band $hidden) {
        $c = "darkgray"
      }
      elseif ($_.Attributes -band $symlink) {
        $c = "cyan"
      }
      elseif ($_.Attributes -band $dir) {
        $c = "blue"
      }
      else {
        $extensions = $env:PATHEXT.toLower().split(';')
        if ($extensions -contains $_.extension) {
          $c = "green"
        }
      }

      $ts = $_.LastWriteTime.ToString("MMM dd yyyy")
      $line = $_.Mode + " " + $(__size($_)) + " " + $ts + " "

      write-host -NoNewLine $line
      $name = rel_path $_.FullName;

      write-host -F $c $name
    }
  }
  else {
    gci
  }
}

function __set_hidden ($f) {
  $item = get-item $f
  $f.Attributes = $f.Attributes -bor [system.io.fileattributes]::Hidden;
}

<# helper for ls to display human readable sizes #>
function __size ($f) {
  $dir = [system.io.fileattributes]::Directory
  if ($f.attributes -band $dir) { return "   dir" }

  switch ($f.length) {
    { $_ -gt 1tb } { return "{0,4:n1} T" -f ($_ / 1tb) }
    { $_ -gt 1gb } { return "{0,4:n1} G" -f ($_ / 1gb) }
    { $_ -gt 1mb } { return "{0,4:n1} M" -f ($_ / 1mb) }
    { $_ -gt 1kb } { return "{0,4:n1} K" -f ($_ / 1Kb) }
    default { return "  {0,4:0}" -f $_ }
  }
}

function rmrf {
  [cmdletbinding()]
  param(
    [parameter(ValueFromPipeline)]
    [string[]] $stdin
  )

  begin {
    $splat = @{
      "Recurse" = $true;
      "Force" = $true;
      "ErrorAction" = "SilentlyContinue";
      "Verbose" = $PSBoundParameters.ContainsKey("Verbose");
    };
  }

  process {
    foreach ($item in $stdin) {
      Remove-Item $item @splat
    }
  }
}

function ansi ($color, $text) {
  $c = [char]0x001b # the magic escape

  switch ($color.toLower()) {
    "red"           { return "${c}[31m${text}${c}[39m"; }
    "green"         { return "${c}[32m${text}${c}[39m"; }
    "yellow"        { return "${c}[33m${text}${c}[39m"; }
    "blue"          { return "${c}[34m${text}${c}[39m"; }
    "magenta"       { return "${c}[35m${text}${c}[39m"; }
    "cyan"          { return "${c}[36m${text}${c}[39m"; }
    "light_red"     { return "${c}[91m${text}${c}[39m"; }
    "light_green"   { return "${c}[92m${text}${c}[39m"; }
    "light_yellow"  { return "${c}[93m${text}${c}[39m"; }
    "light_blue"    { return "${c}[94m${text}${c}[39m"; }
    "light_magenta" { return "${c}[95m${text}${c}[39m"; }
    "light_cyan"    { return "${c}[96m${text}${c}[39m"; }
    default { return "${text}"; }
  }
}

function ansi_debug() {
  ansi red red
  ansi light_red light_red

  ansi green green
  ansi light_green light_green

  ansi yellow yellow
  ansi light_yellow light_yellow

  ansi blue blue
  ansi light_blue light_blue

  ansi cyan cyan
  ansi light_cyan light_cyan

  ansi magenta magenta
  ansi light_magenta light_magenta
}

function basic-auth($decode, $encode) {
  $utf = [System.Text.Encoding]::UTF8;

  if ($decode) {
    return $utf.GetString([System.Convert]::FromBase64String($decode));
  }
  elseif ($encode) {
    return [System.Convert]::ToBase64String($utf.GetBytes($encode));
  }
}

function file-as-b64 ($f) {
  $bytes = [system.io.File]::ReadAllBytes((resolve-path $f));
  return [system.Convert]::ToBase64String($bytes);
}

# alias = gls
function get-locationstack {
  $arr = (get-location -stack).ToArray();

  for ($i = 0; $i -lt $arr.Length; $i++) {
    [pscustomobject] @{
      "i"    = $i + 1;
      "path" = $arr[$i]
    };
  }
}

# need build tools and SSDT for all the database project things
$MSBUILD_EXE = "C:/Program Files (x86)/Microsoft Visual Studio/2019/Community/MSBuild/Current/bin/MSBuild.exe"

function build {
  [cmdletbinding()]
  param(
    [parameter(mandatory = $true, position = 0)] $sln,
    [parameter(
      position = 1,
      ValueFromRemainingArguments = $true)] $rest_args
  )

  & $MSBUILD_EXE $sln /m /v:m $rest_args
}

# alias = build
function build-dir {
  dotnet build
}

function ldenv ([switch] $secure) {
  if (test-path "./.env") {
    $lines = if ($secure) { (unprotect .env).Split("`n") } else { cat .env }
    $lines | % {
      $idx = $_.IndexOf("=");
      $key = $_.Substring(0, $idx);
      $val = $_.Substring($idx + 1);

      [environment]::SetEnvironmentVariable($key, $val.Trim(), "Process");
      "$key set"
    }
  }
  else {
    "no .env file found in the current directory"
  }
}

# if we pass in a script block, turn this into a push/pop pair
# otherwise just pushd and list the directory.
function push_location ($dir, [scriptblock] $block) {
  $dir = [System.Environment]::ExpandEnvironmentVariables($dir);

  Push-Location $dir

  if ($block) {
    try {
      $block.Invoke();
    }
    catch {
      throw $_
    }
    finally {
      Pop-Location
    }
  } else {
    list_directory
  }
}

# alias = b
function go-back($n = 1) {
  while ($n-- -gt 0) {
    try { popd; }
    catch { }
  }
}

function fe {
  rg --files | fzf | edit
}

function cdf {
  $dir = (fd --color=never -t d | fzf)

  if ($dir) {
    cd $dir
  }
}

function edit {
  [cmdletbinding()]
  param(
    [parameter(ValueFromPipeline)]
    [string[]]$stdin
  )

  code $stdin
}

function edit-todo {
  [CmdletBinding()] [alias("ted")] param()

  edit "$env:HOMEPATH/.todo.txt"
}

$task_regex = [regex]::new("^(?<dt>\d{4}-\d\d-\d\d):(?<priority>(high|medium|low)):\s*(?<msg>.*)$", "Compiled,IgnoreCase");
function get-todo {
  [alias("tls")]
  [CmdletBinding()]
  param(
    [switch] $h
  )

  $groups = cat ~/.todo.txt | % {
    $m = $task_regex.Match($_);
    if ($m.Success) {
      $created = [datetime] $m.Groups["dt"].Value;
      $age = [datetime]::Today - $created;

      return [pscustomobject] @{
        'age'      = $age.TotalDays;
        'priority' = $m.Groups["priority"].Value;
        'msg'      = $m.Groups["msg"].Value;
      };
    }
  } | Group-Object -prop priority -AsHashTable

  $high = $groups["high"] | sort age -desc
  $medium = $groups["medium"] | sort age -desc
  $low = $groups["low"] | sort age -desc

  foreach ($item in $high) {
    (ansi white "$($item.age)d ago ") + (ansi red "$($item.msg) ")
  }

  foreach ($item in $medium) {
    (ansi white "$($item.age)d ago ") + (ansi yellow "$($item.msg) ")
  }

  foreach ($item in $low) {
    (ansi white "$($item.age)d ago ") + (ansi light_blue "$($item.msg) ")
  }
}

function add-todo {
  [alias("ta")]
  [CmdletBinding()]
  param(
    [parameter(mandatory = $true, position = 0)] $sev,
    [parameter(
      mandatory = $true,
      position = 1,
      ValueFromRemainingArguments = $true)
    ] [string[]] $msg
  )

  function to_sev($s) {
    switch -regex ($s) {
      "h|hi"  { return "high";   }
      "m|med" { return "medium"; }
      default { return "low";    }
    }
  }

  $dt = [datetime]::Now.ToString("yyyy-MM-dd");

  "$($dt):$(to_sev $sev): $([string]::Join(' ', $msg))`n" | out-file -append ~/.todo.txt

  echo "task added!"
}

<#
  .DESCRIPTION
    - saves as utf8
    - strips trailing newlines
    - removes bad ascii characters
    - replace tabs with spaces

  .EXAMPLE
    fix_ws *.sql
#>
function fix_ws($glob) {
  $files = (dir -r $glob)
  $files | Foreach-Object -parallel {
    $name = $_.FullName.replace("\", "/");
    # cache the text to avoid file lock weirdness
    $text = (c:/tools/git/usr/bin/expand.exe -t 2 $name);

    # the out-file accomplishes the re-encoding to utf8-no-bom
    # tr 
    $text |
      tr -cd '[:print:] \r \n' |
      sed 's/[[:blank:]]*$//' |
      out-file $name;
  }
}

function glog {
  git log --oneline
}

function chrome_debug {
  chrome.exe --remote-debugging-port=9222
}

function brb {
  # stop current task
  shutdown /r /t 1
}

function bye {
  # stop current task
  shutdown /s /t 1
}

function top {
  ps | select name, id, vm, cpu | sort -desc cpu | select -f 10 | ft
}

function make_map($array, $key_selector, $key_type_name) {
  $map = @{};
  $key_type = [type]::GetType($key_type_name);

  foreach ($element in $array) {
    $props = $element.PSObject.Properties;
    $prop = $props[$key_selector];

    if ($prop) {
      $key = $prop.Value;
      if ($key_type) {
        # type coercion for later sorting
        $key = [system.convert]::ChangeType($key, $key_type);
      }

      $map.Add($key, $element);
    }
  }
  return $map;
}

function stringify($o) {
  $buff = [system.text.stringbuilder]::new();
  $props = $o.PSObject.Properties;
  # it's an enumerator, so we don't have a definite length.
  foreach($p in $props) {
    $buff.Append($p.Value).Append(", ") | out-null;
  }

  # slice off the last trailing ', '
  $buff.Length = $buff.Length - 2;
  return $buff.ToString()
}

function ps-cli ($name) {
  ps $name | %{ "$($_.Id.ToString().PadRight(8)) $($_.CommandLine)" }
}

function fuzzy-ps ($s) {
  $fzf_args = if ($s) { "-q $s" }
  ps | %{ "$($_.Name) [$($_.Id)] " } | fzf -m $fzf_args
}

function ascii_chart() {
  $table = 32..128 | % { "$($_.ToString().PadRight(3)) = $([char] $_)" }
  for ($i = 0; $i -lt 24; $i++) {
    $c1 = $table[$i];
    $c2 = $table[$i + 24];
    $c3 = $table[$i + 48];
    $c4 = $table[$i + 72];

    write-host "$c1    $c2     $c3     $c4"
  }
}

function fuzzy-kill($s) {
   fuzzy-ps $s | % {
    $id = [regex]::Match($_, "[0-9]+").Value;
    kill -Id $id
  }
}

<#
  produce a list of differences between two lists, based on some key in the object

  currently does NOT work with arrays of primitives

  .EXAMPLE
    $a = @(
      [pscustomobject] @{ id=1; name="bob" };
      [pscustomobject] @{ id=2; name="fred" };
      [pscustomobject] @{ id=4; name="mr4" };
    );

    $b = @(
      [pscustomobject] @{ id=1; name="bob" };
      [pscustomobject] @{ id=2; name="fred" };
      [pscustomobject] @{ id=3; name="mark" };
    );

    diff_lists $a $b "id"
#>
function diff_lists {
  param(
    $a, $b,
    [string] $key_selector,
    [string] $key_type_name = "System.Int32",
    [switch] $full_match,
    [switch] $missing_left,
    [switch] $missing_right
  )

  $key_type = [type] $key_type_name;
  $a_map = make_map $a $key_selector $key_type
  $b_map = make_map $b $key_selector $key_type
  $all_keys = [system.collections.generic.HashSet[object]]::new()

  foreach ($key in $a_map.Keys) {
    $all_keys.Add($key) | out-null
  }

  foreach ($key in $b_map.Keys) {
    $all_keys.Add($key) | out-null
  }

  # lexical sorting is a bit annoying
  foreach ($key in $all_keys | sort) {
    $left = $a_map[$key];
    $right = $b_map[$key];

    $left = if (-not $left) { "NONE" } else { stringify $left }
    $right = if (-not $right) { "NONE" } else { stringify $right }

    if ($full_match -and $left -ne "NONE" -and $right -ne "NONE") {
      "$left <==> $right"
    } else {
      if ($missing_left -and $left -eq "NONE") {
        "$left <==> $right"
      }

      if ($missing_right -and $right -eq "NONE") {
        "$left <==> $right"
      }
    }
  }
}

function lower {
  [cmdletbinding()]
  param(
    [parameter(ValueFromPipeline)]
    [string[]]$stdin
  )

  process {
    foreach ($l in $stdin) {
      if ($l) {
        $l.ToLower();
      }
    }
  }
}

function decode_url_base_64($str) {
  $len = $str.Length;
  $padding = switch($len % 4) {
    2 { 2 }
    3 { 1 }
    default { 0 }
  }

  $total = $len + $padding
  $chars = [Array]::CreateInstance([char], $total);

  for ($i = 0; $i -lt $total; $i++) {
    if ($i -ge $len) {
      $chars[$i] = '=';
      continue;
    }

    $c = $str[$i];

    $chars[$i] = switch($c) {
       '-' { '+' }
       '_' { '/' }
      default { $c }
    }
  }

  return [system.text.encoding]::UTF8.GetString(
    [Convert]::FromBase64String([string]::new($chars)));
}

function encode_url_base_64($str) {
  $encoded = [Convert]::ToBase64String(
    [system.text.encoding]::UTF8.GetBytes($str));

  return $encoded.Replace("=", "").Replace("+", "-").Replace("/", "_");
}

function is_expired($jwt) {
  $parts = $jwt.Split('.');
  $data = decode_url_base_64 $parts[1] | ConvertFrom-Json
  $now = [int]([datetime]::UtcNow - [datetime]::UnixEpoch).TotalSeconds;

  return $now -ge $data.exp;
}

function jwt($token) {
  $parts = $token.Split('.');

  "`nHeader:"
  decode_url_base_64 $parts[0] | jq -C

  "`nData:"
  decode_url_base_64 $parts[1] | jq -C
}

function trim {
  [cmdletbinding()]
  param(
    [parameter(ValueFromPipeline)]
    [string[]]$stdin
  )

  process {
    foreach ($l in $stdin) {
      if ($l) {
        $l.Trim();
      }
    }
  }
}

function index_of_next_char($line, $from, $len) {
  for ($i = $from; $i -lt $len; $i++) {
    if (-not ($line[$i] -match "\s") ) {
      return $i;
    }
  }

  return -1;
}

function trace_on($scenario = "dotnet") {
  $tag = [datetime]::now.toString("yyMMddhh");
  $trace_path = "c:\temp\traces\" + $scenario + "_$tag.nettrace";
  $env:COMPlus_EnableEventPipe=1
  $env:COMPlus_EventPipeOutputPath=$trace_path
  $env:COMPlus_CircularBufferMB=256

  write-host "Traces will be written to: $trace_path"
}

function trace_off($scenario = "dotnet") {
  $env:COMPlus_EnableEventPipe=0
  write-host "dotnet tracing disabled"
}

function ship-it {
  $ticket = read-host "ticket? "
  $environment = read-host "environment? "
  $ticket = read-host "script path? "
  # make a jira ticket with approvals
  # message approvers
  #
}

function format_columns {
  [cmdletbinding()]
  param(
    [parameter(ValueFromPipeline)]
    [string[]] $stdin
  )

  begin {
    # jagged array
    # $map[row][col]=(begin, end)
    $map = @()
  }

  process {
    $r = 0;
    foreach ($line in $stdin) {
      $len = $line.Length;
      $begin = -1;
      $row = @()

      while (1) {
        $begin = index_of_next_char $line ($begin+1) $len

        if ($begin -eq -1) {
          break;
        }

        $end = index_of_next_char $line ($begin+1) $len
        $row += [tuple]::Create($begin, $end);
        $begin = $end;
      }

      $map += $row;
    }
  }

  end {
    foreach ($row in $map) {
      foreach ($col in $row) {
        "$row   $col"
      }
    }
  }
}

function debug_tests([switch] $off) {
  $env:VSTEST_HOST_DEBUG = if ($off) {
    "0"
  } else {
    "1"
  }
  Write-Host "VSTEST_HOST_DEBUG = $($env:VSTEST_HOST_DEBUG)"
}

function dotnet_gc {
  param(
    [Parameter(Mandatory)]
    [ValidateSet("workstation", "server")] $kind);

  switch ($kind) {
    "workstation" { $env:COMPlus_gcServer = 0; break; }
    "server" { $env:COMPlus_gcServer = 1; break; }
  }
}

function dotnet_log {
  param([ValidateSet("err", "warn", "info", "debug")] $label)
  switch ($label) {
    "err"   { $env:Logging__Console__LogLevel__Default="Error"; break; }
    "warn"  { $env:Logging__Console__LogLevel__Default="Warning"; break; }
    "info"  { $env:Logging__Console__LogLevel__Default="Information"; break; }
    "debug" { $env:Logging__Console__LogLevel__Default="Debug"; break; }
  }

  "Logging__Console__LogLevel__Default = $($env:Logging__Console__LogLevel__Default)"
}

function use_nonprod() {
  set-azcontext c15f082d-4698-4134-a8e5-fab135d4ad25
}

function udiff($a, $b) {
  c:/tools/git/usr/bin/diff.exe --unified --color $a $b
}

<#
  .description
    poor-man's word-count implementation

  .outputs
    line_count{TAB}word_count{TAB}char_count

  .parameter chars output the char count only.
  .parameter lines output the line count only.
  .parameter words output the word count only.
#>
function wc {
  [cmdletbinding()]
  param(
    [parameter(ValueFromPipeline)]
    [string[]]$stdin,

    [alias("m")][switch] $chars,
    [alias("l")][switch] $lines,
    [alias("w")][switch] $words
  )

  begin {
    $line_count = 0;
    $word_count = 0;
    $char_count = 0;
    $flags = $chars -or $lines -or $words
  }

  process {
    foreach ($l in $stdin) {
      $line_count++;

      for ($i = 0; $i -lt $l.length; $i++) {
        if ($l[$i] -ne ' ' -and ($i-1 -eq -1 -or $l[$i-1] -eq ' ')) {
          $word_count++;
        }
      }

      $char_count += $l.length;
    }
  }

  end {
    if (-not($flags)) {
      write-host "$line_count`t$word_count`t$char_count"
    }
    else {
      $parts = @()
      if ($lines) {
        $parts += $line_count
      }

      if ($words) {
        $parts += $word_count;
      }

      if ($chars) {
        $parts += $char_count;
      }

      write-host $parts
    }
  }
}

# not portable and also still kinda janky
function watch($dir, [scriptblock] $handler, $debounce = 250) {

  # could also put this in the bg
  try {
    $id = [guid]::NewGuid();
    $f = resolve-path $dir;
    $watcher = [system.io.FileSystemWatcher]::new($f);
    $watcher.IncludeSubDirectories = $true;

    $hit = $false;
    while ($true) {
      # todo: if we want changed files we need a hashset
      # or something. Does not support that at the moment
      $e = $watcher.WaitForChanged("All", $debounce);
      if (-not $e.TimedOut) {
        $hit = $true;
      } else {
        # debounce-lite, if changes have stopped for 250ms
        # THEN trigger the handler
        if ($hit) {
          $hit = $false;
          $handler.Invoke();
        }
      }
    }
  }
  finally {
    $watcher.Dispose();
  }
}

function freemem {
  k devenv
  k code
  k chrome
  k azuredatastudio
  k teams
  k slack
  k outlook
  k winword
  k excel
}

# some commands like query user output "human readable" stdout
# but windows doesn't have a nice awk-like thing built in
# so this is that.
function from_column_aligned_output([string[]] $lines) {
  $headers = $lines[0];

  if ($lines.Length -eq 1) { return; }

  # extract headers and offsets
  $columns = @();
  $begin = 0;
  $end = 0;
  $len = $headers.Length;
  while ($true) {
    # seek column begin
    $begin = $end;
    for (; $begin -lt $len; $begin++) {
      if (-not [char]::IsWhiteSpace($headers[$begin])) {
        break;
      }
    }

    # seek column end
    $end = $begin;
    $consecutive = 0;
    for (; $end -lt $len; $end++) {
      if ([char]::IsWhiteSpace($headers[$end])) {
        $consecutive++;
      }

      if ($consecutive -eq 2) {
        break;
      }
    }

    $columns += new-object psobject -Property @{
      "begin" = $begin;
      "name" = $headers.Substring($begin, $end - $begin).Trim();
    };

    if ($end -eq $len) {
      break;
    }
  }

  $output = @();
  for ($i = 1; $i -lt $lines.Length; $i++) {
    $line = $lines[$i];
    $o = new-object psobject;
    for ($c = 0; $c -lt $columns.Length; $c++) {
      $col = $columns[$c];
      $end = if ($c -eq $columns.Length - 1) { $len } else { $columns[$c+1].begin }
      $size = $end - $col.begin;
      $value = $line.Substring($col.begin, $size).Trim();
      $o | add-member -MemberType NoteProperty -Name $col.name -Value $value;
    }

    $output += $o;
  }

  return $output;
}

Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -AddToHistoryHandler {
  param($cmd)

  if ($cmd -like "*password*") {
    return $false;
  }

  if ($cmd.length -le 2) {
    return $false;
  }

  if ($cmd -eq "cd ..") {
    return $false;
  }

  if ($cmd -match "^git (status|push|pull)") {
    return $false;
  }

  return $true;
};

function lgtm($proj, $author, $repo) {
  $prs = az repos pr list -p "$proj" --reviewer ross.jennings@edhc.com --status active | ConvertFrom-Json
}

function file ($f) {
  [string] $f = (resolve-path $f)
  [system.io.FileInfo]::new($f) | select *
}

<#
  .DESCRIPTION
    applies a -replace operator to the stdin list of files paths
    and renames the files based on the replaced values

  .EXAMPLE
    fd .txt | bulk-rename Icon apple-touch-icon

  .EXAMPLE
    prepend something to the beginning of the filename
    (dir *.sql).Name | bulk-rename "^" "Something."

  .EXAMPLE
    append a number at the end of a file name

    (dir *.sql).Name | bulk-rename "\.sql" "-{0:D2}.sql" -ordinal
#>
function bulk-rename () {
  [cmdletbinding()]
  param(
    [parameter(ValueFromPipeline)]
    [string] $stdin,

    [parameter(mandatory, position = 0)]
    [string] $pattern,

    [parameter(mandatory, position = 1)]
    [string] $replace,

    [switch] $ordinal,
    [switch] $confirm,
  
    [int] $firstOrdinal = 0
  );

  # honestly, what if this just opened vscode and let you change them all in a temp file and close
  # and then the rename happens?

  begin {
    $i = $firstOrdinal;

    if ($edit) {
      $old_names = @();
      $new_names = @();
    }
  }

  process {
    foreach ($p in $stdin) {
      $t = if ($ordinal) { $replace -f $i } else { $replace }
      $new = $p -replace $pattern,$t

      Rename-Item -Path $p -NewName $new -Verbose -Confirm $confirm;
      $i++;
    }
  }
}

# open vscode and change the file names in a temp file and do a multi-rename
function rename-files ([switch] $recurse, [switch] $confirm, [switch] $verbose) {
  $old_names = (dir -Recurse $recurse).FullName;
  $tmp = [system.io.path]::GetTempFileName();

  [system.io.file]::WriteAllLines($tmp, $old_names);
  code $tmp --wait

  try {
    $new_names = [system.io.file]::ReadAllLines($tmp);
    $params = @{
      "Confirm" = $confirm;
      "Verbose" = $verbose;
    };

    for ($i = 0; $i -lt $old_names.Length; $i++) {
      if ($old_names[$i] -ne $new_names[$i]) {
        Rename-Item -Path $old_names[$i] -NewName $new_names[$i] @params;
      }
    }
  }
  finally {
    rm $tmp
  }
}

function use-az-account {
  # the descending sort and fzf are a bit weird
  $accounts = (az account list) | ConvertFrom-JSON
  $selected = $accounts.name | sort -descending | fzf | % {
    $accounts | where name -eq $_ | select -first 1
  };

  $selected

  az account set -s "$($selected.id)"
  set-azcontext -Subscription "$($selected.id)"
}

function pedit {
  edit $profile;
}

$SEC = [System.Security.Cryptography.ProtectedData];
$CURRENT_USER = [System.Security.Cryptography.DataProtectionScope]::CurrentUser;

function protect($f) {
  if ($f.EndsWith(".enc")) {
    throw "don't double-encrypt you dummy";
  }

  $f = (Resolve-Path $f).Path
  $new_file = $f + '.enc';

  $bytes = [system.io.file]::ReadAllBytes($f);
  $cipher = $SEC::Protect($bytes, $null, $CURRENT_USER);
  [system.io.file]::WriteAllBytes($new_file, $cipher);

  write-host "Wrote $new_file"
  Remove-Item $f -Verbose
}

function unprotect($f, [switch] $raw) {
  $f = (Resolve-Path $f).Path
  $bytes = [system.io.file]::ReadAllBytes($f);
  $clear_bytes = $SEC::Unprotect($bytes, $null, $CURRENT_USER);

  if (-not $raw) {
    [system.text.Encoding]::Utf8.GetString($clear_bytes)
  } else {
    $clear_bytes
  }
}

# will only catch the transition, not the whole file
# need something like AWK to really do it accurately for all indents
function grep-mixed-whitespace {
  rg "( \t)|(\t )"
}

# really all indents should be spaces so... any tabs is a ban, basically
function grep-tabs {
  rg "\t";
}

function grep-nonascii {
  rg "[\xA0\x{00FF}-\x{FFFF}]"
}

function my-todos {
  rg "todo\(ross\)"
}

set-alias mt my-todos

Set-PSReadLineKeyHandler -Chord Ctrl+a -Function BeginningOfLine
Set-PSReadLineKeyHandler -Chord Ctrl+e -Function EndOfLine

## AUTO_CD
$ExecutionContext.InvokeCommand.CommandNotFoundAction = {
  param($cmd, $e);

  # powershell to resolve a get-foo resolving 'foo'
  if ($cmd.StartsWith("get-")) { return }

  # todo: maybe try to resolve with Z!?
  $path = [system.io.path]::combine($pwd.Path, $cmd);
  $handler = if ([system.io.directory]::exists($path)) {
    "cd"
  }
  elseif ([system.io.file]::exists($path)) {
    "bat -A "
  }

  if ($handler) {
    $e.CommandScriptBlock = { & $handler $path }.GetNewClosure();
  }
};

# print the managed DLLs referenced by a dll
function net_ldd( $f ) {
  $resolved = resolve-path $f
  $asm = [system.reflection.assembly]::LoadFile($resolved);

  foreach ($m in $asm.GetReferencedAssemblies()) {
    $m.FullName
  }
}

# no sed, just a big dumb find/replace
function bulk_replace($glob, $file) {
  $replacements = cat $file | %{ $_.split(' ') };
  $len = $replacements.length / 2;
  "running $len replacements over all file matching $glob"

  dir -file -r $glob | % {
    $file_name = $_.FullName;
    $text = [system.io.file]::ReadAllText($file_name);
    $did_replace = $false;

    if ($text -and $text.length -gt 0) {
      for ($i = 0; $i -lt $len; $i++) {
        $off = $i * 2;
        $old = $replacements[$off];
        $new = $replacements[$off + 1];

        if ($text.contains($old)) {
          $did_replace = $true;
          $text = $text.replace($old, $new);

          write-debug "$($file_name):replaced $old with $new"
        }
      }

      if ($did_replace) {
        $text | out-file $file_name
      }
    } else {
      "WARN: $file_name no text!?"
    }
  }
}

function debug_tools {
  param(
    [Parameter(Position=0)]
    [ValidateSet('32','64')]
    [string] $v
  );

  $dbg_32 = "c:/Program Files (x86)/Windows Kits/10/Debuggers/x86;";
  $dbg_64 = "c:/Program Files (x86)/Windows Kits/10/Debuggers/x64;";

  if ($v -eq "64") {
    $env:PATH = $env:PATH.Replace($dbg_32, "") + $dbg_64;
  }
  else {
    $env:PATH = $env:PATH.Replace($dbg_64, "") + $dbg_32;
  }
}

function clean-path ($remove) {
  $parts = $env:PATH -split ';' | lower | sort | unique;
  $new_path = "";

  foreach ($p in $parts) {
    if ($p -and -not ($p -match $remove)) {
      $new_path += "$p;";
    }
    else {
      write-Debug "clean-path: removing $p"
    }
  }

  $env:PATH = $new_path.Trim();
}

set-alias fk fuzzy-kill
set-alias k pskill

set-alias e edit
set-alias sql "c:/tools/sqlcmd.exe"
set-alias localdb "C:/Program Files/Microsoft SQL Server/150/Tools/Binn/SqlLocalDB.exe";
set-alias sql_package "C:/Program Files (x86)/Microsoft Visual Studio/2019/*/Common7/IDE/Extensions/Microsoft/SQLDB/DAC/150/sqlpackage.exe"
set-alias msbuild "C:/Program Files (x86)/Microsoft Visual Studio/2019/*/MSBuild/Current/bin/MSBuild.exe"
set-alias vstest "C:/Program Files (x86)/Microsoft Visual Studio/2019/*/Common7/IDE/Extensions/TestPlatform/vstest.console.exe"
set-alias build build-dir
set-alias which where.exe
set-alias less more
set-alias gls get-locationstack
set-alias b go-back
set-alias ls list_directory -Option AllScope
set-alias showpr az-show-pr
set-alias mkbr git-make-remote-branch
set-alias co git-checkout-interactive
set-alias gs git-status
set-alias caz change-az-account;

set-alias gd git-diff
set-alias gdc git-diff-cached

set-alias curl curl.exe -Option AllScope
set-alias iis "C:\Program Files\IIS Express\iisexpress.exe"

# register completions
c:\tools\_fd.ps1
c:\tools\_az.ps1
c:\tools\_sqlcmd.ps1

. c:\tools\db-deploy.ps1
