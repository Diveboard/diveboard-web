class InitTableAreas < ActiveRecord::Migration
  def up
    Rake::Task["area_detection:launch"].execute
    Rake::Task["area:attendance"].execute
  end

  def down
    ActiveRecord::Base.connection.execute('ALTER TABLE areas AUTO_INCREMENT = 1')
  end
end
