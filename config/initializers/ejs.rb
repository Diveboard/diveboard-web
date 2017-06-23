# Template Handler
require 'action_view'
require 'active_support'
require 'ejs'
require 'i18n-js'
require "execjs"

EJS.evaluation_pattern = /<\$([\s\S]+?)\$>/
EJS.interpolation_pattern = /<\$=([\s\S]+?)\$>/
EJS.escape_pattern = /<\$-([\s\S]+?)\$>/

ActionView::Template.register_template_handler("ejs", EJSHandler)
