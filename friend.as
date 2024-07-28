package {
  import flash.display.Shape;
  import flash.display.Sprite;
  import flash.events.MouseEvent;
  import flash.external.ExternalInterface;
  import flash.text.TextField;
  import flash.text.TextFormat;

  import components.buttons.*;
  import components.colorpicker.ColorButton;

  public class Friend {
    public static const MASTERY_RANK_FORMAT:String = config.msg.MASTERY_RANK_FORMAT;
    public static const REQUEST_OUTGOING:String = config.msg.REQUEST_OUTGOING;
    public static const REQUEST_INCOMING:String = config.msg.REQUEST_INCOMING;

    public var friends:Friends;

    private var _uid:String;
    public var bg:Shape;
    private var _name:TextField;
    private var _is_online:Shape;
    private var _world:TextField;
    private var _rank:TextField;
    private var _can_join:Boolean = true;
    private var _is_request:Boolean;
    private var _can_accept:Boolean;
    private var _can_invite:Boolean = true;
    private var _is_ignored:Boolean;

    private var _row:Sprite;

    // Buttons
    public var btnJoin:icnbtn;
    public var btnInvite:icnbtn;
    public var btnQuickList:icnbtn;
    public var btnFavorite:icnbtn;
    public var btnAccept:icnbtn;

    private var colors_in:Array = [];

    public function Friend(uid:String, name:String, is_online:Boolean, world:String, rank:String, can_join:Boolean, is_request:Boolean, can_accept:Boolean, can_invite:Boolean, is_ignored:Boolean, friends:Friends) {
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
      this.is_ignored = is_ignored;
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
      this._uid = uid;
    }

    public function get uid() : String {
      return this._uid;
    }

    public function set can_join(can_join:Boolean) : void {
      if(can_join == this._can_join) return;

      if(this.btnJoin != null)  {
        if(can_join) {
          this.btnJoin.disabled = false;
          this.btnJoin.addEventListener(MouseEvent.CLICK, this.onJoin);
        } else {
          this.btnJoin.disabled = true;
          this.btnJoin.removeEventListener(MouseEvent.CLICK, this.onJoin);
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
        this.btnInvite.addEventListener(MouseEvent.CLICK, this.onInvite);
      }
      this._can_invite = can_invite;
    }

    public function get can_invite() : Boolean {
      return this._can_invite;
    }

    public function set rank(rank:String) : void {
      if(!this._rank) {
        this._rank = renderer.text("", 23, 0, 12, "left", -1, -1, false, true);
        this._rank.textColor = renderer.RANK_COLOR;
      }
      this._rank.text = rank.indexOf(MASTERY_RANK_FORMAT) == 0 ? rank.substring(MASTERY_RANK_FORMAT.length) : rank;
      if(this._name) this._name.x = 23 + int(Math.max(3, this._rank.width) + 0.5) - 3;
    }

    public function get rank() : String {
      return this._rank.text;
    }

    public function set name(name:String) : void {
      if(!this._name) {
        this._name = renderer.text("", 23, 0, 12, "left", -1, -1, false, true);
        this._name.textColor = renderer.DEFAULT_NAME_COLOR;
        this._name.mouseEnabled = true;
        this._name.addEventListener(MouseEvent.MOUSE_OVER, this.onNameMouseOver);
        this._name.addEventListener(MouseEvent.RIGHT_MOUSE_UP, this.onNameMouseUp);
        this._name.addEventListener(MouseEvent.MOUSE_UP, this.onNameMouseUp);
        this._name.addEventListener(MouseEvent.MOUSE_OUT, this.onNameMouseOut);
        this._name.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, this.onNameRightMouseDown);
        this._name.addEventListener(MouseEvent.MOUSE_DOWN, this.onNameMouseDown);
        this._name.addEventListener(MouseEvent.CLICK, this.onNameClick);
        this._name.addEventListener(MouseEvent.RIGHT_CLICK, this.onNameRightClick);
        if(this._rank) this._name.x += int(Math.max(3,this._rank.width) + 0.5) - 3;
      }
      this._name.text = name;
    }

    public function get name() : String {
      return this._name.text;
    }

    private function onNameMouseUp(e:MouseEvent) : void {
      this._name.alpha = 1;
    }

    private function onNameMouseOver(e:MouseEvent) : void {
      this._name.alpha = 0.8;
    }

    private function onNameRightMouseDown(e:MouseEvent) : void {
      this._name.alpha = 0.3;
    }

    private function onNameMouseDown(e:MouseEvent) : void {
      this._name.alpha = 0.5;
    }

    private function onNameMouseOut(e:MouseEvent) : void {
      this._name.alpha = 1;
    }

    private function onNameClick(e:MouseEvent) : void {
      if(!this.is_ignored) {
        ExternalInterface.call("POST_SOUND_EVENT", "Play_ui_btnon_select");
        ExternalInterface.call("OnWhisper", this.name);
      }
    }

    private function onNameRightClick() : void {
      ExternalInterface.call("POST_SOUND_EVENT", "Play_ui_btnon_select");
      ExternalInterface.call("OnRemove", uid, is_request);
    }

    /* ------------------- */
    /*   Setters/Getters   */
    /* ------------------- */

    public function set world(world:String) : void {
      if(!this._world) {
        this._world = renderer.text("", 23, 17, 10, "left", 230, 16);
        this._world.textColor = 0xCECED7;
      }
      this._world.text = world;
    }

    public function get world() : String {
      return this._world.text;
    }

    public function set is_online(is_online:Boolean) : void {
      if(!this._is_online)
        this._is_online = renderer.rectangle(new Shape(), 0, 0, 2, 37, renderer.GREEN, 1);
      if(this._is_online.visible == is_online) return;
      this._is_online.visible = is_online;
      this.refreshColors();
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
          this.btnAccept = new icnbtn(new IconAccept(), 28, 28);
          this.btnAccept.x = 315;
          this.btnAccept.y = 5;
          this.btnAccept.addEventListener(MouseEvent.CLICK, this.onAccept);
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

    public function set theme(theme:Boolean) : void {
      this._row.removeChild(this.bg);
      this.bg.graphics.clear();
      this.bg = renderer.rectangle(new Shape(), 2, 0, 353, 37, theme ? renderer.GRAY_30 : renderer.GRAY_28, 1);
      this._row.addChildAt(this.bg, 0);
    }

    private function buildRow() : void {
      this.buildCoreBtns();
      this.buildGroupBtns();
      this.buildColors();

      this.bg = renderer.rectangle(new Shape(), 2, 0, 353, 37, renderer.GRAY_30, 1);
      this._row = renderer.rectangle(new Sprite(), 0, 0, 2, 37, renderer.GRAY_38, 1);
      var group_container:Shape = renderer.rectangle(new Shape(), 2, 0, 17, 37, renderer.GRAY_16, 0.5);
      this._row.addChild(this.bg);
      this._row.addChild(group_container);

      this._row.width = 355;
      this._row.height = 37;

      this._row.addChild(this._is_online);
      this._row.addChild(this._rank);
      this._row.addChild(this._name);
      this._row.addChild(this._world);
      this._row.addChild(this.btnJoin);
      this._row.addChild(this.btnInvite);

      if(this.btnAccept) this._row.addChild(this.btnAccept);

      this._row.addChild(this.btnQuickList);
      this._row.addChild(this.btnFavorite);

      for each(var btn:ColorButton in this.colors_in)
        this._row.addChild(btn);
    }

    private function buildCoreBtns() : void {
      this.btnJoin = new icnbtn(new IconJoin(), 28, 28);
      this.btnInvite = new icnbtn(new IconInvite(), 28, 28);
      this.btnJoin.x = 315;
      this.btnJoin.y = 5;
      this.btnInvite.x = 270;
      this.btnInvite.y = 5;

      // if(!this.can_join) this.btnJoin.disabled = true;
      // else this.btnJoin.addEventListener(MouseEvent.CLICK,this.onJoin);
      this.btnJoin.addEventListener(MouseEvent.CLICK,this.onJoin);

      this.btnInvite.addEventListener(MouseEvent.CLICK,this.onInvite);

      if(this.is_ignored || this.is_request) {
        this.btnJoin.visible = false;
        this.btnInvite.visible = false;
        if(this.is_request) this.world = !this.can_accept ? REQUEST_OUTGOING : REQUEST_INCOMING;
      }
    }

    private function buildGroupBtns() : void {
      // Heart
      this.btnFavorite = new icnbtn(new IconHeartSmall(), 15, 13);
      this.btnFavorite.x = 3;
      this.btnFavorite.y = 3;
      if(config.favs[this.uid]) {
        this.btnFavorite.toggled = true;
        this._name.textColor = renderer.FAVORITE_COLOR;
      }

      // Quick List
      this.btnQuickList = new icnbtn(new IconQuickListSmall(), 15, 13, true);
      this.btnQuickList.x = 3;
      this.btnQuickList.y = 20;
      this.updateQuickListBtn();

      this.btnFavorite.addEventListener(MouseEvent.CLICK, this.onFavorite);
      this.btnQuickList.addEventListener(MouseEvent.CLICK, this.onQuickList);
    }

    private function buildColors() : void {
      var i:int = 0;
      var adjust:int = this._name.width + this._name.x - 7;
      for each(var clr:String in config.colors) {
        if(config[clr][this.uid]) {
          var btn:ColorButton = new ColorButton(5, clr, (++i * 15) + adjust, 11);
          btn.addEventListener(MouseEvent.RIGHT_CLICK, this.removeColor);
          this.colors_in.push(btn);
        }
      }
    }

    public function updateQuickListBtn() : void {
      if(this.btnQuickList == null) return;
      var color:String = config.cfg.active_color;
      this.btnQuickList.toggled = !!config[color][this.uid];
    }

    public function refreshColors() : void {
      if(this._row == null) return;
      for each(var btn:ColorButton in this.colors_in) {
        btn.removeEventListener(MouseEvent.RIGHT_CLICK, this.removeColor);
        this._row.removeChild(btn);
      }

      this.colors_in = [];
      this.buildColors();

      for each(var clrBtn:ColorButton in this.colors_in)
        this._row.addChild(clrBtn);
    }

    /* ------------------- */
    /* --- Event Hooks --- */
    /* ------------------- */

    public function onInvite() : void {
      ExternalInterface.call("OnInviteToJoinMe", this.uid);
    }

    public function onJoin(e:MouseEvent) : void {
      ExternalInterface.call("OnJoinWorld", this.uid);
      // if(this.can_join) ExternalInterface.call("OnJoinWorld", this.uid);
    }

    public function onAccept(e:MouseEvent) : void {
      ExternalInterface.call("OnAcceptRequest",this.uid);
    }

    public function onFavorite(e:MouseEvent) : void {
      var previous:Boolean = !!config.favs[this.uid];
      this.btnFavorite.toggled = !previous;

      if(previous) { // If favorite - remove it
        this._name.textColor = renderer.DEFAULT_NAME_COLOR;
        config.favs[this.uid] = null;
        this.friends.onFavoriteRemove(this);
      } else { // If default - make it favorite
        this._name.textColor = renderer.FAVORITE_COLOR;
        config.favs[this.uid] = true;
        this.friends.onFavoriteAdd(this);
      }
    }

    public function onQuickList(e:MouseEvent) : void {
      var color:String = config.cfg.active_color;
      var previous:Boolean = !!config[color][this.uid];

      this.btnQuickList.toggled = !previous;

      if(previous) { // If in list - remove it
        config[color][this.uid] = null;
        this.friends.onQuickListRemove(this);
      } else {
        config[color][this.uid] = true;
        this.friends.onQuickListAdd(this);
      }

      config.configWrite(color);
      this.refreshColors();
      this.updateQuickListBtn();
    }

    /* ------------------- */
    /* -- Remove Colors -- */
    /* ------------------- */
    private function removeColor(e:MouseEvent) : void {
      var color:String = e.target.color;
      config[color][this.uid] = null;
      config.configWrite(color);
      this.refreshColors();
      this.updateQuickListBtn();
      this.friends.onQuickListRemove(this, color);
    }
  }
}
