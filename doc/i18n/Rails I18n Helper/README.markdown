# Sublime Text 2 plugin: Rails I18n Helper

Makes creating Rails Internationalization (I18n) easier. Select text and create the key in en.yml and key to translation 

## Shortcut Keys

**Windows / OSX / Linux:**

 * `ctrl+alt+x` 

## How to Use

you have to install yaml library for python. On linux:
``` bash
sudo apt-get install python-yaml
```
The following instructions are all done inside your Rails Apps's view (.erb, .haml) files.

Select the string you wish to put into a Internationalization yml file and hit the shortcut key

##### Example:
file path: rails_root/app/views/users/show.html.haml
``` bash
= link_to new_user_path do
  %i{class: 'icon-plus'}
  Add user
```
you have to select "Add user" and click the shortcut key. receive:

``` bash
= link_to new_user_path do
  %i{class: 'icon-plus'}
  =t(".add_user")
```
and in rails_root/config/locales/en.yml
``` bash
en:
  users:
    show:
      add_user: Add user
```

## Limitations

This plugin has support for the following file types:
 * .erb
 * .html

This list will possibly be expanded in the future. If you would like support for other files, please submit an issue or an pull request.


## Installation

You have two options, we'll start with the preferred installation method, Package Control.


### Package Control

The easiest and preferred way to of installing this plugin is with [Package Control](http://wbond.net/sublime\_packages/package\_control).

 * Ensure Package Control is installed and Sublime Text 2 has been restarted.
 * Open the Command Palette (Command+Shift+P on OS X, Control+Shift+P on Linux/Windows).
 * Select "Package Control: Install Package"
 * Select Rails I18n Helper when the list appears.

Package Control will automatically keep Rails I18n Helper up to date with the latest version.


### Git

This method required a little more work, but simply clone this repo into your Sublime Text 2 Package directory.

``` bash
$ git clone git://github.com/adeptus/rails-i18n-helper.git "Rails I18n Helper"
```

Further instructions below.

#### Windows XP, 7 and 8
Execute the commands below one by one in your Command prompt.

``` bash
$ cd "%APPDATA%\Sublime Text 2\Packages"
$ git clone git://github.com/adeptus/rails-i18n-helper.git "Rails I18n Helper"
```

#### Linux
Execute the commands below one by one in your terminal.

``` bash
$ cd ~/.config/sublime-text-2/Packages/
$ git clone git://github.com/adeptus/rails-i18n-helper.git "Rails I18n Helper"
```
