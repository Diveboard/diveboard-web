$(document).ready(function(){
  $("#spreadsheet_import").live("click", spreadsheet_import_popup);
});


function myAutocompleteRenderer(instance, td, row, col, prop, value, cellProperties) {
    Handsontable.AutocompleteCell.renderer.apply(this, arguments);
    td.style.fontStyle = 'normal';
    td.title = I18n.t(["js","spreadsheet_importer","Type to show the list of options"]);
  }

function spreadsheet_import_popup(e){
  if(e){
    e.preventDefault();
  }

  var actions = {};
  actions[I18n.t(["js","spreadsheet_importer","Cancel"])] = function(){};
  actions[I18n.t(["js","spreadsheet_importer","Import"])] = spreadsheet_do_import;

  diveboard.propose(
    I18n.t(["js","spreadsheet_importer","Spreadheet dive importer"]),
    I18n.t(["js","spreadsheet_importer","Select units:"])+' <select id="spreadsheet_import_units"> \
      <option value="si">'+I18n.t(["js","spreadsheet_importer","Metric (m, &deg;C, bar, L)"])+'</option> \
      <option value="imperial">'+I18n.t(["js","spreadsheet_importer","Imperial (ft, &deg;F, psi, cuft)"])+'</option> \
    </select> \
    <br/> \
    <div id="spreadsheet_import_data" style="overflow: auto"></div>',
    actions
  );
  $(".ui-dialog").css({width: "90%", height: $(window).height()-50+"px", left: "5%", top: "5%", position: "fixed"})
  $("#spreadsheet_import_data").css({width: $(window).width()*0.85+"px", height: $(window).height()-170+"px"})
  var cname_list = countries.map(function(e){return e.value}).slice(1);;


  G_spreadsheet_import = {
    date_format: 'mm/dd/yy',
    values_api: {
      visibility: ['excellent', 'good', 'average', 'bad'],
      tank_material: ['aluminium', 'steel', 'carbon'],
      watertype: ['salt', 'fresh'],
      current: ['none', 'light', 'medium', 'strong', 'extreme']
    },
    values_i18n: {},
    values_untr: {}
  }

  for (var c in G_spreadsheet_import.values_api){
    G_spreadsheet_import.values_untr[c] = {}
    G_spreadsheet_import.values_i18n[c] = $.map(G_spreadsheet_import.values_api[c], function(e){
      var t = I18n.t(['globals', c, e]);
      if (t.push)
        for (var i in t)
          G_spreadsheet_import.values_untr[c][t[i]] = e
      else
        G_spreadsheet_import.values_untr[c][t] = e
      return t
    })
  }

  if (I18n.locale != 'en')
    G_spreadsheet_import.date_format = 'dd/mm/yy';

  $("#spreadsheet_import_data").handsontable({
    data: create_spreadsheet_import(),
    rowHeaders: true,
    colHeaders:  [
      I18n.t(["js","spreadsheet_importer","Trip Name"]),
      I18n.t(["js","spreadsheet_importer","Dive #"]),
      I18n.t(["js","spreadsheet_importer","Date"]),
      I18n.t(["js","spreadsheet_importer","Time in"]),
      I18n.t(["js","spreadsheet_importer","Duration"]),
      I18n.t(["js","spreadsheet_importer","Depth"]),
      I18n.t(["js","spreadsheet_importer","Country"]),
      I18n.t(["js","spreadsheet_importer","Location"]),
      I18n.t(["js","spreadsheet_importer","Spot name"]),
      I18n.t(["js","spreadsheet_importer","Comments"]),
      I18n.t(["js","spreadsheet_importer","Buddies"]),
      I18n.t(["js","spreadsheet_importer","Divemaster"]),
      I18n.t(["js","spreadsheet_importer","Tank size"]),
      I18n.t(["js","spreadsheet_importer","Tank material"]),
      I18n.t(["js","spreadsheet_importer","%02"]),
      I18n.t(["js","spreadsheet_importer","%N2"]),
      I18n.t(["js","spreadsheet_importer","%He"]),
      I18n.t(["js","spreadsheet_importer","Pressure start"]),
      I18n.t(["js","spreadsheet_importer","Pressure end"]),
      I18n.t(["js","spreadsheet_importer","Water type"]),
      I18n.t(["js","spreadsheet_importer","Visibility"]),
      I18n.t(["js","spreadsheet_importer","Type (Night dive, Deep dive...)"]),
      I18n.t(["js","spreadsheet_importer","Surface Temp"]),
      I18n.t(["js","spreadsheet_importer","Bottom Temp"]),
      I18n.t(["js","spreadsheet_importer","Weights"]),
      I18n.t(["js","spreadsheet_importer","Altitude"]),
      I18n.t(["js","spreadsheet_importer","Current"])
      ],
    columns: [
      { //trip name : text
        data: "trip_name"
      },
      { //dive #
        data: "dive_number",
        type: 'numeric'
      },
      { //date
        data: "date",
        type: 'date',
        dateFormat: G_spreadsheet_import.date_format
        //dateFormat: 'yy-mm-dd'
      },
      { // time in
        data: "time_in",
        type: 'numeric',
        format: '00:00:00'
      },
      { // duration
        data: "duration",
        type: 'numeric'
      },
      { //depth
        data: "depth",
        type: 'numeric'
      },
      { //country
        data: "country",
        type: {renderer: myAutocompleteRenderer, editor: Handsontable.AutocompleteEditor},
        source: cname_list,
        strict: true
      },
      { // spot Location
        data: "location"
      },
      { // spot name
        data: "spot_name"
      },
      { // comments
        data: "comments"
      },
      { // buddies
        data: "buddies"
      },
      { // DM
        data: "dm"
      },
      { //tank size
        data: "tank_size",
        type: 'numeric'
      },
      { //tank material
        data: "tank_material",
        type: 'autocomplete',
        source: G_spreadsheet_import.values_i18n.tank_material,
        strict: true
      },
      { // o2
        data: "o2",
        type: 'numeric'
      },
      { // n2
        data: "n2",
        type: 'numeric'
      },
      { // he
        data: "he",
        type: 'numeric'
      },
      { // pstart
        data: "pstart",
        type: 'numeric'
      },
      { // pend
        data: "pend",
        type: 'numeric'
      },
      { //water type
        data: "watertype",
        type: 'autocomplete',
        source: G_spreadsheet_import.values_i18n.watertype,
        strict: true
      },
      { //visibility
        data: "visibility",
        type: 'autocomplete',
        source: G_spreadsheet_import.values_i18n.visibility,
        strict: true
      },
      { //dive type
        data: "dive_type"
      },
      { // surface temp
        data: "surf_temp",
        type: 'numeric'
      },
      { // bottom temp
        data: "bottom_temp",
        type: 'numeric'
      },
      { // weights
        data: "weights",
        type: 'numeric'
      },
      { // altitude
        data: "altitude",
        type: 'numeric'
      },
      { //current
        data: "current",
        type: 'autocomplete',
        source: G_spreadsheet_import.values_i18n.current,
        strict: true
      }
    ],
    scrollH: 'auto',
    scrollV: 'auto',
    minSpareRows: 20,
    contextMenu: true
  });
}

function create_spreadsheet_import(){
  var arr = [
    {
    trip_name: "Hawaii 2012",
    dive_number: "23",
    date: $.datepicker.formatDate(G_spreadsheet_import.date_format, new Date()),
    time_in: "14:35:00",
    duration: "22",
    depth: "33",
    country: I18n.t(["js","spreadsheet_importer","United States"]),
    location: I18n.t(["js","spreadsheet_importer","California"]),
    spot_name: I18n.t(["js","spreadsheet_importer","Whale point"]),
    comments: I18n.t(["js","spreadsheet_importer","No whales but plenty nudis !"]),
    buddies: I18n.t(["js","spreadsheet_importer","Alex <alex@xxx.xx>, Pascal"]),
    dm: I18n.t(["js","spreadsheet_importer","James"]),
    tank_size: "12",
    tank_material: G_spreadsheet_import.values_i18n.tank_material[0],
    o2: "21",
    n2: "79",
    he: "00",
    pstart: "200",
    pend: "60",
    watertype: G_spreadsheet_import.values_i18n.watertype[0],
    visibility: G_spreadsheet_import.values_i18n.visibility[0],
    dive_type: "Deep dive, Photography, Wreck",
    surf_temp: "26",
    bottom_temp: "20",
    weights: "10",
    altitude: "0",
    current: G_spreadsheet_import.values_i18n.current[0]
    }
  ];

  if ($("#spreadsheet_import_units").val() == 'imperial'){
    arr[0].pstart = "3000";
    arr[0].pend = "700";
    arr[0].tank_size = "12";
    arr[0].surf_temp = "50";
    arr[0].bottom_temp = "20";
  }

  return arr;
}

function generate_data_from_spreadheet(){

var convert = ($("#spreadsheet_import_units").val() == "imperial");
  data =  $("#spreadsheet_import_data").data('handsontable').getData();
  valid_data = [];
  $.each(data, function(idx, el0){
    var el = jQuery.extend({}, el0);;
    if(el.date && el.time_in && el.duration && el.depth ){
      if(el.date.match(/^[0-9]{1,2}:[0-9]{1,2}$/))
        el.date = el.date+":00";

      //Rewriting element values to API keys for i18n
      for (var attr in G_spreadsheet_import.values_api){
        el[attr] = G_spreadsheet_import.values_untr[attr][el[attr]];
      }


      var buddies = []
      if(el.buddies){
        $.each(el.buddies.split(","), function(idx, bud){
          m = bud.match(/^(.+[a-zA-Z])\ *<(.+)>$/)
          if(m == null){
            buddies.push({"name": bud});
          }else{
            buddies.push({"name": m[1], "email": m[2]});
          }
        });
      }
      var tanks;
      if(el.tank_size || el.tank_material || el.o2 || el.he || el.n2 || el.pstart || el.pend ){
        if(el.o2 == "21" && el.n2 == "79" )
          var gas = "air"
        else if (el.he == 0 || el.he == "" || el.he == null)
          if (el.o2 == "32")
            var gas = "EANx32"
          else if (el.o2 == "36")
            var gas = "EANx36"
          else if(el.o2 == "40")
            var gas = "EANx40"
          else
            var gas = "custom"
        else
          var gas = "custom"

        var mytank = {};
        mytank.gas = gas;
        if(gas =="custom"){
          if(el.o2)
            mytank.o2 = Number(el.o2);
          if(el.n2)
            mytank.n2 = Number(el.n2);
          if(el.he)
            mytank.he = Number(el.he);
        }
        if(el.tank_size)
          mytank.volume = Number(convert?(el.tank_size/100*12):el.tank_size);
        if(el.pstart)
          mytank.p_start = Number(convert?(el.pstart/14.5037738):el.pstart);
        if(el.pend)
          mytank.p_end = Number(convert?(el.pend/14.5037738):el.pend);
        if(el.tank_material)
          mytank.material = el.tank_material.toLowerCase();

        tanks =[mytank];
      }
      else{
        tanks = [];
      }


      var cn
      var de = {}
      de["user_id"] = G_user_api.shaken_id;
      var date = $.datepicker.parseDate(G_spreadsheet_import.date_format, el.date);
      date = $.datepicker.formatDate("dd/mm/yy", date);
      de["time_in"] = date+"T"+el.time_in+"Z";
      de["duration"] = Number(el.duration);
      de["maxdepth"] = convert?(Number(el.depth)/3.2808399):Number(el.depth);
      if(el.country || el.spot_name || el.location){
        de["spot"]= {};
        if(el.spot_name)
          de["spot"]["name"] = el.spot_name;
        else
          de["spot"]["name"] = "New Spot";
        var ccode = country_code_from_name(el.country||"")
        if(ccode)
          de["spot"]["country_code"] = ccode;
        if(el.location){
          de["spot"]["location"] = {name: el.location};
        }
      }
      if(el.trip_name)
        de["trip_name"] = el.trip_name;
      if(el.comments)
        de["notes"] = el.comments;
      if(buddies.length > 0)
        de["buddies"] = buddies;
      if(tanks.length > 0)
        de["tanks"] = tanks;
      if(el.weights)
        de["weights"] = convert?(el.weights/2):Number(el.weights);
      if(el.surf_temp)
        de["temp_surface"] = convert?((Number(el.surf_temp)-32)*5/9):Number(el.surf_temp);
      if(el.bottom_temp)
        de["temp_bottom"] = convert?((Number(el.bottom_temp)-32)*5/9):Number(el.bottom_temp);
      if(el.divetype)
        de["divetype"] = el.divetype.toLowerCase().split(",").map(function(e){return e.match(/^\ *(.*)\ *$/)[1]});
      if(el.altitude)
        de["altitude"] = convert?(Number(el.altitude)/3.2808399):Number(el.altitude);
      if(el.watertype)
        de["water"] = el.watertype.toLowerCase();
      if(el.visibility)
        de["visibility"] = el.visibility.toLowerCase();
      if(el.dive_number)
        de["number"] = Number(el.dive_number);
      if(el.current)
        de["current"] = el.current;
      if(el.dm)
        de["guide"] = el.dm
      /*if(el[11])
        de["diveshop"] = {"name":el[11]}*/

      valid_data.push(de);
    }
  });

  return valid_data;

}


function spreadsheet_do_import(){
  diveboard.mask_file(true);
  //will check and import the content of the spreadsheet


//return valid_data;

  $.ajax({
    type: 'POST',
    dataType: 'json',
    url: "/api/V2/dive/",
    data:{
      'authenticity_token': auth_token,
      arg: JSON.stringify(generate_data_from_spreadheet())
    },
    error: function(jqXHR, textStatus, errorThrown){
      if (callback_fail){
        console.log("Update failed")
        console.log(data);
        diveboard.notify(I18n.t(["js","spreadsheet_importer","update failed"]), textStatus, function(){
          window.location = "/"+G_user_api.vanity_url+"/bulk?bulk=wizard";
        });
      }
    },
    success: function(data){
      if(!data.user_authentified){
        console.log("Server could not authentify user");
      }

      if (data.success===true){
        console.log("successufully updated")
        console.log(data)
        if(data.error.length > 0 ){
          diveboard.notify(I18n.t(["js","spreadsheet_importer","Update successful with errors"]), JSON.stringify(data.error), function(){
            window.location = "/"+G_user_api.vanity_url+"/bulk?bulk=manager";
          });
        }else{
          diveboard.notify(I18n.t(["js","spreadsheet_importer","Update successful"]), I18n.t(["js","spreadsheet_importer","Reloading the dive list"]), function(){
            window.location = "/"+G_user_api.vanity_url+"/bulk?bulk=manager";
          });
        }
      } else {
        console.log("Update failed")
        console.log(data);
        diveboard.notify(I18n.t(["js","spreadsheet_importer","update failed"]), data.error, function(){
          window.location = "/"+G_user_api.vanity_url+"/bulk?bulk=wizard";
        });
      }
    }
  });

}


