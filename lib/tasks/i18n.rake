require 'find'

namespace :i18n do

  desc "Downloading all the i18n files from onesky"
  task :onesky_get  => :environment do |t, args|
    project_id = 17859
    default_locale = :en
    locales = ['zh-CN', :fr, :en, :es]
    puts "Will be fetching locales: #{locales.to_s}"
    t=Time.now.to_i
    p = { api_key: "ZfF7zS5zb0eS987E7VfaikhtEVxClF1b", timestamp: t, dev_hash: Digest::MD5.hexdigest("#{t}Bz8ghtm7at4OQj4oE8YLdxfhltNe8Ahz") }
    r = Curl.get("https://platform.api.onesky.io/1/projects/#{project_id}/files", p) do |http|
      http.headers['Content-Type'] = 'application/json'
      http.encoding = "UTF-8"
    end
    files = JSON.parse(r.body)['data']

    locales.each do |locale|
      files.each do |file|
        filename = file['file_name']
        t=Time.now.to_i
        puts "#{locale}/#{filename}"
        p = { api_key: "ZfF7zS5zb0eS987E7VfaikhtEVxClF1b", timestamp: t, dev_hash: Digest::MD5.hexdigest("#{t}Bz8ghtm7at4OQj4oE8YLdxfhltNe8Ahz") }
        p[:locale] = locale
        p[:source_file_name] = filename
        r = Curl.get("https://platform.api.onesky.io/1/projects/#{project_id}/translations", p) do |http|
          http.headers['Content-Type'] = 'application/json'
          http.encoding = "UTF-8"
        end
        if r.status != "200 OK" then
          puts "Error fetching file '#{filename}' in locale '#{locale}': #{r.status}"
          next
        end
        Dir.mkdir "config/locales" rescue nil
        Dir.mkdir "config/locales/#{locale}" rescue nil
        File.open("config/locales/#{locale}/#{filename}", "w") do |f|
          f.write r.body.force_encoding('UTF-8')
        end
      end
    end
  end

  desc "Uploading all the default i18n files to onesky"
  task :onesky_send_default  => :environment do |t, args|
    project_id = 17859

    sending_locales = [:en, :fr, :es]

    sending_locales.each do |locale|
      Find.find("config/locales/#{locale}").each do |filename|
        next if FileTest.directory?(filename)
        t=Time.now.to_i
        puts filename
        p = { api_key: "ZfF7zS5zb0eS987E7VfaikhtEVxClF1b", timestamp: t, dev_hash: Digest::MD5.hexdigest("#{t}Bz8ghtm7at4OQj4oE8YLdxfhltNe8Ahz") }
        p[:locale] = locale
        p[:file] = filename
        p[:file_format] = 'RUBY_YML'
        p[:is_keeping_all_strings] = "true"
        c = Curl::Easy.new("https://platform.api.onesky.io/1/projects/#{project_id}/files")

        post_data = p.map { |k, v| Curl::PostField.content(k.to_s, v.to_s) }
        post_data << Curl::PostField.file('file', filename)

        c.multipart_form_post = true
        c.headers["Expect"] = ''
        c.http_post(post_data)

        if c.status != "201 Created" then
          puts "Error fetching file '#{filename}' in locale '#{locale}': #{c.status}"
          next
        end
      end
    end
  end

end
