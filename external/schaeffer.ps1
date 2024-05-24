# Powershell Profile - EDHC
# Schaeffer Duncan
# Date Modified: 02/16/2022

# Set path to IIS (hopefully yours is in the same place)
set-alias iis "C:\Program Files (x86)\IIS Express\iisexpress.exe"
# Add msbuild to the path (again, hopefully yours is in the same place)

$env:Path += ";C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin"
$npmDirectory = npm config get prefix;
if (-not ($env:Path.Contains($npmDirectory)))
{
    $env:Path += ";$npmDirectory";
}

# For Mobile App development
$env:PATH += "$(yarn global bin);"
$env:JAVA_HOME = "C:\java\jdk-14.0.2";
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jre"
$env:PATH += "C:\java\jdk-14.0.2\bin;";
$ANDROID_SDK = "$($env:LOCALAPPDATA)\Android\Sdk"
$env:PATH += "$ANDROID_SDK/platform-tools;";
$env:PATH += "$ANDROID_SDK/emulator;";
$env:PATH += "$ANDROID_SDK/cmdline-tools/latest/bin;";
$env:ANDROID_SDK_ROOT= $ANDROID_SDK;

# For custom Nuget package stuff
$local_dev_pkg_version = "1.0.99999";


### SET BELOW AS NECESSARY ###
$home_path = "C:\vs";  				        									# Root folder containing all projects
$db_location = "C:\vs\DB-CareHub\CareHub"       								# S+ Database project location
$db_ccd_location = "C:\vs\DB-CCD-CareHub"       								# CCD Database project location
$edhc_location = "C:\vs\EDHC"           						                # EDHC project location
$ccd_location = "C:\vs\CCD"           						                	# CCD project location
$ccd_db_location = "C:\vs\DB-CCD-CareHub"           						    # CCD Database project location
$ch_location = $edhc_location + "\ch-core\core-web-app"           				# CareHub-S+ project location
$cc_location = $edhc_location +  "\ch-core\convert-claims"						# Claims Automation function app project location
$cl_location = $edhc_location + "\web-svcs\edh-carehub-listener"		        # CareHub listener function app project location
$ef_location = $edhc_location + "\tools\ef-scaffold" 	        				# EF Scaffold-S+ tool location
$bu_location = $ch_location + "\buccaneer" 	        							# Buccaneer project location
$ch_ccd_location = $ccd_location + "\web-apps\carehub"           				# CareHub-CCD project location
$fhir_location = $ccd_location + "\functions\FHIR"           					# FHIR function app project location
$bu_ccd_location = $ch_ccd_location + "\buccaneer" 	        					# Buccaneer-CCD project location
$ef_ccd_location = $ccd_location + "\tools\ef-scaffold" 	        			# EF Scaffold-CCD tool location
$mp_location = "C:\vs\MemberPortal"		        								# Member Portal project location
$mi_location = "C:\vs\Misc" 	                                                # Misc project location
$qa_location = "C:\vs\QualityAssurance\CarehubAutomation\CareHubAPIAutomation" 	# Quality Assurance project location
$ma_location = "C:\vs\member-app"		        								# Member mobile app project location
$maa_location = "C:\vs\member-app-api"		        							# Member mobile app API project location
$mac_location = "C:\vs\member-app-common"		        						# Member mobile app common project location
$maf_location = "C:\vs\member-app-functions"		        					# Member mobile app functions project location
$mas_location = "C:\vs\member-app-sql"		        						    # Member mobile app sql project location
$mal_location = "C:\vs\member-app-functions\functions\splus-listener"		    # Member mobile app listener function app location
$desktop_location = "C:\Users\Schaeffer.Duncan\OneDrive - EDHC\Desktop" 		# Desktop folder location
$documents_location = "C:\Users\Schaeffer.Duncan\OneDrive - EDHC\Documents"		# Documents folder location

function prompt
{
    Write-Host ("PS (" + $(get-date -Format "MM/dd/yyyy h:mm:ss tt") + ") " + $(Get-Location) +">") -nonewline -foregroundcolor White
    return " "
}

function pack-all {
    kill-local-edh-nuget-pkgs;
    Push-Location $home_path;

    Push-Location "./member/libs/Edh.Mobile.Data";
    remove-file './bin' 'Edh.Mobile.Data bin';
    pack;
    Pop-Location;

	Push-Location "./member/libs/Edh.Mobile.Data.Extensions.Query";
    remove-file './bin' 'Edh.Mobile.Data.Extensions.Query bin';
    pack;
    Pop-Location;

    Push-Location "./member/libs/Edh.Mobile.Utils";
    remove-file './bin' 'Edh.Mobile.Utils bin';
    pack;
    Pop-Location;

    Push-Location "./member/libs/Integrations/Auth0";
    remove-file './bin' 'Edh.Integrations.Auth0 bin';
    pack;
    Pop-Location;

    Push-Location "./member/libs/Integrations/AuthorizeDotNet";
    remove-file './bin' 'Edh.Integrations.AuthorizeDotNet bin';
    pack;
    Pop-Location;

    Push-Location "./member/libs/Integrations/Firebase";
    remove-file './bin' 'Edh.Integrations.Firebase bin';
    pack;
    Pop-Location;

    Pop-Location;
}
function copy-pkgs {
    $pkgPath = "./bin/Debug/*.nupkg";
    Copy-Item -Path $pkgPath -Destination "C:\temp\pkgs\" -Recurse
}
function pack {
    dotnet pack -p:PackageVersion=$local_dev_pkg_version;
    copy-pkgs;
}
function run-mp {
	iis /site:mp /config:$pwd\applicationhost.config;
}
function build-db {
	msbuild ./CareHub.sln
}
function build-ch {
	ng build
}
function build-ch-prod {
	ng build --prod
}
function run-ch-fe-local {
	ng serve -o --configuration=local
}
function run-ch-fe-localApi {
	ng serve -o --configuration=localApi
}
function run-ch-fe-localSecApi {
	ng serve -o --configuration=local-sec-api
}
function run-ch-fe-default {
	ng serve -o
}
function buccaneer {
	node --nolazy -r ts-node/register buccaneer.ts;
}
function chrome-debug {
	Push-Location $desktop_location;
	& '.\Chrome DEBUG.lnk'
	Pop-Location;
}
function my-notes {
	Push-Location $desktop_location;
	& '.\ImportantNotes.lnk'
	Pop-Location;
}
function kill-local-edh-nuget-pkgs {
    $NUPKG_DIR = "~/.nuget/packages";

    Push-Location ;
    remove-file ($NUPKG_DIR + '/edh.mobile.data') 'edh.mobile.data package';
    remove-file ($NUPKG_DIR + '/edh.mobile.data.extensions.query') 'edh.mobile.data.extensions.query package';
    remove-file ($NUPKG_DIR + '/edh.mobile.utils') 'edh.mobile.utils package';
    remove-file ($NUPKG_DIR + '/edh.mobile.integrations.auth0') 'edh.mobile.integrations.auth0 package';
    remove-file ($NUPKG_DIR + '/edh.mobile.integrations.firebase') 'edh.mobile.integrations.firebase package';
    remove-file ($NUPKG_DIR + '/edh.integrations.authorizedotnet') 'edh.integrations.authorizedotnet package';

    Push-Location $home_path;
    remove-file "./member/libs/Edh.Mobile.Data/bin" 'Edh.Mobile.Data bin';
    remove-file "./member/libs/Edh.Mobile.Data.Extensions.Query/bin" 'Edh.Mobile.Data.Extensions.Query bin';
    remove-file "./member/libs/Edh.Mobile.Utils/bin" 'Edh.Mobile.Utils bin';
    remove-file "./member/libs/Integrations/Auth0/bin" 'Edh.Mobile.Auth0 bin';
    remove-file "./member/libs/Integrations/AuthorizeDotNet/bin" 'Edh.Integrations.AuthorizeDotNet bin';
    remove-file "./member/libs/Integrations/Firebase/bin" 'Edh.Integrations.Firebase bin';
    Pop-Location;

    Pop-Location;
}
function remove-file($path, $friendlyName)
{
    if (Test-Path -Path $path) {
        Write-Host "$friendlyName exists, removing..."
        Remove-Item -Recurse $path;
        Write-Host "$friendlyName removed..."
    } else {
        Write-Host "$friendlyName doesn't exist."
    }
}
function build {
	# These are flags, sent in like so: build -db -ch -p -bu -mp
	  param(
		# builds database project
	    [switch] $db,
		# builds carehub
		[switch] $ch,
		# builds carehub prod
		[switch] $p,
		# runs buccaneer
		[switch] $bu,
		# builds member portal
		[switch] $mp
	  )
  	if($db) {
		Push-Location $db_location;
		build-db;
		Pop-Location;
	}
	if($ch) {
		Push-Location $ch_location;
		if ($p) {
			build-ch-prod;
		} else {
			build-ch;
		}
		Pop-Location;
	}
	if ($bu) {
		Push-Location $bu_location;
		buccaneer;
		Pop-Location;
	}
	if ($mp) {
		Push-Location $mp_location
		msbuild
		Pop-Location;
	}
}
function run {
	param(
		# runs commands in CCD location instead of EDHC
		[switch] $ccd,
		# runs CareHub-S+ with localApi config
		[switch] $ch,
		# runs member portal
		[switch] $mp,
		# runs chrome in debug mode
		[switch] $cd,
		# runs CareHub-S+ with local config
		[switch] $l,
		# runs CareHub-S+ with default config
		[switch] $d,
        # runs vs code to member app frontend
		[switch] $maf,
        # runs vs code to member app backend
		[switch] $mab
	  )
	if($ccd) {
		Push-Location $ch_ccd_location;
		if($l) {
			run-ch-fe-localSecApi;
		}
		if($d) {
			run-ch-fe-default;
		} else {
			run-ch-fe-localApi;
		}
		Pop-Location;
	}
	if($ch) {
		Push-Location $ch_location;
		if($l) {
			run-ch-fe-local;
		} else {
			run-ch-fe-localApi;
		}
		Pop-Location;
	}
	if($mp) {
		Push-Location $home_path;
		run-mp;
		Pop-Location;
	}
	if($cd) {
		chrome-debug;
	}
    if($mp) {
		Push-Location $mp_location;
		run-mp;
		Pop-Location;
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

