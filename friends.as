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

  import components.buttons.*;
  import components.helparea.HelpArea;
  import ui.*;

  public class Friends {
    private var _init:Boolean = false;
    public var container:Sprite;
    public var clipping_mask:Sprite;
    public var scroll:Object;
    private var sort_timer:Timer;
    public var full_list:Sprite;

    public var header_section:Header;

    // Tab constants
    private var _tab:int = 0;
    public static const TAB_ALL:uint = 0;
    public static const TAB_FAV:uint = 1;
    public static const TAB_QUICK:uint = 2;
    public static const TAB_REQUEST:uint = 3;
    public static const TAB_IGNORED:uint = 4;

    // List arrays
    public var lookup:Object;
    public var list:Array = [];
    public var list_fav:Vector.<Friend> = new Vector.<Friend>();
    public var list_request:Vector.<Friend> = new Vector.<Friend>();
    public var list_default:Vector.<Friend> = new Vector.<Friend>();
    public var list_ignored:Vector.<Friend> = new Vector.<Friend>();
    public var render_list:Vector.<Friend> = new Vector.<Friend>();

    // Color arrays
    public var list_colors:Object = {
      "red": new Vector.<Friend>(),
      "orange": new Vector.<Friend>(),
      "yellow": new Vector.<Friend>(),
      "green": new Vector.<Friend>(),
      "cyan": new Vector.<Friend>(),
      "blue": new Vector.<Friend>(),
      "purple": new Vector.<Friend>()
    };

    public function Friends() {
      super();
      this.lookup = {};
      this.buildContainer();
      this.tab = config.cfg.default_tab;
    }

    public function set tab(tab:int) : void {
      if(tab > TAB_IGNORED) tab = int(TAB_ALL);
      if(tab != this._tab || !this._init) {
        this.header_section.tab_buttons[this._tab].toggled = false;
        this.header_section.tab_buttons[tab].toggled = true;
        this.container.y = 1;
        this.scroll.scrubber.y = 0;

        if(TAB_ALL <= tab && tab <= TAB_REQUEST && this._init) {
          config.cfg.default_tab = tab;
          config.configWrite("default_tab");
        }
        this._tab = tab;
        this._init = true;
        this.onSortTimerComplete();
      }

      this.updateQL();
    }

    public function get tab() : int {
      return this._tab;
    }

    public function add(uid:String, name:String, is_online:Boolean = false, world:String = "", rank:String = "", can_join:Boolean = false, is_request:Boolean = false, can_accept:Boolean = false, can_invite:Boolean = false, is_ignored:Boolean = false) : void {
      if(this.lookup[uid]) return this.update(uid,name, is_online, world, rank, can_join,is_request, can_accept,can_invite,is_ignored);
      if(name == "" && config.cfg.drop_nameless) return;

      var friend:Friend = new Friend(uid, name, is_online, world, rank, can_join, is_request, can_accept, can_invite, is_ignored, this);
      this.lookup[friend.uid] = friend;
      this.list.push(friend);

      if(friend.is_ignored) {
        this.list_ignored.push(friend);
        this.queueDelayedSort();
        return;
      }

      if(friend.is_request) {
        this.list_request.push(friend);
        if(friend.can_accept) this.header_section.requests++;
        this.queueDelayedSort();
        return;
      }

      if(config.favs[friend.uid]) this.list_fav.push(friend);
      else this.list_default.push(friend);

      for each (var color:String in config.colors)
        if(config[color][friend.uid])
          this.list_colors[color].push(friend);

      this.header_section.count++;
      if(is_online) ++this.header_section.online;

      this.queueDelayedSort();
    }

    public function update(uid:String, name:String, is_online:Boolean, world:String, rank:String, can_join:Boolean, is_request:Boolean, can_accept:Boolean, can_invite:Boolean, is_ignored:Boolean) : void {
      var idx:int = this.list.indexOf(this.lookup[uid]);
      if(idx == -1) return this.add(uid,name,is_online,world,rank,can_join,is_request,can_accept,can_invite,is_ignored);

      var friend:Friend = this.list[idx];
      var state_changed:Boolean = friend.is_online != is_online;
      if(friend.can_accept && !can_accept) this.header_section.requests--;
      friend.name = name != "" ? name : friend.name;
      friend.is_online = is_online;
      friend.world = world;
      friend.rank = rank;
      friend.can_join = can_join;
      friend.is_request = is_request;
      friend.can_accept = can_accept;
      friend.can_invite = can_invite;
      friend.is_ignored = is_ignored;
      if(state_changed) {
        this.header_section.online += is_online ? 1 : -1;
        this.queueDelayedSort();
      }
    }

    public function remove(uid:String) : void {
      var f:Friend = this.lookup[uid];
      var idx:int = this.list.indexOf(f);
      if(idx == -1) return;

      if(f.is_request && f.can_accept) {
        --this.header_section.requests;
        return;
      }

      this.list.splice(idx,1);
      --this.header_section.count;
      if(f.is_online) --this.header_section.online;

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
      this.list_default.length = 0;
      this.list_fav.length = 0;
      this.list_request.length = 0;
      this.list_ignored.length = 0;
      for each (var color:String in config.colors) this.list_colors[color].length = 0;

      this.onSortTimerComplete();
      this.destroyAllReferences();
      this.header_section.clear();
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

    private function buildContainer() : void {
      this.full_list = renderer.rectangle(new Sprite(), 0, 0, 364, 41, config.darken(config.cfg.fl_color, 0.4), 1);
      this.full_list.x = 5;
      this.full_list.y = 150 + config.cfg.vertical_offset;

      this.container = new Sprite();
      this.container.x = 1;
      this.container.y = 1;

      renderer.rectangle(this.full_list, 1, 1, 355, 39, config.cfg.fl_color, 1);
      this.clipping_mask = renderer.rectangle(new Sprite(), 0, 0, 355, 1, renderer.MASK, 1);
      this.clipping_mask.x = 1;
      this.clipping_mask.y = 1;
      this.container.mask = this.clipping_mask;

      this.buildScrollbar();
      this.header_section = new Header(this);

      this.full_list.addChild(this.scroll.bar);
      this.full_list.addChild(this.container);
      this.full_list.addChild(this.clipping_mask);
      this.full_list.addChild(this.header_section);
      this.full_list.visible = false;
    }

    public function applyOffset(val:int) : void {
      this.full_list.y = 150 + val;
    }

    /* ---------------- */
    /*    SCROLLBAR     */
    /* ---------------- */

    private function buildScrollbar() : void {
      this.scroll = {};
      this.scroll.color = [config.cfg.scrubber_color_1, config.cfg.scrubber_color_2];
      this.scroll.bar = renderer.rectangle(new Sprite(), 0, 0, 6, 38, config.cfg.bar_color, 1);
      this.scroll.bar.mouseEnabled = true;
      this.scroll.bar.x = 357;
      this.scroll.bar.y = 1;
      this.scroll.scrubber = renderer.rectangle(new Shape(), 0, 0, 6, 38, this.scroll.color[0], 1);
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
      if(this.render_list.length <= config.cfg.max_rows) return;
      var percent:Number = NaN;
      var temp:Point = new Point(this.full_list.x,this.full_list.y - 147 - config.cfg.vertical_offset);
      var min:Point = this.full_list.localToGlobal(temp);
      temp.x += this.header_section.width - 7;
      temp.y += this.scroll.bar.height;
      var max:Point = this.full_list.localToGlobal(temp);

      if(!this.scroll.bar.stage || !config.within(min.x,e.stageX,max.x) || !config.within(min.y,e.stageY,max.y)) return;

      if(!this.scroll.zone.stage) {
        this.container.y = config.clamp(this.container.y + 39 * (e.delta > 0 ? 1 : -1),-(Math.max(this.render_list.length * 39,1) - config.cfg.max_rows * 39), 1);
        percent = this.container.y / -(this.render_list.length * 39 - config.cfg.max_rows * 39);
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
      this.scroll.scrubber.y = Math.max(0, Math.min(this.scroll.bar.height - this.scroll.scrubber.height - 800, realY - int(this.scroll.scrubber.height / 2)));
      var percent:Number = this.getScrollPercent();
      this.container.y = 1 - int(percent * (Math.max(this.render_list.length * 39, 1) - config.cfg.max_rows * 39) + 0.5);
      this.setupRows();
    }

    private function getScrollPercent() : Number {
      if(!this.scroll.bar.stage) return 0;
      return this.scroll.scrubber.y / (this.scroll.bar.height - (!!this.scroll.zone.stage ? 800 : 0) - this.scroll.scrubber.height) || 0;
    }

    private function updateContainerSize() : void {
      this.full_list.visible = true;
      var h:int = Math.min(config.cfg.max_rows * 39 - 3,this.render_list.length * 39 - 3);
      var w:int = 357;
      this.scroll.scrubber.graphics.clear();
      this.scroll.bar.graphics.clear();
      this.scroll.zone.graphics.clear();

      var size:int = config.getScrubberSize(this.render_list.length, 24);
      renderer.rectangle(this.scroll.scrubber, 0, 0, 6, size, this.scroll.color[0], 1);
      renderer.rectangle(this.scroll.scrubber, 1, 1, 4, size - 2, this.scroll.color[1], 1);
      renderer.rectangle(this.scroll.bar, 0, 0, 7, h, config.darken(config.cfg.fl_color, 0.6), 1);
      renderer.rectangle(this.scroll.zone, 0, 0, 1600, h + 800, renderer.MASK, 0);
      w = 364;

      this.clipping_mask.scaleY = h;
      this.full_list.graphics.clear();
      renderer.rectangle(this.full_list, 0, 0, w, h + 2, config.darken(config.cfg.fl_color, 0.4), 1);
      renderer.rectangle(this.full_list, 1, 1, 355, h, config.cfg.fl_color, 1);
      if (this.render_list.length == 0) renderer.rectangle(this.full_list, 0, 0, w, 38, config.darken(config.cfg.fl_color, 0.4), 1);
      else if(h <= 1) renderer.rectangle(this.full_list, 0, 0, w, 39, config.darken(config.cfg.fl_color, 0.4), 1);
    }

    /* ---------------- */

    private function compareByName(a:Friend, b:Friend) : int {
      return a.name.toLowerCase() < b.name.toLowerCase() ? -1 : 1;
    }

    private function compareAcceptName(a:Friend, b:Friend) : int {
      // sort by can_accept, then by name
      if(a.can_accept && !b.can_accept) return -1;
      if(!a.can_accept && b.can_accept) return 1;
      return compareByName(a, b);
    }

    private function compareOnlineName(a:Friend, b:Friend) : int {
      // sort by online status, then by name
      if(a.is_online && !b.is_online) return -1;
      if(!a.is_online && b.is_online) return 1;
      return compareByName(a, b);
    }

    public function customConcat(vec1:Vector.<Friend>, vec2:Vector.<Friend>):Vector.<Friend> {
      var result:Vector.<Friend> = new Vector.<Friend>();
      var item:Friend;
      for each (item in vec1)
        if (item != null)
          result.push(item);

      for each (item in vec2)
        if (item != null)
          result.push(item);
      return result;
    }

    private function updateRenderList() : Vector.<Friend> {
      this.render_list.length = 0;
      if(this.tab == TAB_REQUEST) {
        this.list_request.sort(compareAcceptName);
        return this.customConcat(this.list_request, new Vector.<Friend>());
      } else if(this.tab == TAB_FAV) {
        this.list_fav.sort(compareOnlineName);
        return this.customConcat(this.list_fav, new Vector.<Friend>());
      } else if(this.tab == TAB_QUICK) {
        for each (var color:String in config.colors) {
          if (color == config.cfg.active_color) {
            this.list_colors[color].sort(compareOnlineName);
            return this.customConcat(this.list_colors[color], new Vector.<Friend>());
          }
        }
      } else if(this.tab == TAB_IGNORED) {
        this.list_ignored.sort(compareByName);
        return this.customConcat(this.list_ignored, new Vector.<Friend>());
      } else {
        this.list_fav.sort(compareOnlineName);
        this.list_default.sort(compareOnlineName);
        return this.customConcat(this.list_fav, this.list_default);
      }
      return this.render_list;
    }

    private function setupRows() : void {
      var rdx:int = 0;
      var spana:int = config.cfg.max_rows + 2;
      var spanb:int = int((config.cfg.max_rows + 5) * 39 + 0.5);
      var f:Friend = null;
      var idx:int = 0;
      var pos:int = Math.max(0,int(this.render_list.length * this.getScrollPercent() + 0.5));
      var mina:int = pos - spana;
      var maxa:int = pos + spana * 2;
      var minb:int = pos * 39 - spanb;
      var maxb:int = pos * 39 + spanb;
      var len:int = int(this.list.length);
      while(idx < len) {
        f = this.list[idx];
        rdx = this.render_list.indexOf(f);
        if(rdx != -1) {
          if(config.within(mina,rdx,maxa)) {
            if(!f.row.stage) this.container.addChild(f.row);
            f.row.y = rdx * 39;
            f.theme = rdx % 2 != 0;
          } else if(f.seen && f.row.stage) this.container.removeChild(f.row);
        } else if(f.seen && (f.row.stage && config.within(minb,f.row.y,maxb))) this.container.removeChild(f.row);
        idx++;
      }
    }

    public function queueDelayedSort(wait:int = 77) : void {
      if(this.render_list.length >= config.cfg.max_rows) {
        if(this.sort_timer != null) this.sort_timer.stop();
        this.sort_timer = new Timer(wait, 1);
        this.sort_timer.addEventListener(TimerEvent.TIMER,this.onSortTimerComplete);
        this.sort_timer.start();
        return;
      }
      this.onSortTimerComplete();
    }

    public function onSortTimerComplete(e:TimerEvent = null) : void {
      if (config.cfg.auto_whisper) {
        ExternalInterface.call("OnWhisper", "auto");
        var timer:Timer = new Timer(100, 1);
        timer.addEventListener(TimerEvent.TIMER_COMPLETE, function(e:TimerEvent):void {
          ExternalInterface.call("OnRequestClose");
        });
        timer.start();
      }
      this.render_list.length = 0;

      var list_all:Vector.<Friend> = this.updateRenderList();
      for each (var f:Friend in list_all)
        if (f.name.toLowerCase().indexOf(this.header_section.searched.toLowerCase()) != -1 || this.header_section.searched == "")
          this.render_list.push(f);

      this.setupRows();
      this.header_section.updateHeaderItems();
      this.updateContainerSize();
    }

    public function search(str:String) : void {
      this.list_fav.sort(compareOnlineName);
      this.list_default.sort(compareOnlineName);
      var list_all:Vector.<Friend> = this.customConcat(this.list_fav, this.list_default);
      var filteredList:Vector.<Friend> = new Vector.<Friend>();
      for each (var f:Friend in list_all)
        if (f.name.toLowerCase().indexOf(str.toLowerCase()) != -1 || str == "")
          filteredList.push(f);

      this.render_list = filteredList;
      this.setupRows();
      this.updateContainerSize();
      this.updateQL();
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

    public function onQuickListRemove(f:Friend, clr:String="") : void {
      // check what color is active (config.cfg["active_color"]) and remove the friend from that list
      if (clr == "") clr = config.cfg.active_color;
      var color:String = clr;
      var idx:int = this.list_colors[color].indexOf(f);

      if(idx != -1) {
        this.list_colors[color].splice(idx, 1);
        if (this.tab == TAB_QUICK) {
          this.onSortTimerComplete();
          this.header_section.updateField();
        }
      }
    }

    public function updateQL() : void {
      if(this.tab == TAB_QUICK) this.onSortTimerComplete();

      for each (var f:Friend in this.render_list) {
        if (!f.btnQuickList) continue;
        f.updateQuickListBtn();
        f.btnQuickList.updateColor();
      }
    }

    public function inviteColor(color:String) : void {
      for each (var f:Friend in this.list_colors[color]) f.onInvite();
    }
  }
}
