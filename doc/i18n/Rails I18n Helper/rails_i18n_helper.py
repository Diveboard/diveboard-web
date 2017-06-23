import sublime, sublime_plugin
import os, re, textwrap
from . import yaml
import codecs


def is_rails_view(path):
  return True if ( re.search(r"(?:\\|\/)app(?:\\|\/)(views|assets)$", path) ) else False

class RailsI18nHelperCommand(sublime_plugin.TextCommand):
  edit         = None

  def run(self, edit):
    self.edit         = edit
    #self.prompt_scope()
    self.get_selected_text(".".join(self.split_path()))

  # Get the selected text
  def get_selected_text(self, scope):
    for region in self.view.sel():
      if not region.empty():
        selected_text = self.view.substr(region)
        self.create_text_and_key(selected_text, scope)
      else:
        self.display_message("First you have to select text!")

  def prompt_scope(self):
    sublime.active_window().show_input_panel("Scope - use dots '.' as delimiter:", ".".join(self.split_path()), self.on_scope, None, None)
    pass

  def on_scope(self, text):
    self.get_selected_text(text)

  # Create the file
  def create_text_and_key(self, selected_text, scope):
    # The source file's pathreload
    source = self.view.file_name()

    key_link = selected_text.strip(" \n\t")
    key_link_bak = key_link

    yml_file = "web.yml"

    if source.endswith(".js") or source.endswith(".ejs"):
      yml_file = "js.yml"
      if re.search(r'^".*"$', key_link):
        key_link = key_link.strip('"')
        selected_text = selected_text.strip('"')
      elif re.search(r"^'.*'$", key_link):
        key_link = key_link.strip("'")
        selected_text = selected_text.strip("'")

    # Get the file path
    source_path      = os.path.dirname(source)
    fileName         = os.path.basename(source).replace(".html", "").replace(".erb", "").replace(".ejs", "").replace(".jst", "").replace(".js", "").replace(".haml", "").strip("_")
    rails_view_path  = os.path.dirname(source_path)
    rails_view_path2 = os.path.dirname(rails_view_path)
    yaml_dict = {}
    root_path = os.path.abspath(source_path)
    prev_path = None

    while not os.path.exists(root_path+"/config/locales/en/"+yml_file) and root_path != prev_path:
      prev_path = root_path
      root_path = os.path.dirname(root_path)

    target_file = root_path+"/config/locales/en/"+yml_file
    if not os.path.exists(target_file):
      self.display_message(target_file + " not exist")
      return

    yaml_dict = yaml.load(codecs.open(target_file, 'r', 'utf-8'))

    #sublime.message_dialog(str(target_file))

    h = yaml_dict['en']
    for key in scope.split("."):
      if key not in h:
        h[key] = {}
      h = h[key]

    h[key_link] = selected_text

    #insert key to view file
    stream = codecs.open(target_file, 'w', 'utf-8')
    yaml.dump(yaml_dict, stream, default_flow_style=False)
    stream.close()
    self.insert_key_link(key_link, source, scope)



  def split_path(self):
    # Get the file path
    source = self.view.file_name()
    source_path      = os.path.dirname(source)
    fileName         = os.path.basename(source).replace(".html", "").replace(".erb", "").replace(".ejs", "").replace(".jst", "").replace(".js", "").replace(".haml", "").strip("_")
    rails_view_path  = os.path.dirname(source_path)
    rails_view_path2 = os.path.dirname(rails_view_path)

    if source.endswith(".js") or source.endswith(".ejs"):
      return ["js", fileName]

    if is_rails_view(source_path):
      return [fileName]

    if is_rails_view(rails_view_path):
      key = source_path.replace(rails_view_path, "").strip("/").replace(".", "_")
      return [key, fileName]

    if is_rails_view(rails_view_path2):
      key = rails_view_path.replace(rails_view_path2, "").strip("/").replace(".", "_")
      key2 = source_path.replace(rails_view_path, "").strip("/").replace(".", "_")
      return [key2, key, fileName]



  # Insert the key code
  def insert_key_link(self, key_link, source, scope):
    #sublime.message_dialog(key_link)
    # Handle different file types
    if source.endswith(".haml"):
      code_replace = '= it("{0}", scope: '+str(scope.split('.'))+')'
    elif source.endswith( (".erb") ):
      code_replace = '<%= it("{0}", scope: '+str(scope.split('.'))+') %>'
    elif source.endswith(".js"):
      code_replace = 'I18n.t(['+ ",".join(map( (lambda x: '"'+x.replace('"', '\\"')+'"'), scope.split('.')+["{0}"] ) ) +'])'
    elif source.endswith(".ejs"):
      code_replace = '<$= I18n.t(['+ ",".join(map( (lambda x: '"'+x.replace('"', '\\"')+'"'), scope.split('.')+["{0}"] ) ) +']) $>'
    else:
      self.display_message("You're using an unsupported file type! The string was created in yml but not, linked automatically.")

    # Replace the selected text with the appropriate key code
    v = sublime.active_window().active_view()
    for region in self.view.sel():
      if region.empty():
        point = region.begin()
        v.insert(self.edit, point, code_replace.format(key_link.replace('"', '\\"')) )
      else:
        v.replace(self.edit, region, code_replace.format(key_link.replace('"', '\\"')) )

    self.display_message(key_link + ' Created Successfully!')


  def display_message(self, value):
      sublime.active_window().active_view().set_status("create_i18_from_text", value)
