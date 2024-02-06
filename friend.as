package {
  import flash.display.Shape;
  import flash.display.Sprite;
  import flash.events.MouseEvent;
  import flash.external.ExternalInterface;
  import flash.text.TextField;
  import flash.text.TextFormat;

  public class Friend {
    public static const MASTERY_RANK_FORMAT:String = config.msg.MASTERY_RANK_FORMAT;
    public static const REQUEST_OUTGOING:String = config.msg.REQUEST_OUTGOING;
    public static const REQUEST_INCOMING:String = config.msg.REQUEST_INCOMING;
    public static const TEXT_FORMAT_NAME:TextFormat = new TextFormat("Open Sans", 12, renderer.DEFAULT_NAME_COLOR, true);
    public static const TEXT_FORMAT_WORLD:TextFormat = new TextFormat("Open Sans", 10, 13553367, false);
    public static const TEXT_FORMAT_RANK:TextFormat = new TextFormat("Open Sans", 12, renderer.RANK_COLOR, true);

    private var _uid:String;
    public var friends:Friends;
    public var bg:Shape;
    private var _name:TextField;
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
    public var btnJoin:icnbtn;
    public var btnInvite:icnbtn;
    public var btnAccept:txtbtn;
    public var btns:Array;

    public var modal:Sprite;

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
      if(!this._rank) this._rank = renderer.text(4, 0, TEXT_FORMAT_RANK, "left", true);
      this._rank.text = rank.indexOf(MASTERY_RANK_FORMAT) == 0 ? rank.substring(MASTERY_RANK_FORMAT.length) : rank;
      if(this._name) this._name.x = 4 + int(Math.max(3, this._rank.width) + 0.5) - 3;
    }

    public function get rank() : String {
      return this._rank.text;
    }

    public function set name(name:String) : void {
      if(!this._name) {
        this._name = renderer.text(4,0,TEXT_FORMAT_NAME,"left",true);
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
        ExternalInterface.call("POST_SOUND_EVENT", "Play_ui_btnon_select");
        ExternalInterface.call("OnWhisper", this.name);
      }
    }

    private function onNameRightClick() : void {
      ExternalInterface.call("POST_SOUND_EVENT", "Play_ui_btnon_select");
      this.toggleModal();
    }

    /* ------------------- */
    /*   Setters/Getters   */
    /* ------------------- */

    public function set world(world:String) : void {
      if(!this._world) {
        this._world = renderer.text(4,17,TEXT_FORMAT_WORLD,"",true);
        this._world.width = 230;
        this._world.height = 16;
      }
      this._world.text = world;
    }

    public function get world() : String {
      return this._world.text;
    }

    public function set is_online(is_online:Boolean) : void {
      if(!this._is_online) this._is_online = renderer.rectangle(new Shape(), 0, 0, 2, 37, renderer.GREEN, 1);
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
          this.btnAccept = new txtbtn(76,13,config.msg.ACCEPT,271,5);
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

    private function buildRow() : void {
      this.buildCoreBtns();
      this.buildBtns();

      this.bg = renderer.rectangle(new Shape(), 2, 0, 353, 37, renderer.GRAY_28, 1);
      this.bg.visible = false;

      this._row = renderer.rectangle(new Sprite(), 0, 0, 2, 37, 5921894, 1);
      this._row.addChild(this.bg);
      this._row.width = 355;
      this._row.height = 37;
      this._row.addChild(this._is_online);
      this._row.addChild(this._rank);
      this._row.addChild(this._name);
      this._row.addChild(this._world);
      this._row.addChild(this.btnJoin);
      this._row.addChild(this.btnInvite);
      if(this.btnAccept) this._row.addChild(this.btnAccept);

      // create modal
      this.modal = renderer.rectangle(new Sprite(), 0, 0, 353, 37, renderer.GRAY_28, 1);

      var unfriendBtn:KeyboardBtn = new KeyboardBtn(76, 27, "UNFRIEND", 271, 5);
      unfriendBtn.addEventListener(MouseEvent.CLICK, function() : void {
        ExternalInterface.call("OnRemove", uid, is_request);
      });
      this.modal.addChild(unfriendBtn);

      this.modal.addEventListener(MouseEvent.RIGHT_CLICK, this.toggleModal);
      for each(var btn:icnbtn in this.btns) this.modal.addChild(btn);
    }

    private function toggleModal() : void {
      if(!this.modal.stage) this._row.addChild(this.modal);
      else this._row.removeChild(this.modal);
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

    private function buildBtns() : void {
      btns = [
        new icnbtn(config.scale(new IconHeart(), 0.75), 24, 24),
        new icnbtn(config.scale(new IconQuickList(), 0.75), 24, 24),
        new icnbtn(config.scale(new IconLeecher(), 0.75), 24, 24),
        new icnbtn(config.scale(new IconCleaner(), 0.75), 24, 24),
        new icnbtn(config.scale(new IconAlts(), 0.75), 24, 24)
      ];

      var i:int = 0;
      for each(var btn:icnbtn in btns) {
        btn.x = 3 + (i * 28);
        btn.y = 7;
        i++;
      }

      // Heart
      if(config.favs[this.uid]) {
        this.btns[0].toggled = true;
        this._name.textColor = renderer.FAVORITE_COLOR;
      }

      // Quick List
      if(config.quick[this.uid]) this.btns[1].toggled = true;

      // Leech
      if(config.leechers[this.uid]) this.btns[2].toggled = true;

      // Clean
      if(config.cleaners[this.uid]) {
        this.btns[3].toggled = true;
        this._name.textColor = renderer.CLEANER_COLOR;
      }

      // Alt
      if(config.alts[this.uid]) this.btns[4].toggled = true;

      this.btns[0].addEventListener(MouseEvent.CLICK, this.onFavorite);
      this.btns[1].addEventListener(MouseEvent.CLICK, this.onQuickList);
      this.btns[2].addEventListener(MouseEvent.CLICK, this.onLeech);
      this.btns[3].addEventListener(MouseEvent.CLICK, this.onClean);
      this.btns[4].addEventListener(MouseEvent.CLICK, this.onAlt);
    }

    /* ------------------- */
    /* --- Event Hooks --- */
    /* ------------------- */

    public function onInvite() : void {
      ExternalInterface.call("OnInviteToJoinMe",this.uid);
    }

    public function onJoin() : void {
      ExternalInterface.call("OnJoinWorld",this.uid);
      // if(this.can_join) ExternalInterface.call("OnJoinWorld",this.uid);
    }

    public function onAccept() : void {
      ExternalInterface.call("OnAcceptRequest",this.uid);
    }

    public function onFavorite() : void {
      var previous:Boolean = !!config.favs[this.uid];
      this.btns[0].toggled = !previous;

      if(previous) { // If favorite - remove it
        this._name.textColor = renderer.DEFAULT_NAME_COLOR;
        config.favs[this.uid] = null;
        this.friends.onFavoriteRemove(this);
      } else { // If default - make it favorite
        this._name.textColor = renderer.FAVORITE_COLOR;
        config.favs[this.uid] = true;
        this.friends.onFavoriteAdd(this);
      }

      this.toggleModal();
    }

    public function onAlt() : void {
      var previous:Boolean = !!config.alts[this.uid];
      this.btns[4].toggled = !previous;

      if(previous) {
        config.alts[this.uid] = null;
        this.friends.onAltRemove(this);
      } else {
        config.alts[this.uid] = true;
        this.friends.onAltAdd(this);
      }

      this.toggleModal();
    }

    public function onQuickList(is_internal:* = null) : void {
      var previous:Boolean = !!config.quick[this.uid];
      this.btns[1].toggled = !previous;

      if(previous) {
        config.quick[this.uid] = null;
        this.friends.onQuickListRemove(this,!!is_internal);
      } else {
        config.quick[this.uid] = true;
        this.friends.onQuickListAdd(this);
      }

      this.toggleModal();
    }

    public function onClean() : void {
      if(config.leechers[this.uid]) { // Disable leecher
        this.btns[2].toggled = false;
        this._name.textColor = renderer.DEFAULT_NAME_COLOR;
        config.leechers[this.uid] = null;
        this.friends.onLeecherRemove(this);
      }

      var previous:Boolean = !!config.cleaners[this.uid];
      this.btns[3].toggled = !previous;

      if(previous) {
        this._name.textColor = renderer.DEFAULT_NAME_COLOR;
        config.cleaners[this.uid] = null;
        this.friends.onCleanerRemove(this);
      } else {
        this._name.textColor = renderer.CLEANER_COLOR;
        config.cleaners[this.uid] = true;
        this.friends.onCleanerAdd(this);
      }

      this.toggleModal();
    }

    public function onLeech() : void {
      if(config.cleaners[this.uid]) { // Disable cleaner
        this.btns[3].toggled = false;
        this._name.textColor = renderer.DEFAULT_NAME_COLOR;
        config.cleaners[this.uid] = null;
        this.friends.onCleanerRemove(this);
      }

      var previous:Boolean = !!config.leechers[this.uid];
      this.btns[2].toggled = !previous;

      if(previous) {
        this._name.textColor = renderer.DEFAULT_NAME_COLOR;
        config.leechers[this.uid] = null;
        this.friends.onLeecherRemove(this);
      } else {
        this._name.textColor = renderer.LEECHER_COLOR;
        config.leechers[this.uid] = true;
        this.friends.onLeecherAdd(this);
      }

      this.toggleModal();
    }
  }
}
