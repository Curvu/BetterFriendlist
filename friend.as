package {
  import flash.display.Shape;
  import flash.display.Sprite;
  import flash.events.MouseEvent;
  import flash.external.ExternalInterface;
  import flash.text.TextField;
  import flash.text.TextFormat;

  public class Friend {
    public static const MASTERY_RANK_FORMAT:String = abi.msg.MASTERY_RANK_FORMAT;
    public static const REQUEST_OUTGOING:String = abi.msg.REQUEST_OUTGOING;
    public static const REQUEST_INCOMING:String = abi.msg.REQUEST_INCOMING;
    public static const TEXT_FORMAT_NAME:TextFormat = new TextFormat("Open Sans",12,16250871,true);
    public static const TEXT_FORMAT_WORLD:TextFormat = new TextFormat("Open Sans",10,13553367,false);
    public static const TEXT_FORMAT_RANK:TextFormat = new TextFormat("Open Sans",12,16768589,true);
    public static const ENV:Boolean = abi.DEBUG > 1;

    private var _uid:String;
    public var friends:Friends;
    public var bg:Shape;
    private var _name:TextField;
    private var _env:TextField;
    private var _is_online:Shape;
    private var _world:TextField;
    private var _rank:TextField;
    private var _can_join:Boolean = true;
    private var _is_request:Boolean;
    private var _can_accept:Boolean;
    private var _can_invite:Boolean = true;
    public var team_pvp_enabled:Boolean;
    private var _is_ignored:Boolean;
    public var highlight:Boolean;
    private var _row:Sprite;

    // Buttons
    public var btnJoin:abbtn;
    public var btnInvite:abbtn;
    public var btnAccept:txtbtn;
    public var btnHeart:abbtn;
    public var btnQuickList:abbtn;
    public var btnLeech:abbtn;
    public var btnClean:abbtn;

    public function Friend(uid:String, name:String, is_online:Boolean, world:String, rank:String, can_join:Boolean, is_request:Boolean, can_accept:Boolean, can_invite:Boolean, team_pvp_enabled:Boolean, is_ignored:Boolean, highlight:Boolean, friends:Friends) {
      super();
      this.uid = uid;
      this.name = name;
      this.is_online = is_online;
      this.world = world;
      this.rank = rank;
      this.can_join = can_join;
      this.is_request = is_request;
      this.can_accept = can_accept;
      this.can_invite = can_invite;
      this.team_pvp_enabled = team_pvp_enabled;
      this.is_ignored = is_ignored;
      this.highlight = highlight;
      this.friends = friends;
    }

    public function get row() : Sprite {
      if(this._row == null) this.buildRow();
      return this._row;
    }

    public function get seen() : Boolean {
      return this._row != null;
    }

    public function set uid(uid:String) : void {
      if(ENV) {
        if(!this._env) this.setupEnv();
        this._env.text = uid.split("").join(" ");
      }
      this._uid = uid;
    }

    private function setupEnv() : void {
      this._env = renderer.text(0,0,new TextFormat("Open Sans",9,16250871,false,false,false,false,false,"right"),"",false);
      this._env.width = 260;
      this._env.height = 16;
      this._env.y = 10;
      this._env.mouseEnabled = false;
    }

    public function get uid() : String {
      return this._uid;
    }

    public function set can_join(can_join:Boolean) : void {
      if(can_join == this._can_join) return;

      if(this.btnJoin != null)  {
        if(can_join) {
          this.btnJoin.disabled = false;
          this.btnJoin.addEventListener(MouseEvent.CLICK,this.onJoin);
        } else {
          this.btnJoin.disabled = true;
          this.btnJoin.removeEventListener(MouseEvent.CLICK,this.onJoin);
        }
      }
      this._can_join = can_join;
    }

    public function get can_join() : Boolean {
      return this._can_join;
    }

    public function set can_invite(can_invite:Boolean) : void {
      if(can_invite == this._can_invite) return;
      if(this.btnInvite != null) {
        this.btnInvite.disabled = false;
        this.btnInvite.addEventListener(MouseEvent.CLICK,this.onInvite);
      }
      this._can_invite = can_invite;
    }

    public function get can_invite() : Boolean {
      return this._can_invite;
    }

    public function set rank(rank:String) : void {
      if(!this._rank) this._rank = renderer.text(40,0,TEXT_FORMAT_RANK,"left",true);
      this._rank.text = rank.indexOf(MASTERY_RANK_FORMAT) == 0 ? rank.substring(MASTERY_RANK_FORMAT.length) : rank;
      if(this._name) this._name.x = 40 + int(Math.max(3,this._rank.width) + 0.5) - 3;
    }

    public function get rank() : String {
      return this._rank.text;
    }

    public function set name(name:String) : void {
      if(!this._name) {
        this._name = renderer.text(40,0,TEXT_FORMAT_NAME,"left",true);
        this._name.mouseEnabled = true;
        this._name.addEventListener(MouseEvent.MOUSE_OVER,this.onNameMouseOver);
        this._name.addEventListener(MouseEvent.RIGHT_MOUSE_UP,this.onNameMouseUp);
        this._name.addEventListener(MouseEvent.MOUSE_UP,this.onNameMouseUp);
        this._name.addEventListener(MouseEvent.MOUSE_OUT,this.onNameMouseOut);
        this._name.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN,this.onNameRightMouseDown);
        this._name.addEventListener(MouseEvent.MOUSE_DOWN,this.onNameMouseDown);
        this._name.addEventListener(MouseEvent.CLICK,this.onNameClick);
        this._name.addEventListener(MouseEvent.RIGHT_CLICK,this.onNameRightClick);
        if(this._rank) this._name.x += int(Math.max(3,this._rank.width) + 0.5) - 3;
      }
      this._name.text = name;
    }

    public function get name() : String {
      return this._name.text;
    }

    private function onNameMouseUp() : void {
      this._name.alpha = 1;
    }

    private function onNameMouseOver() : void {
      this._name.alpha = 0.8;
    }

    private function onNameRightMouseDown() : void {
      this._name.alpha = 0.3;
    }

    private function onNameMouseDown() : void {
      this._name.alpha = 0.5;
    }

    private function onNameMouseOut() : void {
      this._name.alpha = 1;
    }

    private function onNameClick() : void {
      if(!this.is_ignored) {
        ExternalInterface.call("POST_SOUND_EVENT","Play_ui_btnon_select");
        ExternalInterface.call("OnWhisper",this.name);
      }
    }

    private function onNameRightClick() : void {
      ExternalInterface.call("POST_SOUND_EVENT","Play_ui_btnon_select");
      ExternalInterface.call("OnRemove",this.uid,this.is_request);
    }

    public function set world(world:String) : void {
      if(!this._world) {
        this._world = renderer.text(40,17,TEXT_FORMAT_WORLD,"",true);
        this._world.width = 230;
        this._world.height = 16;
      }
      this._world.text = world;
    }

    public function get world() : String {
      return this._world.text;
    }

    public function set is_online(is_online:Boolean) : void {
      if(!this._is_online) this._is_online = renderer.rectangle(new Shape(),0,0,2,37,5299046,1);
      this._is_online.visible = is_online;
    }

    public function get is_online() : Boolean {
      return this._is_online.visible;
    }

    public function get is_request() : Boolean {
      return this._is_request;
    }

    public function get can_accept() : Boolean {
      return this._can_accept;
    }

    public function set is_request(is_request:Boolean) : void {
      if(this.btnJoin != null && this.btnInvite != null) {
        if(is_request) {
          this.btnJoin.visible = false;
          this.btnInvite.visible = false;
          this.world = REQUEST_OUTGOING;
        } else if(!this.is_ignored) {
          this.btnJoin.visible = true;
          this.btnInvite.visible = true;
        }
      }
      this._is_request = is_request;
    }

    public function set can_accept(can_accept:Boolean) : void {
      if(can_accept && this._can_accept != can_accept) {
        this.world = REQUEST_INCOMING;
        if(!this.btnAccept) {
          this.btnAccept = new txtbtn(76,13,abi.msg.ACCEPT,271,5);
          this.btnAccept.addEventListener(MouseEvent.CLICK,this.onAccept);
        }
        if(this._row) this._row.addChild(this.btnAccept);
      } else if(this.btnAccept && this.btnAccept.stage) this._row.removeChild(this.btnAccept);
      this._can_accept = can_accept;
    }

    public function get is_ignored() : Boolean {
      return this._is_ignored;
    }

    public function set is_ignored(is_ignored:Boolean) : void {
      if(this.btnJoin != null && this.btnInvite != null) {
        if(is_ignored) {
          this.btnJoin.visible = false;
          this.btnInvite.visible = false;
          this._name.alpha = 0.5;
        } else if(!this.is_request) {
          this.btnJoin.visible = true;
          this.btnInvite.visible = true;
        }
      }
      this._is_ignored = is_ignored;
    }

    private function buildRow() : void {
      this.buildCorebtnons();
      this.buildGroupbtnons();
      this.bg = renderer.rectangle(new Shape(), 2, 0, 353, 37, 1579052, 1);
      this._row = renderer.rectangle(new Sprite(), 0, 0, 2, 37, 5921894, 1);
      var group_container:Shape = renderer.rectangle(new Shape(), 2, 0, 34, 37, 986907, 0.5);
      this._row.addChild(this.bg);
      this._row.addChild(group_container);
      this.bg.visible = false;
      this._row.width = 355;
      this._row.height = 37;
      if(ENV) this._row.addChild(this._env);
      this._row.addChild(this._is_online);
      this._row.addChild(this._rank);
      this._row.addChild(this._name);
      this._row.addChild(this._world);
      this._row.addChild(this.btnJoin);
      this._row.addChild(this.btnInvite);
      this._row.addChild(this.btnHeart);
      this._row.addChild(this.btnQuickList);
      this._row.addChild(this.btnLeech);
      this._row.addChild(this.btnClean);
      if(this.btnAccept) this._row.addChild(this.btnAccept);
    }

    private function buildCorebtnons() : void {
      this.btnJoin = new abbtn(new IconJoin(), 28, 28);
      this.btnInvite = new abbtn(new IconInvite(), 28, 28);
      this.btnJoin.x = 315;
      this.btnJoin.y = 5;
      this.btnInvite.x = 270;
      this.btnInvite.y = 5;

      if(!this.can_join) this.btnJoin.disabled = true;
      else this.btnJoin.addEventListener(MouseEvent.CLICK,this.onJoin);

      this.btnInvite.addEventListener(MouseEvent.CLICK,this.onInvite);

      if(this.is_ignored || this.is_request) {
        this.btnJoin.visible = false;
        this.btnInvite.visible = false;
        if(this.is_request) this.world = !this.can_accept ? REQUEST_OUTGOING : REQUEST_INCOMING;
      }
    }

    private function buildGroupbtnons() : void {
      // Heart
      this.btnHeart = new abbtn(new IconHeartSmall(), 15, 13);
      this.btnHeart.x = 3;
      this.btnHeart.y = 3;
      if(abi.favs[this.uid]) {
        this.btnHeart.toggled = true;
        this._name.textColor = 16201328;
        this._rank.textColor = 16250871;
      }
      this.btnHeart.addEventListener(MouseEvent.CLICK, this.onFavorite);

      // Quick List
      this.btnQuickList = new abbtn(new IconQuickListSmall(), 15, 13);
      this.btnQuickList.x = 3;
      this.btnQuickList.y = 20;
      if(abi.quick[this.uid]) this.btnQuickList.toggled = true;
      this.btnQuickList.addEventListener(MouseEvent.CLICK, this.onQuickList);

      // Leech
      this.btnLeech = new abbtn(new IconLeecher(), 15, 13);
      this.btnLeech.x = 20;
      this.btnLeech.y = 3;
      if(abi.leechers[this.uid]) this.btnLeech.toggled = true;
      this.btnLeech.addEventListener(MouseEvent.CLICK, this.onLeech);

      // Clean
      this.btnClean = new abbtn(new IconCleaner(), 15, 13);
      this.btnClean.x = 20;
      this.btnClean.y = 20;
      if(abi.cleaners[this.uid]) {
        this.btnClean.toggled = true;
        this._name.textColor = 4290479868;
      }
      this.btnClean.addEventListener(MouseEvent.CLICK, this.onClean);
    }

    /* ------------------- */
    /* --- Event Hooks --- */
    /* ------------------- */

    public function onInvite() : void {
      ExternalInterface.call("OnInviteToJoinMe",this.uid);
    }

    public function onJoin() : void {
      if(this.can_join) ExternalInterface.call("OnJoinWorld",this.uid);
    }

    public function onAccept() : void {
      ExternalInterface.call("OnAcceptRequest",this.uid);
    }

    private function onFavorite() : void {
      var previous:Boolean = !!abi.favs[this.uid];
      if(previous) {
        this.btnHeart.toggled = false;
        this._name.textColor = 16250871;
        this._rank.textColor = 16768589;
        abi.favs[this.uid] = null;
        this.friends.onFavoriteRemove(this);
      } else {
        this.btnHeart.toggled = true;
        this._name.textColor = 16201328;
        this._rank.textColor = 16250871;
        abi.favs[this.uid] = true;
        this.friends.onFavoriteAdd(this);
      }
    }

    public function onQuickList(is_internal:* = null) : void {
      var previous:Boolean = !!abi.quick[this.uid];
      if(previous) {
        this.btnQuickList.toggled = false;
        abi.quick[this.uid] = null;
        this.friends.onQuickListRemove(this,!!is_internal);
      } else {
        this.btnQuickList.toggled = true;
        abi.quick[this.uid] = true;
        this.friends.onQuickListAdd(this);
      }
    }

    public function onClean() : void {
      if(abi.leechers[this.uid]) { // Disable leecher
        this.btnLeech.toggled = false;
        abi.leechers[this.uid] = null;
        this.friends.onLeecherRemove(this);
      }

      var previous:Boolean = !!abi.cleaners[this.uid];
      if(previous) {
        this.btnClean.toggled = false;
        this._name.textColor = 16250871;
        abi.cleaners[this.uid] = null;
        this.friends.onCleanerRemove(this);
      } else {
        this.btnClean.toggled = true;
        this._name.textColor = 4290479868;
        abi.cleaners[this.uid] = true;
        this.friends.onCleanerAdd(this);
      }
    }

    public function onLeech() : void {
      if(abi.cleaners[this.uid]) { // Disable cleaner
        this.btnClean.toggled = false;
        this._name.textColor = 16250871;
        abi.cleaners[this.uid] = null;
        this.friends.onCleanerRemove(this);
      }

      var previous:Boolean = !!abi.leechers[this.uid];
      if(previous) {
        this.btnLeech.toggled = false;
        abi.leechers[this.uid] = null;
        this.friends.onLeecherRemove(this);
      } else {
        this.btnLeech.toggled = true;
        abi.leechers[this.uid] = true;
        this.friends.onLeecherAdd(this);
      }
    }
  }
}
