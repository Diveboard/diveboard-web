module Jammit
  # Generates the server-absolute URL to an asset package.
  def self.asset_url_with_lb(package, extension, suffix=nil, mtime=nil)
    asset_name = filename(package, extension, suffix)
    mtime ||= File.mtime("public/assets/#{asset_name}") rescue Time.now
    timestamp = mtime ? "?v=#{mtime.to_i}" : ''
    ::HtmlHelper.lbroot( "/#{package_path}/#{asset_name}#{timestamp}" ).gsub(/^https?:/, "")
  end

end


class << Jammit
  alias :asset_url_without_lb :asset_url
  alias :asset_url :asset_url_with_lb
end
