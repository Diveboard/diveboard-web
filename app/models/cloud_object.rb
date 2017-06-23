require 'filemagic'
require 'google_storage'

class CloudObject < ActiveRecord::Base
  after_initialize :get_client
  before_destroy :remove

  @@client = nil
  def get_client
    # OK, it's dirty... but it's the only way that the object won't get thrown at every request in dev env
    # If the client were re-created each time, it would overflow the quota of authent
    @@client ||= Thread.main[:gs_client] || GoogleStorage::Client.new({:timeout => 180, :debug => false}) rescue nil
    Thread.main[:gs_client] ||= @@client
  end

  def self.create_bucket(bucket)
    client = GoogleStorage::Client.new
    client.create_bucket(bucket)
  end

  def self.bucket_info(bucket)
    client = GoogleStorage::Client.new
    marker = nil
    continue = true
    size = 0
    count = 0
    while continue do
      continue = false
      Rails.logger.debug "request to google from '#{marker}'"
      info = client.get_bucket(bucket, {:params => {'max-keys' => 10000, 'marker' => marker}})
      info[:contents]=[] if info[:contents].nil?
      Rails.logger.debug "received #{info[:contents].count} elements"
      info[:contents].each do |file|
        size += file['Size'].to_i
        count += 1
      end
      marker = info[:raw]["ListBucketResult"]["NextMarker"]
      continue = !marker.nil?
    end

    return {
        :size => size,
        :count => count
      }
  end

  def self.orphans
    CloudObject.where('id not in (
      SELECT cloud_objects.id FROM `cloud_objects`, pictures p where cloud_objects.id = p.thumb_id
      UNION ALL SELECT cloud_objects.id FROM `cloud_objects`, pictures p where cloud_objects.id = p.small_id
      UNION ALL SELECT cloud_objects.id FROM `cloud_objects`, pictures p where cloud_objects.id = p.medium_id
      UNION ALL SELECT cloud_objects.id FROM `cloud_objects`, pictures p where cloud_objects.id = p.large_id
      UNION ALL SELECT cloud_objects.id FROM `cloud_objects`, pictures p where cloud_objects.id = p.large_fb_id
      UNION ALL SELECT cloud_objects.id FROM `cloud_objects`, pictures p where cloud_objects.id = p.original_image_id
      UNION ALL SELECT cloud_objects.id FROM `cloud_objects`, pictures p where cloud_objects.id = p.original_video_id
      UNION ALL SELECT cloud_objects.id FROM `cloud_objects`, pictures p where cloud_objects.id = p.mp4
      UNION ALL SELECT cloud_objects.id FROM `cloud_objects`, pictures p where cloud_objects.id = p.webm
    )')
  end

  def self.ghosts(bucket)
    all_stored_objects = CloudObject.all.group_by &:path
    client = GoogleStorage::Client.new

    marker = nil
    continue = true
    missing = []
    size = 0
    while continue do
      continue = false
      Rails.logger.debug "request to google from '#{marker}'"
      info = client.get_bucket(bucket, {:params => {'max-keys' => 10000, 'marker' => marker}})
      info[:contents]=[] if info[:contents].nil?
      Rails.logger.debug "received #{info[:contents].count} elements"

      info[:contents].each do |file|
        next if file['Key'].match(/_\$folder\$$/)
        if all_stored_objects[file['Key']].nil? then
          missing.push file
          size += file['Size'].to_i
        else
          all_stored_objects[file['Key']] = []
        end
      end

      marker = info[:raw]["ListBucketResult"]["NextMarker"]
      continue = !marker.nil?
    end

    notfound = all_stored_objects.flatten.flatten

    return {
        :size => size,
        :count => missing.length,
        :missing => missing,
        :notfound => notfound
      }
  end

  def initialize(src_path, dst_bucket_symbol, dst_path)
    super(nil)

    Rails.logger.debug "New cloud object in #{dst_bucket_symbol} requested for #{src_path}"

    if Rails.application.config.google_cloud_buckets[dst_bucket_symbol].is_a? Array then
      bucket_idx = Random.new.rand(Rails.application.config.google_cloud_buckets[dst_bucket_symbol].length)
      dst_bucket = Rails.application.config.google_cloud_buckets[dst_bucket_symbol][bucket_idx]
    else
      dst_bucket = Rails.application.config.google_cloud_buckets[dst_bucket_symbol]
    end

    Rails.logger.debug "Bucket #{dst_bucket} chosen"

    get_client

    # Getting the real file type and finding a file extension for that type
    fm = FileMagic.new(FileMagic::MAGIC_MIME_TYPE)
    content_type = fm.file(src_path)
    content_ext = Mime::Type.file_extension_of(content_type)

    ##if the content_ext is .empty then sth went wrong
    #raise "Cannot identify the mime type" if content_ext == "empty" || content_ext == "stream"

    # if no dst_path is provided, just dump the file at the root of the bucket
    if dst_path.nil? then
      dst_path = find_name(dst_bucket, {:extension => content_ext})

    elsif dst_path.class == Hash then
      options = dst_path.clone
      options[:extension] = options[:extension] || content_ext
      dst_path = find_name(dst_bucket, options)

    elsif dst_path.class == String && CloudObject.where(:bucket => dst_bucket, :path => dst_path).count > 0 then
      raise DBTechnicalError.new "Object already exists. Choose another name or bucket."

    else
      raise DBTechnicalError.new "Invalid path descriptor"
    end


    # Uploading the file
    begin
      logger.debug "Uploading to google : #{dst_bucket}, #{dst_path}, #{src_path}, #{content_type}"
      r = @@client.upload_object(dst_bucket, dst_path, :path_to_file => src_path, :content_type => content_type , :x_goog_acl => 'public-read', :headers => {'Cache-Control' => 'public, max-age=315360000'})
      logger.debug r
      if !r['Error'].nil? && r['Error']['Code'].match(/AuthenticationRequired/) then
        logger.debug "Retrying after AuthenticationRequired"
        r = @@client.upload_object(dst_bucket, dst_path, :path_to_file => src_path, :content_type => content_type , :x_goog_acl => 'public-read', :headers => {'Cache-Control' => 'public, max-age=315360000'})
        logger.debug r
      end
      raise DBTechnicalError.new "Error while uploading picture to google", error: r['Error'].to_s if !r['Error'].nil?

      self.bucket = dst_bucket
      self.path = dst_path
      self.etag = Digest::MD5.file(src_path).to_s
      self.size = File.size src_path

      save!
    # If something went wrong we don't want to pollute the storage
    rescue
      logger.warn "Something wnet wrong wile uploading file : #{$!.message}"
      logger.debug $!.backtrace
      begin
        if Rails.application.config.google_cloud_buckets.values.flatten.include? dst_bucket then
          @@client.delete_object(dst_bucket, dst_path)
          logger.debug "Object '#{dst_path}' correctly deleted from bucket #{dst_bucket} after exception"
        else
          logger.warn "Object '#{dst_path}' has NOT been deleted from bucket #{dst_bucket} because this bucket does not belong to us !"
        end
      rescue
        logger.debug "Error while deleting object '#{dst_path}' from bucket #{dst_bucket} : #{$!.message}"
      end
      raise
    end

  end

  def check

    info = @@client.object_head(self.bucket, self.path)

    info.class == Hash && info[:etag] == "\"" + self.etag + "\""
  end

  def meta
    JSON.parse(read_attribute(:meta)) unless read_attribute(:meta).nil?
  end

  def meta=(val)
    if val.nil? then
      write_attribute(:meta, nil)
    else
      write_attribute(:meta, val.to_json)
    end
  end

  def url
    begin
      host = Rails.application.config.google_cloud_hosts[self.bucket] || "commondatastorage.googleapis.com/#{self.bucket}"
      return "http://#{host}/#{self.path}"
    rescue
      return "http://commondatastorage.googleapis.com/#{self.bucket}/#{self.path}"
    end
  end

private
  #These setters should not be accessed
  def bucket=(val)
    write_attribute(:bucket, val)
  end

  def path=(val)
    write_attribute(:path, val)
  end

  def etag=(val)
    write_attribute(:etag, val)
  end

  def size=(val)
    write_attribute(:size, val)
  end

  def delete
    super
  end

  def remove
    CloudObject.transaction do
      Picture.where(:thumb_id => self.id).each { |p|
        p.thumb_id = nil
        p.save!
      }
      Picture.where(:small_id => self.id).each { |p|
        p.small_id = nil
        p.save!
      }
      Picture.where(:medium_id => self.id).each { |p|
        p.medium_id = nil
        p.save!
      }
      Picture.where(:large_id => self.id).each { |p|
        p.large_id = nil
        p.save!
      }
      Picture.where(:large_fb_id => self.id).each { |p|
        p.large_fb_id = nil
        p.save!
      }
      Picture.where(:original_image_id => self.id).each { |p|
        p.original_image_id = nil
        p.save!
      }
      Picture.where(:original_video_id => self.id).each { |p|
        p.original_video_id = nil
        p.save!
      }
      logger.debug "deleting '#{self.path}' from '#{self.bucket}'"
      if Rails.application.config.google_cloud_buckets.values.flatten.include? self.bucket then
        r=@@client.delete_object(self.bucket, self.path)
        logger.debug "Object '#{self.path}' correctly deleted from bucket #{self.bucket} after exception"
      else
        logger.warn "Object '#{self.path}' has NOT been deleted from bucket #{self.bucket} because this bucket does not belong to us !"
      end
      logger.debug r
    end
  end

  def find_name(bucket, constraints)

    cnt = 0
    ext = constraints[:extension] || 'bin'
    path = constraints[:path] || ''
    name = constraints[:prefix].to_s + ( constraints[:name] || Digest::MD5.hexdigest(Time.now.to_f.to_s+bucket) ) + constraints[:postfix].to_s
    name.gsub!('/','')

    dst_path = (path + "/" + name + "." + ext).gsub(/\/\/*/, '/')
    dst_path = (path + "/" + name + (++cnt).to_s + "." + ext).gsub(/\/\/*/, '/') while CloudObject.where(:bucket => bucket, :path => dst_path).count > 0

    dst_path
  end

end
