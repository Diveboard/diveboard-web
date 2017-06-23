class ChangeUnitSettings < ActiveRecord::Migration
  def up
    users = Media.select_all_sanitized("select id, settings from users")
    users.each do |u|
      settings = JSON.parse(u['settings']) rescue {}
      next unless settings['units'].is_a? Hash
      next unless settings['units']['distance'] == 'Km' || settings['units']['weight'] == 'Kg'
      settings['units']['distance'] = 'm' if settings['units']['distance']=='Km'
      settings['units']['weight'] = 'kg' if settings['units']['weight']=='Kg'
      Media.execute_sanitized "update users set settings=:s where id=:id", id: u['id'], s: JSON.unparse(settings)
    end
  end

  def down
    users = Media.select_all_sanitized("select id, settings from users")
    users.each do |u|
      settings = JSON.parse(u['settings']) rescue {}
      next unless settings['units'].is_a? Hash
      next unless settings['units']['distance'] == 'm' || settings['units']['weight'] == 'kg'
      settings['units']['distance'] = 'Km' if settings['units']['distance']=='m'
      settings['units']['weight'] = 'Kg' if settings['units']['weight']=='kg'
      Media.execute_sanitized "update users set settings=:s where id=:id", id: u['id'], s: JSON.unparse(settings)
    end
  end
end
