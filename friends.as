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
    public static const FRIENDS_ONLINE:String = abi.msg.FRIENDS + " " + abi.msg.ONLINE;
    public static const ADD_FRIEND:* = abi.msg.ADD + " " + abi.msg.FRIEND.toUpperCase();

    private var _init:Boolean = false;
    public var container:Sprite;
    public var clipping_mask:Sprite;
    public var header_section:Sprite;
    public var scroll:Object;
    private var sort_timer:Timer;
    public var _requests:TextField;
    public var full_list:Sprite;
    private var _online:TextField;
    private var num_online:int = 0;
    private var _tab:int = 0;
    public var lookup:Object;

    public var leechers_count:int = 0;
    public var cleaners_count:int = 0;

    public var header_btns:Array = [];
    public var header_items:Array = [];
    private var help_area:Sprite;

    // Tab constants
    public static const TAB_ALL:uint = 0;
    public static const TAB_FAV:uint = 1;
    public static const TAB_ALTS:uint = 2;
    public static const TAB_QUICK:uint = 3;
    public static const TAB_SHIP:uint = 4;
    public static const TAB_REQUEST:uint = 5;
    public static const TAB_IGNORED:uint = 6;

    // List arrays
    public var list:Array = [];
    public var list_fav:Array = [];
    public var list_request:Array = [];
    public var list_quick:Array = [];
    public var list_default:Array = [];
    public var list_ignored:Array = [];
    public var render_list:Array = [];
    public var list_cleaners:Array = [];
    public var list_leechers:Array = [];
    public var list_alts:Array = [];

    public function Friends() {
      super();
      this.lookup = {};
      this.buildContainer();
      this.tab = abi.cfg.default_tab;
    }

    public function set tab(tab:int) : void {
      var items:Array = null;
      var idx:int = 0;
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
          abi.cfg.default_tab = tab;
          abi.configWrite("default_tab");
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
      if(tab == TAB_SHIP) {
        this._online.htmlText = "<font color=\"#CECED7\" size=\"9\">" + this.leechers_count + " LEECHES / " + this.cleaners_count + " CLEANERS</font>";
      } else if(this.tab != TAB_IGNORED) {
        this._online.htmlText = "<b>" + num + "</b><font color=\"#CECED7\">/" + (this.list.length - this.list_request.length - this.list_ignored.length) + "</font> " + FRIENDS_ONLINE;
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
      if(name == "" && abi.cfg.drop_nameless) return;

      var friend:Friend = new Friend(uid,name,is_online,world,rank,can_join,is_request,can_accept,can_invite,team_pvp_enabled,is_ignored,highlight,this);
      this.lookup[friend.uid] = friend;
      this.list.push(friend);

      if(abi.favs[friend.uid]) this.list_fav.push(friend);
      else if(abi.alts[friend.uid]) this.list_alts.push(friend);
      else if(friend.is_request) this.list_request.push(friend);
      else if(friend.is_ignored) this.list_ignored.push(friend);
      else this.list_default.push(friend);

      if(abi.quick[friend.uid]) {
        this.list_quick.push(friend);
        this.header_items[TAB_QUICK][2].count++;
      }

      if(abi.leechers[friend.uid]) {
        this.list_leechers.push(friend);
        this.leechers_count++;
      }

      if(abi.cleaners[friend.uid]) {
        this.list_cleaners.push(friend);
        this.cleaners_count++;
      }

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
      if(f.is_online) {
        if(abi.quick[f.uid]) this.header_items[TAB_QUICK][2].count--;
        if(abi.leechers[f.uid]) this.leechers_count--;
        if(abi.cleaners[f.uid]) this.cleaners_count--;
        --this.online;
      } else if(f.is_request && f.can_accept) {
        --this.requests;
        this.header_items[TAB_REQUEST][1].count = this.requests;
      }

      idx = this.list_fav.indexOf(f);
      if(idx != -1) this.list_fav.splice(idx,1);

      idx = this.list_request.indexOf(f);
      if(idx != -1) this.list_request.splice(idx,1);

      idx = this.list_quick.indexOf(f);
      if(idx != -1) this.list_quick.splice(idx,1);

      idx = this.list_ignored.indexOf(f);
      if(idx != -1) this.list_ignored.splice(idx,1);

      idx = this.list_cleaners.indexOf(f);
      if(idx != -1) this.list_cleaners.splice(idx,1);

      idx = this.list_leechers.indexOf(f);
      if(idx != -1) this.list_leechers.splice(idx,1);

      idx = this.list_alts.indexOf(f);
      if(idx != -1) this.list_alts.splice(idx,1);

      idx = this.list_default.indexOf(f);
      if(idx != -1) this.list_default.splice(idx,1);

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
      this.list_quick.splice(0);
      this.list_ignored.splice(0);
      this.list_leechers.splice(0);
      this.list_cleaners.splice(0);
      this.list_alts.splice(0);
      this.onSortTimerComplete();
      this.destroyAllReferences();
      this.online = 0;
      this.header_items[TAB_QUICK][2].count = 0;
      this.header_items[TAB_REQUEST][1].count = 0;
      this.leechers_count = 0;
      this.cleaners_count = 0;
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
      this.full_list = renderer.rectangle(new Sprite(),0,0,364,42,986907,1);
      this.full_list.x = 5;
      this.full_list.y = 150 + abi.cfg.vertical_offset;
      this.container = new Sprite();
      this.container.x = 1;
      this.container.y = 1;
      renderer.rectangle(this.full_list,1,1,355,40,1776433,1);
      this.clipping_mask = renderer.rectangle(new Sprite(),0,0,355,1,16711935,1);
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
      this.header_section = renderer.rectangle(new Sprite(),0,-1,357,45,986907,1);
      renderer.rectangle(this.header_section,0,29,357,15,855319,1);
      this.header_section.y = -43;
      this._online = renderer.text(0,0,TEXT_FORMAT_ONLINE,"",true,"0 / 0 Friends Online");
      this._online.width = 355;
      this._online.y = 4;
      this._online.height = 16;
      this.header_section.addChild(this._online);
      this.buildTabButtons();
      this.buildHeaderItems();
      this._requests = renderer.text(0,0,TEXT_FORMAT_REQUESTS,"",true,"");
      this._requests.x = 147;
      this._requests.y = -1;
      this.header_section.addChild(this._requests);
      this.help_area = renderer.rectangle(new Sprite(),365,-1,3 * 60,45,855319,1);
      this.help_area = renderer.rectangle(this.help_area,366,0,178,43,986907,1);
      var temp_text:TextField = renderer.text(367,3,TEXT_FORMAT_ONLINE,"left",true,"");
      temp_text.htmlText = "<b>LEFT-CLICK</b> player to <b>Whisper\nRIGHT-CLICK</b> player to <b>Remove</b>";
      this.help_area.addChild(temp_text);
    }

    private function buildTabButtons() : void {
      this.header_btns = [
        new abbtn(abi.scale(new IconFriends(), 0.75), 24, 24),
        new abbtn(abi.scale(new IconHeart(), 0.75), 24, 24),
        new abbtn(abi.scale(new IconAlts(), 0.75), 24, 24),
        new abbtn(abi.scale(new IconQuickList(), 0.75), 24, 24),
        new abbtn(abi.scale(new IconShip(), 0.75), 24, 24),
        new abbtn(abi.scale(new IconRequest(), 0.75), 24, 24),
        new abbtn(abi.scale(new IconIgnore(), 0.75), 24, 24)
      ];

      for (var i:int = 0; i < this.header_btns.length; i++) {
        this.header_btns[i].x = i * 32 + 10;
        this.header_btns[i].y = 3;
        this.header_section.addChild(this.header_btns[i]);
      }

      this.header_btns[TAB_ALL].addEventListener(MouseEvent.CLICK,this.onTabAllClicked);
      this.header_btns[TAB_FAV].addEventListener(MouseEvent.CLICK,this.onTabFavClicked);
      this.header_btns[TAB_ALTS].addEventListener(MouseEvent.CLICK,this.onTabAltsClicked);
      this.header_btns[TAB_QUICK].addEventListener(MouseEvent.CLICK,this.onTabQuickClicked);
      this.header_btns[TAB_SHIP].addEventListener(MouseEvent.CLICK,this.onTabShipClicked);
      this.header_btns[TAB_REQUEST].addEventListener(MouseEvent.CLICK,this.onTabRequestClicked);
      this.header_btns[TAB_IGNORED].addEventListener(MouseEvent.CLICK,this.onTabIgnoredClicked);
    }

    private function buildHeaderItems() : void {
      var all:Array = [
        new txtbtn(235,13,ADD_FRIEND,1,30),
        new txtbtn(14,13,"?",237,30),
        renderer.text(268,28,TEXT_FORMAT_HEADERS,"left",true,abi.msg.INVITE),
        renderer.text(316,28,TEXT_FORMAT_HEADERS,"left",true,abi.msg.JOIN)
      ];
      this.header_items[TAB_ALL] = all;

      var fav:Array = [
        renderer.text(1,28,TEXT_FORMAT_HEADERS,"left",true,"FAVORITES"),
        renderer.text(268,28,TEXT_FORMAT_HEADERS,"left",true,abi.msg.INVITE),
        renderer.text(316,28,TEXT_FORMAT_HEADERS,"left",true,abi.msg.JOIN)
      ];
      this.header_items[TAB_FAV] = fav;

      var alts:Array = [
        renderer.text(1,28,TEXT_FORMAT_HEADERS,"left",true,"ALTS"),
        new txtbtn(93, 13, "INVITE ALL", 263, 30)
      ];
      this.header_items[TAB_ALTS] = alts;

      var quick:Array = [
        renderer.text(1,28,TEXT_FORMAT_HEADERS,"left",true,"QUICK LIST"),
        new txtbtn(14,13,"x",248,30),
        new txtbtn(93,13,"INVITE ALL",263,30)
      ];
      this.header_items[TAB_QUICK] = quick;

      var request:Array = [
        renderer.text(1,28,TEXT_FORMAT_HEADERS,"left",true,"FRIEND REQUESTS"),
        new txtbtn(93,13,"ACCEPT ALL",263,30)
      ];
      this.header_items[TAB_REQUEST] = request;

      var ignored:Array = [
        renderer.text(1,28,TEXT_FORMAT_HEADERS,"left",true,"IGNORED PLAYERS"),
        new txtbtn(93,13,"ADD IGNORED",263,30)
      ];
      this.header_items[TAB_IGNORED] = ignored;

      var ship:Array = [
        renderer.text(1, 28, TEXT_FORMAT_HEADERS, "left", true, "SHIP LIST"),
        new txtbtn(14, 13, "x", 188, 30),
        new txtbtn(46, 13, "ALL", 203, 30),
        new txtbtn(53, 13, "CLEANERS", 250, 30),
        new txtbtn(53, 13, "LEECHERS", 304, 30)
      ];
      this.header_items[TAB_SHIP] = ship;

      this.header_items[TAB_ALL][0].addEventListener(MouseEvent.CLICK,this.onAdd);
      this.header_items[TAB_ALL][1].addEventListener(MouseEvent.MOUSE_OVER,this.onHelpMouseOver);
      this.header_items[TAB_ALL][1].addEventListener(MouseEvent.MOUSE_OUT,this.onHelpMouseOut);

      this.header_items[TAB_ALTS][1].addClickListener(this.onInviteAltsList);

      this.header_items[TAB_QUICK][1].addClickListener(this.onClearQuickList);
      this.header_items[TAB_QUICK][2].addClickListener(this.onInviteQuickList);
      this.header_items[TAB_QUICK][2].count = 0;

      this.header_items[TAB_REQUEST][1].addClickListener(this.onAcceptAll);
      this.header_items[TAB_REQUEST][1].count = 0;
      this.header_items[TAB_IGNORED][1].addEventListener(MouseEvent.CLICK,this.onAdd);

      this.header_items[TAB_SHIP][1].addClickListener(this.onClearShipList);
      this.header_items[TAB_SHIP][2].addClickListener(this.onInviteShipList);
      this.header_items[TAB_SHIP][3].addClickListener(this.onInviteCleaners);
      this.header_items[TAB_SHIP][4].addClickListener(this.onInviteLeechers);
    }

    private function onHelpMouseOver() : void {
      if(!this.help_area.stage) this.header_section.addChild(this.help_area);
    }

    private function onHelpMouseOut() : void {
      if(this.help_area.stage) this.header_section.removeChild(this.help_area);
    }

    /* ---------------- */
    /*   Click Events   */
    /* ---------------- */

    private function onInviteAltsList() : void {
      for each (var f:Friend in this.list_alts) f.onInvite();
    }

    private function onInviteQuickList() : void {
      for each (var f:Friend in this.list_quick) f.onInvite();
    }

    private function onClearQuickList() : void {
      while(0 < this.list_quick.length) this.list_quick[0].onQuickList();
      abi.configWrite("quick_list");
      this.header_items[TAB_QUICK][2].count = 0;
    }

    private function onInviteCleaners() : void {
      for each (var f:Friend in this.list_cleaners) f.onInvite();
    }

    private function onInviteLeechers() : void {
      for each (var f:Friend in this.list_leechers) f.onInvite();
    }

    private function onInviteShipList() : void {
      for each (var f:Friend in this.list_leechers) f.onInvite();
      for each (var f:Friend in this.list_cleaners) f.onInvite();
    }

    private function onClearShipList() : void {
      while(0 < this.list_leechers.length) this.list_leechers[0].onLeech();
      while(0 < this.list_cleaners.length) this.list_cleaners[0].onClean();
      abi.configWrite("list_leechers");
      abi.configWrite("list_cleaners");
      this.leechers_count = 0;
      this.cleaners_count = 0;
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
        ExternalInterface.call("OnTabClick",0);
        this._online.alpha = 1;
      }
      this.tab = TAB_ALL;
    }

    private function onTabFavClicked() : void {
      if(this.tab == TAB_IGNORED) {
        ExternalInterface.call("OnTabClick",0);
        this._online.alpha = 1;
      }
      this.tab = TAB_FAV;
    }

    private function onTabAltsClicked() : void {
      if(this.tab == TAB_IGNORED) {
        ExternalInterface.call("OnTabClick",0);
        this._online.alpha = 1;
      }
      this.tab = TAB_ALTS;
    }

    private function onTabQuickClicked() : void {
      if(this.tab == TAB_IGNORED) {
        ExternalInterface.call("OnTabClick",0);
        this._online.alpha = 1;
      }
      this.tab = TAB_QUICK;
    }

    private function onTabShipClicked() : void {
      if(this.tab == TAB_IGNORED) {
        ExternalInterface.call("OnTabClick",0);
        this._online.alpha = 1;
      }
      this.tab = TAB_SHIP;
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
      this.scroll.color = [2961475,1974319];
      this.scroll.bar = renderer.rectangle(new Sprite(),0,0,6,40,986907,1);
      this.scroll.bar.mouseEnabled = true;
      this.scroll.bar.x = 357;
      this.scroll.bar.y = 1;
      this.scroll.scrubber = renderer.rectangle(new Shape(),0,0,6,40,this.scroll.color[0],1);
      renderer.rectangle(this.scroll.scrubber,1,1,4,38,this.scroll.color[1],1);
      this.scroll.bar.addChild(this.scroll.scrubber);
      this.scroll.zone = renderer.rectangle(new Sprite(),0,0,1600,400,0,0);
      this.scroll.zone.x = -400;
      this.scroll.zone.y = -400;
      this.scroll.zone.addEventListener(MouseEvent.MOUSE_MOVE,this.onMouseMove);
      this.scroll.bar.addEventListener(MouseEvent.MOUSE_DOWN,this.setScrollBarListener);
      this.scroll.bar.addEventListener(MouseEvent.MOUSE_UP,this.removeScrollBarListener);
      abi.M.parent.addEventListener(MouseEvent.MOUSE_WHEEL,this.onMouseWheel);
    }

    private function onMouseWheel(e:MouseEvent) : void {
      var percent:Number = NaN;
      var temp:Point = new Point(this.full_list.x,this.full_list.y - 147 - abi.cfg.vertical_offset);
      var min:Point = this.full_list.localToGlobal(temp);
      temp.x += this.header_section.width - 7;
      temp.y += this.scroll.bar.height;
      var max:Point = this.full_list.localToGlobal(temp);

      if(!this.scroll.bar.stage || !abi.within(min.x,e.stageX,max.x) || !abi.within(min.y,e.stageY,max.y)) return;

      if(!this.scroll.zone.stage) {
        this.container.y = abi.clamp(this.container.y + 40 * (e.delta > 0 ? 1 : -1),-(Math.max(this.render_list.length * 40,1) - abi.cfg.max_rows * 40),1);
        percent = this.container.y / -(this.render_list.length * 40 - abi.cfg.max_rows * 40);
        this.scroll.scrubber.y = abi.clamp(int((this.scroll.bar.height - this.scroll.scrubber.height) * percent + 0.5),0,this.scroll.bar.height - this.scroll.scrubber.height);
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
      this.scroll.scrubber.y = Math.max(0,Math.min(this.scroll.bar.height - this.scroll.scrubber.height - 800,realY - int(this.scroll.scrubber.height / 2)));
      var percent:Number = this.getScrollPercent();
      this.container.y = 1 - int(percent * (Math.max(this.render_list.length * 40,1) - abi.cfg.max_rows * 40) + 0.5);
      this.setupRows();
    }

    private function getScrollPercent() : Number {
      if(!this.scroll.bar.stage) return 0;
      return this.scroll.scrubber.y / (this.scroll.bar.height - (!!this.scroll.zone.stage ? 800 : 0) - this.scroll.scrubber.height) || 0;
    }

    private function updateContainerSize() : void {
      this.full_list.visible = true;
      var h:int = Math.min(abi.cfg.max_rows * 40 - 3,this.render_list.length * 40 - 3);
      var w:int = 357;
      this.scroll.scrubber.graphics.clear();
      this.scroll.bar.graphics.clear();
      this.scroll.zone.graphics.clear();
      this.header_section.graphics.clear();

      if(this.render_list.length > abi.cfg.max_rows) {
        if(!this.scroll.bar.stage) this.full_list.addChild(this.scroll.bar);

        renderer.rectangle(this.scroll.scrubber,0,0,6,abi.getScrubberSize(this.render_list.length,24),this.scroll.color[0],1);
        renderer.rectangle(this.scroll.scrubber,1,1,4,abi.getScrubberSize(this.render_list.length,24) - 2,this.scroll.color[1],1);
        renderer.rectangle(this.scroll.bar,0,0,6,h,986907,1);
        renderer.rectangle(this.scroll.zone,0,0,1600,h + 800,16711935,0);
        w = 364;
      } else if(this.scroll.bar.stage) this.full_list.removeChild(this.scroll.bar);

      renderer.rectangle(this.header_section,0,-1,w,45,986907,1);
      renderer.rectangle(this.header_section,0,29,w,15,855319,1);
      this.clipping_mask.scaleY = h;
      this.full_list.graphics.clear();
      renderer.rectangle(this.full_list,0,0,w,h + 2,986907,1);
      renderer.rectangle(this.full_list,1,1,355,h,1776433,1);
      if(h <= 1) renderer.rectangle(this.full_list,0,0,w,40,986907,1);
    }

    private function updateRenderList() : void {
      this.render_list.splice(0);
      if(this.tab == TAB_REQUEST) {
        this.list_request.sortOn(["can_accept", "name"], [Array.DESCENDING, Array.CASEINSENSITIVE]);
        this.render_list = this.render_list.concat(this.list_request);
      } else if(this.tab == TAB_FAV) {
        this.list_fav.sortOn(["is_online", "name"], [Array.DESCENDING, Array.CASEINSENSITIVE]);
        this.render_list = this.render_list.concat(this.list_fav);
      } else if(this.tab == TAB_ALTS) {
        this.list_alts.sortOn(["is_online", "name"], [Array.DESCENDING, Array.CASEINSENSITIVE]);
        this.render_list = this.render_list.concat(this.list_alts);
      } else if(this.tab == TAB_QUICK) {
        this.list_quick.sortOn(["is_online", "name"], [Array.DESCENDING, Array.CASEINSENSITIVE]);
        this.render_list = this.render_list.concat(this.list_quick);
      } else if(this.tab == TAB_IGNORED) {
        this.list_ignored.sortOn("name", Array.CASEINSENSITIVE);
        this.render_list = this.render_list.concat(this.list_ignored);
      } else if(this.tab == TAB_SHIP) {
        this.list_cleaners.sortOn("name", Array.CASEINSENSITIVE);
        this.list_leechers.sortOn("name", Array.CASEINSENSITIVE);
        this.render_list = this.render_list.concat(this.list_cleaners).concat(this.list_leechers);
      } else {
        this.list_fav.sortOn(["is_online", "name"], [Array.DESCENDING, Array.CASEINSENSITIVE]);
        this.list_default.sortOn(["is_online", "name"], [Array.DESCENDING, Array.CASEINSENSITIVE]);
        this.render_list = this.render_list.concat(this.list_fav).concat(this.list_default);
      }
      this.online = this.online;
    }

    private function setupRows() : void {
      var rdx:int = 0;
      var spana:int = abi.cfg.max_rows + 2;
      var spanb:int = int((abi.cfg.max_rows + 5) * 40 + 0.5);
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
          if(abi.within(mina,rdx,maxa)) {
            if(!f.row.stage) this.container.addChild(f.row);
            f.row.y = rdx * 40;
            f.bg.visible = rdx % 2 != 0;
          } else if(f.seen && f.row.stage) this.container.removeChild(f.row);
        } else if(f.seen && (f.row.stage && abi.within(minb,f.row.y,maxb))) this.container.removeChild(f.row);
        idx++;
      }
    }

    public function queueDelayedSort(wait:int = 77) : void {
      if(this.sort_timer != null) this.sort_timer.stop();
      this.sort_timer = new Timer(wait,1);
      this.sort_timer.addEventListener(TimerEvent.TIMER,this.onSortTimerComplete);
      this.sort_timer.start();
    }

    private function onSortTimerComplete() : void {
      this.updateRenderList();
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
      abi.configWrite("favorites");
    }

    public function onFavoriteRemove(f:Friend) : void {
      var idx:int = this.list_fav.indexOf(f);
      if(idx != -1) {
        this.list_fav.splice(idx, 1);
        this.list_default.push(f);
        this.onSortTimerComplete();
      }
      abi.configWrite("favorites");
    }

    public function onAltAdd(f:Friend) : void {
      if(this.list_alts.indexOf(f) == -1) this.list_alts.push(f);

      var idx:int = this.list_default.indexOf(f);
      if(idx != -1) this.list_default.splice(idx, 1);

      this.onSortTimerComplete();
      abi.configWrite("alts");
    }

    public function onAltRemove(f:Friend) : void {
      var idx:int = this.list_alts.indexOf(f);
      if(idx != -1) {
        this.list_alts.splice(idx, 1);
        this.list_default.push(f);
        this.onSortTimerComplete();
      }
      abi.configWrite("alts");
    }

    public function onQuickListAdd(f:Friend) : void {
      if(this.list_quick.indexOf(f) == -1) {
        this.list_quick.push(f);
        this.header_items[TAB_QUICK][2].count++;
      }
      abi.configWrite("quick_list");
    }

    public function onQuickListRemove(f:Friend, is_internal:Boolean = false) : void {
      var idx:int = this.list_quick.indexOf(f);
      if(idx != -1) {
        this.list_quick.splice(idx,1);
        this.header_items[TAB_QUICK][2].count--;
      }
      if(this.tab == TAB_QUICK) this.onSortTimerComplete();
      if(is_internal) abi.configWrite("quick_list");
    }

    public function onLeecherAdd(f:Friend) : void {
      if(this.list_leechers.indexOf(f) == -1 && this.list_cleaners.indexOf(f) == -1) {
        this.list_leechers.push(f);
        this.leechers_count++;
        abi.configWrite("list_leechers");
      }
    }

    public function onLeecherRemove(f:Friend) : void {
      var idx:int = this.list_leechers.indexOf(f);
      if(idx != -1) {
        this.list_leechers.splice(idx, 1);
        this.leechers_count--;
        abi.configWrite("list_leechers");
        this.onSortTimerComplete();
      }
    }

    public function onCleanerAdd(f:Friend) : void {
      if(this.list_cleaners.indexOf(f) == -1 && this.list_leechers.indexOf(f) == -1) {
        this.list_cleaners.push(f);
        this.cleaners_count++;
        abi.configWrite("list_cleaners");
      }
    }

    public function onCleanerRemove(f:Friend) : void {
      var idx:int = this.list_cleaners.indexOf(f);
      if(idx != -1) {
        this.list_cleaners.splice(idx, 1);
        this.cleaners_count--;
        abi.configWrite("list_cleaners");
        this.onSortTimerComplete();
      }
    }
  }
}
