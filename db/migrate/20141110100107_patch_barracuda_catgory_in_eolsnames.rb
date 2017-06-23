class PatchBarracudaCatgoryInEolsnames < ActiveRecord::Migration
  def up
    barracuda = Eolsname.where("category_inspire = 'baracuda'")
    barracuda.each do |b|
      b.category_inspire = "barracuda"
      b.save
    end
    barracuda = AreaCategory.where("category = 'baracuda'")
    barracuda.each do |b|
      b.category = "barracuda"
      b.save
    end
  end

  def down
  end
end
