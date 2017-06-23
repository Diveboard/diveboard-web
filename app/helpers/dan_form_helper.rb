
module DanFormHelper
  # This call sends the DAN form by mail
  #
  # [Authentication]
  #   Required
  # [Request]
  #   - *id* : dive id
  #   - *dan_data_form*
  #     - *dive*
  #       - *altitude_date* : ZSR 17
  #       - *altitude_exposure* : ZSR 14 req
  #       - *altitude_interval* : ZSR 16
  #       - *altitude_length* : ZSR 18
  #       - *altitude_value* : ZSR 19
  #       - *comments* : ZSR 15
  #       - *decompression* : ZDD 13 req
  #       - *dive_plan* : ZDD 7 required
  #       - *dive_plan_table* : ZDD 8
  #       - *dress* : ZDD 9 required
  #       - *drinks* : ZSR 4
  #       - *environment* : ZDD 5 required
  #       - *exercice* : ZSR 5
  #       - *gases* : ZDD 15 and following required
  #       - *gases_number* : ZDD 14 required
  #       - *hyperbar* : ZSR 20
  #       - *hyperbar_location* : ZSR 21
  #       - *hyperbar_number* : ZSR 22
  #       - *malfunction* : ZSR 12 req
  #       - *med_dive* : ZSR 6 repiping
  #       - *platform* : ZDD 6 req
  #       - *problems* : ZSR 11 req
  #       - *program* : ZDD 4
  #       - *purpose* : ZDD 3
  #       - *rest* : ZSR 3
  #       - *symptoms* : ZSR 13 req
  #       - *thermal_confort* : ZSR 9 required
  #       - *workload* : ZSR 10 req
  #       - *apparatus* : ZDD 10 req
  #       - *bottom_gas* : ZDD 12 req
  #       - *current* : ZSR 8
  #       - *visibilty* : ZSR 7
  #       - not implemented : ZDD 11 Gas source
  #     - *diver* : information about the diver
  #       - *address*: array - ZPA 1
  #       - *alias* : ZPD 6
  #       - *birthday* : ZPD 8 YYYYMMDD req
  #       - *birthplace* : array ZPD 9
  #       - *certif_level* : ZPD  14
  #       - *cigarette* : ZPD 19
  #       - *citizenship* : ZPA 6
  #       - *conditions* : ZPD 17 - pipized
  #       - *dan_id* : ZPD 4
  #       - *dan_pde_id* : ZPD 1 req
  #       - *dives_5y* : ZPD 16
  #       - *dives_12m* : ZPD 15
  #       - *email* : ZPA 4
  #       - *first_certif* : ZPD 13 YYYY
  #       - *height* : array - ZPD 12 req
  #       - *language* : ZPA 5
  #       - *license* : array - ZPD 3
  #       - *medications* : ZPD 18 - pipized
  #       - *mother* : ZPD 7
  #       - *name* : array - ZPD 5 req
  #       - *phone_home* : array - ZPA 2 req
  #       - *phone_work* : array - ZPA 3
  #       - *sex* : ZPD 10 req
  #       - *weight* : array - ZPD 11 req
  #     - *version* : should be 1
  # [Response]
  #   - *success* : boolean
  #   - *error* : first error message encountered
  def DanFormHelper.send_to_dan(dive, dan_data_form)
    begin

      dan_form = ValidationHelper.validate_and_filter_parameters dan_data_form, { :class => Hash,
                  :sub => {
                    'version' => { :class => Fixnum, :presence => true, :in => [1] },
                    'dive' => { :class => Hash,
                      :sub => {
                        'altitude_date' => { :class => String, :presence => false, :nil => true },
                        'altitude_exposure' => { :class => Fixnum, :presence => true, :nil => false, :convert_if_string => proc{|a| Integer(a)} },
                        'altitude_interval' => { :class => Fixnum, :presence => false, :nil => true, :convert_if_string => proc{|a| Integer(a)} },
                        'altitude_length' => { :class => Fixnum, :presence => false, :nil => true, :convert_if_string => proc{|a| Integer(a)} },
                        'altitude_value' => { :class => Fixnum, :presence => false, :nil => true, :convert_if_string => proc{|a| Integer(a)} },
                        'comments' => { :class => String, :presence => false, :nil => true },
                        'decompression' => { :class => Fixnum, :presence => true, :nil => false, :convert_if_string => proc{|a| Integer(a)} },
                        'dive_plan' => { :class => Fixnum, :presence => true, :nil => false, :convert_if_string => proc{|a| Integer(a)} },
                        'dive_plan_table' => { :class => Fixnum, :presence => false, :nil => true, :convert_if_string => proc{|a| Integer(a)} },
                        'dress' => { :class => Fixnum, :presence => true, :nil => false, :convert_if_string => proc{|a| Integer(a)} },
                        'drinks' => { :class => Fixnum, :presence => false, :nil => true, :convert_if_string => proc{|a| Integer(a)} },
                        'environment' => { :class => Fixnum, :presence => true, :nil => false, :convert_if_string => proc{|a| Integer(a)} },
                        'exercice' => { :class => Fixnum, :presence => false, :nil => true, :convert_if_string => proc{|a| Integer(a)} },
                        'gases' => { :class => Array, :presence => true, :nil => false },
                        'gases_number' => { :class => Fixnum, :presence => true, :nil => false, :convert_if_string => proc{|a| Integer(a)} },
                        'hyperbar' => { :class => Fixnum, :presence => false, :nil => true, :convert_if_string => proc{|a| Integer(a)} },
                        'hyperbar_location' => { :class => String, :presence => false, :nil => true },
                        'hyperbar_number' => { :class => Fixnum, :presence => false, :nil => true, :convert_if_string => proc{|a| Integer(a)} },
                        'malfunction' => { :class => Fixnum, :presence => true, :nil => false, :convert_if_string => proc{|a| Integer(a)} },
                        'med_dive' => { :class => String, :presence => false, :nil => true },
                        'platform' => { :class => Fixnum, :presence => true, :nil => false, :convert_if_string => proc{|a| Integer(a)} },
                        'problems' => { :class => Fixnum, :presence => true, :nil => false, :convert_if_string => proc{|a| Integer(a)} },
                        'program' => { :class => Fixnum, :presence => false, :nil => true, :convert_if_string => proc{|a| Integer(a)} },
                        'purpose' => { :class => Fixnum, :presence => false, :nil => true, :convert_if_string => proc{|a| Integer(a)} },
                        'rest' => { :class => Fixnum, :presence => false, :nil => true, :convert_if_string => proc{|a| Integer(a)} },
                        'symptoms' => { :class => Fixnum, :presence => true, :nil => false, :convert_if_string => proc{|a| Integer(a)} },
                        'thermal_confort' => { :class => Fixnum, :presence => true, :nil => false, :convert_if_string => proc{|a| Integer(a)} },
                        'workload' => { :class => Fixnum, :presence => true, :nil => false, :convert_if_string => proc{|a| Integer(a)} },
                        'apparatus' => { :class => Fixnum, :presence => true, :nil => false, :convert_if_string => proc{|a| Integer(a)} },
                        'bottom_gas' => { :class => String, :presence => true, :nil => false },
                        'current' => { :class => Fixnum, :presence => false, :nil => true, :convert_if_string => proc{|a| Integer(a)} },
                        'visibilty' => { :class => Fixnum, :presence => false, :nil => true, :convert_if_string => proc{|a| Integer(a)} }
                      }
                    },
                    'diver' => { :class => Hash,
                      :sub => {
                        'dan_pde_id' => {:class => String, :presence => false, :nil => true},
                        'license' => {:class => Array, :presence => false, :nil => true},
                        'dan_id' => {:class => String, :presence => false, :nil => true},
                        'name' => {:class => Array, :presence => true, :nil => false},
                        'alias' => {:class => String, :presence => false, :nil => true},
                        'mother' => {:class => String, :presence => false, :nil => true},
                        'dives_5y' => { :class => Fixnum, :presence => false, :nil => true, :convert_if_string => proc{|a| Integer(a)} },
                        'dives_12m' => { :class => Fixnum, :presence => false, :nil => true, :convert_if_string => proc{|a| Integer(a)} },
                        'birthday' => {:class => String, :presence => true, :nil => false, :regexp => /^[0-9]{8}$/ },
                        'birthplace' => {:class => Array, :presence => false, :nil => true},
                        'sex' => {:class => Fixnum, :presence => true, :nil => false, :convert_if_string => proc{|a| Integer(a)}},
                        'weight' => {:class => Array, :presence => true, :nil => false},
                        'height' => {:class => Array, :presence => true, :nil => false},
                        'first_certif' => {:class => String, :presence => false, :nil => true},
                        'certif_level' => {:class => Fixnum, :presence => false, :nil => true, :convert_if_string => proc{|a| Integer(a)}},
                        'conditions' => {:class => String, :presence => false, :nil => true},
                        'medications' => {:class => String, :presence => false, :nil => true},
                        'cigarette' => {:class => Fixnum, :presence => false, :nil => true, :convert_if_string => proc{|a| Integer(a)}},
                        'address' => {:class => Array, :presence => false, :nil => true},
                        'phone_home' => {:class => Array, :presence => false, :nil => true},
                        'phone_work' => {:class => Array, :presence => false, :nil => true},
                        'email' => {:class => String, :presence => false, :nil => true},
                        'language' => {:class => String, :presence => false, :nil => true},
                        'citizenship' => {:class => String, :presence => false, :nil => true}
                      }
                    },
                    'version' => { :class => Fixnum, :presence => true, :in => [1], :convert_if_string => proc{|a| Integer(a)} }
                  }
                }


      zpd_array = [
        'ZPD',
        dan_form['diver']['dan_pde_id'],
        dive.user.id.to_s + "^A",
        dan_form['diver']['license'].join('^'),
        dan_form['diver']['dan_id'],
        dan_form['diver']['name'].join('^'),
        dan_form['diver']['alias'],
        dan_form['diver']['mother'],
        dan_form['diver']['birthday'],
        dan_form['diver']['birthplace'].join('^'),
        dan_form['diver']['sex'],
        dan_form['diver']['weight'].join('^'),
        dan_form['diver']['height'].join('^'),
        dan_form['diver']['first_certif'] && dan_form['diver']['first_certif'][0..3],  # only the year is sent to DAN
        dan_form['diver']['certif_level'],
        dan_form['diver']['dives_12m'],
        dan_form['diver']['dives_5y'],
        dan_form['diver']['conditions'] && dan_form['diver']['conditions'].gsub( /[\n\r]+/, '^'),
        dan_form['diver']['medications'] && dan_form['diver']['medications'].gsub( /[\n\r]+/, '^'),
        dan_form['diver']['cigarette'],
        nil
      ]

      zpa_array = [
        'ZPA',
        dan_form['diver']['address'].join('^'),
        dan_form['diver']['phone_home'].join('^'),
        dan_form['diver']['phone_work'].join('^'),
        dan_form['diver']['email'],
        dan_form['diver']['language'],
        dan_form['diver']['citizenship'],
        nil
      ]

      zdd_array = [
        'ZDD',
        1,            # export sequence
        dive.id,      # internal dive sequence
        dan_form['dive']['purpose'],
        dan_form['dive']['program'],
        dan_form['dive']['environment'],
        dan_form['dive']['platform'],
        dan_form['dive']['dive_plan'],
        dan_form['dive']['dive_plan_table'],
        dan_form['dive']['dress'],
        dan_form['dive']['apparatus'],
        nil,          #not implemented : ZDD 11 Gas source
        dan_form['dive']['bottom_gas'],
        dan_form['dive']['decompression'],
        dan_form['dive']['gases_number'],
        dan_form['dive']['gases'].join('|'),
        nil
      ]

      zsr_array = [
        'ZSR',
        1,            # export sequence
        dive.id,      # internal dive sequence
        dan_form['dive']['rest'],
        dan_form['dive']['drinks'],
        dan_form['dive']['exercice'],
        dan_form['dive']['med_dive'] && dan_form['dive']['med_dive'].gsub( /[\n\r]+/, '^'),
        dan_form['dive']['visibilty'],
        dan_form['dive']['current'],
        dan_form['dive']['thermal_confort'],
        dan_form['dive']['workload'],
        dan_form['dive']['problems'],
        dan_form['dive']['malfunction'],
        dan_form['dive']['symptoms'],
        dan_form['dive']['altitude_exposure'],
        dan_form['dive']['comments'] && dan_form['dive']['comments'].gsub( /[\n\r]+/, ' ' ),
        dan_form['dive']['altitude_interval'],
        dan_form['dive']['altitude_date'],
        dan_form['dive']['altitude_length'],
        dan_form['dive']['altitude_value'],
        dan_form['dive']['hyperbar'],
        dan_form['dive']['hyperbar_location'] && dan_form['dive']['hyperbar_location'].gsub( /[\n\r]+/, ' ' ),
        dan_form['dive']['hyperbar_number'],
        nil
      ]

      # Format the full export
      export = Divelog.new
      export.fromDiveDB dive.id
      zxl_export = export.toZXL
      zxl_export.sub!( /ZAR{}/, [ 'ZAR{}',  zpd_array.join('|'),  zpa_array.join('|') ].join("\n") )
      zxl_export.sub!( /^(FSH[^\n]*)ZXU/, '\1ZXL')
      zxl_export += "\n"+ zdd_array.join('|') +"\n"+ zsr_array.join('|')

      # send the data
      Rails.logger.info zxl_export
      DanMailer.send_zxl(dive.id, zxl_export).deliver

      # store the sent form
      dive.dan_data_sent = dan_form
      dive.dan_data = nil
      dive.save!

    rescue
      #trace the error
      Rails.logger.warn "Error on submitting DAN form : #{$!}"
      Rails.logger.debug $!.backtrace
      raise $!
      #we should not raise the exception (which causes an error 500), but send mail separately...
      #render :json => {:success => false, :error => "Exception caught (#{$!})"}
    end
  end

end
