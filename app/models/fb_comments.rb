class FbComments < ActiveRecord::Base

  belongs_to :source, polymorphic: true

  def self.update_fb_comments object, raw_data

    target = nil
    FbComments.where(:source_type => object.class.name).where(:source_id => object.id).each_with_index do |e,i|
      e.destroy if i!=0
      target = e if i == 0
    end
    if target.nil?
      target = FbComments.create{|e|
        e.source_type = object.class.name
        e.source_id = object.id
      }
    end
    target.raw_data = raw_data
    target.updated_at = Time.now
    target.save!
  end

  def update_fb_comments
    return source.update_fb_comments_without_delay if source.respond_to? :update_fb_comments_without_delay
    return source.update_fb_comments if source.respond_to? :update_fb_comments
    return nil
  end

end
