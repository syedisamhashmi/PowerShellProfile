#!/usr/bin/bash
# Prints out the usage of the script
usage()
{
  echo 'Usage: '$0 $'[-h]\n\n'; exit 1; 
}

while getopts ":h:c" option;
do
  case $option in
    # b)
    #   base=${OPTARG};
    #   echo "Using new base of: $base";
    #   ;;
    h)
      usage
      ;;
    # c)
    #   config_only=true;
    #   echo "Only configuring"
    #   ;;
    *)
      usage
      ;;
  esac
done

#----------------------------------------------
# Where all cloned repositories live.
export repo_dir=$(git rev-parse --show-toplevel)
export arch_dir=$(git rev-parse --show-toplevel)/arch
export aur_dir=$(git rev-parse --show-toplevel)/../aur
pushd $aur_dir > /dev/null
aur_dir=$(pwd)
popd > /dev/null

echo "repo: $repo_dir"
echo "aur: $aur_dir"
echo "arch_dir: $arch_dir"

export config_files_directory=$arch_dir/conf
export packages_files_directory=$arch_dir/packages
export scripts_files_directory=$arch_dir/setup/scripts


# #----------------------------------------------
# #Go to the config files directory, for relative directory retrieval.
# echo "Adding configs from: $config_files_directory"

if ! [ -d "${config_files_directory}" ];
then
  echo "Config files directory not found: $config_files_directory"
  exit 1;
else
  pushd $config_files_directory > /dev/null
  config_directories=$(find $PWD -type d | awk -v CURR_DIR="$PWD" '{ if ($0 != CURR_DIR) print $0 }')
  for cfg_directory in $config_directories
  do
    echo $'\nFound config directory: '$cfg_directory
    for cfg_script in $cfg_directory/*.sh
    do 
      if [ -e "${cfg_script}" ];
      then
        echo $'Executing configuration script ' $cfg_script
        # TODO: Not running for now, I don't want to break anything :)
        # sh $cfg_script
      fi
    done
  done
  popd > /dev/null
fi
# echo "Popping directory $config_files_directory"
popd > /dev/null

pushd $packages_files_directory
package_directories=$(find $PWD -type d | awk -v CURR_DIR="$PWD" '{ if ($0 != CURR_DIR) print $0 }')
for pkg_directory in $package_directories
do
	echo $'\nFound package directory: '$pkg_directory
	for pkg_script in $pkg_directory/*.sh
	do
		echo $'Executing package script ' $pkg_script
    # TODO: Not running for now, I don't want to break anything :)
		# sh $pkg_script
	done
done
popd > /dev/null


# ----------------------------------------------
# Scripts
# ----------------------------------------------
pushd $scripts_files_directory
for script in $scripts_files_directory/*.sh
do
  echo $'Executing script ' $script
  # TODO: Not running for now, I don't want to break anything :)
  #sh $script
done
popd > /dev/null


