class GetRidOfEanxOnTanks < ActiveRecord::Migration
  def up
    execute "ALTER TABLE tanks add column gas_type enum('air','nitrox','trimix')"
    execute "update tanks set o2=21, n2=79, he=0, gas_type='air' where gas='air'"
    execute "update tanks set o2=32, n2=68, he=0, gas_type='nitrox' where gas='EANx32'"
    execute "update tanks set o2=36, n2=64, he=0, gas_type='nitrox' where gas='EANx36'"
    execute "update tanks set o2=40, n2=60, he=0, gas_type='nitrox' where gas='EANx40'"
    execute "update tanks set gas_type='trimix' where he IS NOT NULL and he > 0"
    execute "update tanks set gas_type='air' where gas_type is null and o2=21 and n2=79 and he=0"
    execute "update tanks set gas_type='nitrox' where gas_type is null"
    execute "ALTER TABLE tanks drop column gas"
  end

  def down
    execute "ALTER TABLE tanks add column gas enum('air','EANx32','EANx36','EANx40','custom')"
    execute "update tanks set gas='air' where gas_type='air'"
    execute "update tanks set gas='custom' where gas is null"
    execute "ALTER TABLE tanks drop column gas_type"
  end
end
