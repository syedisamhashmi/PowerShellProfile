# Introduction

Tools that all developers can utilize to increase productivity.

# Getting Started

> **⚠️ Warning**
>
> You MUST install the Powershell from the Microsoft store.
>
> The regular powershell that comes with Windows is not fully
> compatible with these scripts.
>
> It WILL throw errors.
> ![install](/docs/powershell_download.png)

After downloading the proper powershell - run the `init.ps1` script at the root level.

# Description

The initialization script will add various scripts to your path to enable you to utilize
various tooling productively as a developer.

# Auto updates

Upon first load, the tool may ask if you would like to partake in auto-updates.
If you would like to automatically receive updates to all tools, simply agree.
If you say no, or change your mind later, edit the file "config.txt" (⚠️ NOT `config.txt.sample`)
within this directory and enable `AutoUpdates` to `True` or `False` under the `UserPreferences` section accordingly.
This file is ignored by git, if you need a reference, please check `config.txt.sample`.

# Config

AutoUpdates can be configured via `UserPreferences`.`AutoUpdates`
CheckPeriod can either be `daily`, `weekly`, or `session`.
