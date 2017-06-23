//modal text editor used throughout diveboard to edit texts stored in the wiki database
elRTE.prototype.options.panels.diveboardpanel = [
    'bold', 'italic', 'underline', 'forecolor', 'justifyleft', 'justifyright',
    'justifycenter', 'justifyfull', 'formatblock', 'insertorderedlist', 'insertunorderedlist',
    'link', 'image'];
elRTE.prototype.options.toolbars.diveboardtoolbar = ['diveboardpanel', 'tables'];
// var opts = {
//         cssClass : 'el-rte',
//         // lang     : 'ru',
//         height   : 200,
//         toolbar  : 'diveboardtoolbar',
//         cssfiles : ['/mod/elrte/css/elrte-inner.css']
//       }


elRTE.prototype.options.buttons.link = 'Link';
/**
 * @class button - insert/edit link to a diveboard location(open dialog window)
**/
(function($) {
elRTE.prototype.ui.prototype.buttons.link = function(rte, name) {
  this.constructor.prototype.constructor.call(this, rte, name);
  var self = this;
  this.img = false;
  
  this.bm;
  
  function init() {
    self.labels = {
      id        : 'ID',
      'class'   : 'Css class',
      style     : 'Css style',
      dir       : 'Script direction',
      lang      : 'Language',
      charset   : 'Charset',
      type      : 'Target MIME type',
      rel       : 'Relationship page to target (rel)',
      rev       : 'Relationship target to page (rev)',
      tabindex  : 'Tab index',
      accesskey : 'Access key'
    }
    self.src = {
      main : {
        href   : $('<input type="text" class="elrte_diveboard_href"/>'),
        title  : $('<input type="text" class="elrte_diveboard_title"/>'),
        diveboardsearch: $('<div>').append($('<select class="elrte_diveboard_search_scope"/>')
          .append($('<option />').text(self.rte.i18n('Country')).val('country'))
          .append($('<option />').text(self.rte.i18n('Location')).val('location'))
          .append($('<option />').text(self.rte.i18n('Body of Water')).val('bodyofwater'))
          .append($('<option />').text(self.rte.i18n('Spot')).val('spot'))
          .append($('<option />').text(self.rte.i18n('Species')).val('species'))
          .append($('<option />').text(self.rte.i18n('Diver')).val('user')))
          .append($('<input type="text" class="elrte_diveboard_search_term"/><img class="elrte_diveboard_search_spinner"/>')).children(),
        anchor : $('<select />').attr('name', 'anchor'),
        target : $('<select />')
        //  .append($('<option />').text(self.rte.i18n('In this window')).val(''))
          .append($('<option />').text(self.rte.i18n('In new window (_blank)')).val('_blank'))
        //  .append($('<option />').text(self.rte.i18n('In new parent window (_parent)')).val('_parent'))
        //  .append($('<option />').text(self.rte.i18n('In top frame (_top)')).val('_top'))
      },

      popup : {
        use        : $('<input type="checkbox" />'),
        url        : $('<input type="text" />'    ).val('http://'),
        name       : $('<input type="text" />'    ),
        width      : $('<input type="text" />'    ).attr({size : 6, title : self.rte.i18n('Width')} ).css('text-align', 'right'),
        height     : $('<input type="text" />'    ).attr({size : 6, title : self.rte.i18n('Height')}).css('text-align', 'right'),
        left       : $('<input type="text" />'    ).attr({size : 6, title : self.rte.i18n('Left')}  ).css('text-align', 'right'),
        top        : $('<input type="text" />'    ).attr({size : 6, title : self.rte.i18n('Top')}   ).css('text-align', 'right'),
        location   : $('<input type="checkbox" />'),        
        menubar    : $('<input type="checkbox" />'),
        toolbar    : $('<input type="checkbox" />'),
        scrollbars : $('<input type="checkbox" />'),
        status     : $('<input type="checkbox" />'),
        resizable  : $('<input type="checkbox" />'),
        dependent  : $('<input type="checkbox" />'),
        retfalse   : $('<input type="checkbox" />').attr('checked', true)
      },

      adv : {
        id        : $('<input type="text" />'),
        'class'   : $('<input type="text" />'),
        style     : $('<input type="text" />'),
        dir       : $('<select />')
              .append($('<option />').text(self.rte.i18n('Not set')).val(''))
              .append($('<option />').text(self.rte.i18n('Left to right')).val('ltr'))
              .append($('<option />').text(self.rte.i18n('Right to left')).val('rtl')),
        lang      : $('<input type="text" />'),
        charset   : $('<input type="text" />'),
        type      : $('<input type="text" />'),
        rel       : $('<input type="text" />'),
        rev       : $('<input type="text" />'),
        tabindex  : $('<input type="text" />'),
        accesskey : $('<input type="text" />')
      },
      events : {}
    }

    $.each(
      ['onblur', 'onfocus', 'onclick', 'ondblclick', 'onmousedown', 'onmouseup', 'onmouseover', 'onmouseout', 'onmouseleave', 'onkeydown', 'onkeypress', 'onkeyup'], 
      function() {
        self.src.events[this] = $('<input type="text" />');
    });

    $.each(self.src, function() {
      for (var n in this) {
        // this[n].attr('name', n);
        var t = this[n].attr('type');
        if (!t || (t == 'text'  && !this[n].attr('size')) ) {
          this[n].css('width', '100%');
        }
      }
    });
    
  }
  
  this.command = function() {
    var n = this.rte.selection.getNode(),
      sel, i, v, opts, l, r, link, href, s;
    
    !this.src && init();
    // this.rte.selection.saveIERange();

    this.bm = this.rte.selection.getBookmark();

    function isLink(n) { return n.nodeName == 'A' && n.href; }
    
    this.link = this.rte.dom.selfOrParentLink(n);
    
    if (!this.link) {
      sel = $.browser.msie ? this.rte.selection.selected() : this.rte.selection.selected({wrap : false});
      if (sel.length) {
        for (i=0; i < sel.length; i++) {
          if (isLink(sel[i])) {
            this.link = sel[i];
            break;
          }
        };
        if (!this.link) {
          this.link = this.rte.dom.parent(sel[0], isLink) || this.rte.dom.parent(sel[sel.length-1], isLink);
        }
      }
    }
    
    this.link = this.link ? $(this.link) : $(this.rte.doc.createElement('a'));
    this.img = n.nodeName == 'IMG' ? n : null;
    this.updatePopup();
    
    this.src.main.anchor.empty();
    $('a[href!=""][name]', this.rte.doc).each(function() {
      var n = $(this).attr('name');
      self.src.main.anchor.append($('<option />').val(n).text(n));
    });
    if (this.src.main.anchor.children().length) {
      this.src.main.anchor.prepend($('<option />').val('').text(this.rte.i18n('Select bookmark')) )
        .change(function() {
          var v = $(this).val();
          if (v) {
            self.src.main.href.val('#'+v);
          }
        });
    }
    
    opts = {
      rtl : this.rte.rtl,
      submit : function(e, d) { e.stopPropagation(); e.preventDefault(); self.set(); d.close(); },
      tabs : { show : function(e, ui) { if (ui.index==3) { self.updateOnclick(); } } },
      close : function() {self.rte.browser.msie && self.rte.selection.restoreIERange(); },
      dialog : {
        width : 'auto',
        width : 430,
        top: 50,
        title : this.rte.i18n('Link')
        
      }
    }

    d = new elDialogForm(opts);
    d.append(this.rte.i18n('Search in Diveboard a page to link to or enter an external URL'));

    l = $('<div />')
      .append( $('<label />').append(this.src.popup.location).append(this.rte.i18n('Location bar')))
      .append( $('<label />').append(this.src.popup.menubar).append(this.rte.i18n('Menu bar')))
      .append( $('<label />').append(this.src.popup.toolbar).append(this.rte.i18n('Toolbar')))        
      .append( $('<label />').append(this.src.popup.scrollbars).append(this.rte.i18n('Scrollbars')));
    r = $('<div />')
      .append( $('<label />').append(this.src.popup.status).append(this.rte.i18n('Status bar')))
      .append( $('<label />').append(this.src.popup.resizable).append(this.rte.i18n('Resizable')))
      .append( $('<label />').append(this.src.popup.dependent).append(this.rte.i18n('Depedent')))       
      .append( $('<label />').append(this.src.popup.retfalse).append(this.rte.i18n('Add return false')));

    d.tab('main', this.rte.i18n('Properies'))
      .tab('popup',  this.rte.i18n('Popup'))
      .tab('adv',    this.rte.i18n('Advanced'))
      .tab('events', this.rte.i18n('Events'))
      .append($('<label />').append(this.src.popup.use).append(this.rte.i18n('Open link in popup window')), 'popup')
      .separator('popup')
      .append([this.rte.i18n('URL'),  this.src.popup.url],  'popup', true)
      .append([this.rte.i18n('Window name'), this.src.popup.name], 'popup', true)
      .append([this.rte.i18n('Window size'), $('<span />').append(this.src.popup.width).append(' x ').append(this.src.popup.height).append(' px')], 'popup', true)
      .append([this.rte.i18n('Window position'), $('<span />').append(this.src.popup.left).append(' x ').append(this.src.popup.top).append(' px')], 'popup', true)        
      .separator('popup')
      .append([l, r], 'popup', true);

    link = this.link.get(0);
    href = this.rte.dom.attr(link, 'href');
    this.src.main.href.val(href).change(function() {
      $(this).val(self.rte.utils.absoluteURL($(this).val()));
    });
    
    d.append([this.rte.i18n('Search Link<br>in Diveboard'), this.src.main.diveboardsearch], 'main', true);
    //d.append(["",$()], 'main', true);

    
    if (this.rte.options.fmAllow && this.rte.options.fmOpen) {
      var s = $('<span />').append(this.src.main.href.css('width', '87%'))
        .append(
          $('<span />').addClass('ui-state-default ui-corner-all')
            .css({'float' : 'right', 'margin-right' : '3px'})
            .attr('title', self.rte.i18n('Open file manger'))
            .append($('<span />').addClass('ui-icon ui-icon-folder-open'))
              .click( function() {
                self.rte.options.fmOpen( function(url) { self.src.main.href.val(url).change(); } );
              })
              .hover(function() {$(this).addClass('ui-state-hover')}, function() { $(this).removeClass('ui-state-hover')})
        );
      d.append([this.rte.i18n('Link URL'), s], 'main', true);
    } else {
      d.append([this.rte.i18n('Link URL'), this.src.main.href], 'main', true);
    }
    this.src.main.href.change();
    
    d.append([this.rte.i18n('Title'), this.src.main.title.val(this.rte.dom.attr(link, 'title'))], 'main', true);
    if (this.src.main.anchor.children().length) {
      d.append([this.rte.i18n('Bookmark'), this.src.main.anchor.val(href)], 'main', true)
    }
    
    //if (!(this.rte.options.doctype.match(/xhtml/) && this.rte.options.doctype.match(/strict/))) {
    //  d.append([this.rte.i18n('Target'), this.src.main.target.val(this.link.attr('target')||'')], 'main', true);
    //}
    


    for (var n in this.src.adv) {
      this.src.adv[n].val(this.rte.dom.attr(link, n));
      d.append([this.rte.i18n(this.labels[n] ? this.labels[n] : n), this.src.adv[n]], 'adv', true);
    }
    for (var n in this.src.events) {
      var v = this.rte.utils.trimEventCallback(this.rte.dom.attr(link, n));
      this.src.events[n].val(v);
      d.append([this.rte.i18n(this.labels[n] ? this.labels[n] : n), this.src.events[n]], 'events', true);
    }
    
    this.src.popup.use.change(function() {
      var c = $(this).attr('checked');
      $.each(self.src.popup, function() {
        if ($(this).attr('name') != 'use') {
          if (c) {
            $(this).removeAttr('disabled');
          } else {
            $(this).attr('disabled', true);
          }
        }
      })
    });
    this.src.popup.use.change();

    d.open();
    init_elrte_diveboardsearch();
  }
  
  this.update = function() {
    var n = this.rte.selection.getNode();
    
    // var t = this.rte.dom.selectionHas(function(n) { return n.nodeName == 'A' && n.href; });
    // this.rte.log(t)
    
    if (this.rte.dom.selfOrParentLink(n)) {
      this.domElem.removeClass('disabled').addClass('active');
    } else if (this.rte.dom.selectionHas(function(n) { return n.nodeName == 'A' && n.href; })) {
      this.domElem.removeClass('disabled').addClass('active');
    } else if (!this.rte.selection.collapsed() || n.nodeName == 'IMG') {
      this.domElem.removeClass('disabled active');
    } else {
      this.domElem.addClass('disabled').removeClass('active');
    }
  }
  
  this.updatePopup = function() {
    var onclick = ''+this.link.attr('onclick');
    // onclick = onclick ? $.trim(onclick.toString()) : ''
    if ( onclick.length>0 && (m = onclick.match(/window.open\('([^']+)',\s*'([^']*)',\s*'([^']*)'\s*.*\);\s*(return\s+false)?/))) {
      this.src.popup.use.attr('checked', 'on')
      this.src.popup.url.val(m[1]);
      this.src.popup.name.val(m[2]);

      if ( /location=yes/.test(m[3]) ) {
        this.src.popup.location.attr('checked', true);
      }
      if ( /menubar=yes/.test(m[3]) ) {
        this.src.popup.menubar.attr('checked', true);
      }
      if ( /toolbar=yes/.test(m[3]) ) {
        this.src.popup.toolbar.attr('checked', true);
      }
      if ( /scrollbars=yes/.test(m[3]) ) {
        this.src.popup.scrollbars.attr('checked', true);
      }
      if ( /status=yes/.test(m[3]) ) {
        this.src.popup.status.attr('checked', true);
      }
      if ( /resizable=yes/.test(m[3]) ) {
        this.src.popup.resizable.attr('checked', true);
      }
      if ( /dependent=yes/.test(m[3]) ) {
        this.src.popup.dependent.attr('checked', true);
      }
      if ((_m = m[3].match(/width=([^,]+)/))) {
        this.src.popup.width.val(_m[1]);
      }
      if ((_m = m[3].match(/height=([^,]+)/))) {
        this.src.popup.height.val(_m[1]);
      }
      if ((_m = m[3].match(/left=([^,]+)/))) {
        this.src.popup.left.val(_m[1]);
      }
      if ((_m = m[3].match(/top=([^,]+)/))) {
        this.src.popup.top.val(_m[1]);
      }
      if (m[4]) {
        this.src.popup.retfalse.attr('checked', true);
      }
    } else {
      $.each(this.src.popup, function() {
        var $this = $(this);
        if ($this.attr('type') == 'text') {
          $this.val($this.attr('name') == 'url' ? 'http://' : '');
        } else {
          if ($this.attr('name') == 'retfalse') {
            this.attr('checked', true);
          } else {
            $this.removeAttr('checked');
          }
        }
      });
    }
    
  }
  
  this.updateOnclick = function () {
    var url = this.src.popup.url.val();
    if (this.src.popup.use.attr('checked') && url) {
      var params = '';
      if (this.src.popup.location.attr('checked')) {
        params += 'location=yes,';
      }
      if (this.src.popup.menubar.attr('checked')) {
        params += 'menubar=yes,';
      }
      if (this.src.popup.toolbar.attr('checked')) {
        params += 'toolbar=yes,';
      }
      if (this.src.popup.scrollbars.attr('checked')) {
        params += 'scrollbars=yes,';
      }
      if (this.src.popup.status.attr('checked')) {
        params += 'status=yes,';
      }
      if (this.src.popup.resizable.attr('checked')) {
        params += 'resizable=yes,';
      }
      if (this.src.popup.dependent.attr('checked')) {
        params += 'dependent=yes,';
      }
      if (this.src.popup.width.val()) {
        params += 'width='+this.src.popup.width.val()+',';
      }
      if (this.src.popup.height.val()) {
        params += 'height='+this.src.popup.height.val()+',';
      }
      if (this.src.popup.left.val()) {
        params += 'left='+this.src.popup.left.val()+',';
      }
      if (this.src.popup.top.val()) {
        params += 'top='+this.src.popup.top.val()+',';
      }
      if (params.length>0) {
        params = params.substring(0, params.length-1)
      }
      var retfalse = this.src.popup.retfalse.attr('checked') ? 'return false;' : '';
      var onclick = "window.open('"+url+"', '"+$.trim(this.src.popup.name.val())+"', '"+params+"'); "+retfalse;
      this.src.events.onclick.val(onclick);
      if (!this.src.main.href.val()) {
        this.src.main.href.val('#');
      }
    } else {
      var v = this.src.events.onclick.val();
      v = v.replace(/window\.open\([^\)]+\)\s*;?\s*return\s*false\s*;?/i, '');
      this.src.events.onclick.val(v);
    }
  }
  
  this.set = function() {
    var href, fakeURL;
    this.updateOnclick();
    this.rte.selection.moveToBookmark(this.bm);
    // this.rte.selection.restoreIERange();
    this.rte.history.add();
    href = this.rte.utils.absoluteURL(this.src.main.href.val());
    if (!href) {
      // this.link.parentNode && this.rte.doc.execCommand('unlink', false, null);
      var bm = this.rte.selection.getBookmark();
      this.rte.dom.unwrap(this.link[0]);
      this.rte.selection.moveToBookmark(bm);

    } else {
        if (this.img && this.img.parentNode) {
          this.link = $(this.rte.dom.create('a')).attr('href', href);
          this.rte.dom.wrap(this.img, this.link[0]);
        } else if (!this.link[0].parentNode) {
          fakeURL = '#--el-editor---'+Math.random();
          this.rte.doc.execCommand('createLink', false, fakeURL);
          this.link = $('a[href="'+fakeURL+'"]', this.rte.doc);
          this.link.each(function() {
            var $this = $(this);

            // удаляем ссылки вокруг пустых элементов
            if (!$.trim($this.html()) && !$.trim($this.text())) {
              $this.replaceWith($this.text()); //  сохраняем пробелы :)
            }
          });
        }

      this.src.main.href.val(href);
      for (var tab in this.src) {
        if (tab != 'popup') {
          for (var n in this.src[tab]) {
            if (n != 'anchors') {
              var v = $.trim(this.src[tab][n].val());
              if (v) {
                this.link.attr(n, v);
              } else {
                this.link.removeAttr(n);
              }
            }
          }
        }
      };


      this.img && this.rte.selection.select(this.img);
    }
    this.rte.ui.update(true);
  }
  
}

})(jQuery);


/**
 * @class button - insert/edit image (open dialog window)
 *
 * @param  elRTE  rte   объект-редактор
 * @param  String name  название кнопки 
 *
 * @author:    Dmitry Levashov (dio) dio@std42.ru
 * Copyright: Studio 42, http://www.std42.ru
 **/
(function($) {
elRTE.prototype.ui.prototype.buttons.image = function(rte, name) {
  this.constructor.prototype.constructor.call(this, rte, name);
  var self = this,
    rte  = self.rte,
    proportion = 0,
    width = 0,
    height = 0,
    bookmarks = null,
    reset = function(nosrc) {
      $.each(self.src, function(i, elements) {
        $.each(elements, function(n, el) {
          if (n == 'src' && nosrc) {
            return;
          }
          el.val('');
        });
      });
    },
    values = function(img) {
      $.each(self.src, function(i, elements) {
        $.each(elements, function(n, el) {
          var val, w, c, s, border;
          
          if (n == 'width') {
            val = img.width();
          } else if (n == 'height') {
            val = img.height();
          } else if (n == 'border') {
            val = '';
            border = img.css('border') || rte.utils.parseStyle(img.attr('style')).border || '';

            if (border) {
              w = border.match(/(\d(px|em|%))/);
              c = border.match(/(#[a-z0-9]+)/);
              val = {
                width : w ? w[1] : border,
                style : border,
                color : rte.utils.color2Hex(c ? c[1] : border)
              }
            } 
          } else if (n == 'margin') {
            val = img;
          } else if (n == 'align') { 
            val = img.css('float');

            if (val != 'left' && val != 'right') {
              val = img.css('vertical-align');
            }
           }else {
            val = img.attr(n)||'';
          }
          
          if (i == 'events') {
            val = rte.utils.trimEventCallback(val);
          }

          el.val(val);
        });
      });
    },
    preview = function() {
      var src = self.src.main.src.val();
      
      reset(true);
      
      if (!src) {
        self.preview.children('img').remove();
        self.prevImg = null;
      } else {
        if (self.prevImg) {
          self.prevImg
            .removeAttr('src')
            .removeAttr('style')
            .removeAttr('class')
            .removeAttr('id')
            .removeAttr('title')
            .removeAttr('alt')
            .removeAttr('longdesc');
            
          $.each(self.src.events, function(name, input) {
            self.prevImg.removeAttr(name);
          });
        } else {
          self.prevImg = $('<img/>').prependTo(self.preview);
        }
        self.prevImg.load(function() {
          self.prevImg.unbind('load');
          setTimeout(function() {
            width      = self.prevImg.width();
            height     = self.prevImg.height();
            proportion = (width/height).toFixed(2);
            self.src.main.width.val(width);
            self.src.main.height.val(height);
            
          }, 100);
        });
        self.prevImg.attr('src', src);
      }
      
    },
    size = function(e) {
      var w = parseInt(self.src.main.width.val())||0,
        h = parseInt(self.src.main.height.val())||0;
        
      if (self.prevImg) {
        if (w && h) {
          if (e.target === self.src.main.width[0]) {
            h = parseInt(w/proportion);
          } else {
            w = parseInt(h*proportion);
          }
        } else {
          w = width;
          h = height;
        }
        self.src.main.height.val(h);
        self.src.main.width.val(w);
        self.prevImg.width(w).height(h);
        self.src.adv.style.val(self.prevImg.attr('style'));
      }
    }
    ;
  
  this.img     = null;
  this.prevImg = null;
  this.preview = $('<div class="elrte-image-preview"/>').text('Proin elit arcu, rutrum commodo, vehicula tempus, commodo a, risus. Curabitur nec arcu. Donec sollicitudin mi sit amet mauris. Nam elementum quam ullamcorper ante. Etiam aliquet massa et lorem. Mauris dapibus lacus auctor risus. Aenean tempor ullamcorper leo. Vivamus sed magna quis ligula eleifend adipiscing. Duis orci. Aliquam sodales tortor vitae ipsum. Aliquam nulla. Duis aliquam molestie erat. Ut et mauris vel pede varius sollicitudin');
  
  this.init = function() {  
    this.labels = {
      main   : 'Properies',
      link   : 'Link',
      adv    : 'Advanced',
      events : 'Events',
      id       : 'ID',
      'class'  : 'Css class',
      style    : 'Css style',
      longdesc : 'Detail description URL',
      href    : 'URL',
      target  : 'Open in',
      title   : 'Title'
    }
    
    this.src = {
      main : {
        src    : $('<input type="text" />').css('width', '100%').change(preview),
        title  : $('<input type="text" />').css('width', '100%'),
        alt    : $('<input type="text" />').css('width', '100%'),
        width  : $('<input type="text" />').attr('size', 5).css('text-align', 'right').change(size),
        height : $('<input type="text" />').attr('size', 5).css('text-align', 'right').change(size),
        margin : $('<div />').elPaddingInput({
          type : 'margin', 
          change : function() {
            var margin = self.src.main.margin.val();
          
            if (self.prevImg) {
              if (margin.css) {
                self.prevImg.css('margin', margin.css)
              } else {
                self.prevImg.css({
                  'margin-left'   : margin.left,
                  'margin-top'    : margin.top,
                  'margin-right'  : margin.right,
                  'margin-bottom' : margin.bottom
                });
              }
            }
          } 
        }), 
        align  : $('<select />').css('width', '100%')
              .append($('<option />').val('').text(this.rte.i18n('Not set', 'dialogs')))
              .append($('<option />').val('left'       ).text(this.rte.i18n('Left')))
              .append($('<option />').val('right'      ).text(this.rte.i18n('Right')))
              .append($('<option />').val('top'        ).text(this.rte.i18n('Top')))
              .append($('<option />').val('text-top'   ).text(this.rte.i18n('Text top')))
              .append($('<option />').val('middle'     ).text(this.rte.i18n('middle')))
              .append($('<option />').val('baseline'   ).text(this.rte.i18n('Baseline')))
              .append($('<option />').val('bottom'     ).text(this.rte.i18n('Bottom')))
              .append($('<option />').val('text-bottom').text(this.rte.i18n('Text bottom')))
              .change(function() {
                var val = $(this).val(),
                  css = {
                    'float' : '',
                    'vertical-align' : ''
                  };
                if (self.prevImg) {
                  if (val == 'left' || val == 'right') {
                    css['float'] = val;
                    css['vertical-align'] = '';
                  } else if (val) {
                    css['float'] = '';
                    css['vertical-align'] = val;
                  } 
                  self.prevImg.css(css);
                }
              })
            ,
        border : $('<div />').elBorderSelect({
          name : 'border',
          change : function() {
            var border = self.src.main.border.val();
            if (self.prevImg) {
              self.prevImg.css('border', border.width ? border.width+' '+border.style+' '+border.color : '');
            }
          }
        })
      },

      adv : {},
      events : {}
    }
    
    $.each(['id', 'class', 'style', 'longdesc'], function(i, name) {
      self.src.adv[name] = $('<input type="text" style="width:100%" />');
    });
    
    this.src.adv['class'].change(function() {
      if (self.prevImg) {
        self.prevImg.attr('class', $(this).val());
      }
    });
    
    this.src.adv.style.change(function() {
      if (self.prevImg) {
        self.prevImg.attr('style', $(this).val());
        values(self.prevImg);
      }
    });
    
    $.each(
      ['onblur', 'onfocus', 'onclick', 'ondblclick', 'onmousedown', 'onmouseup', 'onmouseover', 'onmouseout', 'onmouseleave', 'onkeydown', 'onkeypress', 'onkeyup'], 
      function() {
        self.src.events[this] = $('<input type="text"  style="width:100%"/>');
    });
  }
  
  this.command = function() {
    !this.src && this.init();
    
    var img, 
      opts = {
        rtl : rte.rtl,
        submit : function(e, d) { 
          e.stopPropagation(); 
          e.preventDefault(); 
          self.set(); 

          dialog.close(); 
        },
        close : function() {
          diveboard.remove_crop_upload("#elrte_upload");
          $("#elrte_browse").off("click");
          bookmarks && rte.selection.moveToBookmark(bookmarks)
        },
        dialog : {
          autoOpen  : false,
          width     : 500,
          zIndex   : 10000, 
          position  : 'center',
          title     : rte.i18n('Image'),
          resizable : true,
          open      : function() {
            $.fn.resizable && $(this).parents('.ui-dialog:first').resizable('option', 'alsoResize', '.elrte-image-preview');
            if($(this).parents('.ui-dialog:first').position().top < 50)
              $(this).parents('.ui-dialog:first').css({top: "50px"}); // ensure it's not going UNDER the top header
          }
        }
      },
      dialog = new elDialogForm(opts),
      fm = !!rte.options.fmOpen,
      src = fm
        ? $('<div class="elrte-image-src-fm"><span class="ui-state-default ui-corner-all"><span class="ui-icon ui-icon-folder-open"/></span></div>')
          .append(this.src.main.src.css('width', '87%'))
        : this.src.main.src;
      
      ;
    
    reset();
    this.preview.children('img').remove();
    this.prevImg = null;
    img = rte.selection.getEnd();
    
    this.img = img.nodeName == 'IMG' && !$(img).is('.elrte-protected')
      ? $(img)
      : $('<img/>');
    
    bookmarks = rte.selection.getBookmark();

    if (fm) {
      src.children('.ui-state-default')
        .click( function() {
          rte.options.fmOpen( function(url) { self.src.main.src.val(url).change() } );
        })
        .hover(function() {
          $(this).toggleClass('ui-state-hover');
        });
    }
    if($("#elrte_browse").length == 0){
      $("#elrte_browse").live("click", function(e){
          e.preventDefault();
          e.stopPropagation();
          diveboard.user_pictures_picker(rte.options.user_id, function(image, full_redirect_link){
            self.src.main.src.val(image).change();
            self.src.main.src.val(full_redirect_link);
          })
        });
    }
    
    dialog.tab('main', this.rte.i18n('Properies'))
      .append([this.rte.i18n('Image URL'), src],                 'main', true)
      .append([this.rte.i18n('Image UPLOAD'), $('<span />').append('<div id="elrte_upload" class="elrte_button"><div class="select_file_btn">upload</div></div>')],                 'main', true)
      .append([this.rte.i18n('Browse your images'), $('<span />').append('<button id="elrte_browse" class="elrte_button">browse</button>')],                 'main', true)
//DIVEBOARD     .append([this.rte.i18n('Title'),     this.src.main.title], 'main', true)
      .append([this.rte.i18n('Alt text'),  this.src.main.alt],   'main', true)
      .append([this.rte.i18n('Size'), $('<span />').append(this.src.main.width).append(' x ').append(this.src.main.height).append(' px')], 'main', true)
      .append([this.rte.i18n('Alignment'), this.src.main.align],  'main', true)
//DIVEBOARD     .append([this.rte.i18n('Margins'),   this.src.main.margin], 'main', true)
//DIVEBOARD     .append([this.rte.i18n('Border'),    this.src.main.border], 'main', true)
    
    dialog.append($('<fieldset><legend>'+this.rte.i18n('Preview')+'</legend></fieldset>').append(this.preview), 'main');

    diveboard.setup_crop_upload({
      selector:"#elrte_upload",
      crop: false,
      user_id: rte.options.user_id,
      box_width: null,
      preview: null, 
      cancel: function(){},
      confirm: function(response){
        self.src.main.src.val(response.getOriginal()).change();
      }
    });

    

    $.each(this.src, function(tabname, elements) {
    
      if (tabname == 'main') {
        return;
      }
      dialog.tab(tabname, rte.i18n(self.labels[tabname]));
      
      $.each(elements, function(name, el) {
        self.src[tabname][name].val(tabname == 'events' ? rte.utils.trimEventCallback(self.img.attr(name)) : self.img.attr(name)||'');
        dialog.append([rte.i18n(self.labels[name] || name), self.src[tabname][name]], tabname, true);
      });
    });
    
    dialog.open();
    
    if (this.img.attr('src')) {
      values(this.img);
      this.prevImg = this.img.clone().prependTo(this.preview);
      proportion   = (this.img.width()/this.img.height()).toFixed(2);
      width        = parseInt(this.img.width());
      height       = parseInt(this.img.height());
    }
  }
    
  this.set = function() {
    var src = this.src.main.src.val(),
      link;
    
    this.rte.history.add();
    bookmarks && rte.selection.moveToBookmark(bookmarks);
    
    if (!src) {
      link = rte.dom.selfOrParentLink(this.img[0]);
      link && link.remove();
      return this.img.remove();
    }
    
    !this.img[0].parentNode && (this.img = $(this.rte.doc.createElement('img')));
    
    this.img.attr('src', src)
      .attr('style', this.src.adv.style.val());
    
    $.each(this.src, function(i, elements) {
      $.each(elements, function(name, el) {
        var val = el.val(), style;
        
        switch (name) {
          case 'width':
            self.img.css('width', val);
            break;
          case 'height':
            self.img.css('height', val);
            break;
          case 'align':
            self.img.css(val == 'left' || val == 'right' ? 'float' : 'vertical-align', val);
            break;
          case 'margin':
            if (val.css) {
              self.img.css('margin', val.css);
            } else {
              self.img.css({
                'margin-left'   : val.left,
                'margin-top'    : val.top,
                'margin-right'  : val.right,
                'margin-bottom' : val.bottom
              });
            }
            break;
          case 'border':
            if (!val.width) {
              val = '';
            } else {
              val = 'border:'+val.css+';'+$.trim((self.img.attr('style')||'').replace(/border\-[^;]+;?/ig, ''));
              name = 'style';
              self.img.attr('style', val)
              return;
            }

            break;
          case 'src':
          case 'style':
            return;
          default:
            val ? self.img.attr(name, val) : self.img.removeAttr(name);
        }
      });
    });
    
    !this.img[0].parentNode && rte.selection.insertNode(this.img[0]);
    this.rte.ui.update();
  }

  this.update = function() {
    this.domElem.removeClass('disabled');
    var n = this.rte.selection.getEnd(),
      $n = $(n);
    if (n.nodeName == 'IMG' && !$n.hasClass('elrte-protected')) {
      this.domElem.addClass('active');
    } else {
      this.domElem.removeClass('active');
    }
  }
  
}
})(jQuery);





function edit_wiki(id, type, text, callback){
  if (!G_USER_LOGGED){
    diveboard.notify("User not logged in", "In order to edit wiki data, you must be logged in diveboard<br/><br/><center><a class='sign_in yellow_button' href='#'>Login</a></center>",function(){});
    return;
  }

  //text should be html
    var default_options={
    anchor: null,
    onsave_callback: null,
    oncancel_callback: null,
    editor_opts: {
        cssClass : 'el-rte',
        height   : 245,
        lang     : I18n.locale,
        toolbar  : 'diveboardtoolbar',
        cssfiles : ['/mod/elrte/css/elrte-inner.css'],
        resizable: false
      },
  };
  var editor_toolbar = ""; //"<div class='elrte_header'>Available versions: <select><option>1</option><option>2</option><option>3</option></select> <button>save</button><button>cancel</button></div>";
  var editor = "<div id='editor'>"+text+"</div>";
  diveboard.propose("Wiki editor", 
                    editor_toolbar+editor, 
    { "cancel": function(){ $("#editor").elrte('destroy');},
      "save": function()
      { 
        save_wiki(id, type, $("#editor").elrte('val') ,callback);
        $("#editor").elrte('destroy');
      }
    });
  $(".ui-dialog").css("width", "800px").css("height", "420px");
  $("#dialog-global-notify p").first().css("height", "320px");
  $('#editor').elrte(default_options.editor_opts);


}

function save_wiki(id, type, new_text, callback){
  diveboard.mask_file(true, {"z-index": 900000});
  $.ajax({
    url:"/api/wiki/update",
    data:({
        'authenticity_token': auth_token,
        id: id,
        type: type,
        text: new_text
      }),
    type:"POST",
    dataType:"json",
    error:function(){
      diveboard.alert("Could not contact server - please check your internet conenction");
      diveboard.unmask_file();
    },
    success:function(data){
      diveboard.unmask_file();
      if(data.success){
        if(callback)
          callback(new_text);
      }else{
        diveboard.alert("Wiki could not be saved <br/>"+data.error);
      }
    }
  });
}


function init_elrte_diveboardsearch(prefix){
  if(!prefix){
    var prefix = "";
  }else{
    prefix = prefix+" ";
  }
  $(prefix+".elrte_diveboard_search_term").val("");
  $(prefix+".elrte_diveboard_search_scope").val("country");


  if ($(prefix+".elrte_diveboard_search_term").hasClass("ui-autocomplete-input")){
    //already initialized
    return;
  }
    $(prefix+".elrte_diveboard_search_term").autocomplete({ 
      source: function(request, response){
        $(prefix+".elrte_diveboard_search_spinner").addClass("visible");
        var search_type =$(prefix+".elrte_diveboard_search_scope").val();
        switch(search_type){
          case "user":
            var search_url = "/api/search/user.json";
            break;
          case "country":
            var search_url = "/api/search/country.json";
            break;
          case "location":
            var search_url = "/api/search/location.json";
            break;
          case "bodyofwater":
            var search_url = "/api/search/region.json";
            break;
          case "spot":
            var search_url = "/api/search/spot.json";
            break;
          case "species":
            var search_url = "/api/fishsearch.json";
            break;
        }
        $.ajax({
          url: search_url,
          data:({
            q: request.term
          }),
          dataType: "json",
          success: function(data){
            $(prefix+".elrte_diveboard_search_spinner").removeClass("visible");

            console.log ("plop");
            switch(search_type){
              case "spot":
              data = data.data;
              break;
            }
            response( $.map( data, function( item ) {
              switch(search_type){
                case "user":
                  return {
                    label: "<img src='"+item.picture+"' class='buddy_picker_list'/>"+"<span class='buddy_picker_list_span'>"+item.label+"</span>",
                    value: item.label,
                    href: item.web
                  }
                  break;
                case "country":
                case "location":
                case "bodyofwater":
                case "species":
                  return {
                    label: item.name,
                    value: item.name,
                    href: item.fullpermalink
                  }
                  break;
                case "spot":
                  return {
                    label: item.name,
                    value: item.name,
                    href: item.data.fullpermalink
                  }
                  break;
              }
            }));
          },
          error: function(data) { diveboard.alert("A technical error happened while trying to connect to Facebook."); 
                                  $(prefix+".elrte_diveboard_search_spinner").removeClass("visible");
                                }
        });
      },
      minLength: 2,autoFocus: true,
      select: function(event, ui){
        //do sth with the result : ui.item. .... value, picture, db_id ...
        $(prefix+".elrte_diveboard_search_spinner").removeClass("visible");
        $(prefix+".elrte_diveboard_href").val(ui.item.href);
        $(prefix+".elrte_diveboard_title").val(ui.item.value);
        },
      close: function(event, ui){ $(prefix+".elrte_diveboard_search_spinner").removeClass("visible"); }
    });
  $.ui.autocomplete.prototype._renderItem = function (ul, item) {
      item.label = item.label.replace(new RegExp("(?![^&;]+;)(?!<[^<>]*)(" + $.ui.autocomplete.escapeRegex(this.term) + ")(?![^<>]*>)(?![^&;]+;)", "gi"), "<strong>$1</strong>");
      return $("<li></li>")
        .data("item.autocomplete", item)
        .append("<a>" + item.label + "</a>")
        .appendTo(ul);
    };

}

