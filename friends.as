package {
  import flash.display.Shape;
  import flash.display.Sprite;
  import flash.events.MouseEvent;
  import flash.events.TimerEvent;
  import flash.external.ExternalInterface;
  import flash.geom.Point;
  import flash.text.TextField;
  import flash.text.TextFormat;
  import flash.utils.Timer;

  public class Friends {
    public static const TEXT_FORMAT_ONLINE:TextFormat = new TextFormat("Open Sans",11,16250871,false,false,false,false,false,"right");
    public static const TEXT_FORMAT_REQUESTS:TextFormat = new TextFormat("Open Sans",10,16201328,true);
    public static const TEXT_FORMAT_HEADERS:TextFormat = new TextFormat("Open Sans",9,4738417,false);
    public static const FRIENDS_ONLINE:String = config.msg.FRIENDS + " " + config.msg.ONLINE;
    public static const ADD_FRIEND:* = config.msg.ADD + " " + config.msg.FRIEND.toUpperCase();

    private var _init:Boolean = false;
    public var container:Sprite;
    public var clipping_mask:Sprite;
    public var header_section:Sprite;
    public var scroll:Object;
    private var sort_timer:Timer;
    public var _requests:TextField;
    public var full_list:Sprite;
    private var num_online:int = 0;
    public var lookup:Object;

    private var _online:TextField;
    private var circle:Shape;

    public var header_btns:Array = [];
    public var header_items:Array = [];
    private var help_area:Sprite;
    private var help_area_quick:Sprite;

    // Tab constants
    private var _tab:int = 0;
    public static const TAB_ALL:uint = 0;
    public static const TAB_FAV:uint = 1;
    public static const TAB_QUICK:uint = 2;
    public static const TAB_REQUEST:uint = 3;
    public static const TAB_IGNORED:uint = 4;

    // List arrays
    public var list:Array = [];
    public var list_fav:Array = [];
    public var list_request:Array = [];
    public var list_default:Array = [];
    public var list_ignored:Array = [];
    public var render_list:Array = [];

    // Color arrays
    private var chooseColor:Sprite;
    private var color_btns:Array = [];
    public var list_colors:Object = {
      "red": [],
      "orange": [],
      "yellow": [],
      "green": [],
      "cyan": [],
      "blue": [],
      "purple": []
    };

    private var pickColor:Sprite;
    private var color_pick_btns:Array = [];

    // Keyboard
    private var keyboard:Sprite;

    public var characters:Array = ["1","2","3","4","5","6","7","8","9","0",
                                  "Q","W","E","R","T","Y","U","I","O","P",
                                  "A","S","D","F","G","H","J","K","L","_",
                                  "Z","X","C","V","B","N","M"];

    public var filter:String = "";
    public var filter_text:TextField;

    public function Friends() {
      super();
      this.lookup = {};
      this.buildContainer();
      this.tab = config.cfg.default_tab;
    }

    public function set tab(tab:int) : void {
      var items:Array = null;
      var idx:int = 0;

      // Remove the color picker and keyboard if leaving the all tab
      if(tab != TAB_ALL) {
        if(this.chooseColor.stage) this.header_section.removeChild(this.chooseColor);
        if(this.keyboard.stage) this.header_section.removeChild(this.keyboard);
        this.filter = "";
        this.filter_text.text = "";
      }

      // Remove the color picker if it's not the quick list
      if(tab != TAB_QUICK && this.pickColor.stage) this.header_section.removeChild(this.pickColor);
      else if(tab == TAB_QUICK && !this.pickColor.stage) {
        // remove the childs from the color picker
        for each(var btn:ColorBtn in this.color_pick_btns) this.pickColor.removeChild(btn);
        this.color_pick_btns = [];

        for (var i:int = 0; i < 7; i++) {
          // calculate the x position of the color button based on the width of the previous button
          var new_x:int = i > 0 ? this.color_pick_btns[i-1].width + this.color_pick_btns[i-1].x + 5 : 140+8;
          this.color_pick_btns.push(new ColorBtn(5, config.colors[i], new_x, 36));
          this.color_pick_btns[i].toggled = config.cfg.active_color == config.colors[i];
          this.color_pick_btns[i].addEventListener(MouseEvent.CLICK, this["changeColor" + config.colors[i].charAt(0).toUpperCase() + config.colors[i].slice(1)]);
          this.color_pick_btns[i].addEventListener(MouseEvent.RIGHT_CLICK, this["inviteColor" + config.colors[i].charAt(0).toUpperCase() + config.colors[i].slice(1)]);
        }

        for each(var btn:ColorBtn in this.color_pick_btns) this.pickColor.addChild(btn);

        this.header_section.addChild(this.pickColor);
      }

      // ---
      if(tab > TAB_IGNORED) tab = int(TAB_ALL);
      if(tab != this._tab || !this._init) {
        this.header_btns[this._tab].toggled = false;
        this.header_btns[tab].toggled = true;
        this.container.y = 1;
        this.scroll.scrubber.y = 0;
        items = this.header_items[tab];
        if(items) {
          idx = 0;
          while(idx < items.length) {
            if(!items[idx].stage) this.header_section.addChild(items[idx]);
            idx++;
          }
        }

        items = this.header_items[this._tab];
        if(items) {
          idx = 0;
          while(idx < items.length) {
            if(items[idx].stage) this.header_section.removeChild(items[idx]);
            idx++;
          }
        }

        if(TAB_ALL <= tab && tab <= TAB_REQUEST && this._init) {
          config.cfg.default_tab = tab;
          config.configWrite("default_tab");
        }
        this._tab = tab;
        this.onSortTimerComplete();
        this._init = true;
      }
    }

    public function get tab() : int {
      return this._tab;
    }

    public function set online(num:int) : void {
      if(!this.circle.stage) this.header_section.addChild(this.circle);

      if(this.tab == TAB_ALL) {
        this._online.htmlText = "<b>" + num + "</b><font color=\"#CECED7\">/" + (this.list.length - this.list_request.length - this.list_ignored.length) + "</font>";
        this._online.x = 305;
      } else {
        this._online.htmlText = "";
        if(this.tab == TAB_QUICK) {
          this._online.htmlText = "<font color=\"#CECED7\">"+this.list_colors[config.cfg.active_color].length+"</font>";
          this._online.x = 335;
        }
        if(this.circle.stage) this.header_section.removeChild(this.circle);
      }

      this.num_online = num;
    }

    public function get online() : int {
      return this.num_online;
    }

    public function get requests() : Number {
      return this._requests.text != "" ? Number(this._requests.text) : 0;
    }

    public function set requests(num:Number) : void {
      this._requests.text = num.toString() != 0 ? num.toString() : "";
    }

    public function add(uid:String, name:String, is_online:Boolean = false, world:String = "", rank:String = "", can_join:Boolean = false, is_request:Boolean = false, can_accept:Boolean = false, can_invite:Boolean = false, team_pvp_enabled:Boolean = false, is_ignored:Boolean = false, highlight:Boolean = false) : void {
      if(this.lookup[uid]) return this.update(uid,name,is_online,world,rank,can_join,is_request,can_accept,can_invite,team_pvp_enabled,is_ignored,highlight);
      if(name == "" && config.cfg.drop_nameless) return;

      var friend:Friend = new Friend(uid,name,is_online,world,rank,can_join,is_request,can_accept,can_invite,team_pvp_enabled,is_ignored,highlight,this);
      this.lookup[friend.uid] = friend;
      this.list.push(friend);

      if(friend.is_request) this.list_request.push(friend);
      else if(friend.is_ignored) this.list_ignored.push(friend);
      else if(config.favs[friend.uid]) this.list_fav.push(friend);
      else this.list_default.push(friend);

      for each (var color:String in config.colors)
        if(config[color][friend.uid])
          this.list_colors[color].push(friend);

      if(is_online) ++this.online;
      else if(is_request && can_accept) {
        this.requests++;
        this.header_items[TAB_REQUEST][1].count = this.requests;
      }
      this.queueDelayedSort();
    }

    public function update(uid:String, name:String, is_online:Boolean, world:String, rank:String, can_join:Boolean, is_request:Boolean, can_accept:Boolean, can_invite:Boolean, team_pvp_enabled:Boolean, is_ignored:Boolean, highlight:Boolean) : void {
      var idx:int = this.list.indexOf(this.lookup[uid]);
      if(idx == -1) return this.add(uid,name,is_online,world,rank,can_join,is_request,can_accept,can_invite,team_pvp_enabled,is_ignored,highlight);

      var friend:Friend = this.list[idx];
      var state_changed:Boolean = friend.is_online != is_online;
      if(friend.can_accept && !can_accept) {
        this.requests--;
        this.header_items[TAB_REQUEST][1].count = this.requests;
      }
      friend.name = name != "" ? name : friend.name;
      friend.is_online = is_online;
      friend.world = world;
      friend.rank = rank;
      friend.can_join = can_join;
      friend.is_request = is_request;
      friend.can_accept = can_accept;
      friend.can_invite = can_invite;
      friend.team_pvp_enabled = team_pvp_enabled;
      friend.is_ignored = is_ignored;
      friend.highlight = highlight;
      if(state_changed) {
        this.online += is_online ? 1 : -1;
        this.queueDelayedSort();
      }
    }

    public function remove(uid:String) : void {
      var f:Friend = this.lookup[uid];
      var idx:int = this.list.indexOf(f);
      if(idx == -1) return;

      this.list.splice(idx,1);
      if(f.is_online) --this.online;
      else if(f.is_request && f.can_accept) {
        --this.requests;
        this.header_items[TAB_REQUEST][1].count = this.requests;
      }

      idx = this.list_fav.indexOf(f);
      if(idx != -1) this.list_fav.splice(idx,1);

      idx = this.list_request.indexOf(f);
      if(idx != -1) this.list_request.splice(idx,1);

      idx = this.list_ignored.indexOf(f);
      if(idx != -1) this.list_ignored.splice(idx,1);

      idx = this.list_default.indexOf(f);
      if(idx != -1) this.list_default.splice(idx,1);

      for each (var color:String in config.colors) {
        idx = this.list_colors[color].indexOf(f);
        if(idx != -1) this.list_colors[color].splice(idx, 1);
      }

      idx = this.render_list.indexOf(f);
      if(idx != -1) {
        if(f.row.stage) {
          this.container.removeChild(f.row);
          this.onSortTimerComplete();
        }
        this.render_list.splice(idx,1);
      }

      this.lookup[uid] = null;
      this.queueDelayedSort();
    }

    public function clear() : void {
      this.list_default.splice(0);
      this.list_fav.splice(0);
      this.list_request.splice(0);
      this.list_ignored.splice(0);
      for each (var color:String in config.colors) this.list_colors[color].splice(0);

      this.onSortTimerComplete();
      this.destroyAllReferences();
      this.online = 0;
      this.header_items[TAB_REQUEST][1].count = 0;
      this.requests = 0;
      this.lookup = {};
    }

    private function destroyAllReferences() : void {
      var f:Friend = null;
      var idx:int = int(this.list.length);
      while(idx--) {
        f = this.list[idx];
        if(f.seen && f.row.stage) this.container.removeChild(f.row);
        this.lookup[f] = null;
        this.list.pop();
      }
    }

    public function getByUid(uid:String) : Friend {
      return this.lookup[uid];
    }

    private function buildContainer() : void {
      this.full_list = renderer.rectangle(new Sprite(), 0, 0, 364, 42, renderer.GRAY_16, 1);
      this.full_list.x = 5;
      this.full_list.y = 150 + config.cfg.vertical_offset;

      this.container = new Sprite();
      this.container.x = 1;
      this.container.y = 1;

      renderer.rectangle(this.full_list, 1, 1, 355, 40, renderer.GRAY_22, 1);
      this.clipping_mask = renderer.rectangle(new Sprite(), 0, 0, 355, 1, 16711935, 1);
      this.clipping_mask.x = 1;
      this.clipping_mask.y = 1;
      this.container.mask = this.clipping_mask;

      this.buildScrollbar();
      this.buildHeaderSection();

      this.full_list.addChild(this.scroll.bar);
      this.full_list.addChild(this.container);
      this.full_list.addChild(this.clipping_mask);
      this.full_list.addChild(this.header_section);
      this.full_list.visible = false;
    }

    public function applyOffset(val:int) : void {
      this.full_list.y = 150 + val;
    }

    public function updateLayoutExternal() : void {
      this.onSortTimerComplete();
    }

    private function buildHeaderSection() : void {
      this.header_section = renderer.rectangle(new Sprite(), 0, -1, 357, 45, renderer.GRAY_22, 1);
      renderer.rectangle(this.header_section, 0, 29, 357, 15, renderer.GRAY_16, 1);

      this.header_section.y = -43;

      // Add a green circle to the left of the header
      this.circle = new Shape();
      renderer.circle(this.circle, 300, 15, 3, renderer.GREEN, 1);
      this.circle.y = -1;
      this.header_section.addChild(this.circle);

      this._online = renderer.text(305, 4, TEXT_FORMAT_ONLINE, "left", true, "0 / 0");
      this._online.width = 50;
      this.header_section.addChild(this._online);

      this.buildTabButtons();
      this.buildHeaderItems();

      // notification
      this._requests = renderer.text(0, 0, TEXT_FORMAT_REQUESTS, "", true, "");
      this._requests.x = 117;
      this._requests.y = -1;
      this.header_section.addChild(this._requests);

      this.help_area = renderer.rectangle(new Sprite(), 365, -1, 200, 45, renderer.GRAY_12, 1);
      this.help_area = renderer.rectangle(this.help_area, 366, 0, 198, 43, renderer.GRAY_30, 1);
      var temp_text:TextField = renderer.text(367, 3, TEXT_FORMAT_ONLINE, "left", true, "");
      temp_text.htmlText = "<b>LEFT-CLICK</b> player to Whisper";
      temp_text.textColor = renderer.WHITE;
      this.help_area.addChild(temp_text);

      temp_text = renderer.text(367, 20, TEXT_FORMAT_ONLINE, "left", true, "");
      temp_text.htmlText = "<b>RIGHT-CLICK</b> player to remove him.";
      this.help_area.addChild(temp_text);

      this.help_area_quick = renderer.rectangle(new Sprite(), 365, -1, 215, 45, renderer.GRAY_12, 1);
      this.help_area_quick = renderer.rectangle(this.help_area_quick, 366, 0, 213, 43, renderer.GRAY_30, 1);
      temp_text = renderer.text(367, 3, TEXT_FORMAT_ONLINE, "left", true, "");
      temp_text.htmlText = "<b>LEFT-CLICK</b> color to go to that list";
      this.help_area_quick.addChild(temp_text);

      temp_text = renderer.text(367, 20, TEXT_FORMAT_ONLINE, "left", true, "");
      temp_text.htmlText = "<b>RIGHT-CLICK</b> color to invite all on that list.";
      this.help_area_quick.addChild(temp_text);

      var x:int = 368;

      // Setup color picker
      this.chooseColor = renderer.rectangle(new Sprite(), 365, -1, 190, 45, renderer.GRAY_12, 1);
      this.chooseColor = renderer.rectangle(this.chooseColor, 366, 0, 188, 43, renderer.GRAY_30, 1);
      this.pickColor = renderer.rectangle(new Sprite(), 0, 0, 0, 0, renderer.GRAY_12, 1);

      var color_text:TextField = renderer.text(367, 3, TEXT_FORMAT_ONLINE, "left", true, "Choose a color");
      color_text.textColor = renderer.WHITE;
      this.chooseColor.addChild(color_text);

      for (var i:int = 0; i < 7; i++) {
        // calculate the x position of the color button based on the width of the previous button
        var new_x:int = i > 0 ? this.color_btns[i-1].width + this.color_btns[i-1].x + 5 : 368+8;
        this.color_btns.push(new ColorBtn(5, config.colors[i], new_x, 30));
        this.color_btns[i].addEventListener(MouseEvent.CLICK, this["changeColor" + config.colors[i].charAt(0).toUpperCase() + config.colors[i].slice(1)]);
      }

      for each(var btn:ColorBtn in this.color_btns) this.chooseColor.addChild(btn);

      // Setup keyboard
      this.keyboard = renderer.rectangle(new Sprite(), 365, -1, 202, 104, renderer.GRAY_12, 1);
      this.keyboard = renderer.rectangle(this.keyboard, 366, 0, 200, 102, renderer.GRAY_30, 1);

      // Add text to see what you're typing
      filter_text = renderer.text(x, 1, TEXT_FORMAT_ONLINE, "left", true, "");
      filter_text.width = 200;
      filter_text.height = 20;
      filter_text.textColor = renderer.WHITE;
      this.keyboard.addChild(filter_text);

      // Add keys
      var key:KeyboardBtn = null;
      var idx:int = 0;
      while(idx < this.characters.length) {
        key = new KeyboardBtn(18, 18, this.characters[idx], 0, 0);
        key.x = idx % 10 * 20 + x;
        key.y = (int(idx / 10)+1) * 20 + 3;
        key.addEventListener(MouseEvent.CLICK, this.onClickKey);
        this.keyboard.addChild(key);
        idx++;
      }

      key = new KeyboardBtn(58, 18, "DEL", 0, 0);
      key.x = 7 * 20 + x;
      key.y = 4 * 20 + 3;
      key.addEventListener(MouseEvent.CLICK, this.deleteKey);
      this.keyboard.addChild(key);
    }

    private function buildTabButtons() : void {
      this.header_btns = [
        new icnbtn(config.scale(new IconFriends(), 0.75), 24, 24),
        new icnbtn(config.scale(new IconHeart(), 0.75), 24, 24),
        new icnbtn(config.scale(new IconQuickList(), 0.75), 24, 24),
        new icnbtn(config.scale(new IconRequest(), 0.75), 24, 24),
        new icnbtn(config.scale(new IconIgnore(), 0.75), 24, 24)
      ];

      for (var i:int = 0; i < this.header_btns.length; i++) {
        this.header_btns[i].x = i * 32 + 10;
        this.header_btns[i].y = 3;
        this.header_section.addChild(this.header_btns[i]);
      }

      this.header_btns[TAB_ALL].addEventListener(MouseEvent.CLICK,this.onTabAllClicked);
      this.header_btns[TAB_FAV].addEventListener(MouseEvent.CLICK,this.onTabFavClicked);
      this.header_btns[TAB_QUICK].addEventListener(MouseEvent.CLICK,this.onTabQuickClicked);
      this.header_btns[TAB_REQUEST].addEventListener(MouseEvent.CLICK,this.onTabRequestClicked);
      this.header_btns[TAB_IGNORED].addEventListener(MouseEvent.CLICK,this.onTabIgnoredClicked);
    }

    private function buildHeaderItems() : void {
      var all:Array = [
        new KeyboardBtn(125, 13, ADD_FRIEND, 1, 30, true),
        new KeyboardBtn(60, 13, "SEARCH", 127, 30, true),
        new KeyboardBtn(48, 13, "COLOR", 188, 30, true),
        new KeyboardBtn(14, 13, "?", 237, 30, true),
        renderer.text(268, 28, TEXT_FORMAT_HEADERS, "left", true, config.msg.INVITE),
        renderer.text(316, 28, TEXT_FORMAT_HEADERS, "left", true, config.msg.JOIN)
      ];
      this.header_items[TAB_ALL] = all;

      var fav:Array = [
        renderer.text(1, 28, TEXT_FORMAT_HEADERS, "left", true, "FAVORITES"),
        renderer.text(268, 28, TEXT_FORMAT_HEADERS, "left", true, config.msg.INVITE),
        renderer.text(316, 28, TEXT_FORMAT_HEADERS, "left", true, config.msg.JOIN)
      ];
      this.header_items[TAB_FAV] = fav;

      var quick:Array = [
        renderer.text(1, 28, TEXT_FORMAT_HEADERS, "left", true, "QUICK LIST"),
        new KeyboardBtn(14, 13, "?", 327, 30, true),
        new KeyboardBtn(14, 13, "x", 342, 30, true)
      ];
      this.header_items[TAB_QUICK] = quick;

      var request:Array = [
        renderer.text(1, 28, TEXT_FORMAT_HEADERS, "left", true, "FRIEND REQUESTS"),
        new KeyboardBtn(93, 13, "ACCEPT ALL", 263, 30, true)
      ];
      this.header_items[TAB_REQUEST] = request;

      var ignored:Array = [
        renderer.text(1, 28, TEXT_FORMAT_HEADERS, "left", true, "IGNORED PLAYERS"),
        new KeyboardBtn(93, 13, "ADD IGNORED", 263, 30, true)
      ];
      this.header_items[TAB_IGNORED] = ignored;

      //* All
      this.header_items[TAB_ALL][0].addEventListener(MouseEvent.CLICK, this.onAdd);
      this.header_items[TAB_ALL][1].addEventListener(MouseEvent.CLICK, this.onKeyboard);
      this.header_items[TAB_ALL][2].addEventListener(MouseEvent.CLICK, this.onPickColor);
      this.header_items[TAB_ALL][3].addEventListener(MouseEvent.MOUSE_OVER, this.onHelpMouseOver);
      this.header_items[TAB_ALL][3].addEventListener(MouseEvent.MOUSE_OUT, this.onHelpMouseOut);
      this.header_items[TAB_ALL][4].textColor = renderer.WHITE;
      this.header_items[TAB_ALL][5].textColor = renderer.WHITE;

      //* Favorites
      this.header_items[TAB_FAV][0].textColor = renderer.WHITE;
      this.header_items[TAB_FAV][1].textColor = renderer.WHITE;
      this.header_items[TAB_FAV][2].textColor = renderer.WHITE;

      //* Quick
      this.header_items[TAB_QUICK][0].textColor = renderer.WHITE;
      this.header_items[TAB_QUICK][1].addEventListener(MouseEvent.MOUSE_OVER, this.onHelpMouseOverQuick);
      this.header_items[TAB_QUICK][1].addEventListener(MouseEvent.MOUSE_OUT, this.onHelpMouseOutQuick);
      this.header_items[TAB_QUICK][2].addEventListener(MouseEvent.CLICK, this.onClearQuickList);

      //* Requests
      this.header_items[TAB_REQUEST][0].textColor = renderer.WHITE;
      this.header_items[TAB_REQUEST][1].addEventListener(MouseEvent.CLICK, this.onAcceptAll);
      this.header_items[TAB_REQUEST][1].count = 0;

      //* Ignored
      this.header_items[TAB_IGNORED][0].textColor = renderer.WHITE;
      this.header_items[TAB_IGNORED][1].addEventListener(MouseEvent.CLICK, this.onAdd);
    }

    /* ---------------- */
    /*   Other Events   */
    /* ---------------- */

    private function onHelpMouseOver() : void {
      if(!this.help_area.stage) this.header_section.addChild(this.help_area);
    }

    private function onHelpMouseOut() : void {
      if(this.help_area.stage) this.header_section.removeChild(this.help_area);
    }

    private function onHelpMouseOverQuick() : void {
      if(!this.help_area_quick.stage) this.header_section.addChild(this.help_area_quick);
    }

    private function onHelpMouseOutQuick() : void {
      if(this.help_area_quick.stage) this.header_section.removeChild(this.help_area_quick);
    }

    private function onPickColor() : void {
      if(this.keyboard.stage) this.header_section.removeChild(this.keyboard);
      if(!this.chooseColor.stage) {
        this.header_section.addChild(this.chooseColor);
        for (var i:int = 0; i < 7; i++) {
          this.color_btns[i].toggled = config.cfg.active_color == config.colors[i];
          this.color_btns[i].x = i > 0 ? this.color_btns[i-1].width + this.color_btns[i-1].x + 5 : 368+8;
        }
      } else this.header_section.removeChild(this.chooseColor);
    }

    private function onKeyboard() : void {
      if(this.chooseColor.stage) this.header_section.removeChild(this.chooseColor);
      if(!this.keyboard.stage) this.header_section.addChild(this.keyboard);
      else this.header_section.removeChild(this.keyboard);
    }

    public function onClickKey(e:MouseEvent) : void {
      this.filter += e.currentTarget.text;
      this.filter_text.text = this.filter;
      filterFriends();
    }

    private function deleteKey() : void {
      if (this.filter == "") return;
      this.filter = filter.substr(0, this.filter.length - 1);
      this.filter_text.text = this.filter;
      filterFriends();
    }

    /* ---------------- */
    /*   Click Events   */
    /* ---------------- */

    private function onClearQuickList() : void {
      var color:String = config.cfg.active_color;
      config[color] = {};
      config.configWrite(color);

      for each (var f:Friend in this.list_colors[color])
        f.refreshColors();

      this.list_colors[color].splice(0);
      this.onSortTimerComplete();
    }

    private function onAcceptAll() : void {
      var idx:int = int(this.list_request.length);
      while(idx--) {
        if(this.list_request[idx].can_accept) {
          this.list_request[idx].onAccept();
          this.list_request.splice(idx,1);
        }
      }
    }

    private function onAdd() : void {
      ExternalInterface.call("OnInvite");
    }

    /* ---------------- */
    /* TAB CLICK EVENTS */
    /* ---------------- */

    private function onTabAllClicked() : void {
      if(this.tab == TAB_IGNORED) {
        ExternalInterface.call("OnTabClick", 0);
        this._online.alpha = 1;
      }
      this.tab = TAB_ALL;
    }

    private function onTabFavClicked() : void {
      if(this.tab == TAB_IGNORED) {
        ExternalInterface.call("OnTabClick", 0);
        this._online.alpha = 1;
      }
      this.tab = TAB_FAV;
    }

    private function onTabQuickClicked() : void {
      if(this.tab == TAB_IGNORED) {
        ExternalInterface.call("OnTabClick", 0);
        this._online.alpha = 1;
      }

      this.tab = TAB_QUICK;
    }

    private function onTabRequestClicked() : void {
      if(this.tab == TAB_IGNORED) {
        ExternalInterface.call("OnTabClick",0);
        this._online.alpha = 1;
      }
      this.tab = TAB_REQUEST;
    }

    private function onTabIgnoredClicked() : void {
      if(this.tab != TAB_IGNORED) {
        ExternalInterface.call("OnTabClick",1);
        this._online.alpha = 0.5;
      }
      this.tab = TAB_IGNORED;
    }

    /* ---------------- */

    private function buildScrollbar() : void {
      this.scroll = {};
      this.scroll.color = [renderer.GRAY_38, renderer.GRAY_28];
      this.scroll.bar = renderer.rectangle(new Sprite(),0,0,6,40, renderer.GRAY_16,1);
      this.scroll.bar.mouseEnabled = true;
      this.scroll.bar.x = 357;
      this.scroll.bar.y = 1;
      this.scroll.scrubber = renderer.rectangle(new Shape(), 0, 0, 6, 40, this.scroll.color[0], 1);
      renderer.rectangle(this.scroll.scrubber, 1, 1, 4, 38, this.scroll.color[1], 1);
      this.scroll.bar.addChild(this.scroll.scrubber);
      this.scroll.zone = renderer.rectangle(new Sprite(), 0, 0, 1600, 400, 0, 0);
      this.scroll.zone.x = -400;
      this.scroll.zone.y = -400;
      this.scroll.zone.addEventListener(MouseEvent.MOUSE_MOVE,this.onMouseMove);
      this.scroll.bar.addEventListener(MouseEvent.MOUSE_DOWN,this.setScrollBarListener);
      this.scroll.bar.addEventListener(MouseEvent.MOUSE_UP,this.removeScrollBarListener);
      config.M.parent.addEventListener(MouseEvent.MOUSE_WHEEL,this.onMouseWheel);
    }

    private function onMouseWheel(e:MouseEvent) : void {
      var percent:Number = NaN;
      var temp:Point = new Point(this.full_list.x,this.full_list.y - 147 - config.cfg.vertical_offset);
      var min:Point = this.full_list.localToGlobal(temp);
      temp.x += this.header_section.width - 7;
      temp.y += this.scroll.bar.height;
      var max:Point = this.full_list.localToGlobal(temp);

      if(!this.scroll.bar.stage || !config.within(min.x,e.stageX,max.x) || !config.within(min.y,e.stageY,max.y)) return;

      if(!this.scroll.zone.stage) {
        this.container.y = config.clamp(this.container.y + 40 * (e.delta > 0 ? 1 : -1),-(Math.max(this.render_list.length * 40,1) - config.cfg.max_rows * 40),1);
        percent = this.container.y / -(this.render_list.length * 40 - config.cfg.max_rows * 40);
        this.scroll.scrubber.y = config.clamp(int((this.scroll.bar.height - this.scroll.scrubber.height) * percent + 0.5),0,this.scroll.bar.height - this.scroll.scrubber.height);
        this.setupRows();
      }
    }

    private function setScrollBarListener(e:MouseEvent) : void {
      this.scroll.bar.addChild(this.scroll.zone);
      if(e.localY >= this.scroll.scrubber.y && e.localY <= this.scroll.scrubber.y + this.scroll.scrubber.height) this.scroll.offset = this.scroll.scrubber.y - e.localY + this.scroll.scrubber.height / 2;
      else this.scroll.offset = 0;

      e.localY += 400;
      this.onMouseMove(e);
    }

    private function removeScrollBarListener(e:MouseEvent) : void {
      this.scroll.bar.removeChild(this.scroll.zone);
    }

    private function onMouseMove(e:MouseEvent) : void {
      var realY:int = e.localY - 400 + this.scroll.offset;
      this.scroll.scrubber.y = Math.max(0,Math.min(this.scroll.bar.height - this.scroll.scrubber.height - 800, realY - int(this.scroll.scrubber.height / 2)));
      var percent:Number = this.getScrollPercent();
      this.container.y = 1 - int(percent * (Math.max(this.render_list.length * 40,1) - config.cfg.max_rows * 40) + 0.5);
      this.setupRows();
    }

    private function getScrollPercent() : Number {
      if(!this.scroll.bar.stage) return 0;
      return this.scroll.scrubber.y / (this.scroll.bar.height - (!!this.scroll.zone.stage ? 800 : 0) - this.scroll.scrubber.height) || 0;
    }

    private function updateContainerSize() : void {
      this.full_list.visible = true;
      var h:int = Math.min(config.cfg.max_rows * 40 - 3,this.render_list.length * 40 - 3);
      var w:int = 357;
      this.scroll.scrubber.graphics.clear();
      this.scroll.bar.graphics.clear();
      this.scroll.zone.graphics.clear();
      this.header_section.graphics.clear();

      if(this.render_list.length > config.cfg.max_rows) {
        if(!this.scroll.bar.stage) this.full_list.addChild(this.scroll.bar);

        renderer.rectangle(this.scroll.scrubber, 0, 0, 6, config.getScrubberSize(this.render_list.length, 24), this.scroll.color[0], 1);
        renderer.rectangle(this.scroll.scrubber, 1, 1, 4, config.getScrubberSize(this.render_list.length, 24) - 2, this.scroll.color[1], 1);
        renderer.rectangle(this.scroll.bar, 0, 0, 6, h, renderer.GRAY_16,1);
        renderer.rectangle(this.scroll.zone, 0, 0, 1600, h + 800, 16711935, 0);
        w = 364;
      } else if(this.scroll.bar.stage) this.full_list.removeChild(this.scroll.bar);

      renderer.rectangle(this.header_section, 0, -1, w, 45, renderer.GRAY_22, 1);
      renderer.rectangle(this.header_section, 0, 29, w, 15, renderer.GRAY_16, 1);
      this.clipping_mask.scaleY = h;
      this.full_list.graphics.clear();
      renderer.rectangle(this.full_list, 0, 0, w, h + 2, renderer.GRAY_16,1);
      renderer.rectangle(this.full_list, 1, 1, 355, h, renderer.GRAY_25, 1);
      if(h <= 1) renderer.rectangle(this.full_list, 0, 0, w, 40, renderer.GRAY_16, 1);
    }

    private function updateRenderList() : void {
      this.render_list.splice(0);
      if(this.tab == TAB_REQUEST) {
        this.list_request.sortOn(["can_accept", "name"], [Array.DESCENDING, Array.CASEINSENSITIVE]);
        this.render_list = this.render_list.concat(this.list_request);
      } else if(this.tab == TAB_FAV) {
        this.list_fav.sortOn(["is_online", "name"], [Array.DESCENDING, Array.CASEINSENSITIVE]);
        this.render_list = this.render_list.concat(this.list_fav);
      } else if(this.tab == TAB_QUICK) {
        for each (var color:String in config.colors) {
          if (color == config.cfg.active_color) {
            this.list_colors[color].sortOn(["is_online", "name"], [Array.DESCENDING, Array.CASEINSENSITIVE]);
            this.render_list = this.render_list.concat(this.list_colors[color]);
          }
        }
      } else if(this.tab == TAB_IGNORED) {
        this.list_ignored.sortOn("name", Array.CASEINSENSITIVE);
        this.render_list = this.render_list.concat(this.list_ignored);
      } else {
        this.list_fav.sortOn(["is_online", "name"], [Array.DESCENDING, Array.CASEINSENSITIVE]);
        this.list_default.sortOn(["is_online", "name"], [Array.DESCENDING, Array.CASEINSENSITIVE]);
        this.render_list = this.render_list.concat(this.list_fav).concat(this.list_default);
      }
      this.online = this.online;
    }

    private function setupRows() : void {
      var rdx:int = 0;
      var spana:int = config.cfg.max_rows + 2;
      var spanb:int = int((config.cfg.max_rows + 5) * 40 + 0.5);
      var f:Friend = null;
      var idx:int = 0;
      var pos:int = Math.max(0,int(this.render_list.length * this.getScrollPercent() + 0.5));
      var mina:int = pos - spana;
      var maxa:int = pos + spana * 2;
      var minb:int = pos * 40 - spanb;
      var maxb:int = pos * 40 + spanb;
      var len:int = int(this.list.length);
      while(idx < len) {
        f = this.list[idx];
        rdx = this.render_list.indexOf(f);
        if(rdx != -1) {
          if(config.within(mina,rdx,maxa)) {
            if(!f.row.stage) this.container.addChild(f.row);
            f.row.y = rdx * 40;
            f.bg.visible = rdx % 2 != 0;
          } else if(f.seen && f.row.stage) this.container.removeChild(f.row);
        } else if(f.seen && (f.row.stage && config.within(minb,f.row.y,maxb))) this.container.removeChild(f.row);
        idx++;
      }
    }

    public function queueDelayedSort(wait:int = 77) : void {
      if(this.sort_timer != null) this.sort_timer.stop();
      this.sort_timer = new Timer(wait,1);
      this.sort_timer.addEventListener(TimerEvent.TIMER,this.onSortTimerComplete);
      this.sort_timer.start();
    }

    public function onSortTimerComplete() : void {
      this.updateRenderList();
      this.setupRows();
      this.updateContainerSize();
      if (this.filter != "")  this.filterFriends();
    }

    private function filterFriends() : void {
      this.list_fav.sortOn(["is_online", "name"], [Array.DESCENDING, Array.CASEINSENSITIVE]);
      this.list_default.sortOn(["is_online", "name"], [Array.DESCENDING, Array.CASEINSENSITIVE]);
      var list_all:Array = this.list_fav.concat(this.list_default);

      var filteredList:Array = [];
      for each (var f:Friend in list_all) {
        if (f.name.toLowerCase().indexOf(this.filter.toLowerCase()) != -1 || this.filter == "") {
          filteredList.push(f);
        }
      }

      this.render_list = filteredList;
      this.setupRows();
      this.updateContainerSize();
    }

    /* ---------------- */
    /*   ADD & REMOVE   */
    /* ---------------- */

    public function onFavoriteAdd(f:Friend) : void {
      if(this.list_fav.indexOf(f) == -1) this.list_fav.push(f);

      var idx:int = this.list_default.indexOf(f);
      if(idx != -1) this.list_default.splice(idx, 1);

      this.onSortTimerComplete();
      config.configWrite("favorites");
    }

    public function onFavoriteRemove(f:Friend) : void {
      var idx:int = this.list_fav.indexOf(f);
      if(idx != -1) {
        this.list_fav.splice(idx, 1);
        this.list_default.push(f);
        this.onSortTimerComplete();
      }
      config.configWrite("favorites");
    }

    public function onQuickListAdd(f:Friend) : void {
      // check what color is active (config.cfg["active_color"]) and add the friend to that list
      var color:String = config.cfg.active_color;
      if(this.list_colors[color].indexOf(f) == -1)
        this.list_colors[color].push(f);
    }

    public function onQuickListRemove(f:Friend) : void {
      // check what color is active (config.cfg["active_color"]) and remove the friend from that list
      var color:String = config.cfg.active_color;
      var idx:int = this.list_colors[color].indexOf(f);

      if(idx != -1) {
        this.list_colors[color].splice(idx, 1);
        if (this.tab == TAB_QUICK) this.onSortTimerComplete();
      }
    }

    /* ---------------- */
    /*   COLOR EVENTS   */
    /* ---------------- */
    private function changeColorRed() : void {
      if (this.checkIfUnselected("red")) return;
      for (var i:int = 0; i < 7; i++) {
        if (i != 0) {
          this.color_btns[i].toggled = false;
          if (this.color_pick_btns[i]) this.color_pick_btns[i].toggled = false;
        }
      }
      this.color_btns[0].toggled = !this.color_btns[0].toggled;
      if (this.color_pick_btns[0]) this.color_pick_btns[0].toggled = !this.color_pick_btns[0].toggled;
      config.cfg.active_color = "red";
      config.configWrite("active_color");
      this.updateQuickListColor();
    }

    private function changeColorOrange() : void {
      if (this.checkIfUnselected("orange")) return;
      for (var i:int = 0; i < 7; i++) {
        if (i != 1) {
          this.color_btns[i].toggled = false;
          if (this.color_pick_btns[i]) this.color_pick_btns[i].toggled = false;
        }
      }
      this.color_btns[1].toggled = !this.color_btns[1].toggled;
      if (this.color_pick_btns[1]) this.color_pick_btns[1].toggled = !this.color_pick_btns[1].toggled;
      config.cfg.active_color = "orange";
      config.configWrite("active_color");
      this.updateQuickListColor();
    }

    private function changeColorYellow() : void {
      if (this.checkIfUnselected("yellow")) return;
      for (var i:int = 0; i < 7; i++) {
        if (i != 2) {
          this.color_btns[i].toggled = false;
          if (this.color_pick_btns[i]) this.color_pick_btns[i].toggled = false;
        }
      }
      this.color_btns[2].toggled = !this.color_btns[2].toggled;
      if (this.color_pick_btns[2]) this.color_pick_btns[2].toggled = !this.color_pick_btns[2].toggled;
      config.cfg.active_color = "yellow";
      config.configWrite("active_color");
      this.updateQuickListColor();
    }

    private function changeColorGreen() : void {
      if (this.checkIfUnselected("green")) return;
      for (var i:int = 0; i < 7; i++) {
        if (i != 3) {
          this.color_btns[i].toggled = false;
          if (this.color_pick_btns[i]) this.color_pick_btns[i].toggled = false;
        }
      }
      this.color_btns[3].toggled = !this.color_btns[3].toggled;
      if (this.color_pick_btns[3]) this.color_pick_btns[3].toggled = !this.color_pick_btns[3].toggled;
      config.cfg.active_color = "green";
      config.configWrite("active_color");
      this.updateQuickListColor();
    }

    private function changeColorCyan() : void {
      if (this.checkIfUnselected("cyan")) return;
      for (var i:int = 0; i < 7; i++) {
        if (i != 4) {
          this.color_btns[i].toggled = false;
          if (this.color_pick_btns[i]) this.color_pick_btns[i].toggled = false;
        }
      }
      this.color_btns[4].toggled = !this.color_btns[4].toggled;
      if (this.color_pick_btns[4]) this.color_pick_btns[4].toggled = !this.color_pick_btns[4].toggled;
      config.cfg.active_color = "cyan";
      config.configWrite("active_color");
      this.updateQuickListColor();
    }

    private function changeColorBlue() : void {
      if (this.checkIfUnselected("blue")) return;
      for (var i:int = 0; i < 7; i++) {
        if (i != 5) {
          this.color_btns[i].toggled = false;
          if (this.color_pick_btns[i]) this.color_pick_btns[i].toggled = false;
        }
      }
      this.color_btns[5].toggled = !this.color_btns[5].toggled;
      if (this.color_pick_btns[5]) this.color_pick_btns[5].toggled = !this.color_pick_btns[5].toggled;
      config.cfg.active_color = "blue";
      config.configWrite("active_color");
      this.updateQuickListColor();
    }

    private function changeColorPurple() : void {
      if (this.checkIfUnselected("purple")) return;
      for (var i:int = 0; i < 7; i++) {
        if (i != 6) {
          this.color_btns[i].toggled = false;
          if (this.color_pick_btns[i]) this.color_pick_btns[i].toggled = false;
        }
      }
      this.color_btns[6].toggled = !this.color_btns[6].toggled;
      if (this.color_pick_btns[6]) this.color_pick_btns[6].toggled = !this.color_pick_btns[6].toggled;
      config.cfg.active_color = "purple";
      config.configWrite("active_color");
      this.updateQuickListColor();
    }

    private function inviteColorRed() : void {
      for each (var f:Friend in this.list_colors["red"]) f.onInvite();
    }

    private function inviteColorOrange() : void {
      for each (var f:Friend in this.list_colors["orange"]) f.onInvite();
    }

    private function inviteColorYellow() : void {
      for each (var f:Friend in this.list_colors["yellow"]) f.onInvite();
    }

    private function inviteColorGreen() : void {
      for each (var f:Friend in this.list_colors["green"]) f.onInvite();
    }

    private function inviteColorCyan() : void {
      for each (var f:Friend in this.list_colors["cyan"]) f.onInvite();
    }

    private function inviteColorBlue() : void {
      for each (var f:Friend in this.list_colors["blue"]) f.onInvite();
    }

    private function inviteColorPurple() : void {
      for each (var f:Friend in this.list_colors["purple"]) f.onInvite();
    }

    private function checkIfUnselected(color:String) : Boolean {
      // if the color selected is the same as the active color then don't allow it to be unselected
      return config.cfg.active_color == color;
    }

    private function updateQuickListColor() : void {
      this.onSortTimerComplete();

      for (var i:int = 0; i < 7; i++) {
        this.color_btns[i].x = i > 0 ? this.color_btns[i-1].width + this.color_btns[i-1].x + 5 : 368+8;
        if (this.color_pick_btns[i])
          this.color_pick_btns[i].x = i > 0 ? this.color_pick_btns[i-1].width + this.color_pick_btns[i-1].x + 5 : 140+8;
      }

      for each (var f:Friend in this.render_list) {
        f.updateQuickListBtn();
        f.btnQuickList.updateColor();
      }
    }
  }
}
